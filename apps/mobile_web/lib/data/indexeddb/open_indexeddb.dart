import '../learning_repository.dart';
import 'indexeddb_repository.dart';

Future<LearningRepository> openDriverRepository() =>
    IndexedDbLearningRepository.open();
