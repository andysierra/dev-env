# Brave en Linux — video por GPU, perfiles y PWAs

## Para el humano

Lo aprendido haciendo que YouTube en Brave deje de ir con lag en Linux. Probado en Linux Mint 22.3 MATE (X11),
Intel UHD (Comet Lake, i5-10210U), Brave 1.96 (Chromium ~154). Resultado medido: la pestaña de un video VP9 720p
pasó de **48 % de CPU a 9 %**.

```text
Qué                              Cómo
-------------------------------  ----------------------------------------------------------------
Video por GPU                    flags en el Exec= de los .desktop de Brave (ver abajo)
YouTube sin AV1                  extensión enhanced-h264ify: Block AV1 (+VP8), VP9 permitido
Perfiles desde rofi              crp (Personal) · crd (dev) · crw (Work)
Verificar                        brave://media-internals → kVideoDecoderName = VaapiVideoDecoder
```

### Para replicar en un sistema nuevo
Compartí este archivo con Claude Code y pedile: *"implementa la sección Para la IA de esta bitácora en este sistema"*.

---

## Para la IA

### Por qué había lag — tres fallas en cadena

Cada una basta para que el video lo decodifique la CPU; hay que resolver las tres.

```text
#  Falla                                          Evidencia                                   Arreglo
-  ---------------------------------------------  ------------------------------------------  ---------------------------
1  Brave en Linux trae la decodificación por GPU   ningún --enable-features de video en su     flags en los .desktop
   apagada                                         gpu-process (ps / /proc/<pid>/cmdline)
2  YouTube manda AV1 y la GPU no lo decodifica     media-internals: codec av1 →                enhanced-h264ify (Block AV1)
   (Intel < Gen12/Tiger Lake no tiene AV1)         "Dav1dVideoDecoder" (CPU)
3  Con el camino OpenGL falla la conversión del    VaapiVideoDecoder vive 0,01 s →             --use-angle=vulkan
   cuadro (NV12 → motor gráfico: ImageProcessor)   "video decoder fallback after initial
                                                   decode error" → VpxVideoDecoder (CPU)
```

Con **ANGLE sobre Vulkan** el cuadro de la GPU se usa directo, sin ImageProcessor, y la decodificación queda estable.

### 1. Requisitos

```sh
vainfo | grep -E 'Driver version|VLD'      # driver VA-API y códecs que decodifica la GPU
```
- Intel: `intel-media-va-driver` (iHD). En Mint ya viene; en Arch/CachyOS: `intel-media-driver`.
- Vulkan: `mesa-vulkan-drivers` (Mint) / `vulkan-intel` (Arch). Debe existir `/usr/share/vulkan/icd.d/intel_icd*.json`.

### 2. Flags — en el `.desktop`, no en un archivo de flags

El lanzador de Brave (`/opt/brave.com/brave/brave-browser`) **no lee** `~/.config/brave-flags.conf` ni nada
parecido: ejecuta `brave "$@"`. Las flags van en cada `Exec=` (menú, acciones "Nueva ventana"/"Incógnito",
lanzadores de perfil):

```text
--use-angle=vulkan --enable-features=Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,AcceleratedVideoDecodeLinuxGL,VaapiVideoDecoder
```

Copia del `.desktop` del sistema en `~/.local/share/applications/brave-browser.desktop` (mismo nombre → lo tapa,
sin sudo y sin que lo pise una actualización de Brave):

```sh
FLAGS='--use-angle=vulkan --enable-features=Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,AcceleratedVideoDecodeLinuxGL,VaapiVideoDecoder'
sed "s|^Exec=/usr/bin/brave-browser-stable|Exec=/usr/bin/brave-browser-stable $FLAGS|" \
    /usr/share/applications/brave-browser.desktop > ~/.local/share/applications/brave-browser.desktop
```

Variantes probadas que **no** sirven en X11 (todas destruyen el decodificador a los ~10 ms):
`AcceleratedVideoDecodeLinuxGL`, `+AcceleratedVideoDecodeLinuxZeroCopyGL`, `+--use-gl=angle --use-angle=gl`,
`--disable-features=UseChromeOSDirectVideoDecoder`. En Wayland no está probado (ZeroCopyGL podría ser la indicada ahí).

