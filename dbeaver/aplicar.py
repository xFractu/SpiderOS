#!/usr/bin/env python3
# SpiderOS: colores del editor SQL de DBeaver (cerrar DBeaver antes de correrlo)
import os, re

D = os.path.expanduser("~/.local/share/DBeaverData/workspace6/.metadata/.plugins/org.eclipse.core.runtime/.settings")
os.makedirs(D, exist_ok=True)

def rgb(h):
    h = h.lstrip("#")
    return ",".join(str(int(h[i:i+2], 16)) for i in (0, 2, 4))

def escribir(archivo, valores):
    p = os.path.join(D, archivo)
    txt = open(p).read() if os.path.exists(p) else ""
    for k, v in valores.items():
        linea = f"{k}={v}"
        if re.search(rf"^{re.escape(k)}=", txt, flags=re.M):
            txt = re.sub(rf"^{re.escape(k)}=.*$", linea, txt, flags=re.M)
        else:
            txt += ("" if txt.endswith("\n") or not txt else "\n") + linea + "\n"
    open(p, "w").write(txt)
    print("listo:", archivo)

S = "org.jkiss.dbeaver.sql.editor.color."
escribir("org.eclipse.ui.workbench.prefs", {
    S + "keyword.foreground":        rgb("#86D0E2"),   # SELECT, FROM, WHERE
    S + "table.foreground":          rgb("#D6EAF0"),   # tablas
    S + "column.foreground":         rgb("#B8E4EC"),   # columnas
    S + "column.derived.foreground": rgb("#9FC9D4"),   # columnas calculadas
    S + "composite.field.foreground":rgb("#B8E4EC"),
    S + "table.alias.foreground":    rgb("#7DB3BD"),   # alias
    S + "schema.foreground":         rgb("#9FC9D4"),   # esquemas
    S + "datatype.foreground":       rgb("#6FA8DC"),   # INT, VARCHAR
    S + "function.foreground":       rgb("#5CC4C4"),   # COUNT, NOW
    S + "string.foreground":         rgb("#8ED6B6"),   # 'texto'
    S + "number.foreground":         rgb("#E8A0A2"),   # 18, 3.5
    S + "parameter.foreground":      rgb("#E0585C"),   # :parametro
    S + "sqlVariable.foreground":    rgb("#E0585C"),   # ${variable}
    S + "comment.foreground":        rgb("#2F6E85"),   # -- comentarios
    S + "delimiter.foreground":      rgb("#5191A2"),   # ; , ( )
    S + "command.foreground":        rgb("#7DB3BD"),   # @set, @include
    S + "text.foreground":           rgb("#B8E4EC"),
    S + "text.background":           rgb("#05111D"),
})

escribir("org.eclipse.ui.editors.prefs", {
    "AbstractTextEditor.Color.Background": rgb("#05111D"),
    "AbstractTextEditor.Color.Background.SystemDefault": "false",
    "AbstractTextEditor.Color.Foreground": rgb("#B8E4EC"),
    "AbstractTextEditor.Color.Foreground.SystemDefault": "false",
    "AbstractTextEditor.Color.SelectionBackground": rgb("#266A88"),
    "AbstractTextEditor.Color.SelectionBackground.SystemDefault": "false",
    "currentLineColor": rgb("#0D2434"),
    "lineNumberColor": rgb("#2F6E85"),
})

# palabras clave en negrita
escribir("org.jkiss.dbeaver.core.prefs", {"SQLEditor.format.boldKeywords": "true"})
