# cheeray-aliyun (115.28.88.113)
#curl "http://cheeray-aliyun:8088/_SERVER/Store/findOBJ?property=i_name&property_value=0001"

curl "http://127.0.0.1:8088/_SERVER/Store/findOBJ?property=i_name&property_value=lle&session_id=9884982f83c0b8d58132d9d925e15572"

curl -H 'Content-type: application/json' http://127.0.0.1:8088/_server/store/saveObj -d '{"session_id":"9884982f83c0b8d58132d9d925e15572", "rawdata": [{"hqy":1}, {"yjr":1}]}'

curl -H 'Content-type: application/json' http://127.0.0.1:8088/_server/store/updateOBJ -d '{"session_id": "9884982f83c0b8d58132d9d925e15572", "id": "oTkJrOjy4pnjDUvtMNwrfVPiNuo", "rawdata": [{"djr":1}, {"hqy":3}]}'


curl -H 'Content-type: application/json' http://127.0.0.1:8088/_server/store/DeleteObj -d '{"session_id":"9884982f83c0b8d58132d9d925e15572", "id": "D+YqrRP9ETsfmhluX-sVid1bUu8"}'

