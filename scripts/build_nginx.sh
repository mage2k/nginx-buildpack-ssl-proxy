#!/bin/bash
# Build NGINX and modules on Heroku.
# This is expected to be run during buildpack compilation
# The resulting nginx binary is copied to $CACHE_DIR/nginx-$STACK

set -o errexit

NGINX_VERSION=${NGINX_VERSION-1.13.8}
PCRE_VERSION=${PCRE_VERSION-8.41}
HEADERS_MORE_VERSION=${HEADERS_MORE_VERSION-0.33}
OPEN_SSL_VERSION=${OPEN_SSL_VERSION-1.0.2n}

nginx_tarball_url=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
pcre_tarball_url=http://downloads.sourceforge.net/project/pcre/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.bz2
headers_more_nginx_module_url=https://github.com/agentzh/headers-more-nginx-module/archive/v${HEADERS_MORE_VERSION}.tar.gz
open_ssl_url=https://www.openssl.org/source/openssl-${OPEN_SSL_VERSION}.tar.gz

BUILD_DIR=$1
NGINX_BUILD_DIR="${BUILD_DIR}/tmp"
CACHE_DIR=$2

num_cpu_cores=$(grep -c ^processor /proc/cpuinfo)

mkdir $NGINX_BUILD_DIR
cd $NGINX_BUILD_DIR
echo "Nginx build dir: ${NGINX_BUILD_DIR}"

echo "Downloading $nginx_tarball_url"
curl -L $nginx_tarball_url | tar xzv

echo "Downloading $pcre_tarball_url"
(cd nginx-${NGINX_VERSION} && curl -L $pcre_tarball_url | tar xvj )

echo "Downloading $headers_more_nginx_module_url"
(cd nginx-${NGINX_VERSION} && curl -L $headers_more_nginx_module_url | tar xvz )

echo "Downloading $open_ssl_url"
(cd nginx-${NGINX_VERSION} && curl -L $open_ssl_url | tar xvz )

(
	cd nginx-${NGINX_VERSION}
	./configure \
		--with-pcre=pcre-${PCRE_VERSION} \
		--prefix=$NGINX_BUILD_DIR/nginx \
		--add-module=$NGINX_BUILD_DIR/nginx-${NGINX_VERSION}/headers-more-nginx-module-${HEADERS_MORE_VERSION} \
    --with-stream \
    --with-stream_ssl_module \
    --with-http_ssl_module --with-openssl=$NGINX_BUILD_DIR/nginx-${NGINX_VERSION}/openssl-${OPEN_SSL_VERSION} \
    --with-http_sub_module \
    --with-stream_realip_module
	make -j ${num_cpu_cores} install
  cp $NGINX_BUILD_DIR/nginx/sbin/nginx $CACHE_DIR/nginx-$STACK
)