### 3. YouTube sin AV1 — enhanced-h264ify

Chrome Web Store → *enhanced-h264ify* → Añadir. En su menú: **Block VP8 ✓, Block VP9 ☐, Block AV1 ✓**.
Así YouTube manda VP9 (la GPU sí; mejor calidad que H.264). Permisos: solo youtube.com / youtu.be / youtube-nocookie.

### 4. Perfiles desde rofi

Un `.desktop` por perfil con `--profile-directory`; el `Name=` empieza con la palabra clave porque rofi busca por
prefijo de palabra. Los de Linux Mint están en `../linux-mint/applications/brave-cr{p,d,w}.desktop`.

```text
rofi   Name=                     --profile-directory
-----  ------------------------  -------------------
crp    crp (Brave · Personal)    "Default"
crd    crd (Brave · dev)         "Profile 1"
crw    crw (Brave · Work)        "Profile 2"
```

Carpeta y nombre de cada perfil: `~/.config/BraveSoftware/Brave-Browser/Local State` → `profile.info_cache`.

### 5. Reiniciar Brave sin perder nada

Las flags son del **proceso**: hay que cerrar Brave entero (también "seguir corriendo en segundo plano",
`brave://settings/system`) y abrirlo desde un `.desktop` con flags. Gotchas:

- Con "¿Quién usa Brave?" (selector de perfiles al iniciar), `--restore-last-session` **no restaura**:
  abrir con `--profile-directory=Default` para saltar el selector.
- Las **PWA nunca** se restauran así: viven en `Default/Sessions/Apps_*`, no en `Session_*`. Reabrir cada una en su
  página: `brave --profile-directory=Default --app-id=<id> --app-launch-url-for-shortcuts-menu-item=<url>`
  (URLs: `strings Sessions/Apps_* | grep -oE 'https://[^ ]+'`; id = `crx_<id>` de su ventana / su `.desktop`).
- Cierre ordenado (guarda la sesión): `kill -TERM` al proceso principal (`/opt/brave.com/brave/brave` sin `--type=`).
- Si Brave lo arranca una **PWA** (sus `.desktop` los genera Brave, sin flags), el proceso va sin aceleración.

### 6. Verificar

Con un video sonando, `brave://media-internals` → el reproductor → buscar `kVideoDecoderName`:

```text
VaapiVideoDecoder   + kIsPlatformVideoDecoder: true   → GPU ✓
Dav1dVideoDecoder                                     → AV1 por CPU (falta el paso 3)
VpxVideoDecoder                                       → VP9 por CPU (las flags no aplicaron o falló la GPU)
```

### 7. Diagnóstico sin tocar la sesión del usuario

Brave aislado + video de prueba + registro del decodificador:

```sh
ffmpeg -f lavfi -i testsrc2=size=1280x720:rate=30 -t 20 -c:v libvpx-vp9 -deadline realtime -cpu-used 8 /tmp/vp9test.webm
timeout 12 /opt/brave.com/brave/brave --user-data-dir=/tmp/bt --no-first-run --disable-extensions \
  --autoplay-policy=no-user-gesture-required --enable-logging=stderr --vmodule='*/media/gpu/*=4' \
  <FLAGS> file:///tmp/vp9test.webm 2>&1 | grep -E 'VaapiVideoDecoder|ImageProcessor'
```

Si `~VaapiVideoDecoder()` aparece a los milisegundos de `VaapiVideoDecoder()` (y antes "Initializing
ImageProcessor"), la GPU falló y volvió a CPU. Si no aparece, decodifica por GPU. Comparar CPU con `top -b -d 5 -n 2`
(no `ps`: `ps` da el promedio desde que arrancó el proceso).

### Límites conocidos

- Vulkan en X11 es el camino menos usado: si aparecen parpadeos o páginas en negro, sospechar de esto.
- AV1 de otros sitios (no YouTube) sigue por CPU: límite del hardware.
