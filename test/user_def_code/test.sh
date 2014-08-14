#curl -H 'Content-Type: application/json' -d '{"rawdata": [{"key1": "curl_key1"}, {"property":"curl_property1"}, {"i_name": "curl_i_name1"}], "indexes": ["i_name", "property"]}' http://localhost:8088/http_test/Store/SaveObj


curl "http://localhost:8088/user/codes?files=SayAction.lua&files=HiAction.lua"

curl -H 'Content-Type: application/json' -d '{"name":"a_name"}' http://localhost:8088/http_test/Say/SayHello
curl http://localhost:8088/http_test/Say/SayHello?name=a_name
curl -d 'name=a_name' http://localhost:8088/http_test/Say/SayHello

curl -H 'Content-Type: application/json' -d '{"name":"a_name"}' http://localhost:8088/http_test/SaY/SAyHElLO
curl http://localhost:8088/http_test/say/sayhello?name=a_name
curl -d 'name=a_name' http://localhost:8088/http_test/SAY/SAYHELLO

