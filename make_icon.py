import urllib.request
from PIL import Image
import os

# ஐகான் கோப்பு உள்ளதா என சரிபார்த்து உருவாக்கல்
if not os.path.exists('assets/app_icon.png'):
    im = Image.new('RGBA', (512, 512), color=(25, 20, 20, 255))
    im.save('assets/app_icon.png')
