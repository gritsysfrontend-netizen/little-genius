import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

String? _previous;

Future<Uri> uriForBytes(Uint8List bytes, String mediaType) async {
  if (_previous != null) URL.revokeObjectURL(_previous!);
  final parts = <BlobPart>[bytes.toJS].toJS;
  final blob = Blob(parts, BlobPropertyBag(type: mediaType));
  final url = URL.createObjectURL(blob);
  _previous = url;
  return Uri.parse(url);
}
