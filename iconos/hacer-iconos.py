#!/usr/bin/env python3
# SpiderOS: tema de íconos "Papirus-SpiderOS" = Papirus-Dark con las carpetas en los azules de SpiderOS.
# Toma las carpetas "darkcyan" de Papirus y les cambia los colores. Se guarda en ~/.local/share/icons.
# Requiere: papirus-icon-theme (pacman) y haber corrido:  papirus-folders -C darkcyan --theme Papirus-Dark
import glob, os, re, shutil

ORIGEN  = "/usr/share/icons/Papirus"
DESTINO = os.path.expanduser("~/.local/share/icons/Papirus-SpiderOS")

# colores de las carpetas darkcyan de Papirus -> SpiderOS
CAMBIOS = {
    "#45abb7": "#266A88",   # frente de la carpeta
    "#35818a": "#174159",   # parte de atrás / símbolos
    "#e4e4e4": "#B8E4EC",   # hoja de papel
    "#eaeaea": "#D6EAF0",   # símbolos claros
}

if not os.path.isdir(ORIGEN):
    raise SystemExit("No encontré Papirus. Instálalo con: sudo pacman -S papirus-icon-theme")

if os.path.isdir(DESTINO):
    shutil.rmtree(DESTINO)
os.makedirs(DESTINO)

n = 0
for carpeta in glob.glob(os.path.join(ORIGEN, "*", "places")):
    tam = os.path.basename(os.path.dirname(carpeta))
    if "symbolic" in tam:
        continue
    for archivo in glob.glob(os.path.join(carpeta, "*.svg")):
        real = os.path.realpath(archivo)
        try:
            svg = open(real, encoding="utf-8").read()
        except Exception:
            continue
        if not any(c in svg.lower() for c in ("#45abb7", "#35818a")):
            continue                      # no es una carpeta darkcyan
        for viejo, nuevo in CAMBIOS.items():
            svg = re.sub(re.escape(viejo), nuevo, svg, flags=re.I)
        salida = os.path.join(DESTINO, tam, "places", os.path.basename(archivo))
        os.makedirs(os.path.dirname(salida), exist_ok=True)
        open(salida, "w", encoding="utf-8").write(svg)
        n += 1

# index.theme: mismo que Papirus-Dark, pero con nombre propio y heredando de él
idx = open("/usr/share/icons/Papirus-Dark/index.theme", encoding="utf-8").read()
idx = re.sub(r"(?m)^Name=.*$", "Name=Papirus-SpiderOS", idx, 1)
idx = re.sub(r"(?m)^Comment=.*$", "Comment=Papirus-Dark con carpetas SpiderOS", idx, 1)
idx = re.sub(r"(?m)^Inherits=.*$", "Inherits=Papirus-Dark,breeze-dark,hicolor", idx, 1)
open(os.path.join(DESTINO, "index.theme"), "w", encoding="utf-8").write(idx)

print(f"listo: {n} íconos de carpeta en {DESTINO}")
