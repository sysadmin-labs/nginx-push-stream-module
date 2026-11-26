# Changelog

## Unreleased

### Fixed

- The build no longer fails on GCC 15 with `assignment discards 'const'
  qualifier`.  `ngx_strchr` casts its argument to `const char *` and GCC 15
  carries that into the result; the statistics handler writes a terminator
  into the channel id and now casts the pointer back explicitly.

- CI: the Test::Nginx cache is now keyed by the Perl build, not just by
  the runner OS.  When the hosted image moved to Ubuntu 26.04 the cached
  `~/perl5` tree was restored against a new interpreter and every test
  file died before its first assertion with `loadable library and perl
  binaries are mismatched`, taking Build & Test, A/UBSan and Valgrind
  down together.

## 0.6.2

First release from this repository, carrying on from upstream's 0.6.0. It
continues Wandenberg Peixoto's and Rogério Carvalho Schneider's module,
whose history is intact here; their repository has had no commit since May
2024.

This replaces 0.6.1, whose archive still carried `misc/` with a minified
jQuery in it, which the GPL notice in `LICENSE` does not cover.

The licence is unchanged: GPL-3.0-or-later, which is upstream's choice and
unusual for an nginx module.

### Fixed

- **The version and commit sent to every client were somebody else's.**
  `include/ngx_http_push_stream_module_version.h` said 0.5.5 and carried
  a commit hash from upstream's tree. The statistics handler sends both
  as the `X-Nginx-PushStream-Tag` and `-Commit` response headers, so the
  stale pair went out on every request rather than sitting in a file.
  The tag is this repository's version now and the commit string is
  empty: a wrong hash is worse than none, and this repository's own hash
  is not known when the file is written. `ci/version.sh` holds the header
  against `CHANGELOG.md` in the lint workflow.
- **Thirteen format conversions took the wrong type.** nginx's printf is
  not C's: `%d` pulls an `int`, while `ngx_int_t` needs `%i`, `size_t`
  needs `%uz` and `ngx_uint_t` needs `%ui`. Passed as `%d` were the
  message id and tag, the message size, a channel id length in three log
  messages, the two padding lengths in one, two worker slot numbers, the
  websocket version and frame step, and the http status in the websocket
  close frame. On a 64-bit little-endian host the low half of the
  argument happens to be the right one for values below 2^31, which is
  why nothing ever failed. The six remaining `%d` are correct: they take
  an `int` or a `pid_t`.

### Added

- Continuous integration against nginx 1.28, 1.30 and 1.31, statically and
  dynamically, with sanitizers, valgrind, CodeQL, a reload gate and a
  FreeBSD run.
- `t/00-channels.t`, which publishes into channels and reads them back out
  of the statistics. This module needs nothing but nginx, so the real path
  is walked rather than only the configuration parsed.
- `ci/version.sh`, run by the lint workflow.

### Changed

- The sanitizer workflow builds with `-DNGX_DEBUG_PALLOC=1` and collects
  the reports through `log_path`. nginx redirects its own stderr onto the
  error log file as soon as `error_log` names one, and Test::Nginx always
  names one, so reports written to stderr were lost: ASan was noticed
  only through the worker dying, and UBSan not at all.
- `config` uses the `auto/module` form only; the pre-1.9.11 branch it
  carried alongside could not build a loadable module. The `.c` files that
  the one translation unit `#include`s are now named as dependencies, so a
  change to one of them rebuilds.
