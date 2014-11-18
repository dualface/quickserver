# cheeray-aliyun (115.28.88.113)
#curl http://cheeray-aliyun:8088/_ServER/ranklist/Count?ranklist=myzset

#count
curl 'http://cheeray-aliyun:8088/_ServER/rankList/count?ranklist=myzset&session_id=ad1fafe255b765054daf65761fd930f7'

#add
curl 'http://cheeray-aliyun:8088/_ServER/rankList/add?ranklist=myzset&session_id=ad1fafe255b765054daf65761fd930f7&key=a&value=11'

#score 
curl 'http://cheeray-aliyun:8088/_ServER/rankList/score?ranklist=myzset&session_id=ad1fafe255b765054daf65761fd930f7&key=a'

#rank 
curl 'http://cheeray-aliyun:8088/_ServER/rankList/GEtrank?ranklist=myzset&session_id=ad1fafe255b765054daf65761fd930f7&key=a' 

#revrank
curl 'http://cheeray-aliyun:8088/_ServER/rankList/GEtrEvrank?ranklist=myzset&session_id=ad1fafe255b765054daf65761fd930f7&key=a' 

#getrankrange
curl 'http://cheeray-aliyun:8088/_ServER/rankList/GEtrankrange?ranklist=myzset&session_id=ad1fafe255b765054daf65761fd930f7&offset=1&count=10' 

#del
curl 'http://cheeray-aliyun:8088/_ServER/rankList/reMove?ranklist=myzset&session_id=ad1fafe255b765054daf65761fd930f7&key=a'
