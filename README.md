# Quick-Server
## A Server Framework Based On OpenResty

---
## Latest Version 0.3.5

## Installation

### Install via Docker

1. Install Docker. Please refer to https://www.docker.com/
2. Run command: docker pull chukong/quick-server

### Install via Shell Script

1. Download codes from github or osc.

   github:
   https://github.com/dualface/quickserver.git
   
   OSChina mirror:
   https://git.oschina.net/cheerayhuang/quick-x-server.git
   
2. Run shell script **install_ubuntu.sh** in root of codes dir.

## Change Log

### 0.3.5

- Adjust directory structure of project, make it more simpler and cleaner.
- Integrate lua-resty-http with quick-server. 
- Fix and mend some confinguration in nginx.conf.

### 0.3.1
- Fix bug: There should be an "actions" sub-dir in root of user-defined codes.  
- Fix bug: Allow the type of response of HTTP is "string".
- Improve: Support case-insensitive uri.

### 0.3.0
- Improve the implemnet of user-defined function, supporting sub-dir structure deployment.

### 0.2.0
- Support user-defined function via uploading lua codes by users themselves.
- Support Http protocol for invoking interfaces. 
- Docker becomes a new way which users can choose for installation besides shell script. 

### 0.1.0
- Support Object Store based on MySql 5 with JSON format.
- Support Index in Object Store.
- Implement Ranklist function based on Redis. 
- All interfaces is based on WebSocket protocol.




