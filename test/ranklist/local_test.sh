# localhost (115.28.88.113)

#count
curl 'http://localhost:8088/_ServER/examples/test/count?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96'

#add
curl 'http://localhost:8088/_ServER/examples/test/add?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&nickname=小&value=11'

curl 'http://localhost:8088/_ServER/examples/test/add?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&uid=小%2b&value=111'

curl 'http://localhost:8088/_ServER/examples/test/add?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&nickname=小&value=12'

curl 'http://localhost:8088/_ServER/examples/test/add?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&nickname=小&value=13'

curl 'http://localhost:8088/_ServER/examples/test/add?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&nickname=小&value=14'

#score 
curl 'http://localhost:8088/_ServER/examples/test/score?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&uid=小%2b2'

#rank 
curl 'http://localhost:8088/_ServER/examples/test/GEtrank?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&uid=小%2b1' 

#revrank
curl 'http://localhost:8088/_ServER/examples/test/GEtrEvrank?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&uid=小%2b' 

#getrankrange
curl 'http://localhost:8088/_ServER/examples/test/GEtrankrange?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&offset=1&count=100' 

#getscorerange
curl 'http://localhost:8088/_ServER/examples/test/GEtscorerange?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&min=1&max=100' 

#del
curl 'http://localhost:8088/_ServER/examples/test/reMove?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&uid=小%2b'

curl 'http://localhost:8088/_ServER/examples/test/count?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96'

curl 'http://localhost:8088/_ServER/examples/test/reMove?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&uid=小%2b1'

curl 'http://localhost:8088/_ServER/examples/test/reMove?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&uid=小%2b2'

curl 'http://localhost:8088/_ServER/examples/test/reMove?ranklist=myzset&session_id=0ba991bbdce369aa2f046310ac67fc96&uid=小%2b3'
