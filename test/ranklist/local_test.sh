# cheeray-aliyun (115.28.88.113)
#curl http://cheeray-aliyun:8088/_ServER/ranklist/Count?ranklist=myzset

#count
curl 'http://localhost:8088/_ServER/rankList/count?ranklist=myzset&session_id=690e1677184c3247d1234312230b1830'

#add
curl 'http://localhost:8088/_ServER/rankList/add?ranklist=myzset&session_id=690e1677184c3247d1234312230b1830&key=a&value=11'

#score 
curl 'http://localhost:8088/_ServER/rankList/score?ranklist=myzset&session_id=690e1677184c3247d1234312230b1830&key=a'

#rank 
curl 'http://localhost:8088/_ServER/rankList/GEtrank?ranklist=myzset&session_id=690e1677184c3247d1234312230b1830&key=a' 

#revrank
curl 'http://localhost:8088/_ServER/rankList/GEtrEvrank?ranklist=myzset&session_id=690e1677184c3247d1234312230b1830&key=a' 

#getrankrange
curl 'http://localhost:8088/_ServER/rankList/GEtrankrange?ranklist=myzset&session_id=690e1677184c3247d1234312230b1830&offset=1&count=10' 

#del
curl 'http://localhost:8088/_ServER/rankList/reMove?ranklist=myzset&session_id=690e1677184c3247d1234312230b1830&key=a'
