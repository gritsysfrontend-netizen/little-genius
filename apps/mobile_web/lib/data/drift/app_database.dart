import 'package:drift/drift.dart';

part 'app_database.g.dart';

class ProfileRows extends Table {
  TextColumn get profileId => text()();
  TextColumn get nickname => text()();
  TextColumn get avatarId => text()();
  TextColumn get ageBand => text()();
  TextColumn get preferredLocale => text()();
  BoolColumn get bilingualMode => boolean()();
  IntColumn get revision => integer()();

  @override
  Set<Column> get primaryKey => {profileId};
}

class EventRows extends Table {
  TextColumn get eventId => text()();
  TextColumn get profileId => text()();
  TextColumn get contentId => text()();
  IntColumn get contentVersion => integer()();
  TextColumn get eventType => text()();
  TextColumn get durationBucket => text().nullable()();
  TextColumn get occurredAt => text()();

  @override
  Set<Column> get primaryKey => {eventId};
}

class ProgressRows extends Table {
  TextColumn get profileId => text()();
  TextColumn get categoryId => text()();
  IntColumn get startedCount => integer()();
  IntColumn get completedCount => integer()();
  TextColumn get lastActivityAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {profileId, categoryId};
}

class OutboxRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get profileId => text()();
  TextColumn get idempotencyKey => text()();
  TextColumn get body => text()();
  TextColumn get createdAt => text()();
}

class DocumentRows extends Table {
  TextColumn get contentId => text()();
  IntColumn get contentVersion => integer()();
  TextColumn get payload => text()();
  TextColumn get payloadSha256 => text()();

  @override
  Set<Column> get primaryKey => {contentId, contentVersion};
}

class BlobRows extends Table {
  TextColumn get assetId => text()();
  TextColumn get sha256 => text()();
  TextColumn get mediaType => text()();
  BlobColumn get bytes => blob()();

  @override
  Set<Column> get primaryKey => {assetId};
}

class SettingRows extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    ProfileRows,
    EventRows,
    ProgressRows,
    OutboxRows,
    DocumentRows,
    BlobRows,
    SettingRows,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
