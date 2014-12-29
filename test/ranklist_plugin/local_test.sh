#call /user/codes update user-defined file
curl -H 'content-type: application/json' "http://127.0.0.1:8088/_server/user/uploadcodes" -d '{"session_id": "f7a60ec532e7e640813be7ed5717bb5a", "commit":"f638f"}'

curl -H 'Content-Type: application/json' -d '{"session_id": "f7a60ec532e7e640813be7ed5717bb5a", "name":"ranklist_plugin"}' http://127.0.0.1:8088/http_test3/useranklist/sayandadd

