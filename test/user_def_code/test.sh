#curl -H 'Content-Type: application/json' -d '{"rawdata": [{"key1": "curl_key1"}, {"property":"curl_property1"}, {"i_name": "curl_i_name1"}], "indexes": ["i_name", "property"]}' http://localhost:8088/http_test/Store/SaveObj

#call /user/codes update user-defined file
curl -H 'content-type: application/json' "http://cheeray-aliyun:8088/_server/user/uploadcodes" -d '{"session_id": "9027ea2fc2b507cc4e6a21e3d938f6ee", "commit":"249b6"}'

curl -H 'Content-Type: application/json' -d '{"session_id": "9027ea2fc2b507cc4e6a21e3d938f6ee", "name":"a_name"}' http://cheeray-aliyun:8088/http_test1/Say/SayHello
curl "http://cheeray-aliyun:8088/http_test1/Say/SayHello?name=a_name&session_id=9027ea2fc2b507cc4e6a21e3d938f6ee"
curl -d 'name=a_name&session_id=9027ea2fc2b507cc4e6a21e3d938f6ee' http://cheeray-aliyun:8088/http_test1/Say/SayHello

curl -H 'Content-Type: application/json' -d '{"session_id":"9027ea2fc2b507cc4e6a21e3d938f6ee", "name":"a_name"}' http://cheeray-aliyun:8088/http_test1/SaY/SAyHElLO
curl "http://cheeray-aliyun:8088/http_test1/say/sayhello?name=a_name&session_id=9027ea2fc2b507cc4e6a21e3d938f6ee"
curl -d 'name=a_name&session_id=9027ea2fc2b507cc4e6a21e3d938f6ee' http://cheeray-aliyun:8088/http_test1/SAY/SAYHELLO

