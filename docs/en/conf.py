import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from common import *
language = "en"
html_title = "rails-newadmin · English"
html_theme_options = dict(html_theme_options, announcement='<a href="../es/index.html">Manual en español</a>')
