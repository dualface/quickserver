# cheeray-aliyun (115.28.88.113)
#curl http://cheeray-aliyun:8088/_ServER/ranklist/Count?ranklist=myzset

#count
curl 'http://cheeray-aliyun:8088/_ServER/rankList/count?ranklist=myzset&session_id=7362ae8a10a3ea90ceffe3f5e98eacf7'

#add
curl 'http://cheeray-aliyun:8088/_ServER/rankList/add?ranklist=myzset&session_id=7362ae8a10a3ea90ceffe3f5e98eacf7&key=a&value=11'

#score 
curl 'http://cheeray-aliyun:8088/_ServER/rankList/score?ranklist=myzset&session_id=7362ae8a10a3ea90ceffe3f5e98eacf7&key=a'

#rank 
curl 'http://cheeray-aliyun:8088/_ServER/rankList/GEtrank?ranklist=myzset&session_id=7362ae8a10a3ea90ceffe3f5e98eacf7&key=a' 

#revrank
curl 'http://cheeray-aliyun:8088/_ServER/rankList/GEtrEvrank?ranklist=myzset&session_id=7362ae8a10a3ea90ceffe3f5e98eacf7&key=a' 

#getrankrange
curl 'http://cheeray-aliyun:8088/_ServER/rankList/GEtrankrange?ranklist=myzset&session_id=7362ae8a10a3ea90ceffe3f5e98eacf7&offset=1&count=10' 

#del
curl 'http://cheeray-aliyun:8088/_ServER/rankList/reMove?ranklist=myzset&session_id=7362ae8a10a3ea90ceffe3f5e98eacf7&key=junk_message!!!'
