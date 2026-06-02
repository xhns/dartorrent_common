## 1.1.0

- Migrate to Dart 3 (`sdk: '>=3.0.0 <4.0.0'`).
- Adopt `package:lints/recommended.yaml`; replace deprecated `pedantic`. Analyzer is now clean under `dart analyze --fatal-infos`.
- Idiomatic cleanups (typed locals, `for` loops over `forEach`, string interpolation) with no public API or behavior changes.
- Fix a no-op `await` on the `utf8.decoder.bind(...)` stream in the public-tracker fetcher.
- Add a comprehensive unit-test suite for `CompactAddress` (IPv4/IPv6 parse/encode round-trips, equality, clone) and the byte utilities.
- Add GitHub Actions CI (analyze + test).

## 1.0.3

- Add a method to find the public trackers url.

## 1.0.1

- Initial version
