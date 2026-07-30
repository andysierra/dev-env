// Lanzador de yazi en iTerm: UNA sola ventana (singleton), en ~/Desktop, maximizada.
// Uso: osascript -l JavaScript yazi-desktop.js [id-ventana-conocida]
// Imprime el id de la ventana usada (el wrapper .sh lo guarda como estado).

const CMD = "/bin/zsh -lc 'cd ~/Desktop && exec yazi'";
const SHELLS = ["login", "zsh", "-zsh", "bash", "-bash", "sh", "-sh"];

function run(argv) {
  ObjC.import('AppKit');
  const sh = Application.currentApplication();
  sh.includeStandardAdditions = true;

  const iTerm = Application('iTerm');
  const wanted = parseInt(argv[0], 10);
  const wasRunning = iTerm.running();

  if (!wasRunning) {
    iTerm.launch();                     // launch (no activate) para no forzar ventana extra
    for (let i = 0; i < 40 && iTerm.windows().length === 0; i++) delay(0.25);
  }

  // 1) Singleton: si la ventana de yazi sigue viva, solo traerla al frente.
  //    (todo en try/catch: la ventana puede estar cerrandose justo ahora)
  if (wasRunning && !isNaN(wanted)) {
    try {
      const known = findWindow(iTerm, w => w.id() === wanted);
      if (known) {
        iTerm.activate();
        known.select();
        maximize(known);
        return String(wanted);
      }
    } catch (e) { /* ventana muerta -> se crea una nueva abajo */ }
  }

  // 2) Arranque en frio: reutilizar la ventana que iTerm abre al lanzarse,
  //    pero solo si es un shell inactivo (nunca escribir sobre trabajo ajeno).
  let win = null;
  if (!wasRunning) {
    try {
      win = findWindow(iTerm, w => isIdleShellWindow(w, sh));
      if (win) win.currentTab.currentSession.write({ text: "cd ~/Desktop && exec yazi" });
    } catch (e) { win = null; }
  }

  // 3) Si no habia nada reutilizable, ventana nueva con yazi.
  if (!win) win = iTerm.createWindowWithDefaultProfile({ command: CMD });

  iTerm.activate();
  win.select();
  maximize(win);
  return String(win.id());
}

// Recorre las ventanas tolerando referencias muertas (ventanas cerrandose).
function findWindow(iTerm, pred) {
  let ws;
  try { ws = iTerm.windows(); } catch (e) { return null; }
  for (let i = 0; i < ws.length; i++) {
    try { if (pred(ws[i])) return ws[i]; } catch (e) { /* siguiente */ }
  }
  return null;
}

// Ventana de un solo shell en reposo: 1 tab, 1 sesion y ningun proceso
// aparte del shell/login corriendo en su tty.
function isIdleShellWindow(w, sh) {
  try {
    if (w.tabs().length !== 1) return false;
    const tab = w.tabs()[0];
    if (tab.sessions().length !== 1) return false;
    const tty = tab.sessions()[0].tty().replace("/dev/", "");
    const procs = sh.doShellScript("ps -t " + tty + " -o comm= 2>/dev/null")
      .split("\r").join("\n").split("\n")
      .map(s => s.trim()).filter(s => s.length);
    return procs.length > 0 && procs.every(p => SHELLS.indexOf(basename(p)) !== -1);
  } catch (e) {
    return false;
  }
}

function basename(p) {
  const parts = p.split("/");
  return parts[parts.length - 1];
}

// Maximizado real: ocupa el area visible (sin menu bar ni Dock) de la pantalla
// donde esta la ventana. No es pantalla completa de macOS.
function maximize(win) {
  const primaryHeight = $.NSScreen.screens.objectAtIndex(0).frame.size.height;
  const screen = screenOf(win, primaryHeight);
  const vis = screen.visibleFrame;
  win.bounds = {
    x: vis.origin.x,
    y: primaryHeight - (vis.origin.y + vis.size.height),
    width: vis.size.width,
    height: vis.size.height
  };
}

function screenOf(win, primaryHeight) {
  try {
    const b = win.bounds();
    // bounds de AppleScript: origen arriba-izquierda; NSScreen: abajo-izquierda.
    const center = $.NSMakePoint(b.x + b.width / 2, primaryHeight - (b.y + b.height / 2));
    const screens = $.NSScreen.screens;
    for (let i = 0; i < screens.count; i++) {
      const s = screens.objectAtIndex(i);
      if ($.NSPointInRect(center, s.frame)) return s;
    }
  } catch (e) { /* cae al default */ }
  return $.NSScreen.mainScreen;
}
