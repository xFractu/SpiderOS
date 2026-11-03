#!/usr/bin/env python3
# SpiderOS: colores de VS Code (estilo DBeaver SpiderOS) sin borrar tu configuración
import json, os, re

MEDIO  = "#174159"   # barras y paneles (como DBeaver)
MEDIO2 = "#13384E"   # encabezados y pestañas inactivas
FONDO  = "#05111D"   # área del código
BORDE  = "#2F6E85"
TEXTO  = "#B8E4EC"
CLARO  = "#D6EAF0"
TENUE  = "#7DB3BD"
CIAN   = "#86D0E2"
ACENTO = "#266A88"
ROJO   = "#E0585C"

COLORES = {
  # editor
  "editor.background": FONDO, "editor.foreground": TEXTO,
  "editor.lineHighlightBackground": "#0D2434", "editor.lineHighlightBorder": "#0D2434",
  "editor.selectionBackground": "#266A8899", "editor.inactiveSelectionBackground": "#266A8855",
  "editorCursor.foreground": CIAN,
  "editorLineNumber.foreground": BORDE, "editorLineNumber.activeForeground": CIAN,
  "editorIndentGuide.background1": "#0D2434", "editorIndentGuide.activeBackground1": BORDE,
  "editorGutter.background": FONDO, "minimap.background": FONDO,
  "editorWidget.background": MEDIO2, "editorWidget.border": BORDE,
  "editorSuggestWidget.background": MEDIO2, "editorSuggestWidget.border": BORDE,
  "editorSuggestWidget.selectedBackground": ACENTO, "editorHoverWidget.background": MEDIO2,
  "editorHoverWidget.border": BORDE, "editorError.foreground": ROJO,
  "editorWarning.foreground": "#E0A458", "editorBracketMatch.border": CIAN,
  "editorBracketMatch.background": "#266A8844",
  # pestañas
  "editorGroupHeader.tabsBackground": MEDIO, "editorGroupHeader.tabsBorder": BORDE,
  "editorGroup.border": BORDE,
  "tab.activeBackground": FONDO, "tab.activeForeground": CLARO, "tab.activeBorderTop": CIAN,
  "tab.inactiveBackground": MEDIO, "tab.inactiveForeground": TENUE,
  "tab.border": BORDE, "tab.hoverBackground": MEDIO2,
  "breadcrumb.background": FONDO, "breadcrumb.foreground": TENUE,
  "breadcrumb.focusForeground": CLARO,
  # barra lateral y actividad
  "sideBar.background": MEDIO, "sideBar.foreground": TEXTO, "sideBar.border": BORDE,
  "sideBarTitle.foreground": CLARO,
  "sideBarSectionHeader.background": MEDIO2, "sideBarSectionHeader.foreground": CLARO,
  "sideBarSectionHeader.border": BORDE,
  "activityBar.background": MEDIO, "activityBar.foreground": CIAN,
  "activityBar.inactiveForeground": TENUE, "activityBar.border": BORDE,
  "activityBar.activeBorder": CIAN,
  "activityBarBadge.background": ROJO, "activityBarBadge.foreground": CLARO,
  "tree.indentGuidesStroke": BORDE,
  "list.activeSelectionBackground": ACENTO, "list.activeSelectionForeground": CLARO,
  "list.inactiveSelectionBackground": MEDIO2, "list.hoverBackground": MEDIO2,
  "list.focusOutline": CIAN,
  # título, estado y panel inferior
  "titleBar.activeBackground": MEDIO, "titleBar.activeForeground": TEXTO,
  "titleBar.inactiveBackground": MEDIO, "titleBar.inactiveForeground": TENUE,
  "titleBar.border": BORDE,
  "commandCenter.background": MEDIO2, "commandCenter.border": BORDE,
  "commandCenter.foreground": TEXTO,
  "statusBar.background": MEDIO, "statusBar.foreground": TEXTO, "statusBar.border": BORDE,
  "statusBar.noFolderBackground": MEDIO, "statusBar.debuggingBackground": ACENTO,
  "statusBarItem.remoteBackground": ACENTO, "statusBarItem.hoverBackground": MEDIO2,
  "panel.background": FONDO, "panel.border": BORDE,
  "panelTitle.activeBorder": CIAN, "panelTitle.activeForeground": CLARO,
  "panelTitle.inactiveForeground": TENUE,
  "terminal.background": FONDO, "terminal.foreground": "#81B6C6",
  "terminalCursor.foreground": CIAN,
  # controles
  "focusBorder": CIAN, "foreground": TEXTO, "widget.border": BORDE,
  "input.background": FONDO, "input.border": BORDE, "input.foreground": TEXTO,
  "dropdown.background": MEDIO2, "dropdown.border": BORDE,
  "button.background": ACENTO, "button.hoverBackground": "#3B849F",
  "button.foreground": CLARO, "badge.background": ACENTO,
  "quickInput.background": MEDIO2, "quickInputList.focusBackground": ACENTO,
  "menu.background": MEDIO2, "menu.border": BORDE, "menu.selectionBackground": ACENTO,
  "notifications.background": MEDIO2, "notifications.border": BORDE,
  "scrollbarSlider.background": "#2F6E8566", "scrollbarSlider.hoverBackground": "#3B849F88",
  "welcomePage.background": FONDO,
}


