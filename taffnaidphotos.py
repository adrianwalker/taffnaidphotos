import os
from subprocess import call

CONVERT_CMD = "convert"
PREVIEW_SIZE = "150x150"
PREVIEW_PREFIX = "preview_"
HTML_EXTENSION = ".html"
IMG_EXTENSION = ".jpg"
INDEX = "index.html"
ALBUM_IMG = "/album.png"

LIST_TEMPLATE = """
<!DOCTYPE html>
<html>
  <head>
    <title>taffnaid.photos</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" type="text/css" href="/taffnaidphotos.css">
  </head>
  <body>
    <div id="list" class="list">
      <div id="list-nav" class="nav">
        {0}
      </div>
      <div id="list-previews" class="previews">
        {1}
      </div>    
    </div>
  </body>
</html>
"""

LIST_NAV_TEMPLATE = """
<a href="{0}" class="parent">&#9783;</a>
"""

PREVIEW_TEMPLATE = """
<div class="preview">
  <a href="{0}">
    <img src="{1}" alt=":-("/>
    <div class="name">{2}</div>
  </a>
</div>
"""

VIEW_TEMPLATE = """
<!DOCTYPE html>
<html>
  <head>
    <title>taffnaid.photos</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" type="text/css" href="/taffnaidphotos.css">
  </head>
  <body>
    <div id="view" class="view">
      <div id="view-nav" class="nav">
        {0}
      </div>
      <div id="view-image" class="image">
        <img src="{1}" alt=":-("/>
        <link rel="prefetch" href="{2}">
        <link rel="prefetch" href="{3}">
      </div>
    </div>
  </body>
</html>
"""

VIEW_NAV_TEMPLATE = """
<a href="{0}" class="previous">&lang;</a>
<a href="{1}" class="parent">&#9783;</a>
<a href="{2}" class="next">&rang;</a>
"""

cwd = os.getcwd()

for root, dirs, files in os.walk(cwd):

    dirs = sorted(dirs)

    files = filter(lambda file: file.endswith(IMG_EXTENSION), files)
    files = filter(lambda file: not file.startswith(PREVIEW_PREFIX), files)
    files = sorted(files)

    preview_html = ""

    for dir in dirs:
        preview_html = PREVIEW_TEMPLATE.format(
            os.path.join(dir, INDEX),
            ALBUM_IMG,
            dir) + preview_html

    for i, file in enumerate(files):
        previous = files[i - 1]
        parent = os.path.join(root.replace(cwd, ""), INDEX)
        next = files[(i + 1) % len(files)]

        nav_html = VIEW_NAV_TEMPLATE.format(
            previous + HTML_EXTENSION,
            parent,
            next + HTML_EXTENSION
        )

        preview_html = preview_html + PREVIEW_TEMPLATE.format(
            file + HTML_EXTENSION,
            PREVIEW_PREFIX + file,
            file)

        view_html = VIEW_TEMPLATE.format(
            nav_html,
            file,
            previous,
            next
        )

        image = os.path.abspath(os.path.join(root, file))
        preview = os.path.abspath(os.path.join(os.path.dirname(image), PREVIEW_PREFIX + os.path.basename(image)))

        cmd = [
            CONVERT_CMD,
            "-define", "jpeg:size=%s" % PREVIEW_SIZE,
            image,
            "-thumbnail", "%s^" % PREVIEW_SIZE,
            "-gravity", "center",
            "-extent", PREVIEW_SIZE,
            preview]

        call(cmd)

        view_file = image + HTML_EXTENSION

        with open(view_file, 'w') as view_file:
            view_file.write(view_html)

    parent = os.path.join(os.path.dirname(root.replace(cwd, "")), INDEX)
    nav_html = LIST_NAV_TEMPLATE.format(parent)

    list_html = LIST_TEMPLATE.format(
        nav_html,
        preview_html)
    index_file = os.path.join(root, INDEX)

    with open(index_file, 'w') as index_file:
        index_file.write(list_html)
