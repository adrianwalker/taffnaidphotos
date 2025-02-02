import os
from subprocess import CompletedProcess
from unittest import mock

import taffnaidphotos


def _run(cmd, **kwargs):
    filename = cmd[-1]

    print(f"writing: {filename}")
    with open(filename, 'wb') as f:
        f.write('test'.encode())

    return CompletedProcess(cmd[1:], 0, None, None)


def _put_object(**args):
    filename = f"/tmp/{args['Bucket']}/{args['Key']}"
    os.makedirs(os.path.dirname(filename), exist_ok=True)

    print(f"writing: {filename}")
    with open(filename, 'wb') as f:
        f.write(args['Body'].encode())


@mock.patch('taffnaidphotos.subprocess')
@mock.patch('taffnaidphotos.list_objects')
@mock.patch('taffnaidphotos.s3')
def test_handler(s3, list_objects, subprocess):
    s3.put_object = _put_object
    subprocess.run = _run

    list_objects.side_effect = [
        (['album/'], []),
        (['album/folder/'], ['album/image1.jpg', 'album/image2.jpg']),
        ([], ['album/folder/IMAGE3.jpg', 'album/folder/IMAGE4.jpg'])
    ]

    event = {
        'prefixes': ['', 'album/', 'album/folder/'],
        'thumbnails': True,
        "views": True
    }

    response = taffnaidphotos.handler(event, {})
    assert response == {
        'prefixes': ['', 'album/', 'album/folder/'],
        'thumbnails': True,
        'views': True
    }