# ---- interfaz moderna de VS Code (paneles flotantes) ----
BORDE_CLARO = "#2F6E85"   # bordes de los paneles (cámbialo a BORDE si lo quieres más discreto)
COLORES.update({
  # fondo alrededor de los paneles y barra de abajo
  "modernUI.shellBackground": MEDIO, "modernUI.inactiveShellBackground": MEDIO,
  "statusBar.background": MEDIO, "statusBar.noFolderBackground": MEDIO, "statusBar.border": MEDIO,
  # paneles (tarjetas): oscuros con borde clarito
  "surface.background": FONDO, "surface.foreground": TEXTO, "surface.border": BORDE_CLARO,
  "editor.border": BORDE_CLARO, "modernPanel.border": BORDE_CLARO, "sideBar.border": BORDE_CLARO,
  "panel.border": BORDE_CLARO, "editorPane.background": FONDO,
  # archivos / extensiones y barra de íconos en oscuro
  "sideBar.background": FONDO, "sideBarSectionHeader.background": FONDO,
  "activityBar.background": FONDO, "modernActivityBar.background": FONDO,
  "modernActivityBar.inactiveBackground": FONDO, "modernActivityBar.border": BORDE_CLARO,
  "modernActivityBarItem.activeBackground": "#143B52", "modernActivityBarItem.activeForeground": CIAN,
  "modernActivityBarItem.hoverBackground": "#0D2434", "modernActivityBarItem.hoverForeground": CLARO,
  # pestañas
  "editorGroupHeader.tabsBackground": FONDO, "editorGroupHeader.noTabsBackground": FONDO,
  "editorGroupHeader.border": BORDE, "editorGroupHeader.tabsBorder": BORDE,
  "modernEditorTab.activeBackground": "#143B52", "modernEditorTab.activeForeground": CLARO,
  "modernEditorTab.inactiveBackground": FONDO,
  "modernEditorTab.hoverBackground": "#0D2434", "modernEditorTab.hoverForeground": CLARO,
  "modernEditorTab.activeHoverBackground": "#1A4A60",
  "modernEditorTab.activeActionBackground": "#143B52", "modernEditorTab.hoverActionBackground": "#0D2434",
  "modernEditorTab.activeHoverActionBackground": "#1A4A60", "modernEditorTab.selectedActionBackground": "#143B52",
  "modernTab.activeBackground": "#143B52", "modernTab.activeForeground": CLARO,
  "modernTab.hoverBackground": "#0D2434", "modernTab.hoverForeground": CLARO,
  "tab.activeBackground": "#143B52", "tab.inactiveBackground": FONDO, "tab.border": FONDO,
  "modernSash.gripForeground": BORDE,
})

# ---- todo lo de afuera en oscuro ----
COLORES.update({
  "modernUI.shellBackground": FONDO, "modernUI.inactiveShellBackground": FONDO,
  "titleBar.activeBackground": FONDO, "titleBar.inactiveBackground": FONDO, "titleBar.border": FONDO,
  "statusBar.background": FONDO, "statusBar.noFolderBackground": FONDO, "statusBar.border": FONDO,
  "statusBarItem.prominentBackground": "#143B52", "statusBarItem.prominentHoverBackground": "#1A4A60",
  "statusBarItem.hoverBackground": "#0D2434",
  "commandCenter.background": "#0D2434",
})

# ---- pestañas cuando VS Code no tiene el foco (si no, se ponen grises) ----
COLORES.update({
  "tab.unfocusedActiveBackground": "#143B52", "tab.unfocusedActiveForeground": TENUE,
  "tab.unfocusedInactiveBackground": FONDO, "tab.unfocusedInactiveForeground": BORDE,
  "tab.unfocusedHoverBackground": "#0D2434", "tab.unfocusedActiveBorderTop": BORDE,
  "tab.unfocusedActiveBorder": FONDO,
  "editorGroupHeader.tabsBackground": FONDO, "editorGroupHeader.noTabsBackground": FONDO,
  "editorGroup.emptyBackground": FONDO,
})

# ---- franja de pestañas de la interfaz moderna (el gris #2b2b2b) ----
COLORES.update({
  "editorGroupHeader.connectedTabsBackground": FONDO,
})

# ---- barra de abajo cuando VS Code no tiene el foco ----
COLORES.update({
  "statusBar.inactiveBackground": FONDO,
})

AJUSTES = {
  "workbench.colorTheme": "Default Dark Modern",   # colores del código como en Neovim
  "workbench.tree.renderIndentGuides": "always",
}

candidatos = [
  "~/.config/Code/User", "~/.config/Code - OSS/User", "~/.config/VSCodium/User",
  "~/.var/app/com.visualstudio.code/config/Code/User",
  "~/.var/app/com.vscodium.codium/config/VSCodium/User",
]
hechos = 0
for c in candidatos:
    d = os.path.expanduser(c)
    if not os.path.isdir(os.path.dirname(d)):
        continue
    os.makedirs(d, exist_ok=True)
    p = os.path.join(d, "settings.json")
    datos = {}
    if os.path.exists(p):
        original = open(p).read()
        txt = re.sub(r"^\s*//.*$", "", original, flags=re.M)
        txt = re.sub(r",(\s*[}\]])", r"\1", txt)
        try:
            datos = json.loads(txt or "{}")
        except Exception as e:
            print(f"OJO: no pude leer {p} ({e}). Mándamelo y lo acomodo."); continue
        if not os.path.exists(p + ".antes-spideros"):
            open(p + ".antes-spideros", "w").write(original)
    datos.update(AJUSTES)
    cc = datos.get("workbench.colorCustomizations", {})
    cc = {k: v for k, v in cc.items() if not k.startswith("[")}   # quitar la versión anterior
    cc.update(COLORES)
    datos["workbench.colorCustomizations"] = cc
    json.dump(datos, open(p, "w"), indent=2)
    print("listo:", p); hechos += 1

if not hechos:
    print("No encontré la configuración de VS Code. Ábrelo una vez, ciérralo y vuelve a correr esto.")
