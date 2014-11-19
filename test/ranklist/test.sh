# cheeray-aliyun (115.28.88.113)
#curl http://cheeray-aliyun:8088/_ServER/ranklist/Count?ranklist=myzset

#count
curl 'http://cheeray-aliyun:8088/_ServER/rankList/count?ranklist=myzset&session_id=9cca425e21661471595a07844ec4bc52'

#add
curl 'http://cheeray-aliyun:8088/_ServER/rankList/add?ranklist=myzset&session_id=9cca425e21661471595a07844ec4bc52&nickname=a&value=11'

curl 'http://cheeray-aliyun:8088/_ServER/rankList/add?ranklist=myzset&session_id=9cca425e21661471595a07844ec4bc52&nickname=a&value=12'

curl 'http://cheeray-aliyun:8088/_ServER/rankList/add?ranklist=myzset&session_id=9cca425e21661471595a07844ec4bc52&nickname=a&value=13'

#score 
curl 'http://cheeray-aliyun:8088/_ServER/rankList/score?ranklist=myzset&session_id=9cca425e21661471595a07844ec4bc52&uid=a2'

#rank 
curl 'http://cheeray-aliyun:8088/_ServER/rankList/GEtrank?ranklist=myzset&session_id=9cca425e21661471595a07844ec4bc52&uid=a1' 

#revrank
curl 'http://cheeray-aliyun:8088/_ServER/rankList/GEtrEvrank?ranklist=myzset&session_id=9cca425e21661471595a07844ec4bc52&uid=a' 

#getrankrange
curl 'http://cheeray-aliyun:8088/_ServER/rankList/GEtrankrange?ranklist=myzset&session_id=9cca425e21661471595a07844ec4bc52&offset=1&count=10' 

#del
curl 'http://cheeray-aliyun:8088/_ServER/rankList/reMove?ranklist=myzset&session_id=9cca425e21661471595a07844ec4bc52&uid=a'

curl 'http://cheeray-aliyun:8088/_ServER/rankList/count?ranklist=myzset&session_id=9cca425e21661471595a07844ec4bc52'

curl 'http://cheeray-aliyun:8088/_ServER/rankList/reMove?ranklist=myzset&session_id=9cca425e21661471595a07844ec4bc52&uid=a1'

curl 'http://cheeray-aliyun:8088/_ServER/rankList/reMove?ranklist=myzset&session_id=9cca425e21661471595a07844ec4bc52&uid=a2'
