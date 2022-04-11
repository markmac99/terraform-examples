# tester
import json
import requests


urlcall = "https://mwqyofhckh.execute-api.eu-west-2.amazonaws.com/stage1/hello/"
headers = {'x-api-key': 'SWxflqiI5r8cjPsnKR42v9OgLcfpTf5q3Y5hpD77'}

urlcall = urlcall + 'mark'
response = requests.get(urlcall, headers = headers)
resp = json.loads(response.content)
print(resp)
