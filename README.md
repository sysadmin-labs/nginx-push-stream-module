# nginx-push-stream-module

[![Build][build-test-badge]][build-test-link]
[![Lint][lint-badge]][lint-link]
[![CodeQL][codeql-badge]][codeql-link]
[![A/UBSan][sanitizers-badge]][sanitizers-link]
[![Valgrind][valgrind-badge]][valgrind-link]
[![Reload][reload-badge]][reload-link]
[![FreeBSD][freebsd-badge]][freebsd-link]

[build-test-badge]: https://github.com/sysadmin-labs/nginx-push-stream-module/actions/workflows/build-test.yml/badge.svg
[build-test-link]: https://github.com/sysadmin-labs/nginx-push-stream-module/actions/workflows/build-test.yml
[lint-badge]: https://github.com/sysadmin-labs/nginx-push-stream-module/actions/workflows/lint.yml/badge.svg
[lint-link]: https://github.com/sysadmin-labs/nginx-push-stream-module/actions/workflows/lint.yml
[codeql-badge]: https://github.com/sysadmin-labs/nginx-push-stream-module/actions/workflows/codeql.yml/badge.svg
[codeql-link]: https://github.com/sysadmin-labs/nginx-push-stream-module/actions/workflows/codeql.yml
[sanitizers-badge]: https://github.com/sysadmin-labs/nginx-push-stream-module/actions/workflows/sanitizers.yml/badge.svg
[sanitizers-link]: https://github.com/sysadmin-labs/nginx-push-stream-module/actions/workflows/sanitizers.yml
[valgrind-badge]: https://github.com/sysadmin-labs/nginx-push-stream-module/actions/workflows/valgrind.yml/badge.svg
[valgrind-link]: https://github.com/sysadmin-labs/nginx-push-stream-module/actions/workflows/valgrind.yml
[reload-badge]: https://github.com/sysadmin-labs/nginx-push-stream-module/actions/workflows/reload.yml/badge.svg
[reload-link]: https://github.com/sysadmin-labs/nginx-push-stream-module/actions/workflows/reload.yml
[freebsd-badge]: https://github.com/sysadmin-labs/nginx-push-stream-module/actions/workflows/freebsd.yml/badge.svg
[freebsd-link]: https://github.com/sysadmin-labs/nginx-push-stream-module/actions/workflows/freebsd.yml

Server push straight out of nginx: publish a message into a channel over
HTTP and have it delivered to whoever is subscribed, as long polling, as an
EventSource stream, or over a WebSocket.

The channels live in nginx's own shared memory, so there is no broker
beside it and no backend holding a connection per subscriber.

## Where this comes from

Wandenberg Peixoto's and Rogério Carvalho Schneider's module, continued
here with its history intact. Their repository has had no commit since May
2024 and the FreeBSD port builds from it, which is the reason for this one.

Nothing in the module itself needed changing so far. What is new is the
scaffolding: a build against the releases the ports ship, the sanitizers,
valgrind, CodeQL, a reload gate and a FreeBSD run.

**This module is GPL-3.0-or-later**, unlike every other module in this
organisation. That is upstream's choice and it is carried over unchanged;
it matters for anyone redistributing an nginx built with it.

## Requirements

nginx 1.28 or newer. Nothing beyond what nginx itself needs; the WebSocket
side uses the SHA-1 in nginx's core.

## Building

```sh
./configure --add-module=/path/to/nginx-push-stream-module
```

As a loadable module, `--add-dynamic-module=` and then

```nginx
load_module modules/ngx_http_push_stream_module.so;
```

## Quick start

```nginx
http {
    push_stream_shared_memory_size 32m;
    push_stream_message_ttl        5m;

    server {
        listen 8080;

        # publishers write here, keep it off the public internet
        location /pub {
            allow 127.0.0.1;
            deny  all;

            push_stream_publisher admin;
            push_stream_channels_path $arg_id;
        }

        # subscribers read here
        location ~ /sub/(.*) {
            push_stream_subscriber eventsource;
            push_stream_channels_path $1;
        }

        location /channels-stats {
            allow 127.0.0.1;
            deny  all;

            push_stream_channels_statistics;
            push_stream_channels_path $arg_id;
        }
    }
}
```

```sh
curl -s -X POST -d 'hello' 'http://127.0.0.1:8080/pub?id=room1'
curl -s -N 'http://127.0.0.1:8080/sub/room1'
```

## Directives

There are around forty, documented in `docs/`, which is upstream's own
reference. The ones that decide the shape of a setup:

|Directive|What it decides|
|---|---|
|`push_stream_shared_memory_size`|how much memory all channels share|
|`push_stream_publisher`|a publisher location, `normal` or `admin`|
|`push_stream_subscriber`|a subscriber location: `streaming`, `polling`, `long-polling`, `eventsource` or `websocket`|
|`push_stream_channels_path`|where the channel id comes from|
|`push_stream_channels_statistics`|a statistics location|
|`push_stream_message_ttl`|how long a message is kept for subscribers that arrive late|
|`push_stream_store_messages`|whether messages are kept at all|
|`push_stream_authorized_channels_only`|refuse subscribers to channels no publisher created|

The limits (`push_stream_max_number_of_channels`,
`push_stream_max_messages_stored_per_channel`,
`push_stream_max_subscribers_per_channel` and the rest) belong in `http{}`,
not in a location, and so do the ping settings.

## Testing

```sh
ci/build.sh 1.30.6 /tmp/nginx-test
TEST_NGINX_BINARY=/tmp/nginx-test/sbin/nginx prove -r t/
ci/reload.sh /tmp/nginx-test/sbin/nginx
```

Unlike most modules here this one needs nothing but nginx to be exercised
for real, so the suite publishes into channels and reads them back out of
the statistics. The reload gate does the same after every reload, which is
what notices shared memory that did not survive the handover.

## License

GPL-3.0-or-later. See `COPYING` for the licence text and `LICENSE` for the
copyright notice.
