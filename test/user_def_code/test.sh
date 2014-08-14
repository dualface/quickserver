#curl -H 'Content-Type: application/json' -d '{"rawdata": [{"key1": "curl_key1"}, {"property":"curl_property1"}, {"i_name": "curl_i_name1"}], "indexes": ["i_name", "property"]}' http://localhost:8088/http_test/Store/SaveObj

#call /user/codes update user-defined file
curl "http://localhost:8088/user/codes?commit=2b7f85"

curl -H 'Content-Type: application/json' -d '{"name":"a_name"}' http://localhost:8088/http_test/Say/SayHello
curl http://localhost:8088/http_test/Say/SayHello?name=a_name
curl -d 'name=a_name' http://localhost:8088/http_test/Say/SayHello

curl -H 'Content-Type: application/json' -d '{"name":"a_name"}' http://localhost:8088/http_test/SaY/SAyHElLO
curl http://localhost:8088/http_test/say/sayhello?name=a_name
curl -d 'name=a_name' http://localhost:8088/http_test/SAY/SAYHELLO

#call /user/codes to info a new commit 
curl "http://localhost:8088/user/codes?commit=a068face"

#run user-defined interface /hi/sayhi

curl -H 'Content-Type: application/json' -d '{"name":"b_name"}' http://localhost:8088/http_test/hi/SAyHi
curl http://localhost:8088/http_test/hi/sayhi?name=b_name
curl -d 'name=b_name' http://localhost:8088/http_test/SAY/SAYHI

