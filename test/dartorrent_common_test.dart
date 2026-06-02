import 'dart:io';
import 'dart:typed_data';

import 'package:dartorrent_common/dartorrent_common.dart';
import 'package:test/test.dart';

void main() {
  group('CompactAddress IPv4', () {
    test('constructor stores address and port', () {
      var addr = InternetAddress.fromRawAddress(
          Uint8List.fromList([192, 168, 0, 1]),
          type: InternetAddressType.IPv4);
      var c = CompactAddress(addr, 6881);
      expect(c.address.address, '192.168.0.1');
      expect(c.port, 6881);
      expect(c.addressString, '192.168.0.1');
      expect(c.toString(), '192.168.0.1:6881');
    });

    test('rejects out-of-range port via assert', () {
      var addr = InternetAddress.fromRawAddress(
          Uint8List.fromList([0, 0, 0, 0]),
          type: InternetAddressType.IPv4);
      expect(() => CompactAddress(addr, 70000), throwsA(isA<AssertionError>()));
      expect(() => CompactAddress(addr, -1), throwsA(isA<AssertionError>()));
    });

    test('toBytes growable and non-growable produce identical content', () {
      var addr = InternetAddress.fromRawAddress(
          Uint8List.fromList([10, 0, 0, 5]),
          type: InternetAddressType.IPv4);
      var c = CompactAddress(addr, 0x1A2B);
      var g = c.toBytes();
      var f = c.toBytes(false);
      expect(g, [10, 0, 0, 5, 0x1A, 0x2B]); // big-endian port
      expect(f, g);
      expect(f, isA<Uint8List>());
    });

    test('parse round-trips toBytes output', () {
      var addr = InternetAddress.fromRawAddress(
          Uint8List.fromList([1, 2, 3, 4]),
          type: InternetAddressType.IPv4);
      var c = CompactAddress(addr, 12112);
      var parsed = CompactAddress.parseIPv4Address(c.toBytes());
      expect(parsed, isNotNull);
      expect(parsed, equals(c));
      expect(parsed!.toString(), c.toString());
    });

    test('parseIPv4Address honors offset', () {
      var bytes = [0xFF, 0xFF, 192, 168, 1, 100, 0x00, 0x50];
      var c = CompactAddress.parseIPv4Address(bytes, 2);
      expect(c, isNotNull);
      expect(c!.address.address, '192.168.1.100');
      expect(c.port, 80);
    });

    test('parseIPv4Address returns null on empty or too-short input', () {
      expect(CompactAddress.parseIPv4Address(<int>[]), isNull);
      expect(CompactAddress.parseIPv4Address([1, 2, 3, 4, 5]), isNull);
      expect(CompactAddress.parseIPv4Address([1, 2, 3, 4, 5, 6, 7], 2), isNull);
    });

    test('parseIPv4Addresses parses multiple 6-byte blocks', () {
      var bytes = [
        10, 0, 0, 1, 0x1F, 0x90, // 10.0.0.1:8080
        10, 0, 0, 2, 0x1F, 0x91, // 10.0.0.2:8081
      ];
      var list = CompactAddress.parseIPv4Addresses(bytes);
      expect(list.length, 2);
      expect(list[0].toString(), '10.0.0.1:8080');
      expect(list[1].toString(), '10.0.0.2:8081');
    });

    test('parseIPv4Addresses on empty input returns empty list', () {
      expect(CompactAddress.parseIPv4Addresses(<int>[]), isEmpty);
    });

    test('parseIPv4Addresses respects end and never reads past it', () {
      // One valid 6-byte block, then 5 trailing bytes that would form an
      // illegal/garbage address if read. end stops parsing before them.
      var bytes = [
        10, 0, 0, 1, 0x1F, 0x90, // 10.0.0.1:8080  (bytes 0..5)
        99, 99, 99, 99, 99, // trailing junk past end (bytes 6..10)
      ];
      var list = CompactAddress.parseIPv4Addresses(bytes, 0, 6);
      expect(list.length, 1);
      expect(list[0].toString(), '10.0.0.1:8080');
    });

    test('parseIPv4Addresses end inside a partial block drops the partial', () {
      // 1.5 blocks of data, but end allows only the first full block.
      var bytes = [
        1, 2, 3, 4, 0, 80, // 1.2.3.4:80
        5, 6, 7, // partial block (3 bytes) — must be ignored
      ];
      var list = CompactAddress.parseIPv4Addresses(bytes, 0, 9);
      expect(list.length, 1);
      expect(list[0].toString(), '1.2.3.4:80');
    });

    test('parseIPv4Addresses with buffer longer than end ignores extra bytes',
        () {
      // Buffer has 3 full blocks; end limits parsing to the first 2.
      var bytes = [
        10, 0, 0, 1, 0x1F, 0x90, // block 0
        10, 0, 0, 2, 0x1F, 0x91, // block 1
        10, 0, 0, 3, 0x1F, 0x92, // block 2 — beyond end, must not be read
      ];
      var list = CompactAddress.parseIPv4Addresses(bytes, 0, 12);
      expect(list.length, 2);
      expect(list[0].toString(), '10.0.0.1:8080');
      expect(list[1].toString(), '10.0.0.2:8081');
    });

    test('multipleAddressBytes is inverse of parseIPv4Addresses', () {
      var a = CompactAddress(
          InternetAddress.fromRawAddress(Uint8List.fromList([8, 8, 8, 8]),
              type: InternetAddressType.IPv4),
          53);
      var b = CompactAddress(
          InternetAddress.fromRawAddress(Uint8List.fromList([1, 1, 1, 1]),
              type: InternetAddressType.IPv4),
          443);
      var bytes = CompactAddress.multipleAddressBytes([a, b]);
      expect(bytes.length, 12);
      var back = CompactAddress.parseIPv4Addresses(bytes);
      expect(back, [a, b]);
    });

    test('multipleAddressBytes on empty list returns empty', () {
      expect(CompactAddress.multipleAddressBytes(<CompactAddress>[]), isEmpty);
    });

    test('clone produces an equal but distinct instance', () {
      var c = CompactAddress(
          InternetAddress.fromRawAddress(Uint8List.fromList([127, 0, 0, 1]),
              type: InternetAddressType.IPv4),
          6881);
      var clone = c.clone();
      expect(clone, equals(c));
      expect(identical(clone, c), isFalse);
      expect(clone.hashCode, equals(c.hashCode));
    });

    test('equality and hashCode are consistent', () {
      var a = CompactAddress(
          InternetAddress.fromRawAddress(Uint8List.fromList([192, 168, 0, 1]),
              type: InternetAddressType.IPv4),
          1000);
      var same = CompactAddress(
          InternetAddress.fromRawAddress(Uint8List.fromList([192, 168, 0, 1]),
              type: InternetAddressType.IPv4),
          1000);
      var diffPort = CompactAddress(
          InternetAddress.fromRawAddress(Uint8List.fromList([192, 168, 0, 1]),
              type: InternetAddressType.IPv4),
          1001);
      expect(a, equals(same));
      expect(a.hashCode, equals(same.hashCode));
      expect(a == diffPort, isFalse);
      // ignore: unrelated_type_equality_checks
      expect(a == 'not an address', isFalse);
    });

    test('toContactEncodingString round-trips back to bytes', () {
      var c = CompactAddress(
          InternetAddress.fromRawAddress(Uint8List.fromList([10, 20, 30, 40]),
              type: InternetAddressType.IPv4),
          8888);
      var s = c.toContactEncodingString();
      expect(s, isNotNull);
      expect(s!.codeUnits, c.toBytes());
    });
  });

  group('CompactAddress IPv6', () {
    test('parse round-trips toBytes output', () {
      var raw = Uint8List.fromList(List<int>.generate(16, (i) => i + 1));
      var addr =
          InternetAddress.fromRawAddress(raw, type: InternetAddressType.IPv6);
      var c = CompactAddress(addr, 9999);
      var bytes = c.toBytes();
      expect(bytes.length, 18);
      var parsed = CompactAddress.parseIPv6Address(bytes);
      expect(parsed, isNotNull);
      expect(parsed!.port, 9999);
      expect(parsed.address.rawAddress, raw);
    });

    test('parseIPv6Address returns null on too-short input', () {
      expect(CompactAddress.parseIPv6Address(<int>[]), isNull);
      expect(
          CompactAddress.parseIPv6Address(List<int>.filled(17, 0)), isNull);
    });

    test('parseIPv6Addresses parses multiple 18-byte blocks', () {
      var a = CompactAddress(
          InternetAddress.fromRawAddress(
              Uint8List.fromList(List<int>.generate(16, (i) => i)),
              type: InternetAddressType.IPv6),
          1);
      var b = CompactAddress(
          InternetAddress.fromRawAddress(
              Uint8List.fromList(List<int>.generate(16, (i) => 255 - i)),
              type: InternetAddressType.IPv6),
          2);
      var bytes = <int>[...a.toBytes(false), ...b.toBytes(false)];
      var list = CompactAddress.parseIPv6Addresses(bytes);
      expect(list.length, 2);
      expect(list[0], equals(a));
      expect(list[1], equals(b));
    });
  });

  group('byte utilities', () {
    test('randomBytes returns growable list of requested length', () {
      var bytes = randomBytes(8);
      expect(bytes.length, 8);
      expect(bytes, isNot(isA<Uint8List>()));
      expect(bytes.every((b) => b >= 0 && b <= 255), isTrue);
    });

    test('randomBytes with typedList returns Uint8List', () {
      var bytes = randomBytes(16, true);
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, 16);
      expect(bytes.every((b) => b >= 0 && b <= 255), isTrue);
    });

    test('randomBytes(0) returns empty', () {
      expect(randomBytes(0), isEmpty);
      expect(randomBytes(0, true), isEmpty);
    });

    test('randomInt stays within bound', () {
      for (var i = 0; i < 100; i++) {
        var v = randomInt(10);
        expect(v, inInclusiveRange(0, 9));
      }
    });

    test('transformBufferToHexString zero-pads and lowercases', () {
      expect(transformBufferToHexString([0, 15, 16, 255]), '000f10ff');
      expect(transformBufferToHexString(<int>[]), '');
      expect(transformBufferToHexString([0xDE, 0xAD, 0xBE, 0xEF]), 'deadbeef');
    });

    test('transformBufferToHexString length is twice the input', () {
      var bytes = randomBytes(20);
      expect(transformBufferToHexString(bytes).length, 40);
    });
  });

  group('public tracker result merging', () {
    test('all sources exhausted (null) -> empty lists, no cast crash',
        () async {
      // Simulate every source running out of retries: each resolves to null.
      var results = <Future<List<Uri>?>>[
        Future.value(null),
        Future.value(null),
        Future.value(null),
      ];
      var emitted = await mergePublicTrackerResults(results).toList();
      expect(emitted.length, 3);
      expect(emitted, everyElement(isEmpty));
    });

    test('mixes null and real results, coalescing null to []', () async {
      var results = <Future<List<Uri>?>>[
        Future.value(null),
        Future.value([Uri.parse('udp://tracker.example:1337')]),
        Future.value(<Uri>[]),
      ];
      var emitted = await mergePublicTrackerResults(results).toList();
      expect(emitted.length, 3);
      // Exactly one non-empty list with the single tracker uri.
      var nonEmpty = emitted.where((e) => e.isNotEmpty).toList();
      expect(nonEmpty.length, 1);
      expect(nonEmpty.first.single.toString(), 'udp://tracker.example:1337');
    });

    test('empty source set yields an empty stream', () async {
      var emitted =
          await mergePublicTrackerResults(<Future<List<Uri>?>>[]).toList();
      expect(emitted, isEmpty);
    });
  });
}
