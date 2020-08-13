#!/bin/bash

set -e # "Exit immediately if a simple command exits with a non-zero status."
basepath=$(cd `dirname $0`; pwd)
DISTRO=''
PM=''
nginx_version='1.16.1'
php_version='7.2.2'
pcre_version='8.38'
zlib_version='1.2.11'
libmcrypt_version='2.5.8'
mhash_version='0.9.9.9'
mcrypt_version='2.6.8'
redis_extend_version='4.2.0'
redis_version='4.0.14'

Linux_Judge()
{
    if grep -Eqii "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        DISTRO='CentOS'
        PM='yum'
    elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release; then
        DISTRO='RHEL'
        PM='yum'
    elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun" /etc/*-release; then
        DISTRO='Aliyun'
        PM='yum'
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        DISTRO='Fedora'
        PM='yum'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        DISTRO='Debian'
        PM='apt'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        DISTRO='Ubuntu'
        PM='apt'
    elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
        DISTRO='Raspbian'
        PM='apt'
    else
        DISTRO='unknow'
    fi
    echo "Your Linux Distribution is ${DISTRO}";
}

install_dependencies()
{
    if [[ $DISTRO == 'CentOS' || $DISTRO == 'RHEL' || $DISTRO == 'Fedora' ]]; then
        yum install -y gcc gcc-c++
        yum install -y epel-release bison re2c oniguruma-devel libxml2 libxml2-devel openssl openssl-devel curl-devel libjpeg-devel libpng-devel freetype-devel mysql-devel libsqlite3x-devel autoconf
    elif [[ $DISTRO == 'Debian' || $DISTRO == 'Ubuntu' ]]; then
        apt-get install -y gcc g++ make openssl pkg-config libssl-dev  libcurl4-openssl-dev autoconf \
        libxml2 libxml2-dev libjpeg-dev libpng-dev libfreetype6-dev epel-release oniguruma-devel  libsqlite3x-devel
        if [[ $DISTRO == 'Ubuntu' ]]; then
            apt-get install -y libmysqlclient-dev
        else
            apt-get install -y default-libmysqlclient-dev
        fi
    fi
}

install_redis()
{
    cd $basepath
    wget http://download.redis.io/releases/redis-${redis_version}.tar.gz
    tar -zxf redis-${redis_version}.tar.gz
    cd redis-${redis_version}/src && make install
    mkdir -p /usr/local/redis/bin/
    mkdir -p /usr/local/redis/etc/
    cd ../
    cp ./src/mkreleasehdr.sh ./src/redis-benchmark ./src/redis-check-aof ./src/redis-check-rdb ./src/redis-cli ./src/redis-server /usr/local/redis/bin/
    cp redis.conf /usr/local/redis/etc/ && cd /usr/local/redis/bin/
    sed -i "s/# requirepass foobared/requirepass 3yzy2ywmy/g" /usr/local/redis/etc/redis.conf
    sed -i "s/daemonize no/daemonize yes/g" /usr/local/redis/etc/redis.conf
    sed -i "s/bind 127.0.0.1/#bind 127.0.0.1/g" /usr/local/redis/etc/redis.conf
    sed -i "s/protected-mode yes/protected-mode no/g" /usr/local/redis/etc/redis.conf
    /usr/local/redis/etc/redis-server /usr/local/redis/etc/redis.conf
    echo "redis 密码 3yzy2ywmy"
}

install_nginx()
{
    cd $basepath
    wget http://nginx.org/download/nginx-${nginx_version}.tar.gz
    wget https://svwh.dl.sourceforge.net/project/pcre/pcre/${pcre_version}/pcre-${pcre_version}.tar.gz
    wget https://zlib.net/zlib-${zlib_version}.tar.gz
    tar -zxvf nginx-${nginx_version}.tar.gz
    tar -zxf pcre-${pcre_version}.tar.gz
    tar -zxf zlib-${zlib_version}.tar.gz

    # nginx  --with-pcre=  --with-zlib --with-openssl
    cd ./nginx-${nginx_version}
    ./configure --prefix=/usr/local/nginx-${nginx_version} --with-pcre=./../pcre-${pcre_version}  --with-zlib=./../zlib-${zlib_version} --with-http_stub_status_module \
    --with-http_ssl_module --user=www --group=www --with-http_realip_module --with-threads
    make
    make install

    # create a link to nginx
    ln -sf /usr/local/nginx-${nginx_version}/sbin/nginx /usr/bin/
    echo 'Nginx installed successfully!'
}

