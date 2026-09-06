import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// App name shown in window titles and the connect header.
  ///
  /// In en, this message translates to:
  /// **'Telltale'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Live vehicle telemetry'**
  String get appTagline;

  /// Bilingual label for the language picker. Options use self-names.
  ///
  /// In en, this message translates to:
  /// **'Language / 語言'**
  String get languageSectionTitle;

  /// No description provided for @connectHeadline.
  ///
  /// In en, this message translates to:
  /// **'Choose a connection'**
  String get connectHeadline;

  /// No description provided for @connectBody.
  ///
  /// In en, this message translates to:
  /// **'Plug in an ELM327 adapter and switch the ignition on, or use the built-in simulator.'**
  String get connectBody;

  /// No description provided for @settingsHeadline.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsHeadline;

  /// No description provided for @startupChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking local share cache and telemetry records'**
  String get startupChecking;

  /// Retryable startup failure title. Distinct from startupChecking (in-progress) and startupRestartRequired (must quit).
  ///
  /// In en, this message translates to:
  /// **'Cannot finish startup checks'**
  String get startupCannotComplete;

  /// No description provided for @startupRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get startupRetry;

  /// No description provided for @startupRestartRequired.
  ///
  /// In en, this message translates to:
  /// **'Restart required to continue safely'**
  String get startupRestartRequired;

  /// No description provided for @startupRetryHint.
  ///
  /// In en, this message translates to:
  /// **'Keep Telltale in the foreground, then retry after other file work finishes. Recording, replay, export and delete stay closed until startup completes.'**
  String get startupRetryHint;

  /// No description provided for @startupRestartHint.
  ///
  /// In en, this message translates to:
  /// **'Local share cache or telemetry records could not be confirmed. Fully quit and reopen Telltale so the wrong file is not overwritten, deleted, or shared.'**
  String get startupRestartHint;

  /// No description provided for @languageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the language. Try again.'**
  String get languageSaveFailed;

  /// No description provided for @appearanceSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSectionTitle;

  /// A live reading that has stopped updating. Not an error and not a fresh value.
  ///
  /// In en, this message translates to:
  /// **'Data is stale'**
  String get telemetryStatusStale;

  /// Distinct from no answer: the ECU replied, and the reply said unsupported.
  ///
  /// In en, this message translates to:
  /// **'The controller answered that it does not support this'**
  String get telemetryStatusUnsupported;

  /// Silence, not a refusal. Must never read as unsupported.
  ///
  /// In en, this message translates to:
  /// **'No answer — will retry'**
  String get telemetryStatusNoAnswer;

  /// No description provided for @telemetryStatusFormulaError.
  ///
  /// In en, this message translates to:
  /// **'Formula error'**
  String get telemetryStatusFormulaError;

  /// No description provided for @telemetryStatusBusError.
  ///
  /// In en, this message translates to:
  /// **'Bus error'**
  String get telemetryStatusBusError;

  /// No description provided for @telemetryStatusHeaderMismatch.
  ///
  /// In en, this message translates to:
  /// **'Header does not match this bus'**
  String get telemetryStatusHeaderMismatch;

  /// The app refused to transmit. Says what did NOT happen.
  ///
  /// In en, this message translates to:
  /// **'Not a read-only query — nothing was sent'**
  String get telemetryStatusUnsafeServiceRefusal;

  /// No description provided for @telemetryEndedByUser.
  ///
  /// In en, this message translates to:
  /// **'Stopped by you'**
  String get telemetryEndedByUser;

  /// No description provided for @telemetryEndedByDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Stopped when the connection dropped'**
  String get telemetryEndedByDisconnect;

  /// No description provided for @telemetryEndedBySessionReplacement.
  ///
  /// In en, this message translates to:
  /// **'The connection session was replaced'**
  String get telemetryEndedBySessionReplacement;

  /// No description provided for @telemetryEndedByBackground.
  ///
  /// In en, this message translates to:
  /// **'Stopped when Telltale went to the background'**
  String get telemetryEndedByBackground;

  /// {minutes} comes from telemetryRecorderDurationLimit; never spell the number in the copy.
  ///
  /// In en, this message translates to:
  /// **'Reached the {minutes}-minute limit'**
  String telemetryEndedByDurationLimit(int minutes);

  /// No description provided for @telemetryEndedBySessionSizeLimit.
  ///
  /// In en, this message translates to:
  /// **'This recording reached its size limit'**
  String get telemetryEndedBySessionSizeLimit;

  /// No description provided for @telemetryEndedByLibrarySizeLimit.
  ///
  /// In en, this message translates to:
  /// **'Local recording storage is full'**
  String get telemetryEndedByLibrarySizeLimit;

  /// No description provided for @telemetryEndedByStorageBackpressure.
  ///
  /// In en, this message translates to:
  /// **'Storage could not keep up'**
  String get telemetryEndedByStorageBackpressure;

  /// No description provided for @telemetryEndedByConfigurationChanged.
  ///
  /// In en, this message translates to:
  /// **'The PID selection changed'**
  String get telemetryEndedByConfigurationChanged;

  /// No description provided for @telemetryEndedByStorageFailure.
  ///
  /// In en, this message translates to:
  /// **'Saving failed'**
  String get telemetryEndedByStorageFailure;

  /// No description provided for @telemetryEndedByRecoveredAfterInterruption.
  ///
  /// In en, this message translates to:
  /// **'Recovered after the last interruption'**
  String get telemetryEndedByRecoveredAfterInterruption;

  /// No description provided for @telemetryStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording started'**
  String get telemetryStartRecording;

  /// No description provided for @telemetryStartNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Connect before starting a recording'**
  String get telemetryStartNeedsConnection;

  /// No description provided for @telemetryStartNeedsForeground.
  ///
  /// In en, this message translates to:
  /// **'Bring Telltale to the foreground before starting a recording'**
  String get telemetryStartNeedsForeground;

  /// Refuses on unknown speed. Absence of a speed reading is not evidence of a parked car.
  ///
  /// In en, this message translates to:
  /// **'Cannot confirm the vehicle is stopped — disconnect first'**
  String get telemetryStartSpeedUnknown;

  /// No description provided for @telemetryStartMoving.
  ///
  /// In en, this message translates to:
  /// **'Park the vehicle first'**
  String get telemetryStartMoving;

  /// No description provided for @telemetryStartInvalidatedBackground.
  ///
  /// In en, this message translates to:
  /// **'Telltale went to the background — no recording started'**
  String get telemetryStartInvalidatedBackground;

  /// No description provided for @telemetryStartInvalidatedDisconnect.
  ///
  /// In en, this message translates to:
  /// **'The connection dropped — no recording started'**
  String get telemetryStartInvalidatedDisconnect;

  /// No description provided for @telemetryStartInvalidatedSessionReplacement.
  ///
  /// In en, this message translates to:
  /// **'The connection session was replaced — no recording started'**
  String get telemetryStartInvalidatedSessionReplacement;

  /// {limit} comes from TelemetryQuota.groupLimit.
  ///
  /// In en, this message translates to:
  /// **'Local recordings reached the limit of {limit} — export or delete some first'**
  String telemetryStartLibraryGroupLimit(int limit);

  /// No description provided for @telemetryStartLibraryByteLimit.
  ///
  /// In en, this message translates to:
  /// **'Not enough local storage for a recording — export or delete some first'**
  String get telemetryStartLibraryByteLimit;

  /// No description provided for @telemetryStartInvalidConfiguration.
  ///
  /// In en, this message translates to:
  /// **'This PID selection cannot be recorded safely — check the definitions'**
  String get telemetryStartInvalidConfiguration;

  /// No description provided for @telemetryStartCannotCreateFile.
  ///
  /// In en, this message translates to:
  /// **'Could not create the recording file'**
  String get telemetryStartCannotCreateFile;

  /// No description provided for @telemetryStartBusy.
  ///
  /// In en, this message translates to:
  /// **'Another recording or file operation has not finished'**
  String get telemetryStartBusy;

  /// Also the startOutcome for restartRequired; one sentence, one key.
  ///
  /// In en, this message translates to:
  /// **'Startup cleanup did not finish — restart Telltale to repair the recordings'**
  String get telemetryRestartToRepairStartup;

  /// No description provided for @telemetryRestartToRepairSave.
  ///
  /// In en, this message translates to:
  /// **'Saving did not finish — restart Telltale to repair the recordings'**
  String get telemetryRestartToRepairSave;

  /// No description provided for @telemetryPendingOwnerRecovery.
  ///
  /// In en, this message translates to:
  /// **'This process still holds the operation. If it stays here, quit Telltale completely and reopen it'**
  String get telemetryPendingOwnerRecovery;

  /// No description provided for @telemetryStartNeedsActivePid.
  ///
  /// In en, this message translates to:
  /// **'Enable at least one PID first'**
  String get telemetryStartNeedsActivePid;

  /// Refers to DerivedEstimates.maxLiveSignals. 'estimated' must never read as 'measured'.
  ///
  /// In en, this message translates to:
  /// **'Recording keeps the estimated-power and estimated-fuel columns — turn some PIDs off first'**
  String get telemetryStartTooManyPids;

  /// No description provided for @telemetryBlockedByRecorder.
  ///
  /// In en, this message translates to:
  /// **'Stop and save the recording first'**
  String get telemetryBlockedByRecorder;

  /// No description provided for @telemetryDeleteNeedsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirm this delete first'**
  String get telemetryDeleteNeedsConfirmation;

  /// No description provided for @telemetryArtifactRestartRequired.
  ///
  /// In en, this message translates to:
  /// **'The state of local file work cannot be confirmed. Quit Telltale completely and reopen it before continuing'**
  String get telemetryArtifactRestartRequired;

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'The dashboard is empty'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pick the signals you want to watch on the PID page and they will appear here.'**
  String get dashboardEmptyBody;

  /// No description provided for @dashboardChoosePids.
  ///
  /// In en, this message translates to:
  /// **'Choose PIDs'**
  String get dashboardChoosePids;

  /// No description provided for @dashboardWorkspaceGauges.
  ///
  /// In en, this message translates to:
  /// **'Gauges'**
  String get dashboardWorkspaceGauges;

  /// No description provided for @dashboardWorkspaceTrends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get dashboardWorkspaceTrends;

  /// No description provided for @dashboardLocalRecordings.
  ///
  /// In en, this message translates to:
  /// **'Local recordings'**
  String get dashboardLocalRecordings;

  /// Stands in for an adapter name before anything is connected. A real device name is passed through untranslated.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get dashboardNotConnected;

  /// No description provided for @dashboardGenericObd.
  ///
  /// In en, this message translates to:
  /// **'Generic OBD'**
  String get dashboardGenericObd;

  /// No description provided for @dashboardVinRead.
  ///
  /// In en, this message translates to:
  /// **'VIN read'**
  String get dashboardVinRead;

  /// The other side of this pill reads the literal 'fastMode', an adapter behaviour name that stays untranslated.
  ///
  /// In en, this message translates to:
  /// **'Single request mode'**
  String get dashboardSingleRequestMode;

  /// PidFault.unsupported only: the controller answered, and the answer said unsupported. Never use it for silence - that is telemetryStatusNoAnswer. It names the vehicle on purpose: the app's own refusal to transmit reads completely differently (telemetryStatusUnsafeServiceRefusal), and this tile must not be read as Telltale declining. It shares a square tile about 122dp wide with the availability badge, so anything longer needs re-measuring against test/l10n/dashboard_l10n_test.dart.
  ///
  /// In en, this message translates to:
  /// **'Not supported by this vehicle'**
  String get gaugeUnsupportedByVehicle;

  /// Heading of the derived panel. These figures are computed from a vehicle profile, never read off the bus, and 'estimated' is the whole reason the panel is separate.
  ///
  /// In en, this message translates to:
  /// **'Estimated values'**
  String get derivedEstimatesTitle;

  /// No description provided for @derivedEstimatesDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimate formulas and assumptions'**
  String get derivedEstimatesDetailsTitle;

  /// No description provided for @derivedAirflow.
  ///
  /// In en, this message translates to:
  /// **'Airflow'**
  String get derivedAirflow;

  /// Neutral cell label: the same cell renders an ECU-reported rate and an estimated one, so it must not itself claim either.
  ///
  /// In en, this message translates to:
  /// **'Fuel use'**
  String get derivedFuelUse;

  /// Engine (crank) power, not wheel power - PhysicsEngine reports both and this cell shows engineHorsepower. Kept short so the cell does not ellipsise at large text scales.
  ///
  /// In en, this message translates to:
  /// **'Engine power'**
  String get derivedEngineHorsepower;

  /// No description provided for @derivedTorque.
  ///
  /// In en, this message translates to:
  /// **'Torque'**
  String get derivedTorque;

  /// Used when no ECU fuel rate was reported and the figure came from the vehicle profile. Must never read as measured.
  ///
  /// In en, this message translates to:
  /// **'Estimated fuel use'**
  String get derivedEstimatedFuelTitle;

  /// Used when the vehicle reported its own fuel rate. Must never read as estimated.
  ///
  /// In en, this message translates to:
  /// **'ECU fuel data'**
  String get derivedEcuFuelTitle;

  /// No description provided for @derivedEcuReported.
  ///
  /// In en, this message translates to:
  /// **'ECU reported'**
  String get derivedEcuReported;

  /// A distinct state, not a row of zeroes: 'we cannot work this out yet' and 'your engine is producing no power' must not look alike.
  ///
  /// In en, this message translates to:
  /// **'Horsepower can only be estimated once vehicle speed and acceleration data arrive'**
  String get derivedUnavailableMessage;

  /// No description provided for @telemetryRecorderPhasePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing to record'**
  String get telemetryRecorderPhasePreparing;

  /// No description provided for @telemetryRecorderPhaseRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get telemetryRecorderPhaseRecording;

  /// No description provided for @telemetryRecorderPhaseFinalizing.
  ///
  /// In en, this message translates to:
  /// **'Saving the recording'**
  String get telemetryRecorderPhaseFinalizing;

  /// Answers 'is a recording running', so it also covers completed and failed. Why a recording failed is the recorder panel's job to say, not this label's.
  ///
  /// In en, this message translates to:
  /// **'Not recording'**
  String get telemetryRecorderPhaseIdle;

  /// No live link right now. Distinct from a controller refusing a PID and from silence on the bus.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get telemetryNotConnected;

  /// The figures came from Telltale's own simulator, not from a vehicle. Must stay unmistakable.
  ///
  /// In en, this message translates to:
  /// **'Built-in simulator data'**
  String get telemetryDemoData;

  /// The figures came from a verification rig, not from a vehicle.
  ///
  /// In en, this message translates to:
  /// **'Test rig data'**
  String get telemetryRigData;

  /// No description provided for @trendSignalsHeading.
  ///
  /// In en, this message translates to:
  /// **'Trend signals'**
  String get trendSignalsHeading;

  /// No description provided for @trendNoSignalsTitle.
  ///
  /// In en, this message translates to:
  /// **'No trend signals available'**
  String get trendNoSignalsTitle;

  /// No description provided for @trendNoSignalsBody.
  ///
  /// In en, this message translates to:
  /// **'Enable the signals you want to watch on the PID page first.'**
  String get trendNoSignalsBody;

  /// No description provided for @trendPickSignalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose trend signals'**
  String get trendPickSignalsTitle;

  /// {limit} comes from maximumTelemetryTrendLanes; never spell the number in the copy.
  ///
  /// In en, this message translates to:
  /// **'Compare up to {limit} signals. This does not change which PIDs are polled.'**
  String trendPickSignalsBody(int limit);

  /// The lane is connected and no status is outstanding. Never shown for a stale or unanswered reading.
  ///
  /// In en, this message translates to:
  /// **'Live data'**
  String get trendLiveData;

  /// No description provided for @trendNoUnits.
  ///
  /// In en, this message translates to:
  /// **'No units'**
  String get trendNoUnits;

  /// Screen-reader only. {seconds} comes from telemetryTrendWindow.
  ///
  /// In en, this message translates to:
  /// **'Showing the last {seconds} seconds'**
  String trendWindowSemantics(int seconds);

  /// No description provided for @trendAxisNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get trendAxisNow;

  /// Joins the fields of a composed semantics label. Chinese uses the fullwidth comma; English must not, or a screen reader announces a fullwidth character.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get semanticsFieldSeparator;

  /// Delete-button tooltip on a signal chip. {name} is a PID name and is not translated here.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String trendRemoveSignal(String name);

  /// No description provided for @trendChooseSignals.
  ///
  /// In en, this message translates to:
  /// **'Choose signals'**
  String get trendChooseSignals;

  /// {limit} comes from maximumTelemetryTrendLanes.
  ///
  /// In en, this message translates to:
  /// **'Choose at most {limit}'**
  String trendTooManySelected(int limit);

  /// No description provided for @trendSignalNoLongerActive.
  ///
  /// In en, this message translates to:
  /// **'One of those signals is no longer in the PID watch list'**
  String get trendSignalNoLongerActive;

  /// Says what did not happen. The chart still shows the selection for this session.
  ///
  /// In en, this message translates to:
  /// **'Could not save the trend display selection'**
  String get trendSelectionSaveFailed;

  /// {limit} comes from maximumTelemetryTrendLanes.
  ///
  /// In en, this message translates to:
  /// **'Choose at most {limit}. This only changes the chart, not PID polling or a recording in progress.'**
  String trendSheetBody(int limit);

  /// Confirm button. Both numbers come from the code: the current selection and maximumTelemetryTrendLanes.
  ///
  /// In en, this message translates to:
  /// **'Done · {selected}/{limit}'**
  String trendSheetDone(int selected, int limit);
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
