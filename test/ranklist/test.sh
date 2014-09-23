# cheeray-aliyun (115.28.88.113)
#curl http://cheeray-aliyun:8088/_ServER/ranklist/Count?ranklist=myzset

#count
curl 'http://cheeray-aliyun:8088/_ServER/rankList/count?ranklist=myzset&session_id=f68ac97d085338d3ef45ab19fffa3b57'

#add
curl 'http://cheeray-aliyun:8088/_ServER/rankList/add?ranklist=myzset&session_id=f68ac97d085338d3ef45ab19fffa3b57&key=a&value=11'

#score 
curl 'http://cheeray-aliyun:8088/_ServER/rankList/score?ranklist=myzset&session_id=f68ac97d085338d3ef45ab19fffa3b57&key=a'

#rank 
curl 'http://cheeray-aliyun:8088/_ServER/rankList/GEtrank?ranklist=myzset&session_id=f68ac97d085338d3ef45ab19fffa3b57&key=a' 

#del
curl 'http://cheeray-aliyun:8088/_ServER/rankList/reMove?ranklist=myzset&session_id=f68ac97d085338d3ef45ab19fffa3b57&key=a'
