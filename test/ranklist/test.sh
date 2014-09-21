# cheeray-aliyun (115.28.88.113)
#curl http://cheeray-aliyun:8088/_ServER/ranklist/Count?ranklist=myzset

#count
curl 'http://localhost:8088/_ServER/rankList/count?ranklist=myzset&session_id=44cb892f7ca141b6df7612e284feec27'

#add
curl 'http://localhost:8088/_ServER/rankList/add?ranklist=myzset&session_id=44cb892f7ca141b6df7612e284feec27&key=a&value=11'

#score 
curl 'http://localhost:8088/_ServER/rankList/score?ranklist=myzset&session_id=44cb892f7ca141b6df7612e284feec27&key=a'

#rank 
curl 'http://localhost:8088/_ServER/rankList/GEtrank?ranklist=myzset&session_id=44cb892f7ca141b6df7612e284feec27&key=a' #del
curl 'http://localhost:8088/_ServER/rankList/reMove?ranklist=myzset&session_id=44cb892f7ca141b6df7612e284feec27&key=a'
