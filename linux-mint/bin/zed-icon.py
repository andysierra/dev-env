#!/usr/bin/python3
"""Le pone ícono a las ventanas de Zed en X11 (barra de tareas de MATE).

Zed no publica _NET_WM_ICON en sus ventanas, así que la lista de ventanas de MATE
(que usa el ícono de la ventana, no el del .desktop) muestra un cuadro gris genérico.
Este proceso escucha cuándo aparecen ventanas nuevas (_NET_CLIENT_LIST del root) y a
las de WM_CLASS "dev.zed.Zed" les escribe _NET_WM_ICON con el SVG del tema (Icon=zed).
Corre en segundo plano desde ~/.config/autostart/zed-icon.desktop.
"""
import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk
from Xlib import X, Xatom, display

WM_CLASS = "dev.zed.Zed"
SIZES = (16, 22, 24, 32, 48, 64, 128)


def icon_cardinals():
    """[ancho, alto, ARGB...] por cada tamaño, como pide _NET_WM_ICON."""
    theme = Gtk.IconTheme.get_default()
    data = []
    for size in SIZES:
        pb = theme.load_icon("zed", size, Gtk.IconLookupFlags.FORCE_SIZE)
        if not pb.get_has_alpha():
            pb = pb.add_alpha(False, 0, 0, 0)
        w, h, stride = pb.get_width(), pb.get_height(), pb.get_rowstride()
        px = pb.get_pixels()
        data += [w, h]
        for y in range(h):
            row = y * stride
            for x in range(w):
                r, g, b, a = px[row + 4 * x: row + 4 * x + 4]
                data.append((a << 24) | (r << 16) | (g << 8) | b)
    return data


def main():
    d = display.Display()
    root = d.screen().root
    net_client_list = d.intern_atom("_NET_CLIENT_LIST")
    net_wm_icon = d.intern_atom("_NET_WM_ICON")
    icon = icon_cardinals()
    done = set()

    def scan():
        prop = root.get_full_property(net_client_list, Xatom.WINDOW)
        clients = set(prop.value) if prop else set()
        done.intersection_update(clients)  # olvidar ventanas cerradas
        for wid in clients - done:
            win = d.create_resource_object("window", wid)
            try:
                cls = win.get_wm_class() or ()
                if WM_CLASS in cls:
                    win.change_property(net_wm_icon, Xatom.CARDINAL, 32, icon)
                done.add(wid)
            except Exception:  # la ventana pudo cerrarse entre medio
                pass
        d.flush()

    root.change_attributes(event_mask=X.PropertyChangeMask)
    scan()
    while True:
        ev = d.next_event()
        if ev.type == X.PropertyNotify and ev.atom == net_client_list:
            scan()


if __name__ == "__main__":
    main()
