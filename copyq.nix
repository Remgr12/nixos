{ pkgs, lib, ... }:

{
  home.packages = [ pkgs.copyq ];

  home.activation.copyqInit = lib.hm.dag.entryAfter ["writeBoundary"] ''
    COPYQ_CONF="$HOME/.config/copyq/copyq.conf"
    mkdir -p "$HOME/.config/copyq"
    if [ ! -f "$COPYQ_CONF" ]; then
      cat > "$COPYQ_CONF" << 'COPYQ_EOF'
[General]
clipboard_tab=&Clipboard
maxitems=500
CheckClipboard=true

[Commands]
Commands\size=1
Commands\1\Name=Screenshots
Commands\1\Command=copyToTab('Screenshots')
Commands\1\Icon=\xf03e
Commands\1\Input=image/png
Commands\1\Automatic=true
Commands\1\Enabled=true
Commands\1\HideWindow=true
Commands\1\InMenu=false
Commands\1\IsScript=false
Commands\1\Wait=false
Commands\1\Transform=false
Commands\1\InToolbar=false
Commands\1\Display=false
Commands\1\Shortcut=
Commands\1\Tag=
Commands\1\Output=
Commands\1\OutputTab=
Commands\1\Sep=\\n

[Theme]
alt_bg=#3B4252
alt_fg=#D8DEE9
bg=#2E3440
fg=#D8DEE9
find_bg=#EBCB8B
find_fg=#2E3440
font="JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
notes_fg=#88C0D0
num_fg=#81A1C1
num_font="JetBrainsMono Nerd Font,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
panel_sheet="QMainWindow,QDialog{background:#2E3440}QTabWidget::pane{border:1px solid #4C566A;background:#2E3440}QTabBar::tab{background:#3B4252;color:#D8DEE9;padding:5px 14px;border:1px solid #4C566A;border-bottom:none;border-radius:4px 4px 0 0;margin-right:2px}QTabBar::tab:selected{background:#5E81AC;color:#ECEFF4}QTabBar::tab:hover:!selected{background:#434C5E}QPushButton{background:#4C566A;color:#D8DEE9;border:1px solid #4C566A;border-radius:4px;padding:4px 10px}QPushButton:hover{background:#5E81AC;color:#ECEFF4}QPushButton:pressed{background:#81A1C1}QScrollBar:vertical{background:#3B4252;width:8px;margin:0}QScrollBar::handle:vertical{background:#4C566A;border-radius:4px;min-height:20px}QScrollBar::handle:vertical:hover{background:#5E81AC}QScrollBar::add-line:vertical,QScrollBar::sub-line:vertical{height:0}QScrollBar:horizontal{background:#3B4252;height:8px}QScrollBar::handle:horizontal{background:#4C566A;border-radius:4px}QScrollBar::handle:horizontal:hover{background:#5E81AC}QScrollBar::add-line:horizontal,QScrollBar::sub-line:horizontal{width:0}QLineEdit,QTextEdit{background:#3B4252;color:#D8DEE9;border:1px solid #4C566A;border-radius:4px;padding:3px;selection-background-color:#5E81AC}QToolBar{background:#2E3440;border:none;padding:2px}QStatusBar{background:#2E3440;color:#D8DEE9}QMenu{background:#3B4252;color:#D8DEE9;border:1px solid #4C566A}QMenu::item:selected{background:#5E81AC;color:#ECEFF4}"
search_bar=true
search_bar_at_bottom=false
sel_bg=#5E81AC
sel_fg=#ECEFF4
show_number=true
show_scrollbars=true
style_main_window=true
use_system_icons=false
COPYQ_EOF
    elif ! grep -q "copyToTab" "$COPYQ_CONF" 2>/dev/null; then
      cat >> "$COPYQ_CONF" << 'COPYQ_EOF'

[Commands]
Commands\size=1
Commands\1\Name=Screenshots
Commands\1\Command=copyToTab('Screenshots')
Commands\1\Icon=\xf03e
Commands\1\Input=image/png
Commands\1\Automatic=true
Commands\1\Enabled=true
Commands\1\HideWindow=true
Commands\1\InMenu=false
Commands\1\IsScript=false
Commands\1\Wait=false
Commands\1\Transform=false
Commands\1\InToolbar=false
Commands\1\Display=false
Commands\1\Shortcut=
Commands\1\Tag=
Commands\1\Output=
Commands\1\OutputTab=
Commands\1\Sep=\\n
COPYQ_EOF
    fi
  '';
}
