# Publish into a channel and read it back.
#
# This module needs nothing but nginx: the channels live in its own shared
# memory, the publisher and the subscriber are both locations in the same
# server.  So unlike most modules here, the real path can be walked in the
# test suite itself.

use Test::Nginx::Socket 'no_plan';

our $HttpConfig = q{
    push_stream_shared_memory_size    16m;
    push_stream_message_ttl           30s;
    push_stream_ping_message_interval 10s;
    push_stream_ping_message_text     "ping";
};

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: a published message comes back out of the statistics
--- http_config eval: $::HttpConfig
--- config
    location /pub {
        push_stream_publisher admin;
        push_stream_channels_path $arg_id;
    }
    location /stat {
        push_stream_channels_statistics;
        push_stream_channels_path $arg_id;
    }
--- pipelined_requests eval
["POST /pub?id=ch1\nhello", "GET /stat?id=ch1"]
--- response_body_like eval
[qr/./, qr/"channel": ?"ch1"/]



=== TEST 2: the published count is the number published
--- http_config eval: $::HttpConfig
--- config
    location /pub {
        push_stream_publisher admin;
        push_stream_channels_path $arg_id;
    }
    location /stat {
        push_stream_channels_statistics;
        push_stream_channels_path $arg_id;
    }
--- pipelined_requests eval
["POST /pub?id=ch2\none", "POST /pub?id=ch2\ntwo", "GET /stat?id=ch2"]
--- response_body_like eval
[qr/./, qr/./, qr/"published_messages": ?2/]



=== TEST 3: every directive of the subscriber side parses
--- http_config eval: $::HttpConfig
--- config
    location /sub {
        push_stream_subscriber                   long-polling;
        push_stream_channels_path                $arg_id;
        push_stream_longpolling_connection_ttl   2s;
        push_stream_message_template             "~text~";
        push_stream_header_template              "started";
        push_stream_footer_template              "done";
        push_stream_last_received_message_time   $arg_time;
        push_stream_last_received_message_tag    $arg_tag;
        push_stream_last_event_id                $http_last_event_id;
        push_stream_authorized_channels_only     off;
        push_stream_padding_by_user_agent        "test,0,0";
        push_stream_allowed_origins              "*";
    }
    location /t { return 200 "ok\n"; }
--- request
GET /t
--- response_body
ok



=== TEST 4: the limits parse
--- http_config
    push_stream_shared_memory_size             16m;
    push_stream_max_channel_id_length          64;
    push_stream_max_number_of_channels         100;
    push_stream_max_number_of_wildcard_channels 10;
    push_stream_max_messages_stored_per_channel 20;
    push_stream_max_subscribers_per_channel    5;
    push_stream_channel_inactivity_time        30s;
    push_stream_message_ttl                    30s;
    push_stream_store_messages                 on;
    push_stream_channel_deleted_message_text   "gone";
    push_stream_channel_info_on_publish        on;
--- config
    location /t { return 200 "ok\n"; }
--- request
GET /t
--- response_body
ok



=== TEST 5: a channel id longer than the limit is refused
--- http_config
    push_stream_shared_memory_size    16m;
    push_stream_max_channel_id_length 4;
--- config
    location /pub {
        push_stream_publisher admin;
        push_stream_channels_path $arg_id;
    }
--- request
POST /pub?id=waytoolong
--- error_code: 400



=== TEST 6: a publisher without a channel path is refused at startup
--- http_config eval: $::HttpConfig
--- config
    location /pub {
        push_stream_publisher admin;
    }
--- must_die



=== TEST 7: a long-polling subscriber returns when the ttl runs out
--- http_config eval: $::HttpConfig
--- config
    location /sub {
        push_stream_subscriber                 long-polling;
        push_stream_channels_path              $arg_id;
        push_stream_longpolling_connection_ttl 1s;
    }
--- request
GET /sub?id=quiet
--- timeout: 5
--- error_code: 304
