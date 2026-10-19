import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from common import *
language = "es"
html_title = "rails-newadmin · Español"
html_theme_options = dict(html_theme_options, announcement='<a href="../en/index.html">English manual</a>')
