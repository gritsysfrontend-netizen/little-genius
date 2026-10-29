// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Little Genius';

  @override
  String get welcomeTitle => 'स्वागत है';

  @override
  String get welcomeBody => 'खेलने और सीखने की एक शांत जगह।';

  @override
  String get continueAction => 'आगे बढ़ें';

  @override
  String get chooseLanguage => 'भाषा चुनें';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get gateTitle => 'बड़ों की जाँच';

  @override
  String get gateBody => 'कृपया किसी बड़े से जवाब पूछें।';

  @override
  String get gateQuestion => '3 + 4 कितना है?';

  @override
  String get gateWrong => 'फिर से कोशिश करें।';

  @override
  String get localTitle => 'यह इसी डिवाइस पर रहता है';

  @override
  String get localBody => 'खाते की ज़रूरत नहीं। सीखना यहीं रहता है।';

  @override
  String get webStorageNote =>
      'वेब पर ब्राउज़र सहेजे पाठ हटा सकता है। फ़ोन उन्हें ज़्यादा सुरक्षित रखता है।';

  @override
  String get createProfile => 'प्रोफ़ाइल बनाएँ';

  @override
  String get nicknameLabel => 'उन्हें क्या बुलाएँ?';

  @override
  String get nicknameHint => 'उपनाम, कानूनी नाम नहीं';

  @override
  String get avatarLabel => 'एक चित्र चुनें';

  @override
  String get ageBandLabel => 'आयु समूह';

  @override
  String get band12 => '1 से 2 साल';

  @override
  String get band23 => '2 से 3 साल';

  @override
  String get band34 => '3 से 4 साल';

  @override
  String get band45 => '4 से 5 साल';

  @override
  String get bilingualLabel => 'दूसरी भाषा भी दिखाएँ';

  @override
  String helloName(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get animalsTitle => 'जानवर';

  @override
  String get downloadAction => 'डाउनलोड';

  @override
  String get downloading => 'डाउनलोड हो रहा है';

  @override
  String get downloadFailed => 'डाउनलोड पूरा नहीं हुआ। फिर कोशिश करें।';

  @override
  String get playAction => 'खेलें';

  @override
  String get contentUnavailable => 'यह गतिविधि अभी उपलब्ध नहीं है।';

  @override
  String get goHome => 'घर';

  @override
  String get back => 'पीछे';

  @override
  String get parentArea => 'बड़े';

  @override
  String get languageSettings => 'भाषा';

  @override
  String get downloadsTitle => 'डाउनलोड';

  @override
  String get progressTitle => 'प्रगति';

  @override
  String get profilesTitle => 'प्रोफ़ाइल';

  @override
  String get accountNotAvailable => 'इस संस्करण में खाता नहीं है।';

  @override
  String get sessionNotBuilt => 'इस संस्करण में सत्र की सीमा नहीं है।';

  @override
  String get privacyNotBuilt => 'इस संस्करण में खाता निर्यात और हटाना नहीं है।';

  @override
  String get pause => 'रोकें';

  @override
  String get replay => 'फिर सुनें';

  @override
  String get playAudio => 'निर्देश सुनें';

  @override
  String get checksumError =>
      'इस डाउनलोड की जाँच नहीं हो सकी, इसलिए इसे सहेजा नहीं गया।';

  @override
  String get finished => 'हो गया';

  @override
  String get retry => 'फिर कोशिश करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get hearOtherLanguage => 'दूसरी भाषा सुनें';

  @override
  String get audioMissing => 'आवाज़ उपलब्ध नहीं है।';

  @override
  String get downloadFirst => 'खेलने से पहले गतिविधि डाउनलोड करें।';

  @override
  String startedLabel(int count) {
    return 'शुरू: $count';
  }

  @override
  String completedLabel(int count) {
    return 'पूरा: $count';
  }

  @override
  String get noProgress => 'अभी कुछ पूरा नहीं हुआ।';

  @override
  String get save => 'सहेजें';

  @override
  String get nicknameInvalid => '1 से 24 अक्षर लिखें।';

  @override
  String get avatarStar => 'तारा';

  @override
  String get avatarSun => 'सूरज';

  @override
  String get avatarLeaf => 'पत्ता';

  @override
  String get avatarMoon => 'चाँद';

  @override
  String get avatarBird => 'पक्षी';

  @override
  String get avatarFish => 'मछली';
}
