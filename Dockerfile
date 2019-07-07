FROM library/centos:7

RUN yum -y groupinstall 'Development Tools'
RUN yum -y install epel-release
RUN yum install -y wget git unzip perl perl-devel perl-ExtUtils-Embed libxslt libxslt-devel libxml2 libxml2-devel gd gd-devel pcre-devel GeoIP GeoIP-devel

WORKDIR /usr/local/src

ADD http://nginx.org/download/nginx-1.17.1.tar.gz https://ftp.pcre.org/pub/pcre/pcre-8.43.tar.gz https://www.zlib.net/zlib-1.2.11.tar.gz https://www.openssl.org/source/openssl-1.1.0k.tar.gz /usr/local/src/
RUN tar -xzvf nginx-1.17.1.tar.gz && tar -xzvf pcre-8.43.tar.gz && tar -xzvf zlib-1.2.11.tar.gz && tar -xzvf openssl-1.1.0k.tar.gz
RUN git clone https://github.com/sergey-dryabzhinsky/nginx-rtmp-module.git

WORKDIR /usr/local/src/nginx-1.17.1

RUN ./configure --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib64/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --user=nginx \
    --group=nginx \
    --build=CentOS \
    --builddir=nginx-1.17.1 \
    --with-select_module \
    --with-poll_module \
    --with-threads \
    --with-file-aio \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_xslt_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_geoip_module=dynamic \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_degradation_module \
    --with-http_slice_module \
    --with-http_stub_status_module \
    --http-log-path=/var/log/nginx/access.log \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --with-mail=dynamic \
    --with-mail_ssl_module \
    --with-stream=dynamic \
    --with-stream_ssl_module \
    --with-stream_realip_module \
    --with-stream_geoip_module=dynamic \
    --with-stream_ssl_preread_module \
    --with-compat \
    --with-pcre=../pcre-8.43 \
    --with-pcre-jit \
    --with-zlib=../zlib-1.2.11 \
    --with-openssl=../openssl-1.1.0k \
    --with-openssl-opt=no-nextprotoneg \
    --add-module=../nginx-rtmp-module \
    --with-debug
RUN make
RUN make install

WORKDIR /

RUN ln -s /usr/lib64/nginx/modules /etc/nginx/modules
RUN useradd -r -d /var/cache/nginx/ -s /sbin/nologin -U nginx
RUN mkdir -p /var/cache/nginx/ && chown -R nginx:nginx /var/cache/nginx/

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 1935
EXPOSE 8080

CMD /sbin/nginx
