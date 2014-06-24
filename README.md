
# Nginx Lua Game Server



### Nginx config


~~~
http {
    lua_package_path "/pathto/quick-x-server/src/?.lua;;";

    ...

    server {
        listen       8088 so_keepalive=on;

        ...

        location /test {
            root /pathto/quick-x-server/src/server;
            lua_code_cache off;
            lua_socket_log_errors off;
            lua_check_client_abort on;
            content_by_lua_file /pathto/quick-x-server/src/server/bootstrap.lua;
        }

    }
}
~~~
