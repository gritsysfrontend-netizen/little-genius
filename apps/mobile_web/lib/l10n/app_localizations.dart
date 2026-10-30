import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Little Genius'**
  String get appTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'A quiet place to play and learn.'**
  String get welcomeBody;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose a language'**
  String get chooseLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @languageTamil.
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get languageTamil;

  /// No description provided for @gateTitle.
  ///
  /// In en, this message translates to:
  /// **'Grown-up check'**
  String get gateTitle;

  /// No description provided for @gateBody.
  ///
  /// In en, this message translates to:
  /// **'Please ask a grown-up to answer.'**
  String get gateBody;

  /// No description provided for @gateQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is 3 + 4?'**
  String get gateQuestion;

  /// No description provided for @gateWrong.
  ///
  /// In en, this message translates to:
  /// **'Try again.'**
  String get gateWrong;

  /// No description provided for @localTitle.
  ///
  /// In en, this message translates to:
  /// **'This stays on this device'**
  String get localTitle;

  /// No description provided for @localBody.
  ///
  /// In en, this message translates to:
  /// **'No account is needed. Learning stays here.'**
  String get localBody;

  /// No description provided for @webStorageNote.
  ///
  /// In en, this message translates to:
  /// **'On the web, the browser can clear saved lessons. A phone keeps them more reliably.'**
  String get webStorageNote;

  /// No description provided for @createProfile.
  ///
  /// In en, this message translates to:
  /// **'Create a profile'**
  String get createProfile;

  /// No description provided for @nicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'What should we call them?'**
  String get nicknameLabel;

  /// No description provided for @nicknameHint.
  ///
  /// In en, this message translates to:
  /// **'A nickname, not a legal name'**
  String get nicknameHint;

  /// No description provided for @avatarLabel.
  ///
  /// In en, this message translates to:
  /// **'Pick a picture'**
  String get avatarLabel;

  /// No description provided for @ageBandLabel.
  ///
  /// In en, this message translates to:
  /// **'Age band'**
  String get ageBandLabel;

  /// No description provided for @band12.
  ///
  /// In en, this message translates to:
  /// **'1 to 2 years'**
  String get band12;

  /// No description provided for @band23.
  ///
  /// In en, this message translates to:
  /// **'2 to 3 years'**
  String get band23;

  /// No description provided for @band34.
  ///
  /// In en, this message translates to:
  /// **'3 to 4 years'**
  String get band34;

  /// No description provided for @band45.
  ///
  /// In en, this message translates to:
  /// **'4 to 5 years'**
  String get band45;

  /// No description provided for @bilingualLabel.
  ///
  /// In en, this message translates to:
  /// **'Show a second language'**
  String get bilingualLabel;

  /// No description provided for @helloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloName(String name);

  /// No description provided for @animalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get animalsTitle;

  /// No description provided for @downloadAction.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadAction;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'The download did not finish. Try again.'**
  String get downloadFailed;

  /// No description provided for @playAction.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playAction;

  /// No description provided for @contentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This activity is not available.'**
  String get contentUnavailable;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get goHome;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @parentArea.
  ///
  /// In en, this message translates to:
  /// **'Grown-ups'**
  String get parentArea;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// No description provided for @downloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsTitle;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @profilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profilesTitle;

  /// No description provided for @accountNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Accounts are not in this version.'**
  String get accountNotAvailable;

  /// No description provided for @sessionNotBuilt.
  ///
  /// In en, this message translates to:
  /// **'Session limits are not in this version.'**
  String get sessionNotBuilt;

  /// No description provided for @privacyNotBuilt.
  ///
  /// In en, this message translates to:
  /// **'Account export and deletion are not in this version.'**
  String get privacyNotBuilt;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @replay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get replay;

  /// No description provided for @playAudio.
  ///
  /// In en, this message translates to:
  /// **'Play instruction'**
  String get playAudio;

  /// No description provided for @checksumError.
  ///
  /// In en, this message translates to:
  /// **'This download could not be checked, so it was not saved.'**
  String get checksumError;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @hearOtherLanguage.
  ///
  /// In en, this message translates to:
  /// **'Hear the other language'**
  String get hearOtherLanguage;

  /// No description provided for @audioMissing.
  ///
  /// In en, this message translates to:
  /// **'The sound is not available.'**
  String get audioMissing;

  /// No description provided for @downloadFirst.
  ///
  /// In en, this message translates to:
  /// **'Download the activity before play.'**
  String get downloadFirst;

  /// No description provided for @startedLabel.
  ///
  /// In en, this message translates to:
  /// **'Started: {count}'**
  String startedLabel(int count);

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Finished: {count}'**
  String completedLabel(int count);

  /// No description provided for @noProgress.
  ///
  /// In en, this message translates to:
  /// **'Nothing finished yet.'**
  String get noProgress;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @nicknameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 1 to 24 characters.'**
  String get nicknameInvalid;

  /// No description provided for @avatarStar.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get avatarStar;

  /// No description provided for @avatarSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get avatarSun;

  /// No description provided for @avatarLeaf.
  ///
  /// In en, this message translates to:
  /// **'Leaf'**
  String get avatarLeaf;

  /// No description provided for @avatarMoon.
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get avatarMoon;

  /// No description provided for @avatarBird.
  ///
  /// In en, this message translates to:
  /// **'Bird'**
  String get avatarBird;

  /// No description provided for @avatarFish.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get avatarFish;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
