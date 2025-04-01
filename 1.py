import requests

url = 'http://apis.data.go.kr/1360000/AsosHourlyInfoService/getWthrDataList'
params ={'serviceKey' : 'wP8W4DDpX+Iqp+vvTfUkWEhefKN9saOFcNN99QUWePzRDwk0hYWN3w1QTgOcVyk7rt+2xVpsv0+KmYCZNRrcDQ==', 'pageNo' : '1', 'numOfRows' : '10', 'dataType' : 'JSON', 'dataCd' : 'ASOS', 'dateCd' : 'HR', 'startDt' : '20250331', 'startHh' : '09', 'endDt' : '20250331', 'endHh' : '11', 'stnIds' : '108' }


response = requests.get(url, params=params)
for item in response.json()["response"]["body"]["items"]["item"]:
    print(item['ta'])
