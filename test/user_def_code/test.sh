#curl -H 'Content-Type: application/json' -d '{"rawdata": [{"key1": "curl_key1"}, {"property":"curl_property1"}, {"i_name": "curl_i_name1"}], "indexes": ["i_name", "property"]}' http://localhost:8088/http_test/Store/SaveObj

#call /user/codes update user-defined file
curl "http://localhost:8088/user/codes?commit=249b6"

curl -H 'Content-Type: application/json' -d '{"name":"a_name"}' http://localhost:8088/http_test1/Say/SayHello
curl http://localhost:8088/http_test1/Say/SayHello?name=a_name
curl -d 'name=a_name' http://localhost:8088/http_test1/Say/SayHello

curl -H 'Content-Type: application/json' -d '{"name":"a_name"}' http://localhost:8088/http_test1/SaY/SAyHElLO
curl http://localhost:8088/http_test1/say/sayhello?name=a_name
curl -d 'name=a_name' http://localhost:8088/http_test1/SAY/SAYHELLO

