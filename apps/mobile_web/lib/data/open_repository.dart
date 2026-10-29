import 'learning_repository.dart';
import 'open_repository_stub.dart'
    if (dart.library.io) 'drift/open_drift.dart'
    if (dart.library.js_interop) 'indexeddb/open_indexeddb.dart'
    as platform;

Future<LearningRepository> openLearningRepository() =>
    platform.openDriverRepository();
