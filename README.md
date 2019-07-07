# goodtune/rtmp

This service can be used to receive one rtmp stream and replay it to several other services.

## Examples

The configuration below is shipped in the container.

    daemon off;
    worker_processes  auto;

    error_log /dev/stderr notice;

    events {
        worker_connections  1024;
    }

    rtmp {
        server {
            listen 1935;
            chunk_size 4000;

            access_log /dev/stdout combined;

            application live {
                live on;
            }
        }
    }

    http {
        server {
            listen 8080;

            location /stat {
                rtmp_stat all;
            }
        }
    }

This is will provide an RTMP that can be published too and consumer from.

### Testing

This quick guide assumes you have two pieces of software locally, in addition
to a working `docker` runtime.

1.  [OBS][1] (Open Broadcaster Software)
2.  [VLC media player][2]

Firstly, launch the container service locally by executing the following command:

    docker run --rm -it -p 1395:1395 goodtune/rtmp

Next, configure OBS stream to [rtmp://localhost/live/](rtmp://localhost/live/).
Start streaming (beyond the scope of this guide) and make sure it connects (you
should see a "live" timer counting up).

Finally, configure VLC to stream from
[rtmp://localhost/live/](rtmp://localhost/live/). Choose "Open Network..." from
the File menu and enter the stream address. After a short wait it should start
showing the content you are publishing from OBS.

## Extending

The initial configuration isn't particularly useful yet. It's not protected
from bad actors and you probably don't want to share RTMP links with users.

Where this will get useful is when we start flexing some of the
[nginx-rtmp-module](https://github.com/arut/nginx-rtmp-module) features to
`push` the stream to one or more services.

You have a few options on how to enact these changes.

### Rebuild the container

The `Dockerfile` already adds `nginx.conf` from this repository. If you edit
that file to your own taste you can simply run the following command to build
your own version of the container.

    docker build -t my-rtmp .

You would then launch the container differently:

    docker run --rm -it -p 1935:1935 my-rtmp

Building the whole container again is overkill, there are lighter ways.

### Mount alternate `nginx.conf`

Again assuming you have edited the default `nginx.conf` you can mount it over
the one shipped in the container:

    docker run --rm -it -p 1935:1935 -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro goodtune/rtmp

### Custom `Dockerfile` to extend the base image

Combining the above two approaches will give you a container image that is
ready to launch without external dependencies.

Create your own `Dockerfile` which looks like this:

    FROM goodtune/rtmp
    COPY nginx.conf /etc/nginx/nginx.conf

You can now build your customised container so that it will replace the shipped
`nginx.conf` with your specialied version.

    docker build -t my-rtmp .
    docker run --rm -it -p 1935:1935 my-rtmp

### Examples

*The keys below was randomly generated, apologies if anyone actually got that
assigned to them!*

Modify the `application` block to forward the stream to YouTube using a
dedicated stream key.

    application live {
        live on;
        push rtmp://a.rtmp.youtube.com/live2/2g6b-4fao-rpm8-3k1i;
    }

You can push to several endpoints if you wish, just add more `push` directives.
To send to YouTube and Facebook concurrently it might look like this.

    application live {
        live on;
        push rtmp://a.rtmp.youtube.com/live2/2g6b-4fao-rpm8-3k1i;
        push rtmp://live-api-s.facebook.com:80/rtmp/246215032874581?s_ps=1&s_vt=api-s&a=ATh0j8kAKxOnUqmY;
    }

If you want to prevent views from receiving the RTMP stream if they know your
application URL you can lock that down with access controls.

    application live {
        live on;
        deny play all;
    }

You can read about all of the possibilities in the [Directives][d] page on the
`nginx-rtmp-module` wiki.

## Credit

This service is built following the tutorial [How to Install Nginx with RTMP
Module on CentOS 7][g].


[1]: https://obsproject.com/
[2]: https://www.videolan.org/vlc/
[g]: https://www.howtoforge.com/tutorial/how-to-install-nginx-with-rtmp-module-on-centos/
[d]: https://github.com/arut/nginx-rtmp-module/wiki/Directives
