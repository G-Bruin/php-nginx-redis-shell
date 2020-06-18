# purpose
Build php nginx redis automatically with shell

# version

tool | version
---- | ---
php | 7.2.2
nginx |  1.16.1
redis |  4.2.0

# usage
### create www user
```bash
[root@localhost shm]# groupadd -r www
[root@localhost shm]# useradd -r -g www -s /sbin/nologin -M www
```
### use shell
```
[root@localhost shm]# chmod a+x install.sh
[root@localhost shm]# ./install.sh
```

### php.ini configuration
```bash
[root@localhost shm]# vim /usr/local/php-${php_version}/etc/php.ini
> extension_dir = "/usr/local/php-${php_version}/lib/php/extensions/no-debug-zts-20190902"
> date.timezone = PRC
```

### centos add php-fpm management to /etc/init.d 
```bash
cp /{source code}/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm

 > vim php.sh

[root@localhost shm]# vim /etc/profile.d/php.sh

> add the following:

export PATH=$PATH:/usr/local/php-${php_version}/bin/:/usr/local/php-${php_version}/sbin/

> save and exit

:wq!

> use source update php env

[root@localhost shm]# source /etc/profile.d/php.sh
[root@localhost shm]# chmod +x /etc/init.d/php-fpm
[root@localhost shm]# chkconfig --add php-fpm
[root@localhost shm]# chkconfig php-fpm on
[root@localhost shm]# php-fpm -t
[root@localhost shm]# systemctl start php-fpm.service

```

### nginx conf example

```bash

server {
        listen       80;
        server_name  localhost;
        root /var/www/laravel/public;


        index index.php index.html index.htm;

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts 
        location ~ \.php$ {
            fastcgi_pass unix:/dev/shm/php-cgi.sock;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
            include        fastcgi_params;
        }
    }

```

# code description
1. `Linux_Judge` Used to determine different Linux distributions
2. `install_dependencies`Install software dependencies
3. `install_nginx`Install nginx
4. `install_php` Install php
5. `install_redis_extend` Install php redis extend
6. `install_redis` Install redis

# 
