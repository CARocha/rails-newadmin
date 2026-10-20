project = "rails-newadmin"
author = "CARocha"
copyright = "2026, CARocha"
release = "0.1.0.alpha.1"
extensions = ["myst_parser"]
source_suffix = {".md": "markdown"}
html_theme = "furo"
html_show_sourcelink = False
nitpicky = True
myst_heading_anchors = 3
html_theme_options = {
 "light_css_variables": {"color-brand-primary":"#344760","color-background-primary":"#f8f9ff"},
 "dark_css_variables": {"color-brand-primary":"#a8bce0","color-background-primary":"#11161d"},
}

exclude_patterns = ["contributing.md"]
