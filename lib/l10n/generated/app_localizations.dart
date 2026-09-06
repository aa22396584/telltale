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

  /// Fault-code screen title.
  ///
  /// In en, this message translates to:
  /// **'Fault codes'**
  String get dtcHeadline;

  /// No description provided for @dtcNotScanned.
  ///
  /// In en, this message translates to:
  /// **'Not scanned yet'**
  String get dtcNotScanned;

  /// Count of observed codes, including partial reads.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 code} other{{count} codes}}'**
  String dtcTotalCodes(int count);

  /// Header subtitle for ScanVerdict.completeClean. The qualifier 'that answered' is the whole hedge: this is the line a glance lands on, and it must never read as 'this vehicle has no faults'.
  ///
  /// In en, this message translates to:
  /// **'No fault codes from the controllers that answered'**
  String get dtcVerdictCompleteClean;

  /// ScanVerdict.partialClean. Some categories could not be read, so the verdict is incomplete. Keep it short and distinct from dtcUnconfirmed; never merge the two into one 'unknown'.
  ///
  /// In en, this message translates to:
  /// **'Partially unconfirmed'**
  String get dtcVerdictPartialClean;

  /// Two call sites, one sentence: the header subtitle for any other verdict, and the headline of a category that failed to answer. Must never be read as 'no problem'.
  ///
  /// In en, this message translates to:
  /// **'Cannot confirm'**
  String get dtcUnconfirmed;

  /// No description provided for @dtcClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get dtcClear;

  /// No description provided for @dtcClearing.
  ///
  /// In en, this message translates to:
  /// **'Clearing…'**
  String get dtcClearing;

  /// Label of the disabled clear button. The button IS the verdict of the last clear: something may already have been erased, so a second global Mode 04 would reset a completed controller's readiness. Keep it an imperative.
  ///
  /// In en, this message translates to:
  /// **'Rescan first'**
  String get dtcRescanFirst;

  /// Tooltip that closes the clear-outcome panel. Closing a message is not learning what happened; only a rescan is.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dtcDismiss;

  /// No description provided for @dtcClearDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear fault codes?'**
  String get dtcClearDialogTitle;

  /// The point of no return. Mode 0A permanent codes must never read as something this clear can remove.
  ///
  /// In en, this message translates to:
  /// **'This erases stored and pending fault codes and turns the fault lamp off, and it also resets emissions readiness — the vehicle has to complete a full round of self-diagnosis again before it can pass an inspection. Permanent fault codes (Mode 0A) cannot be cleared.'**
  String get dtcClearDialogBody;

  /// Fault codes come back if the fault recurs; the snapshot of the moment it first happened does not.
  ///
  /// In en, this message translates to:
  /// **'The freeze frame for {codes} goes with it — the whole record of engine speed, coolant temperature and load at the moment the fault happened — and it cannot be read back until the fault happens again.'**
  String dtcClearDialogFrames(Object codes);

  /// A read failure, not an absent frame. Collapsing the two causes irreversible evidence loss.
  ///
  /// In en, this message translates to:
  /// **'This scan did not read a freeze frame — that does not mean the vehicle has none. Rescan first, then decide whether to clear.'**
  String get dtcClearDialogFrameUnread;

  /// What the scan could not establish, said at the point of no return.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One category in this scan did not answer completely} other{{count} categories in this scan did not answer completely}} ({categories}), so there may be fault codes you have not seen. After a clear they can never be read again.'**
  String dtcClearDialogUnanswered(int count, Object categories);

  /// No description provided for @dtcClearCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dtcClearCancel;

  /// No description provided for @dtcClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear them'**
  String get dtcClearConfirm;

  /// No description provided for @dtcNotConnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get dtcNotConnectedTitle;

  /// No description provided for @dtcNotConnectedBody.
  ///
  /// In en, this message translates to:
  /// **'Reading fault codes needs a connected ELM327 adapter, or the simulator running.'**
  String get dtcNotConnectedBody;

  /// No description provided for @dtcScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan the vehicle for fault codes'**
  String get dtcScanTitle;

  /// The three classes are three different things and must stay distinguishable.
  ///
  /// In en, this message translates to:
  /// **'Reads Mode 03 stored, Mode 07 pending and Mode 0A permanent fault codes.'**
  String get dtcScanBody;

  /// Two call sites, one sentence: the empty-state title after a failed scan, and the headline of a category whose read errored rather than went silent.
  ///
  /// In en, this message translates to:
  /// **'Read failed'**
  String get dtcReadFailed;

  /// No description provided for @dtcScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get dtcScanning;

  /// No description provided for @dtcStartScan.
  ///
  /// In en, this message translates to:
  /// **'Start scan'**
  String get dtcStartScan;

  /// Retries the fault-code scan. Deliberately not shared with startupRetry: the two screens are free to reword independently.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get dtcRetry;

  /// A controller with no stored frame shows nothing, which is exactly what a failed read shows. Saying so is the only thing standing between a Mode 02 timeout and a clear.
  ///
  /// In en, this message translates to:
  /// **'This scan did not read a freeze frame — that does not mean the vehicle has none. Rescan first, then decide whether to clear the fault codes, because clearing destroys the record of the moment of the fault permanently. If every scan looks the same, this vehicle may not provide one.'**
  String get dtcFreezeFrameUnreadPanel;

  /// 'that answered' is the whole hedge. Never render this as 'no fault codes' or 'your car is fine'.
  ///
  /// In en, this message translates to:
  /// **'None of the controllers that answered reported a fault code.'**
  String get dtcCompleteCleanTitle;

  /// A controller whose reply is lost outright leaves nothing to count as missing, and the app has no inventory of who should have answered.
  ///
  /// In en, this message translates to:
  /// **'That means every controller that replied reported no fault code. It does not mean every module on the vehicle was asked.'**
  String get dtcCompleteCleanBody;

  /// No description provided for @dtcPartialCleanTitle.
  ///
  /// In en, this message translates to:
  /// **'The categories that answered reported no fault codes.'**
  String get dtcPartialCleanTitle;

  /// Modes 07 and 0A are optional in SAE J1979. A vehicle that implements neither is compliant and fine; that is a different situation from a class nobody answered.
  ///
  /// In en, this message translates to:
  /// **'All three categories were queried to completion. {count, plural, =1{One controller} other{{count} controllers}} ({controllers}) implement neither pending nor permanent fault codes — normal on many vehicles, and also why this cannot be declared a fault-free vehicle.'**
  String dtcPartialCleanOptionalGaps(int count, Object controllers);

  /// No description provided for @dtcPartialCleanUnanswered.
  ///
  /// In en, this message translates to:
  /// **'{categories} did not answer, so their state cannot be confirmed — that is not the same as the vehicle having no problem.'**
  String dtcPartialCleanUnanswered(Object categories);

  /// Heading for one class of codes. {label} still comes from lib/obd/dtc/dtc.dart and is Chinese in both locales until the engine wave lands.
  ///
  /// In en, this message translates to:
  /// **'{label} (Mode {mode}) · {count}'**
  String dtcGroupHeader(Object label, Object mode, int count);

  /// Shown instead of a description this app does not have. Never invent one.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer-specific code — check the service manual for this vehicle'**
  String get dtcManufacturerSpecific;

  /// The subsystem the code's own third digit names. Says the app is missing the description rather than pretending to one.
  ///
  /// In en, this message translates to:
  /// **'{subsystem} — this app has no detailed description for this code'**
  String dtcNoDescriptionForSubsystem(Object subsystem);

  /// No description provided for @dtcCategoryFault.
  ///
  /// In en, this message translates to:
  /// **'A fault related to {category}'**
  String dtcCategoryFault(Object category);

  /// Attribution for a reply that carried a header. Two modules reporting one code is two of them seeing the fault.
  ///
  /// In en, this message translates to:
  /// **'Controller {controller}'**
  String dtcControllerLabel(Object controller);

  /// Incomplete coverage is a reason to qualify a finding, never to hide it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One fault code was read} other{{count} fault codes were read}} before this category stopped, but the coverage is incomplete:'**
  String dtcPartialCodesRead(int count);

  /// Not 'this vehicle does not provide the category'. NO DATA cannot tell an unimplemented service from a lost, filtered or late reply.
  ///
  /// In en, this message translates to:
  /// **'This category did not answer'**
  String get dtcSilentCategoryHeadline;

  /// Mode 07 and Mode 0A are not the same feature and must not share a sentence: pending codes date from 1996, permanent codes from around 2010.
  ///
  /// In en, this message translates to:
  /// **'Permanent fault codes (Mode 0A) did not answer. This category arrived with the OBD-II generation around 2010, so older vehicles do not always support it — but no answer can equally mean it simply was not read this time, and the two cannot be told apart. The stored fault-code result is unaffected.'**
  String get dtcSilentPermanentDetail;

  /// Distinct from dtcSilentPermanentDetail on purpose. Telling a driver their 2004 car is too old for pending codes is simply wrong.
  ///
  /// In en, this message translates to:
  /// **'Pending fault codes (Mode 07) did not answer. This ECU may not implement the service, or it may simply not have been read this time — no answer cannot tell the two apart, and must not be taken to mean there are no pending faults. The stored fault-code result is unaffected.'**
  String get dtcSilentPendingDetail;

  /// Mode 03 is mandatory, so silence here is never ordinary.
  ///
  /// In en, this message translates to:
  /// **'The vehicle did not answer the Mode {mode} query, so whether it has stored fault codes cannot be confirmed. That is not the same thing as having no fault codes.'**
  String dtcStoredSilentDetail(Object mode);

  /// {message} is the engine's own failure text and is still Chinese in both locales.
  ///
  /// In en, this message translates to:
  /// **'Only some controllers in this category answered and the rest did not reply, so this cannot stand as a result for the whole vehicle. {message}'**
  String dtcPartiallyAnsweredDetail(Object message);

  /// No description provided for @dtcBothSilentDetail.
  ///
  /// In en, this message translates to:
  /// **'The vehicle did not answer the Mode {mode} query, and Mode 03 did not answer either — so there is no telling whether the vehicle lacks support or this connection simply did not read it.'**
  String dtcBothSilentDetail(Object mode);

  /// No description provided for @dtcReadFailureDetail.
  ///
  /// In en, this message translates to:
  /// **'{label} (Mode {mode}): {message}'**
  String dtcReadFailureDetail(Object label, Object mode, Object message);

  /// No description provided for @dtcUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get dtcUnknownError;

  /// The only view of the car while the fault was actually happening, and the one thing a clear destroys for good.
  ///
  /// In en, this message translates to:
  /// **'The vehicle at the moment of the fault'**
  String get dtcFreezeFrameTitle;

  /// Names the code in the card itself: a car with three stored codes has a frame belonging to exactly one of them.
  ///
  /// In en, this message translates to:
  /// **'The values this controller recorded at the instant {code} was confirmed. Clearing fault codes destroys this record with them.'**
  String dtcFreezeFrameBody(Object code);

  /// 'It would not tell us' — worth another scan. Distinct from dtcFreezeFrameNothingDecodable, which is a limit of this app.
  ///
  /// In en, this message translates to:
  /// **'This controller has a freeze frame, but it did not answer the query asking which items are in it, so the contents could not be read. A rescan may work.'**
  String get dtcFreezeFrameContentsUnknown;

  /// No description provided for @dtcFreezeFrameNothingDecodable.
  ///
  /// In en, this message translates to:
  /// **'This controller has a freeze frame, but none of the items in it are ones this app can decode.'**
  String get dtcFreezeFrameNothingDecodable;

  /// An app limitation that rescanning will not change. Must stay distinct from dtcFreezeFrameUnreadItems, which rescanning usually fixes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A further item in this freeze frame has no conversion formula in this app, so it is not listed.} other{{count} further items in this freeze frame have no conversion formula in this app, so they are not listed.}}'**
  String dtcFreezeFrameUndecodable(int count);

  /// A read failure, not an app limitation. Rescanning usually fixes it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One item did not come back this time (there may not have been enough time, or the controller did not answer). A rescan may read it.} other{{count} items did not come back this time (there may not have been enough time, or the controller did not answer). A rescan may read them.}}'**
  String dtcFreezeFrameUnreadItems(int count);

  /// No description provided for @dtcMilOn.
  ///
  /// In en, this message translates to:
  /// **'The fault lamp is lit'**
  String get dtcMilOn;

  /// No description provided for @dtcMilOff.
  ///
  /// In en, this message translates to:
  /// **'The fault lamp is not lit'**
  String get dtcMilOff;

  /// The controller's own claim, which can contradict what Mode 03 returned. Keep it attributed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This controller self-reports 1 confirmed fault code.} other{This controller self-reports {count} confirmed fault codes.}}'**
  String dtcSelfReportedCodes(int count);

  /// No description provided for @dtcSelfReportedNoCodes.
  ///
  /// In en, this message translates to:
  /// **'This controller self-reports no confirmed fault codes.'**
  String get dtcSelfReportedNoCodes;

  /// No description provided for @dtcReadinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Emissions readiness'**
  String get dtcReadinessTitle;

  /// A module outside emissions monitoring answers with all zeroes. Reading that as a clean bill of health turns silence into an answer.
  ///
  /// In en, this message translates to:
  /// **'This controller reported no readiness monitors at all — it may not be responsible for emissions monitoring, and that does not mean it is ready.'**
  String get dtcReadinessSaysNothing;

  /// No description provided for @dtcReadinessAllComplete.
  ///
  /// In en, this message translates to:
  /// **'Every readiness monitor this controller is responsible for is complete.'**
  String get dtcReadinessAllComplete;

  /// Counts monitors this app cannot name as well, so one left unfinished still blocks 'ready'.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 monitor is still unfinished} other{{count} monitors are still unfinished}} — an inspection now may not pass.'**
  String dtcReadinessIncomplete(int count);

  /// A readiness monitor the vehicle reported and this app has no name for. It is still counted as unfinished — not being able to name it is not permission to discount it. Never 'N/A' or 'other'.
  ///
  /// In en, this message translates to:
  /// **'Unknown monitor'**
  String get dtcUnknownMonitor;

  /// Joins fault codes, categories or controller ids in a sentence. Chinese uses the enumeration comma; English uses a comma and a space.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get dtcListSeparator;
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
