#!/usr/bin/env python3
"""Stop hook: renderiza los bloques ```mermaid del último turno del asistente a
PNG (mmdc) y los abre en un visor que salta al foco (imv, si no xdg-open).

- No bloquea: hace doble fork y devuelve el control al harness de inmediato.
- Deduplica por hash: cada diagrama se abre una sola vez por sesión.
- Log de diagnóstico en ~/.cache/claude-mermaid/hook.log
"""
import sys, os, json, re, hashlib, subprocess, shutil, time, glob

HOME = os.path.expanduser("~")
CACHE = os.path.join(HOME, ".cache", "claude-mermaid")
LOG = os.path.join(CACHE, "hook.log")

# Retención: los PNG/MMD solo se necesitan mientras el visor los carga; se
# borran a los 10 min. El estado de dedup (seen-*) se conserva 24 h.
MEDIA_TTL = 600
STATE_TTL = 86400


def prune_old() -> None:
    """Borra imágenes/temporales viejos para no acumular nada en disco."""
    now = time.time()
    for pat, ttl in (("*.png", MEDIA_TTL), ("*.mmd", MEDIA_TTL), ("seen-*.txt", STATE_TTL)):
        for f in glob.glob(os.path.join(CACHE, pat)):
            try:
                if now - os.path.getmtime(f) > ttl:
                    os.remove(f)
            except OSError:
                pass

# Asegura que mmdc (symlink en ~/.local/bin) esté en PATH.
os.environ["PATH"] = os.path.join(HOME, ".local", "bin") + os.pathsep + os.environ.get("PATH", "")


def log(msg: str) -> None:
    try:
        os.makedirs(CACHE, exist_ok=True)
        if os.path.exists(LOG) and os.path.getsize(LOG) > 200_000:
            os.remove(LOG)
        with open(LOG, "a") as f:
            f.write(msg.rstrip() + "\n")
    except Exception:
        pass


def last_turn_text(transcript_path: str) -> str:
    """Texto del último turno del asistente (varias entradas JSONL, saltando
    tool_result; se corta al llegar a un prompt humano real)."""
    try:
        entries = []
        with open(transcript_path) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entries.append(json.loads(line))
                except Exception:
                    continue
    except Exception as e:
        log(f"no pude leer transcript: {e}")
        return ""

    texts = []
    for d in reversed(entries):
        t = d.get("type")
        if t == "assistant":
            content = (d.get("message") or {}).get("content")
            if isinstance(content, list):
                for b in content:
                    if isinstance(b, dict) and b.get("type") == "text":
                        texts.append(b.get("text", ""))
        elif t == "user":
            content = (d.get("message") or {}).get("content")
            is_tool_result = isinstance(content, list) and any(
                isinstance(b, dict) and b.get("type") == "tool_result" for b in content
            )
            if is_tool_result:
                continue  # sigue siendo el mismo turno
            break  # prompt humano real → frontera del turno
        # otras entradas meta: se ignoran
    texts.reverse()
    return "\n".join(texts)


def puppeteer_config() -> str:
    """Config con --no-sandbox para que chromium headless de mmdc no falle."""
    path = os.path.join(CACHE, "puppeteer.json")
    if not os.path.exists(path):
        with open(path, "w") as f:
            json.dump({"args": ["--no-sandbox"]}, f)
    return path


def open_viewer(png: str) -> None:
    if os.environ.get("CLAUDE_MERMAID_NO_OPEN") == "1":
        log(f"NO_OPEN set, no abro {png}")
        return
    # Orden de preferencia: imv (Wayland) → display (ImageMagick, X11/XWayland)
    # → ffplay → xdg-open. En este equipo funciona `display` sin sudo.
    if shutil.which("imv"):
        cmd = ["imv", png]
    elif shutil.which("display"):
        cmd = ["display", "-title", "Claude · Mermaid", png]
    elif shutil.which("ffplay"):
        cmd = ["ffplay", "-autoexit", "-loglevel", "quiet", png]
    elif shutil.which("xdg-open"):
        cmd = ["xdg-open", png]
    else:
        log("sin visor disponible")
        return
    try:
        subprocess.Popen(
            cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL, start_new_session=True,
        )
        log(f"abierto: {' '.join(cmd)}")
    except Exception as e:
        log(f"fallo al abrir {png}: {e}")


def render_and_open(blocks, session_id: str) -> None:
    mmdc = shutil.which("mmdc")
    if not mmdc:
        log("mmdc no está en PATH")
        return
    os.makedirs(CACHE, exist_ok=True)
    prune_old()
    seen_path = os.path.join(CACHE, f"seen-{session_id}.txt")
    seen = set()
    if os.path.exists(seen_path):
        seen = set(open(seen_path).read().split())
    pconf = puppeteer_config()
    for block in blocks:
        h = hashlib.sha1(block.encode("utf-8")).hexdigest()[:16]
        if h in seen:
            continue
        mmd = os.path.join(CACHE, f"{h}.mmd")
        png = os.path.join(CACHE, f"{h}.png")
        with open(mmd, "w") as f:
            f.write(block)
        try:
            r = subprocess.run(
                [mmdc, "-i", mmd, "-o", png, "-p", pconf, "-b", "white"],
                stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, timeout=60,
            )
            if r.returncode != 0 or not os.path.exists(png):
                log(f"mmdc falló ({h}): {r.stderr.decode(errors='replace')[:300]}")
                continue
        except Exception as e:
            log(f"excepción mmdc ({h}): {e}")
            continue
        open_viewer(png)
        seen.add(h)
    with open(seen_path, "w") as f:
        f.write("\n".join(sorted(seen)))


def main() -> None:
    raw = sys.stdin.read()
    try:
        data = json.loads(raw)
    except Exception:
        return
    tpath = data.get("transcript_path")
    session_id = data.get("session_id", "default")
    if not tpath or not os.path.exists(tpath):
        return
    text = last_turn_text(tpath)
    blocks = re.findall(r"```mermaid[ \t]*\r?\n(.*?)```", text, re.DOTALL)
    blocks = [b.strip() for b in blocks if b.strip()]
    if not blocks:
        return

    # Doble fork → proceso desligado; el hook retorna ya.
    if os.environ.get("CLAUDE_MERMAID_SYNC") == "1":
        render_and_open(blocks, session_id)
        return
    try:
        if os.fork() != 0:
            return
        os.setsid()
        if os.fork() != 0:
            os._exit(0)
    except OSError:
        render_and_open(blocks, session_id)
        return
    devnull = os.open(os.devnull, os.O_RDWR)
    os.dup2(devnull, 0); os.dup2(devnull, 1); os.dup2(devnull, 2)
    render_and_open(blocks, session_id)
    os._exit(0)


if __name__ == "__main__":
    main()
