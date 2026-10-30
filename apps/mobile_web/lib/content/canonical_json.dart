import 'dart:convert';

import 'package:crypto/crypto.dart';

String canonicalJson(Object? value) => _stringify(value);

String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

String _stringify(Object? value) {
  if (value == null) return 'null';
  if (value is String) return jsonEncode(value);
  if (value is num) {
    if (value is double && !value.isFinite) {
      throw ArgumentError('non-finite number');
    }
    return jsonEncode(value);
  }
  if (value is bool) return value ? 'true' : 'false';
  if (value is List) {
    return '[${value.map(_stringify).join(',')}]';
  }
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return '{${keys.map((key) => '${jsonEncode(key)}:${_stringify(value[key])}').join(',')}}';
  }
  throw ArgumentError('unsupported json value');
}
