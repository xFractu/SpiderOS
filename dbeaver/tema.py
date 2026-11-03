#!/usr/bin/env python3
# SpiderOS: tema para la interfaz de DBeaver (cambia el gris del tema Dark por los azules de SpiderOS)
# Toma el tema Dark que trae tu propio DBeaver, cambia sus colores y lo guarda como reemplazo.
# Cerrar DBeaver antes de correrlo.  Para quitarlo:  python3 tema.py --quitar
import glob, os, re, sys, zipfile

NOMBRE = "e4-dark_linux.css"

# escala de grises -> escala de azules SpiderOS (luminosidad: color)
ESCALA = [
    (0,   (0x02, 0x0A, 0x12)),
    (30,  (0x05, 0x11, 0x1D)),   # fondo
    (45,  (0x08, 0x18, 0x26)),
    (55,  (0x0D, 0x24, 0x34)),   # paneles
    (70,  (0x14, 0x3B, 0x52)),
    (90,  (0x1E, 0x50, 0x68)),
    (120, (0x2F, 0x6E, 0x85)),   # bordes
    (160, (0x51, 0x91, 0xA2)),   # texto tenue
    (190, (0x7D, 0xB3, 0xBD)),
    (215, (0xB8, 0xE4, 0xEC)),   # texto
    (240, (0xD6, 0xEA, 0xF0)),
    (256, (0xEA, 0xF6, 0xF9)),
]

def gris_a_azul(l):
    for (l1, c1), (l2, c2) in zip(ESCALA, ESCALA[1:]):
        if l1 <= l < l2:
            f = (l - l1) / (l2 - l1)
            return tuple(round(a + (b - a) * f) for a, b in zip(c1, c2))
    return ESCALA[-1][1]

def convertir(r, g, b):
    l = 0.299 * r + 0.587 * g + 0.114 * b
    if max(r, g, b) - min(r, g, b) < 40:          # gris
        return gris_a_azul(l)
    if b > r + 40 and b >= g:                     # azules de Eclipse -> azules SpiderOS
        return (0x86, 0xD0, 0xE2) if l > 110 else (0x26, 0x6A, 0x88)
    return (r, g, b)                              # otros colores (avisos, errores) se quedan

def hexa(c): return "#%02X%02X%02X" % c

def cambiar_colores(css):
    def h6(m):
        v = m.group(1)
        if len(v) == 3: v = "".join(ch * 2 for ch in v)
        return hexa(convertir(int(v[0:2], 16), int(v[2:4], 16), int(v[4:6], 16)))
    css = re.sub(r"#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b", h6, css)
    css = re.sub(r"rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)",
                 lambda m: hexa(convertir(*map(int, m.groups()))), css)
    # colores en preferencias: 'clave=R,G,B'
    css = re.sub(r"=(\d{1,3}),(\d{1,3}),(\d{1,3})\b",
                 lambda m: "=" + ",".join(map(str, convertir(*map(int, m.groups())))), css)
    return css

def buscar_jar():
    bases = ["/usr/share/dbeaver*", "/usr/lib/dbeaver*", "/opt/dbeaver*", "/usr/share/dbeaver-ce",
             os.path.expanduser("~/.local/share/dbeaver*"), "/var/lib/flatpak/app/io.dbeaver.DBeaverCommunity/current/active/files/*"]
    for b in bases:
        for j in glob.glob(b + "/plugins/org.eclipse.ui.themes_*"):
            return j

def armar(jar):
    if os.path.isdir(jar):
        leer_archivo = lambda r: open(os.path.join(jar, r), "rb").read()
    else:
        z = zipfile.ZipFile(jar)
        leer_archivo = z.read
    vistos = set()
    def leer(ruta):
        if ruta in vistos: return ""
        vistos.add(ruta)
        txt = leer_archivo(ruta).decode("utf-8", "replace")
        def imp(m):
            url = m.group(1)
            pre = "platform:/plugin/org.eclipse.ui.themes/"
            if url.startswith(pre):
                return "/* --- " + url + " --- */\n" + leer(url[len(pre):])
            if not url.startswith("platform:"):
                return leer(os.path.normpath(os.path.join(os.path.dirname(ruta), url)))
            return m.group(0)
        return re.sub(r'@import\s+url\(\s*["\']?([^"\')]+)["\']?\s*\)\s*;', imp, txt)
    return leer("css/" + NOMBRE)

def carpetas_destino():
    salida = set()
    for raiz in [os.path.expanduser("~"), "/usr/share", "/usr/lib", "/opt"]:
        for d, subdirs, _ in os.walk(raiz):
            if os.path.basename(d) == "org.eclipse.e4.ui.css.swt.theme":
                salida.add(d); subdirs[:] = []
            elif d.count(os.sep) - raiz.count(os.sep) > 7 or any(x in d for x in ("/proc", "/.cache", "node_modules", "/.git", "/.npm")):
                subdirs[:] = []
    return [d for d in salida if "dbeaver" in d.lower() or "jkiss" in d.lower() or ".eclipse" in d]

destinos = carpetas_destino()
if not destinos:
    print("No encontré la carpeta de temas de DBeaver. Ábrelo una vez con el tema Dark, ciérralo y vuelve a correr esto.")
    sys.exit(1)

if "--quitar" in sys.argv:
    for d in destinos:
        p = os.path.join(d, NOMBRE)
        if os.path.exists(p): os.remove(p); print("quitado:", p)
    sys.exit(0)

jar = buscar_jar()
if not jar:
    print("No encontré el tema Dark dentro de DBeaver (org.eclipse.ui.themes_*)."); sys.exit(1)

css = "/* SpiderOS: tema Dark de DBeaver con los azules de SpiderOS (generado por tema.py) */\n" + cambiar_colores(armar(jar))
for d in destinos:
    p = os.path.join(d, NOMBRE)
    try:
        open(p, "w").write(css); print("listo:", p)
    except PermissionError:
        print("sin permiso (corre con sudo si es necesario):", p)
