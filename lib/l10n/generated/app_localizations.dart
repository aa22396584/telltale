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

  /// Number of recorded signals in one session.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 signal} other{{count} signals}}'**
  String telemetrySignalCount(int count);

  /// Values the recorder actually wrote. Not the number of samples attempted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 valid value} other{{count} valid values}}'**
  String telemetryValueCount(int count);

  /// Status events (no answer, unsupported, bus error) stored beside the values.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 status} other{{count} statuses}}'**
  String telemetryStatusCount(int count);

  /// Breaks in the recorded stream. A gap is missing data, never a zero reading.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 gap} other{{count} gaps}}'**
  String telemetryGapCount(int count);

  /// Joins two phrases inside one screen-reader label. The separator is punctuation and differs by language; folding the list through this keeps it out of the Dart.
  ///
  /// In en, this message translates to:
  /// **'{first}. {second}'**
  String telemetryPhraseJoin(String first, String second);

  /// Joins two complete sentences. Chinese uses the ideographic full stop, so the separator cannot be hard-coded.
  ///
  /// In en, this message translates to:
  /// **'{first}. {second}'**
  String telemetrySentenceJoin(String first, String second);

  /// Title of the saved-recordings screen and of the entry that opens it.
  ///
  /// In en, this message translates to:
  /// **'Local recordings'**
  String get telemetrySessionsTitle;

  /// No description provided for @telemetryReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get telemetryReload;

  /// No description provided for @telemetrySessionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load — retry'**
  String get telemetrySessionsLoadFailed;

  /// No description provided for @telemetrySessionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No local recordings yet\nConnect, then start recording'**
  String get telemetrySessionsEmpty;

  /// Screen-reader form of the two quota chips. Both limits come from TelemetryQuota, never from the prose.
  ///
  /// In en, this message translates to:
  /// **'Local storage: {groups} of {groupLimit} groups, {used} of {byteLimit} MiB'**
  String telemetryLibraryQuotaSemantics(
    int groups,
    int groupLimit,
    String used,
    int byteLimit,
  );

  /// {limit} is TelemetryQuota.groupLimit.
  ///
  /// In en, this message translates to:
  /// **'{groups}/{limit} groups'**
  String telemetryLibraryGroupCount(int groups, int limit);

  /// {limit} is TelemetryQuota.libraryByteLimit in MiB. MiB is a unit and is not translated.
  ///
  /// In en, this message translates to:
  /// **'{used}/{limit} MiB'**
  String telemetryLibraryBytes(String used, int limit);

  /// Groups the index found but did not list. Not a claim that they are unreadable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more group not shown} other{{count} more groups not shown}}'**
  String telemetryLibraryOmitted(int count);

  /// No description provided for @telemetrySessionsReplayable.
  ///
  /// In en, this message translates to:
  /// **'Recordings you can replay'**
  String get telemetrySessionsReplayable;

  /// No description provided for @telemetrySessionsDamaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged recording files'**
  String get telemetrySessionsDamaged;

  /// No description provided for @telemetryDeleteDamagedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete damaged recording'**
  String get telemetryDeleteDamagedTooltip;

  /// No description provided for @telemetryDeleteDamagedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this damaged recording?'**
  String get telemetryDeleteDamagedTitle;

  /// No description provided for @telemetryDeleteDamagedBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes {id} (file time {time}). It cannot be undone.'**
  String telemetryDeleteDamagedBody(String id, String time);

  /// The app refuses to guess which file is the real one. 'neither was chosen' must survive translation: picking one silently is the failure this reports.
  ///
  /// In en, this message translates to:
  /// **'A finished and an unfinished file share this id — neither was chosen'**
  String get telemetryDamagedCollision;

  /// Damaged, not empty. It is never replayed or exported.
  ///
  /// In en, this message translates to:
  /// **'The recording is damaged and cannot be read safely'**
  String get telemetryDamagedCorrupt;

  /// Filesystem modification time, not a recording timestamp — the file is unreadable, so it has none.
  ///
  /// In en, this message translates to:
  /// **'File time {time}'**
  String telemetryDamagedFileTime(String time);

  /// No description provided for @telemetryCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get telemetryCancel;

  /// No description provided for @telemetryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get telemetryDelete;

  /// Says the delete did not complete, never that it failed harmlessly.
  ///
  /// In en, this message translates to:
  /// **'Delete did not finish: {reason}'**
  String telemetryDeleteFailed(String reason);

  /// No description provided for @telemetryReplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Recording replay'**
  String get telemetryReplayTitle;

  /// No description provided for @telemetryReplayLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the recording'**
  String get telemetryReplayLoadFailed;

  /// Two possibilities, both stated. Not 'empty'.
  ///
  /// In en, this message translates to:
  /// **'The recording is damaged or cannot be read'**
  String get telemetryReplayUnreadable;

  /// No description provided for @telemetryDeleteSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this local recording?'**
  String get telemetryDeleteSessionTitle;

  /// No description provided for @telemetryDeleteSessionBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes the recording from {time}. It cannot be undone.'**
  String telemetryDeleteSessionBody(String time);

  /// No description provided for @telemetryExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export did not finish: {reason}'**
  String telemetryExportFailed(String reason);

  /// Sampled, not the full recording. The exported file keeps every event; this preview does not.
  ///
  /// In en, this message translates to:
  /// **'Offline sampled replay'**
  String get telemetryOfflineSampledReplay;

  /// No description provided for @telemetryPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get telemetryPlay;

  /// No description provided for @telemetryPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get telemetryPause;

  /// No description provided for @telemetryReplayPositionSemantics.
  ///
  /// In en, this message translates to:
  /// **'Replay position {percent}%'**
  String telemetryReplayPositionSemantics(int percent);

  /// No description provided for @telemetryExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get telemetryExport;

  /// Points kept by the downsampler for this lane's preview, not values recorded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sampled point} other{{count} sampled points}}'**
  String telemetryReplaySampleCount(int count);

  /// Discontinuities in this lane. The line is not drawn across them.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 break} other{{count} breaks}}'**
  String telemetryReplayBreakCount(int count);

  /// No description provided for @telemetryExportSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Export a local recording'**
  String get telemetryExportSheetTitle;

  /// No description provided for @telemetryExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get telemetryExportCsv;

  /// No description provided for @telemetryExportJson.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get telemetryExportJson;

  /// Idle title. Foreground-only is a property of the recorder, not a suggestion.
  ///
  /// In en, this message translates to:
  /// **'Foreground local recording'**
  String get telemetryRecorderPhaseIdle;

  /// Shared by the recorder panel and the shell strip — one key, so the two surfaces cannot disagree about the phase.
  ///
  /// In en, this message translates to:
  /// **'Preparing to record'**
  String get telemetryRecorderPhasePreparing;

  /// The recorder is running and nothing has arrived. Distinct from preparing (not started) and from recording (values are landing).
  ///
  /// In en, this message translates to:
  /// **'Recording — no values yet'**
  String get telemetryRecorderPhaseAwaitingValues;

  /// No description provided for @telemetryRecorderPhaseRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get telemetryRecorderPhaseRecording;

  /// Shared by the recorder panel and the shell strip.
  ///
  /// In en, this message translates to:
  /// **'Saving the recording'**
  String get telemetryRecorderPhaseFinalizing;

  /// No description provided for @telemetryRecorderPhaseCompleted.
  ///
  /// In en, this message translates to:
  /// **'Recording saved'**
  String get telemetryRecorderPhaseCompleted;

  /// No description provided for @telemetryRecorderPhaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Saving the recording failed'**
  String get telemetryRecorderPhaseFailed;

  /// {duration} is the elapsed clock, already formatted.
  ///
  /// In en, this message translates to:
  /// **'Recording {duration}'**
  String telemetryRecorderStripRecording(String duration);

  /// No description provided for @telemetryOpenHistory.
  ///
  /// In en, this message translates to:
  /// **'Open local recordings'**
  String get telemetryOpenHistory;

  /// No description provided for @telemetryDismissNotice.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get telemetryDismissNotice;

  /// {laneLimit} is maximumTelemetryTrendLanes, {activeCount} the enabled PID count. 'estimated' must never read as 'measured': these two columns are computed from vehicle assumptions the app cannot verify.
  ///
  /// In en, this message translates to:
  /// **'Records only the OBD signals you have enabled — no location, VIN, or account data. Trends show at most {laneLimit} signals; a recording keeps all {activeCount} enabled signals and adds estimated horsepower and estimated fuel rate, which rest on the vehicle assumptions.'**
  String telemetryRecorderDisclosure(int laneLimit, int activeCount);

  /// No description provided for @telemetryStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get telemetryStarting;

  /// No description provided for @telemetryStartRecordingButton.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get telemetryStartRecordingButton;

  /// The button. Distinct from telemetryBlockedByRecorder, which is the refusal that names this action.
  ///
  /// In en, this message translates to:
  /// **'Stop and save'**
  String get telemetryStopAndSave;

  /// No description provided for @telemetryReturnToTrends.
  ///
  /// In en, this message translates to:
  /// **'Back to trends'**
  String get telemetryReturnToTrends;

  /// The check finished. It does not claim damaged data was repaired.
  ///
  /// In en, this message translates to:
  /// **'Startup check of the recordings finished'**
  String get telemetryRecoveryTitle;

  /// Sealed as they were found. Nothing was reconstructed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 interrupted recording was safely sealed} other{{count} interrupted recordings were safely sealed}}'**
  String telemetryRecoveryInstalled(int count);

  /// Only files that held no valid value were removed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unfinished file with no valid values was cleaned up} other{{count} unfinished files with no valid values were cleaned up}}'**
  String telemetryRecoveryCleaned(int count);

  /// Left unchanged, not repaired and not deleted. The app never edits a file it cannot read.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 damaged or conflicting file was left unchanged} other{{count} damaged or conflicting files were left unchanged}}'**
  String telemetryRecoveryDamaged(int count);

  /// Both halves are load-bearing: never used, and deletable only under the safety gate.
  ///
  /// In en, this message translates to:
  /// **'Damaged content is never used for replay or export, and can only be deleted by hand while it is safe to do so.'**
  String get telemetryRecoveryDamagedNote;

  /// No description provided for @telemetryHistoryEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 saved group — replay and export offline} other{{count} saved groups — replay and export offline}}'**
  String telemetryHistoryEntrySubtitle(int count);

  /// Below a kilobyte the exact byte count is shown, because a failed handshake is a few hundred bytes and '0 KB' reads as empty.
  ///
  /// In en, this message translates to:
  /// **'{bytes, plural, =1{1 byte} other{{bytes} bytes}}'**
  String transcriptSizeBytes(int bytes);

  /// No description provided for @transcriptNothingToExport.
  ///
  /// In en, this message translates to:
  /// **'There is no transcript to export.'**
  String get transcriptNothingToExport;

  /// No description provided for @transcriptExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String transcriptExportFailed(String error);

  /// The middle-omitted disclosure is load-bearing: a truncated transcript must announce its truncation.
  ///
  /// In en, this message translates to:
  /// **'This connection keeps the opening handshake and the most recent raw traffic; if a long connection drops the middle, the file says so. When something will not read on the car, exporting the transcript and bringing it back is worth far more than one message on screen.'**
  String get transcriptExportExplanation;

  /// No description provided for @transcriptExportButton.
  ///
  /// In en, this message translates to:
  /// **'Export transcript'**
  String get transcriptExportButton;

  /// No description provided for @transcriptExportWithHex.
  ///
  /// In en, this message translates to:
  /// **'With hex'**
  String get transcriptExportWithHex;

  /// No description provided for @transcriptExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get transcriptExport;

  /// No description provided for @transcriptDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get transcriptDelete;

  /// Previous connection, not this one. Somebody looking at a working car must not mistake it for the log they are about to make.
  ///
  /// In en, this message translates to:
  /// **'Transcript from the previous connection'**
  String get transcriptRecoveredTitle;

  /// No description provided for @transcriptRecoveredBody.
  ///
  /// In en, this message translates to:
  /// **'Left at {timestamp}, {size}. It survived the system killing Telltale or the phone losing power.'**
  String transcriptRecoveredBody(String timestamp, String size);

  /// Refuses to export or delete bytes that are no longer the ones on screen.
  ///
  /// In en, this message translates to:
  /// **'The previous connection\'s transcript has changed — check it again.'**
  String get transcriptRecoveredChanged;

  /// No description provided for @transcriptDeleteBusy.
  ///
  /// In en, this message translates to:
  /// **'Another file operation has not finished.'**
  String get transcriptDeleteBusy;

  /// A refusal, not advice.
  ///
  /// In en, this message translates to:
  /// **'The current speed or connection state does not allow deleting the transcript.'**
  String get transcriptDeleteRefusedBySafety;

  /// No description provided for @transcriptDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the previous connection\'s transcript.'**
  String get transcriptDeleteFailed;

  /// No description provided for @powertrainConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle battery signals await confirmation'**
  String get powertrainConfirmTitle;

  /// Installing makes definitions available; it does not say the car on the wire is that vehicle. The per-connection scope is the point — plugging into a different car must never inherit the grant.
  ///
  /// In en, this message translates to:
  /// **'Installed profile signals are read only after you confirm this car is that model, and the confirmation lasts for this connection alone.'**
  String get powertrainConfirmBody;

  /// No description provided for @powertrainConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm vehicle'**
  String get powertrainConfirmButton;

  /// No description provided for @powertrainConfirmDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm the connected vehicle'**
  String get powertrainConfirmDialogTitle;

  /// Carries this project's organising principle into product copy: a plausible wrong number is worse than no number. Never soften 'look plausible and are wrong'.
  ///
  /// In en, this message translates to:
  /// **'Once confirmed, this profile\'s read-only battery queries are polled for the rest of this connection. The wrong profile can produce numbers that look plausible and are wrong — cancel if you are not sure.'**
  String get powertrainConfirmDialogBody;

  /// No description provided for @powertrainCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get powertrainCancel;

  /// No description provided for @powertrainConfirmAccept.
  ///
  /// In en, this message translates to:
  /// **'This is the car'**
  String get powertrainConfirmAccept;

  /// The acceptance was a statement about the vehicle on the wire at prompt time; it cannot carry over.
  ///
  /// In en, this message translates to:
  /// **'The connection changed — confirm the vehicle again for the new connection.'**
  String get powertrainConnectionChanged;

  /// The per-connection scope is part of the sentence, not a footnote.
  ///
  /// In en, this message translates to:
  /// **'Battery signals for {profile} are on for this connection'**
  String powertrainAuthorizationGranted(String profile);

  /// No description provided for @powertrainAuthorizationRefused.
  ///
  /// In en, this message translates to:
  /// **'Could not enable: {reason}'**
  String powertrainAuthorizationRefused(String reason);

  /// No description provided for @powertrainProfileNotVerified.
  ///
  /// In en, this message translates to:
  /// **'The profile is not in the verified catalog'**
  String get powertrainProfileNotVerified;
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
