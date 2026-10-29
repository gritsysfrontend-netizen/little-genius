// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'Little Genius';

  @override
  String get welcomeTitle => 'வரவேற்பு';

  @override
  String get welcomeBody => 'விளையாடிக் கற்றுக்கொள்ள அமைதியான இடம்.';

  @override
  String get continueAction => 'தொடருங்கள்';

  @override
  String get chooseLanguage => 'மொழியைத் தேர்ந்தெடுங்கள்';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get gateTitle => 'பெரியவர் சோதனை';

  @override
  String get gateBody => 'ஒரு பெரியவரிடம் பதிலைக் கேளுங்கள்.';

  @override
  String get gateQuestion => '3 + 4 எவ்வளவு?';

  @override
  String get gateWrong => 'மீண்டும் முயற்சிக்கவும்.';

  @override
  String get localTitle => 'இது இந்தச் சாதனத்திலேயே இருக்கும்';

  @override
  String get localBody => 'கணக்கு தேவையில்லை. கற்றல் இங்கேயே இருக்கும்.';

  @override
  String get webStorageNote =>
      'வலையில் உலாவி சேமித்த பாடங்களை அழிக்கலாம். தொலைபேசி அவற்றை நம்பகமாக வைத்திருக்கும்.';

  @override
  String get createProfile => 'சுயவிவரம் உருவாக்குங்கள்';

  @override
  String get nicknameLabel => 'அவர்களை எப்படி அழைப்பது?';

  @override
  String get nicknameHint => 'புனைப்பெயர், சட்டப்பெயர் அல்ல';

  @override
  String get avatarLabel => 'ஒரு படத்தைத் தேர்ந்தெடுங்கள்';

  @override
  String get ageBandLabel => 'வயதுப் பிரிவு';

  @override
  String get band12 => '1 முதல் 2 வயது';

  @override
  String get band23 => '2 முதல் 3 வயது';

  @override
  String get band34 => '3 முதல் 4 வயது';

  @override
  String get band45 => '4 முதல் 5 வயது';

  @override
  String get bilingualLabel => 'இரண்டாவது மொழியையும் காட்டு';

  @override
  String helloName(String name) {
    return 'வணக்கம், $name';
  }

  @override
  String get animalsTitle => 'விலங்குகள்';

  @override
  String get colorsTitle => 'நிறங்கள்';

  @override
  String get pairsTitle => 'இணைகள்';

  @override
  String get sizesTitle => 'அளவுகள்';

  @override
  String get numbersTitle => 'எண்கள்';

  @override
  String get routinesTitle => 'வரிசை';

  @override
  String get countMore => 'கூடுதல்';

  @override
  String get countLess => 'குறைவு';

  @override
  String get countDone => 'முடிந்தது';

  @override
  String get gentleRetry => 'மீண்டும் முயலுங்கள்.';

  @override
  String storageUsed(int bytes) {
    return 'பயன்படுத்திய இடம்: $bytes பைட்டுகள்';
  }

  @override
  String get notDownloaded => 'பதிவிறக்கப்படவில்லை';

  @override
  String get downloadedCopy => 'பதிவிறக்கப்பட்டது';

  @override
  String get downloadPack => 'தொகுப்பைப் பதிவிறக்குங்கள்';

  @override
  String installedPack(int version) {
    return 'நிறுவப்பட்ட தொகுப்பு பதிப்பு $version';
  }

  @override
  String get packCheckFailed =>
      'இந்தத் தொகுப்பைச் சரிபார்க்க முடியவில்லை. கடைசியாகச் சரிபார்த்த தொகுப்பு இந்தச் சாதனத்தில் இருக்கும்.';

  @override
  String get downloadAction => 'பதிவிறக்கம்';

  @override
  String get downloading => 'பதிவிறக்குகிறது';

  @override
  String get downloadFailed =>
      'பதிவிறக்கம் முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get playAction => 'விளையாடு';

  @override
  String get contentUnavailable => 'இந்தச் செயல்பாடு இப்போது இல்லை.';

  @override
  String get goHome => 'முகப்பு';

  @override
  String get back => 'பின்னால்';

  @override
  String get parentArea => 'பெரியவர்';

  @override
  String get languageSettings => 'மொழி';

  @override
  String get downloadsTitle => 'பதிவிறக்கங்கள்';

  @override
  String get progressTitle => 'முன்னேற்றம்';

  @override
  String get profilesTitle => 'சுயவிவரங்கள்';

  @override
  String get accountNotAvailable => 'இந்தப் பதிப்பில் கணக்கு இல்லை.';

  @override
  String get privacyNotBuilt =>
      'இந்தப் பதிப்பில் கணக்கு ஏற்றுமதியும் நீக்கமும் இல்லை.';

  @override
  String get caregiverPurpose =>
      'Little Genius என்பது சுமார் 1 முதல் 5 வயது குழந்தைகள் பார்க்க, கேட்க, தட்ட ஒரு அமைதியான இடம்.';

  @override
  String get caregiverPrivacy =>
      'ஒரு புனைப்பெயர் போதும். சட்டப்பெயர், புகைப்படம், அல்லது பள்ளியை நாங்கள் கேட்பதில்லை.';

  @override
  String get caregiverAccount =>
      'இந்தப் பதிப்பில் கணக்கு இல்லை. எதுவும் பதிவேற்றப்படாது. எதிர்காலக் கணக்கு தனித் தேர்வாக இருக்கும், அது இப்போது இயக்கப்படவில்லை.';

  @override
  String get sessionLimitTitle => 'விளையாட்டு நினைவூட்டல்';

  @override
  String get sessionLimitBody =>
      'இந்தச் செயலியின் உள்ளே ஒரு நினைவூட்டலை அமைக்கலாம். இது தொலைபேசியைப் பூட்டாது. இது திரை நேரமோ சாதனக் கட்டுப்பாடோ அல்ல. Little Genius திறந்திருக்கும்போது மட்டுமே இது எண்ணும்.';

  @override
  String get sessionOff => 'நினைவூட்டல் இல்லை';

  @override
  String sessionMinutes(int count) {
    return '$count நிமிடங்கள்';
  }

  @override
  String get sessionEndedTitle => 'ஓய்வு நேரம்';

  @override
  String get sessionEndedBody =>
      'Little Genius உள்ளே உள்ள நினைவூட்டல் முடிந்தது. இது சாதனத்தை அணைக்கவில்லை.';

  @override
  String get sessionPaused =>
      'Little Genius பின்னணியில் இருக்கும்போது நினைவூட்டல் இடைநிறுத்தப்படும். இது தொலைபேசியைக் கட்டுப்படுத்தாது.';

  @override
  String get stateLoading => 'ஏற்றுகிறது';

  @override
  String get stateEmpty => 'இங்கே இன்னும் எதுவும் இல்லை.';

  @override
  String get stateSuccess => 'சேமிக்கப்பட்டது';

  @override
  String get stateRecoverable => 'ஏதோ தவறு நேர்ந்தது. மீண்டும் முயற்சிக்கலாம்.';

  @override
  String get stateOffline =>
      'நீங்கள் இணைப்பில்லாமல் இருக்கிறீர்கள். சேமித்த செயல்பாடுகளை இன்னும் விளையாடலாம்.';

  @override
  String get stateRetrying => 'மீண்டும் முயல்கிறது';

  @override
  String get stateUpdateAvailable =>
      'புதிய நகல் உள்ளது. நீங்கள் விளையாடும் நகல் அப்படியே இருக்கும்.';

  @override
  String get pause => 'இடைநிறுத்து';

  @override
  String get replay => 'மீண்டும் கேளுங்கள்';

  @override
  String get playAudio => 'வழிமுறையைக் கேளுங்கள்';

  @override
  String get checksumError =>
      'இந்தப் பதிவிறக்கத்தைச் சரிபார்க்க முடியவில்லை, அதனால் சேமிக்கப்படவில்லை.';

  @override
  String get finished => 'முடிந்தது';

  @override
  String get retry => 'மீண்டும் முயற்சி';

  @override
  String get cancel => 'நிறுத்து';

  @override
  String get hearOtherLanguage => 'மற்ற மொழியில் கேளுங்கள்';

  @override
  String get audioMissing => 'ஒலி இல்லை.';

  @override
  String get downloadFirst => 'விளையாடும் முன் செயல்பாட்டைப் பதிவிறக்குங்கள்.';

  @override
  String startedLabel(int count) {
    return 'தொடங்கியது: $count';
  }

  @override
  String completedLabel(int count) {
    return 'முடிந்தது: $count';
  }

  @override
  String get noProgress => 'இன்னும் எதுவும் முடியவில்லை.';

  @override
  String get progressOnDevice =>
      'இந்தப் பட்டியல் இந்தச் சாதனத்திலேயே இருக்கும். இது பதிவேற்றப்படாது.';

  @override
  String get completedHeading => 'முடிந்த செயல்பாடுகள்';

  @override
  String get categoriesHeading => 'வகைகள்';

  @override
  String get recentHeading => 'சமீபத்தியவை';

  @override
  String get suggestionHeading => 'ஒரு செயல்பாட்டை முயலலாம்';

  @override
  String get suggestionNone =>
      'இந்த வயதுக்கும் மொழிக்கும் வேறு செயல்பாடு இப்போது இல்லை.';

  @override
  String get openedActivity => 'திறந்தது';

  @override
  String get noCategoryYet => 'இன்னும் வகை இல்லை.';

  @override
  String get noRecent => 'இன்னும் சமீபத்தியது இல்லை.';

  @override
  String get save => 'சேமி';

  @override
  String get nicknameInvalid => '1 முதல் 24 எழுத்துகள் வரை எழுதுங்கள்.';

  @override
  String get avatarStar => 'நட்சத்திரம்';

  @override
  String get avatarSun => 'சூரியன்';

  @override
  String get avatarLeaf => 'இலை';

  @override
  String get avatarMoon => 'நிலா';

  @override
  String get avatarBird => 'பறவை';

  @override
  String get avatarFish => 'மீன்';
}
