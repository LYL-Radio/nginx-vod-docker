# [Nginx](https://hub.docker.com/_/nginx) docker image with [nginx-vod-module](https://github.com/kaltura/nginx-vod-module)

This image is based on [nginx:1.21.3-alpine](https://github.com/nginxinc/docker-nginx/blob/d496baf859613adfe391ca8e7615cc7ec7966621/mainline/alpine/Dockerfile) and include the add-ons described below.

## Add-ons
- [FFmpeg](https://www.ffmpeg.org/) 4.4 compiled with FDK support as required by [nginx-vod-module](https://github.com/kaltura/nginx-vod-module#compilation).
- [kaltura/nginx-vod-module](https://github.com/kaltura/nginx-vod-module) 1.29
- [kaltura/nginx-aws-auth-module](https://github.com/kaltura/nginx-aws-auth-module) (Tested with DigitalOcean Spaces)

Nginx modules provided with this image are compiled as dynamic modules. Therefore, the `load_module` directive should be used in `nginx.conf` in order to load the module, e.g.:

```
load_module "modules/ngx_http_vod_module.so";
```

## Install
```
docker pull ghcr.io/lyl-radio/nginx-vod-docker:latest
```

This repo also provides a `docker-compose.yml` configuration for a quick setup.

## Credits

This image is based on work from:
- [alfg/docker-ffmpeg](https://github.com/alfg/docker-ffmpeg)
- [nytimes/nginx-vod-module-docker](https://github.com/nytimes/nginx-vod-module-docker)