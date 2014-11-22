# cheeray-aliyun (115.28.88.113)
#curl http://cheeray-aliyun:8088/_ServER/ranklist/Count?ranklist=myzset

#count
curl 'http://cheeray-aliyun:8088/_ServER/rankList/count?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96'

#add
curl 'http://cheeray-aliyun:8088/_ServER/rankList/add?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&nickname=小&value=11'

curl 'http://cheeray-aliyun:8088/_ServER/rankList/add?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&uid=小%2b&value=111'

curl 'http://cheeray-aliyun:8088/_ServER/rankList/add?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&nickname=小&value=12'

curl 'http://cheeray-aliyun:8088/_ServER/rankList/add?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&nickname=小&value=13'

curl 'http://cheeray-aliyun:8088/_ServER/rankList/add?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&nickname=小&value=14'

#score 
curl 'http://cheeray-aliyun:8088/_ServER/rankList/score?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&uid=小%2b2'

#rank 
curl 'http://cheeray-aliyun:8088/_ServER/rankList/GEtrank?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&uid=小%2b1' 

#revrank
curl 'http://cheeray-aliyun:8088/_ServER/rankList/GEtrEvrank?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&uid=小%2b' 

#getrankrange
curl 'http://cheeray-aliyun:8088/_ServER/rankList/GEtrankrange?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&offset=1&count=100' 

#getscorerange
curl 'http://cheeray-aliyun:8088/_ServER/rankList/GEtscorerange?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&min=1&max=100' 

#del
curl 'http://cheeray-aliyun:8088/_ServER/rankList/reMove?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&uid=小%2b'

curl 'http://cheeray-aliyun:8088/_ServER/rankList/count?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96'

curl 'http://cheeray-aliyun:8088/_ServER/rankList/reMove?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&uid=小%2b1'

curl 'http://cheeray-aliyun:8088/_ServER/rankList/reMove?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&uid=小%2b2'

curl 'http://cheeray-aliyun:8088/_ServER/rankList/reMove?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&uid=小%2b3'

#curl 'http://cheeray-aliyun:8088/_ServER/rankList/limit?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&count=0'
