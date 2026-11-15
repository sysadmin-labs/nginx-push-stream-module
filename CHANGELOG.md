# Changelog

## 0.6.1

First release from this repository, carrying on from upstream's 0.6.0. It
continues Wandenberg Peixoto's and Rogério Carvalho Schneider's module,
whose history is intact here; their repository has had no commit since May
2024.

The licence is unchanged: GPL-3.0-or-later, which is upstream's choice and
unusual for an nginx module.

### Added

- Continuous integration against nginx 1.28, 1.30 and 1.31, statically and
  dynamically, with sanitizers, valgrind, CodeQL, a reload gate and a
  FreeBSD run.
- `t/00-channels.t`, which publishes into channels and reads them back out
  of the statistics. This module needs nothing but nginx, so the real path
  is walked rather than only the configuration parsed.

### Changed

- `config` uses the `auto/module` form only; the pre-1.9.11 branch it
  carried alongside could not build a loadable module. The `.c` files that
  the one translation unit `#include`s are now named as dependencies, so a
  change to one of them rebuilds.
