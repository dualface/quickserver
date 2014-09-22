#curl -H 'Content-Type: application/json' -d '{"rawdata": [{"key1": "curl_key1"}, {"property":"curl_property1"}, {"i_name": "curl_i_name1"}], "indexes": ["i_name", "property"]}' http://localhost:8088/http_test/Store/SaveObj

#call /user/codes update user-defined file
curl -H 'content-type: application/json' "http://127.0.0.1:8088/_server/user/uploadcodes" -d '{"session_id": "5444168caca8869c21e54abb3204c4fa", "commit":"29c1d"}'

curl -H 'Content-Type: application/json' -d '{"session_id": "5444168caca8869c21e54abb3204c4fa", "name":"a_name"}' http://127.0.0.1:8088/http_test1/Say/SayHello
curl "http://127.0.0.1:8088/http_test1/Say/SayHello?name=a_name&session_id=5444168caca8869c21e54abb3204c4fa"
curl -d 'name=a_name&session_id=5444168caca8869c21e54abb3204c4fa' http://127.0.0.1:8088/http_test1/Say/SayHello

curl -H 'Content-Type: application/json' -d '{"session_id":"5444168caca8869c21e54abb3204c4fa", "name":"a_name"}' http://127.0.0.1:8088/http_test1/SaY/SAyHElLO
curl "http://127.0.0.1:8088/http_test1/say/sayhello?name=a_name&session_id=5444168caca8869c21e54abb3204c4fa"
curl -d 'name=a_name&session_id=5444168caca8869c21e54abb3204c4fa' http://127.0.0.1:8088/http_test1/SAY/SAYHELLO

