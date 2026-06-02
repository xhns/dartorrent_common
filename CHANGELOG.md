## 1.1.1

- Fix an unsound runtime cast in `findPublicTrackers`. The list of per-source
  fetches (`Future<List<Uri>?>`) was cast to `Iterable<Future<List<Uri>>>`;
  when a source exhausted its retries it resolved to `null`, throwing a
  `TypeError` inside `Stream.fromFutures` and crashing the whole stream.
  Null results are now coalesced to an empty list, so an exhausted source
  surfaces as `[]`. Extracted `mergePublicTrackerResults` to make this path
  unit-testable.
- Fix `parseIPv4Addresses` / `parseIPv6Addresses` ignoring the `end` argument:
  the loop bound and bounds checks used `message.length` instead of `end`, so a
  trailing partial block could be read past `end`. Parsing now consumes only
  complete blocks fully contained in `[offset, end)`.
- Add tests for the null-exhaustion merge path and for `end`-bounded parsing.

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
