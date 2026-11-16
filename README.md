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

36 of them, read out of the module's own command tables, so this is
the whole set and the contexts are the ones the code enforces.

The ones that decide the shape of a setup:

|Directive|What it decides|
|---|---|
|`push_stream_shared_memory_size`|how much memory all channels share|
|`push_stream_publisher`|a publisher location, `normal` or `admin`|
|`push_stream_subscriber`|a subscriber location: `streaming`, `polling`, `long-polling`, `eventsource` or `websocket`|
|`push_stream_channels_path`|where the channel id comes from|
|`push_stream_channels_statistics`|a statistics location|
|`push_stream_message_ttl`|how long a message is kept for subscribers arriving late|
|`push_stream_store_messages`|whether messages are kept at all|
|`push_stream_authorized_channels_only`|refuse subscribers to channels no publisher created|

And all of them:

|Directive|Context|Takes|
|---|---|---|
|`push_stream_allow_connections_to_events_channel`|http, server, location, if|1 argument|
|`push_stream_allowed_origins`|http, server, location|1 argument|
|`push_stream_authorized_channels_only`|http, server, location|1 argument|
|`push_stream_channel_deleted_message_text`|http|1 argument|
|`push_stream_channel_inactivity_time`|http|1 argument|
|`push_stream_channel_info_on_publish`|http, server, location|1 argument|
|`push_stream_channels_path`|http, server, location, if|1 argument|
|`push_stream_channels_statistics`|location|no arguments|
|`push_stream_events_channel_id`|http|1 argument|
|`push_stream_footer_template`|http, server, location|1 argument|
|`push_stream_header_template`|http, server, location|1 argument|
|`push_stream_header_template_file`|http, server, location|1 argument|
|`push_stream_last_event_id`|http, server, location, if|1 argument|
|`push_stream_last_received_message_tag`|http, server, location, if|1 argument|
|`push_stream_last_received_message_time`|http, server, location, if|1 argument|
|`push_stream_longpolling_connection_ttl`|http, server, location|1 argument|
|`push_stream_max_channel_id_length`|http|1 argument|
|`push_stream_max_messages_stored_per_channel`|http|1 argument|
|`push_stream_max_number_of_channels`|http|1 argument|
|`push_stream_max_number_of_wildcard_channels`|http|1 argument|
|`push_stream_max_subscribers_per_channel`|http|1 argument|
|`push_stream_message_template`|http, server, location|1 argument|
|`push_stream_message_ttl`|http|1 argument|
|`push_stream_padding_by_user_agent`|http, server, location|1 argument|
|`push_stream_ping_message_interval`|http, server, location|1 argument|
|`push_stream_ping_message_text`|http|1 argument|
|`push_stream_publisher`|location|no arguments, 1 argument|
|`push_stream_shared_memory_size`|http|1 or 2 arguments|
|`push_stream_store_messages`|http, server, location, if|1 argument|
|`push_stream_subscriber`|location|no arguments, 1 argument|
|`push_stream_subscriber_connection_ttl`|http, server, location|1 argument|
|`push_stream_timeout_with_body`|http|1 argument|
|`push_stream_user_agent`|http, server, location|1 argument|
|`push_stream_websocket_allow_publish`|http, server, location|1 argument|
|`push_stream_wildcard_channel_max_qtd`|http, server, location|1 argument|
|`push_stream_wildcard_channel_prefix`|http|1 argument|

## Testing

```sh
ci/build.sh 1.30.6 /tmp/nginx-test
TEST_NGINX_BINARY=/tmp/nginx-test/sbin/nginx prove -r t/
ci/reload.sh /tmp/nginx-test/sbin/nginx
ci/version.sh
```

`ci/version.sh` holds the version in
`include/ngx_http_push_stream_module_version.h` against `CHANGELOG.md`.
The statistics handler sends it as the `X-Nginx-PushStream-Tag` response
header, so a stale value goes out on every request.

Unlike most modules here this one needs nothing but nginx to be exercised
for real, so the suite publishes into channels and reads them back out of
the statistics. The reload gate does the same after every reload, which is
what notices shared memory that did not survive the handover.

## License

GPL-3.0-or-later. See `COPYING` for the licence text and `LICENSE` for the
copyright notice.
