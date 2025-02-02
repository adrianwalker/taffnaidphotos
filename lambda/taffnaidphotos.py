import os
import subprocess
import tempfile

import boto3

BUCKET = os.environ['BUCKET']

CONVERT_CMD = '/opt/bin/convert'
PREVIEW_SIZE = '150x150'
PREVIEW_PREFIX = 'preview_'
HTML_EXTENSION = '.html'
JPG_EXTENSION = '.jpg'
INDEX = 'index.html'
ALBUM = 'album.png'


def read(file: str):
    with open(file, 'r') as f:
        return f.read()


LIST_TEMPLATE = read('list.html')
LIST_NAV_TEMPLATE = read('list-nav.html')
PREVIEW_TEMPLATE = read('preview.html')
VIEW_TEMPLATE = read('view.html')
VIEW_NAV_TEMPLATE = read('view-nav.html')

s3 = boto3.client('s3')


def put_object(key: str, body: str, content_type='text/html') -> None:
    s3.put_object(Bucket=BUCKET, Key=key, Body=body, ContentType=content_type)


def download_file(key: str) -> str:
    with tempfile.NamedTemporaryFile(delete=False) as f:
        s3.download_fileobj(BUCKET, key, f)

    path = f.name

    return path


def upload_file(path: str, key: str) -> None:
    with open(path, 'rb') as f:
        s3.upload_fileobj(f, BUCKET, key)


def delete_file(path: str) -> None:
    os.remove(path)


def convert(image_path: str) -> str:
    path, image = image_path.rsplit('/', 1)
    preview_path = f'{path}/{PREVIEW_PREFIX}{image}'

    cmd = [
        CONVERT_CMD,
        '-define', f'jpeg:size={PREVIEW_SIZE}',
        image_path,
        '-thumbnail', f'{PREVIEW_SIZE}^',
        '-gravity', 'center',
        '-extent', PREVIEW_SIZE,
        preview_path]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise Exception(result.stdout)

    return preview_path


def create_thumbnail(image: str, preview: str) -> None:
    image_file = download_file(image)
    preview_file = convert(image_file)
    upload_file(preview_file, preview)
    delete_file(image_file)
    delete_file(preview_file)


def list_objects(prefix: str) -> tuple[list[str], list[str]]:
    dirs = []
    files = []

    paginator = s3.get_paginator('list_objects_v2')
    for page in paginator.paginate(Bucket=BUCKET, Prefix=prefix, Delimiter='/'):
        dirs += [prefix_info['Prefix'] for prefix_info in page.get('CommonPrefixes', [])]
        files += [obj['Key'] for obj in page.get('Contents', [])]

    return dirs, files


def create_thumbnails(root: str, files: list[str]) -> None:
    for file in files:
        image = f'{root}/{file}'
        preview = f'{root}/{PREVIEW_PREFIX}{file}'

        create_thumbnail(image, preview)


def create_views(root: str, files: list[str]) -> None:
    for i, file in enumerate(files):
        previous = files[i - 1]
        parent = f'/{root}/{INDEX}'
        next = files[(i + 1) % len(files)]

        nav_html = VIEW_NAV_TEMPLATE.format(f'{previous}{HTML_EXTENSION}', parent, f'{next}{HTML_EXTENSION}')
        view_html = VIEW_TEMPLATE.format(nav_html, file, previous, next)

        image = f'{root}/{file}'
        view_file = f'{image}{HTML_EXTENSION}'
        put_object(view_file, view_html)


def create_index(root: str, dirs: list[str], files: list[str]) -> None:
    preview_html = ''

    for dir in dirs:
        preview_html = PREVIEW_TEMPLATE.format(f'{dir}/{INDEX}', f'/{ALBUM}', dir) + preview_html

    for file in files:
        preview_html = preview_html + PREVIEW_TEMPLATE.format(file + HTML_EXTENSION, PREVIEW_PREFIX + file, file)

    parent = '/' + '/'.join(root.split('/')[:-1] + [INDEX])
    nav_html = LIST_NAV_TEMPLATE.format(parent)
    list_html = LIST_TEMPLATE.format(nav_html, preview_html)

    index_file = f'{root}/{INDEX}' if root else INDEX
    put_object(index_file, list_html)


def map_filter_sort(prefix: str, dirs: list[str], files: list[str]) -> tuple[str, list[str], list[str]]:
    root = prefix.strip('/')

    dirs = (dir.replace(root, '').strip('/') for dir in dirs)

    files = (file.replace(root, '').strip('/') for file in files)
    files = (file for file in files if file.lower().endswith(JPG_EXTENSION))
    files = (file for file in files if not file.startswith(PREVIEW_PREFIX))

    return root, sorted(dirs, reverse=True), sorted(files)


def process_prefix(prefix: str, thumbnails: bool, views: bool) -> None:
    dirs, files = list_objects(prefix)
    root, dirs, files = map_filter_sort(prefix, dirs, files)

    if thumbnails:
        create_thumbnails(root, files)

    if views:
        create_views(root, files)

    create_index(root, dirs, files)


def handler(event: dict, _) -> dict:
    prefixes = event['prefixes']
    thumbnails = event['thumbnails']
    views = event['views']

    for prefix in prefixes:
        process_prefix(prefix, thumbnails, views)

    return {
        'prefixes': prefixes,
        'thumbnails': thumbnails,
        'views': views
    }
