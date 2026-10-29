import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<Uri> uriForBytes(Uint8List bytes, String mediaType) async {
  final directory = await getTemporaryDirectory();
  final extension = mediaType.contains('png') ? 'png' : 'mp3';
  final file = File(
    p.join(directory.path, 'little-genius-instruction.$extension'),
  );
  await file.writeAsBytes(bytes, flush: true);
  return file.uri;
}
