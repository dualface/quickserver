# cheeray-aliyun (115.28.88.113)
#curl "http://cheeray-aliyun:8088/_SERVER/Store/findOBJ?property=i_name&property_value=0001"

curl "http://cheeray-aliyun:8088/_SERVER/Store/findOBJ?property=i_name&property_value=lle&session_id=c052a3ddd07553520bab8921fceefade"

curl -H 'Content-type: application/json' http://cheeray-aliyun:8088/_server/store/saveObj -d '{"session_id":"c052a3ddd07553520bab8921fceefade", "rawdata": [{"hqy":1}, {"yjr":1}]}'

curl -H 'Content-type: application/json' http://cheeray-aliyun:8088/_server/store/updateOBJ -d '{"session_id": "c052a3ddd07553520bab8921fceefade", "id": "oTkJrOjy4pnjDUvtMNwrfVPiNuo", "rawdata": [{"djr":1}, {"hqy":3}]}'


curl -H 'Content-type: application/json' http://cheeray-aliyun:8088/_server/store/DeleteObj -d '{"session_id":"c052a3ddd07553520bab8921fceefade", "id": "D+YqrRP9ETsfmhluX-sVid1bUu8"}'

