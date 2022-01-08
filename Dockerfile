ARG NGINX_VERSION=1.21.3

##########################
# build image
##########################
FROM nginx:${NGINX_VERSION}-alpine as build

ARG FFMPEG_VERSION=4.4
ARG VOD_MODULE_VERSION=1.29
ARG AWS_AUTH_MODULE_VERSION=master

ARG PREFIX=/opt/ffmpeg
ARG LD_LIBRARY_PATH=/opt/ffmpeg/lib
ARG MAKEFLAGS="-j4"

RUN apk add --no-cache \
    git \
    curl \
    build-base \
    openssl \
    openssl-dev \
    zlib-dev \
    linux-headers \
    pcre-dev \
    coreutils \
    freetype-dev \
    gcc \
    lame-dev \
    libogg-dev \
    libass \
    libass-dev \
    libvpx-dev \
    libvorbis-dev \
    libwebp-dev \
    libtheora-dev \
    opus-dev \
    pkgconf \
    pkgconfig \
    rtmpdump-dev \
    x264-dev \
    x265-dev \
    yasm

# Get fdk-aac from community.
RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories && \
  apk add --update fdk-aac-dev

# Get rav1e from testing.
RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
  apk add --update rav1e-dev

# Get ffmpeg source.
RUN mkdir /ffmpeg
RUN curl -sL http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz | tar -C /ffmpeg --strip 1 -xz

# Compile ffmpeg.
WORKDIR /ffmpeg
RUN ./configure \
    --enable-version3 \
    --enable-gpl \
    --enable-nonfree \
    --enable-small \
    --enable-libmp3lame \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libvpx \
    --enable-libtheora \
    --enable-libvorbis \
    --enable-libopus \
    --enable-libfdk-aac \
    --enable-libass \
    --enable-libwebp \
    --enable-librtmp \
    --enable-librav1e \
    --enable-postproc \
    --enable-libfreetype \
    --enable-openssl \
    --disable-debug \
    --disable-doc \
    --disable-ffplay \
    --extra-cflags="-I${PREFIX}/include" \
    --extra-ldflags="-L${PREFIX}/lib" \
    --extra-libs="-lpthread -lm" \
    --prefix="${PREFIX}"

RUN make && make install && make distclean

RUN mkdir /nginx
RUN curl -sL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar -C /nginx --strip 1 -xz

# Get nginx-vod-module
RUN git clone --depth=1 --branch=$VOD_MODULE_VERSION https://github.com/kaltura/nginx-vod-module.git /nginx-vod-module

# Get nginx-aws-auth-module
RUN git clone --depth=1 --branch=$AWS_AUTH_MODULE_VERSION https://github.com/kaltura/nginx-aws-auth-module.git /nginx-aws-auth-module

# Compile nginx.
WORKDIR /nginx
RUN NGINX_ARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
    ./configure \
    --with-compat \
	--add-dynamic-module=/nginx-vod-module \
    --add-dynamic-module=/nginx-aws-auth-module \
    --with-file-aio \
    --with-threads \
    --with-cc-opt="-O3 -mpopcnt" \
    ${NGINX_ARGS}

RUN make modules

##########################
# nginx image
##########################
FROM nginx:${NGINX_VERSION}-alpine
LABEL MAINTAINER Maxime Epain <me@maxep.me>
ENV PATH=/opt/ffmpeg/bin:$PATH

RUN apk add --no-cache \
    zlib \
    ca-certificates \
    openssl \
    pcre \
    lame \
    libogg \
    libass \
    libvpx \
    libvorbis \
    libwebp \
    libtheora \
    opus \
    rtmpdump \
    x264-dev \
    x265-dev

COPY --from=build /opt/ffmpeg /opt/ffmpeg
COPY --from=build /usr/lib/libfdk-aac.so.2 /usr/lib/libfdk-aac.so.2
COPY --from=build /usr/lib/librav1e.so /usr/lib/librav1e.so
COPY --from=build /nginx/objs/ngx_http_vod_module.so /etc/nginx/modules/
COPY --from=build /nginx/objs/ngx_http_aws_auth_module.so /etc/nginx/modules/