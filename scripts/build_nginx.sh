#!/bin/bash
# Build NGINX and modules on Heroku.
# This program is designed to run in a web dyno provided by Heroku.
# We would like to build an NGINX binary for the builpack on the
# exact machine in which the binary will run.
# Our motivation for running in a web dyno is that we need a way to
# download the binary once it is built so we can vendor it in the buildpack.
#
# Once the dyno has is 'up' you can open your browser and navigate
# this dyno's directory structure to download the nginx binary.

set -o errexit

PATH="/app/.apt/usr/bin/:${PATH}"

NGINX_VERSION=${NGINX_VERSION-1.13.8}
PCRE_VERSION=${PCRE_VERSION-8.41}
HEADERS_MORE_VERSION=${HEADERS_MORE_VERSION-0.33}
OPEN_SSL_VERSION=${OPEN_SSL_VERSION-1.0.2n}

nginx_tarball_url=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
pcre_tarball_url=http://downloads.sourceforge.net/project/pcre/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.bz2
headers_more_nginx_module_url=https://github.com/agentzh/headers-more-nginx-module/archive/v${HEADERS_MORE_VERSION}.tar.gz
open_ssl_url=https://www.openssl.org/source/openssl-${OPEN_SSL_VERSION}.tar.gz

build_dir="$1/tmp"
mkdir $build_dir

num_cpu_cores=$(grep -c ^processor /proc/cpuinfo)

cd $build_dir
echo "Build dir: $build_dir"

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
  rm $1/bin/nginx-$STACK
	./configure \
		--with-pcre=pcre-${PCRE_VERSION} \
		--prefix=$build_dir/nginx \
		--add-module=${build_dir}/nginx-${NGINX_VERSION}/headers-more-nginx-module-${HEADERS_MORE_VERSION} \
    --with-stream \
    --with-stream_ssl_module \
    --with-http_ssl_module --with-openssl=${build_dir}/nginx-${NGINX_VERSION}/openssl-${OPEN_SSL_VERSION} \
    --with-http_sub_module
	make -j ${num_cpu_cores} install
  cp $build_dir/nginx/sbin/nginx $1/bin/nginx-$STACK
)

# while true
# do
#   sleep 1
#   echo "."
# done
