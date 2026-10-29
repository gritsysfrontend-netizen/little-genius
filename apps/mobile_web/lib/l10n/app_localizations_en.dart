// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Little Genius';

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get welcomeBody => 'A quiet place to play and learn.';

  @override
  String get continueAction => 'Continue';

  @override
  String get chooseLanguage => 'Choose a language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get gateTitle => 'Grown-up check';

  @override
  String get gateBody => 'Please ask a grown-up to answer.';

  @override
  String get gateQuestion => 'What is 3 + 4?';

  @override
  String get gateWrong => 'Try again.';

  @override
  String get localTitle => 'This stays on this device';

  @override
  String get localBody => 'No account is needed. Learning stays here.';

  @override
  String get webStorageNote =>
      'On the web, the browser can clear saved lessons. A phone keeps them more reliably.';

  @override
  String get createProfile => 'Create a profile';

  @override
  String get nicknameLabel => 'What should we call them?';

  @override
  String get nicknameHint => 'A nickname, not a legal name';

  @override
  String get avatarLabel => 'Pick a picture';

  @override
  String get ageBandLabel => 'Age band';

  @override
  String get band12 => '1 to 2 years';

  @override
  String get band23 => '2 to 3 years';

  @override
  String get band34 => '3 to 4 years';

  @override
  String get band45 => '4 to 5 years';

  @override
  String get bilingualLabel => 'Show a second language';

  @override
  String helloName(String name) {
    return 'Hello, $name';
  }

  @override
  String get animalsTitle => 'Animals';

  @override
  String get colorsTitle => 'Colors';

  @override
  String get pairsTitle => 'Pairs';

  @override
  String get sizesTitle => 'Sizes';

  @override
  String get numbersTitle => 'Numbers';

  @override
  String get routinesTitle => 'Order';

  @override
  String get countMore => 'More';

  @override
  String get countLess => 'Less';

  @override
  String get countDone => 'Done';

  @override
  String get gentleRetry => 'Let\'s try again.';

  @override
  String storageUsed(int bytes) {
    return 'Storage used: $bytes bytes';
  }

  @override
  String get notDownloaded => 'Not downloaded';

  @override
  String get downloadedCopy => 'Downloaded';

  @override
  String get downloadPack => 'Download pack';

  @override
  String installedPack(int version) {
    return 'Installed pack version $version';
  }

  @override
  String get packCheckFailed =>
      'This pack could not be checked. The last checked pack stays on this device.';

  @override
  String get downloadAction => 'Download';

  @override
  String get downloading => 'Downloading';

  @override
  String get downloadFailed => 'The download did not finish. Try again.';

  @override
  String get playAction => 'Play';

  @override
  String get contentUnavailable => 'This activity is not available.';

  @override
  String get goHome => 'Home';

  @override
  String get back => 'Back';

  @override
  String get parentArea => 'Grown-ups';

  @override
  String get languageSettings => 'Language';

  @override
  String get downloadsTitle => 'Downloads';

  @override
  String get progressTitle => 'Progress';

  @override
  String get profilesTitle => 'Profiles';

  @override
  String get accountNotAvailable => 'Accounts are not in this version.';

  @override
  String get privacyNotBuilt =>
      'Account export and deletion are not in this version.';

  @override
  String get caregiverPurpose =>
      'Little Genius is a quiet place for children about 1 to 5 years old to look, listen, and tap.';

  @override
  String get caregiverPrivacy =>
      'A nickname is enough. We do not ask for a legal name, a photo, or a school.';

  @override
  String get caregiverAccount =>
      'An account is not part of this version. Nothing is uploaded. A future account would be a separate choice, and it is not turned on.';

  @override
  String get sessionLimitTitle => 'Play reminder';

  @override
  String get sessionLimitBody =>
      'You can set a reminder that stays inside this app. It does not lock the phone, and it is not Screen Time or a device control. The reminder counts only while Little Genius is open.';

  @override
  String get sessionOff => 'No reminder';

  @override
  String sessionMinutes(int count) {
    return '$count minutes';
  }

  @override
  String get sessionEndedTitle => 'Time for a rest';

  @override
  String get sessionEndedBody =>
      'The play reminder inside Little Genius has finished. It did not turn off the device.';

  @override
  String get sessionPaused =>
      'The reminder is paused while Little Genius is in the background. It does not control the phone.';

  @override
  String get stateLoading => 'Loading';

  @override
  String get stateEmpty => 'Nothing here yet.';

  @override
  String get stateSuccess => 'Saved';

  @override
  String get stateRecoverable => 'Something went wrong. You can try again.';

  @override
  String get stateOffline =>
      'You are offline. Saved activities can still be played.';

  @override
  String get stateRetrying => 'Trying again';

  @override
  String get stateUpdateAvailable =>
      'A newer copy is available. The one you are playing stays as it is.';

  @override
  String get pause => 'Pause';

  @override
  String get replay => 'Replay';

  @override
  String get playAudio => 'Play instruction';

  @override
  String get checksumError =>
      'This download could not be checked, so it was not saved.';

  @override
  String get finished => 'Finished';

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get hearOtherLanguage => 'Hear the other language';

  @override
  String get audioMissing => 'The sound is not available.';

  @override
  String get downloadFirst => 'Download the activity before play.';

  @override
  String startedLabel(int count) {
    return 'Started: $count';
  }

  @override
  String completedLabel(int count) {
    return 'Finished: $count';
  }

  @override
  String get noProgress => 'Nothing finished yet.';

  @override
  String get save => 'Save';

  @override
  String get nicknameInvalid => 'Use 1 to 24 characters.';

  @override
  String get avatarStar => 'Star';

  @override
  String get avatarSun => 'Sun';

  @override
  String get avatarLeaf => 'Leaf';

  @override
  String get avatarMoon => 'Moon';

  @override
  String get avatarBird => 'Bird';

  @override
  String get avatarFish => 'Fish';
}
