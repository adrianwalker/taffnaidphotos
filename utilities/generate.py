from time import sleep

import boto3
import json

albums = [
    '',
    'Athens 2019/',
    'Basingstoke 2024/',
    'Brid 2018/',
    'Cardiff 2015/',
    'Disney 2018/',
    'Disney 2018/Memory Maker/',
    'Dragon Boat Race 2009/',
    'Dusty and Pastel 2022/',
    'Egypt 2007/',
    'Halloween 2015/',
    'Halloween 2017/',
    'Halloween 2019/',
    'Halloween 2024/',
    'India 2009/',
    ['Italy 2023/',
     'Italy 2023/1 - Pisa/',
     'Italy 2023/2 - Florence/',
     'Italy 2023/3 - Rome/',
     'Italy 2023/4 - Pompeii/'],
    'JBO 2005/',
    'Jet The Dog/',
    'Jodrell Bank 2019/',
    'New York 2006/',
    'On Tour 2014/',
    'On Tour 2022/',
    ['Poland 2017/',
     'Poland 2017/2017-06-20/',
     'Poland 2017/2017-06-21/',
     'Poland 2017/2017-06-22/',
     'Poland 2017/2017-06-23/',
     'Poland 2017/2017-06-24/',
     'Poland 2017/2017-06-25/',
     'Poland 2017/2017-06-26/',
     'Poland 2017/2017-06-27/',
     'Poland 2017/2017-06-28/',
     'Poland 2017/2017-06-29/',
     'Poland 2017/2017-06-30/',
     'Poland 2017/2017-07-01/',
     'Poland 2017/2017-07-02/'],
    'Ripon 2023/',
    'Romania 2023/',
    'Scarborough 2023/',
    'Venice 2014/',
    'Wensleydale 2020/',
    'York Bunker 2024/',
    'Yorkshire Wildlife Park 2019/',
    'Yorkshire Wildlife Park 2024/'
]

lambda_client = boto3.client('lambda')

for album in albums:
    print(f'Generating html for album "{album}"')

    event = {
        'prefixes': album if isinstance(album, list) else [album],
        'thumbnails': False,
        'views': True
    }

    lambda_client.invoke(
        FunctionName='taffnaidphotos',
        InvocationType='Event',
        Payload=json.dumps(event)
    )

    sleep(1)
