import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../learning_repository.dart';
import 'drift_repository.dart';

/// Native SQLite via Drift. This file is not part of the web compilation,
/// so the web build does not include sqlite3.wasm.
///
/// `sqlite3_flutter_libs` stays in the pubspec as the 0.6 end-of-line shim.
/// It has no library members. Current `package:sqlite3` bundles the native
/// library itself and does not load a wasm module unless wasm.dart is imported.
Future<LearningRepository> openDriverRepository() async {
  final directory = await getApplicationSupportDirectory();
  final file = File(p.join(directory.path, 'little_genius.sqlite'));
  return DriftLearningRepository.openFile(file);
}