install_php()
{
    mkdir -p /usr/local/php-${php_version}/bin/
    local configure_str=$(cat <<EOF
./configure \
            --prefix=/usr/local/php-${php_version} \
            --with-config-file-path=/usr/local/php-${php_version}/etc \
            --enable-fpm \
            --with-fpm-user=www \
            --with-fpm-group=www \
            --with-fileinfo \
            --with-mysqli \
            --with-pdo-mysql \
            --with-libdir=lib64 \
            --with-iconv-dir \
            --with-jpeg \
            --with-png \
            --with-zlib \
            --with-libxml-dir=/usr \
            --enable-xml \
            --disable-rpath  \
            --enable-bcmath \
            --enable-shmop \
            --enable-sysvsem \
            --enable-inline-optimization \
            --with-curl \
            --enable-mbregex \
            --enable-mbstring \
            --enable-ftp \
            --enable-gd \
            --enable-gd-native-ttf \
            --with-openssl \
            --with-mhash \
            --enable-pcntl \
            --enable-sockets \
            --enable-opcache \
            --with-xmlrpc \
            --enable-zip \
            --enable-soap \
            --without-pear \
            --with-gettext 
EOF
)
    cd $basepath
    wget https://www.php.net/distributions/php-${php_version}.tar.gz
    tar -zxvf php-${php_version}.tar.gz
    cd ./php-${php_version}
    $configure_str
    make
    make install

    # create a link to php
    ln -sf /usr/local/php-${php_version}/bin/php /usr/local/bin/

    # write php-fpm configure
    cat > /usr/local/php-${php_version}/etc/php-fpm.conf <<EOF
[global]
pid = /usr/local/php-${php_version}/var/run/php-fpm.pid
error_log = /usr/local/php-${php_version}/var/log/php-fpm.log
log_level = notice

[www]
listen = /dev/shm/php-cgi.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.max_children = 20
pm.start_servers = 10
pm.min_spare_servers = 10
pm.max_spare_servers = 20
request_terminate_timeout = 100
request_slowlog_timeout = 0
slowlog = var/log/slow.log
EOF
    cp php.ini-production  /usr/local/php-${php_version}/etc/php.ini
    cp /usr/local/php-${php_version}/etc/php-fpm.d/www.conf.default /usr/local/php-${php_version}/etc/php-fpm.d/www.conf
    echo 'PHP installed successfully!'
}

install_redis_extend()
{
  wget http://pecl.php.net/get/redis-${redis_extend_version}.tgz
  tar -xzvf redis-${redis_extend_version}.tgz
  cd redis-${redis_extend_version}
  /usr/local/php-${php_version}/bin/phpize
  ./configure --with-php-config=/usr/local/php-${php_version}/bin/php-config
  make && make install
  echo "extension=redis.so" >> /usr/local/php-${php_version}/etc/php.ini
  echo 'redis installed successfully!'
}

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmp"
    exit 1
fi

Linux_Judge
echo -e "Which do you want to install?\n1. nginx\n2. php\n3. nginx and php\n4. redis_extend\n5. redis"
read choose
install_dependencies


if [[ $choose = '1' ]]; then
    install_nginx
elif [[ $choose = '2' ]]; then
    install_php
elif [[ $choose = '3' ]]; then
    install_nginx
    install_php
elif [[ $choose = '4' ]]; then
    install_redis_extend
elif [[ $choose = '5' ]]; then
    install_redis
else
    echo "Nothing to install."
fi
