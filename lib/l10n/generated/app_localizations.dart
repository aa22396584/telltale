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

  /// Screen title of the PID manager.
  ///
  /// In en, this message translates to:
  /// **'PID manager'**
  String get pidManagerHeadline;

  /// Counts come from the active list and the registry; never spell a number into the sentence.
  ///
  /// In en, this message translates to:
  /// **'{active} enabled · {total} available'**
  String pidManagerCounts(int active, int total);

  /// No description provided for @pidManagerAdd.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get pidManagerAdd;

  /// Tooltip on the overflow menu.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get pidManagerMoreActions;

  /// No description provided for @pidManagerArrangeDashboard.
  ///
  /// In en, this message translates to:
  /// **'Arrange dashboard'**
  String get pidManagerArrangeDashboard;

  /// The CSV column headers themselves are a machine format and are never localized.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get pidManagerImportCsv;

  /// No description provided for @pidManagerExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export custom PIDs'**
  String get pidManagerExportCsv;

  /// No description provided for @pidManagerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or PID code…'**
  String get pidManagerSearchHint;

  /// Filter chip label; must stay short enough for a chip.
  ///
  /// In en, this message translates to:
  /// **'Enabled only'**
  String get pidManagerActiveOnly;

  /// No description provided for @pidManagerPowertrainBatteryCatalog.
  ///
  /// In en, this message translates to:
  /// **'Powertrain-battery catalog'**
  String get pidManagerPowertrainBatteryCatalog;

  /// No description provided for @pidManagerNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching PID'**
  String get pidManagerNoMatchTitle;

  /// No description provided for @pidManagerNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another keyword, or create a custom PID.'**
  String get pidManagerNoMatchMessage;

  /// No description provided for @pidPickCsvDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a PID definition CSV'**
  String get pidPickCsvDialogTitle;

  /// No description provided for @pidImportPickerFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file picker: {error}'**
  String pidImportPickerFailed(String error);

  /// No description provided for @pidImportReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the file: {error}'**
  String pidImportReadFailed(String error);

  /// No description provided for @pidImportNothingToImport.
  ///
  /// In en, this message translates to:
  /// **'No definitions to import.'**
  String get pidImportNothingToImport;

  /// No description provided for @pidExportNoCustomPids.
  ///
  /// In en, this message translates to:
  /// **'There are no custom PIDs to export.'**
  String get pidExportNoCustomPids;

  /// No description provided for @pidExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String pidExportFailed(String error);

  /// No description provided for @pidBulkAddDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {count} confirmed supported PIDs?'**
  String pidBulkAddDialogTitle(int count);

  /// No description provided for @pidBulkAddCount.
  ///
  /// In en, this message translates to:
  /// **'Add {count}'**
  String pidBulkAddCount(int count);

  /// No description provided for @pidBulkAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {count} confirmed supported PIDs.'**
  String pidBulkAdded(int count);

  /// Both halves are load-bearing: still unconfirmed, AND only positively evidenced items are added.
  ///
  /// In en, this message translates to:
  /// **'{count} support blocks are still unconfirmed — this adds only the items with positive evidence.'**
  String pidBulkUnconfirmedBlocks(int count);

  /// 'may refresh less often' is a hedge; the scheduler makes no promise about a rate.
  ///
  /// In en, this message translates to:
  /// **'Will add {count}. The more PIDs are enabled, the less often each one may refresh.'**
  String pidBulkWillAdd(int count);

  /// No description provided for @pidCapabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle-supported PIDs'**
  String get pidCapabilityTitle;

  /// No description provided for @pidCapabilityPhaseNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Scan not started'**
  String get pidCapabilityPhaseNotStarted;

  /// No description provided for @pidCapabilityPhaseRunning.
  ///
  /// In en, this message translates to:
  /// **'Confirming what this vehicle supports'**
  String get pidCapabilityPhaseRunning;

  /// Scoped to this attempt. Never 'scan complete', which would read as full coverage.
  ///
  /// In en, this message translates to:
  /// **'This support scan finished'**
  String get pidCapabilityPhaseAttemptFinished;

  /// No description provided for @pidCapabilityPhaseInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The support scan was interrupted'**
  String get pidCapabilityPhaseInterrupted;

  /// Screen-reader summary of the capability panel. {phase} is one of the pidCapabilityPhase* strings.
  ///
  /// In en, this message translates to:
  /// **'Vehicle-supported PIDs. {phase}. {confirmed} confirmed. {unknown} unknown blocks.'**
  String pidCapabilitySemantics(String phase, int confirmed, int unknown);

  /// No description provided for @pidCapabilityConfirmedCount.
  ///
  /// In en, this message translates to:
  /// **'{confirmed} confirmed'**
  String pidCapabilityConfirmedCount(int confirmed);

  /// Unknown, never unsupported: these blocks were not read at all.
  ///
  /// In en, this message translates to:
  /// **'{unknown} unknown blocks'**
  String pidCapabilityUnknownBlocks(int unknown);

  /// {through} is a hex PID number and is never localized.
  ///
  /// In en, this message translates to:
  /// **'Contiguous coverage 01–{through} (reached the end)'**
  String pidCapabilityCoverageThroughEnd(String through);

  /// Unknown beyond that point, not absent beyond it.
  ///
  /// In en, this message translates to:
  /// **'Contiguous coverage 01–{through} (unknown beyond)'**
  String pidCapabilityCoverageThroughUnknown(String through);

  /// No description provided for @pidCapabilityCoverageNone.
  ///
  /// In en, this message translates to:
  /// **'No contiguous coverage established yet'**
  String get pidCapabilityCoverageNone;

  /// No description provided for @pidBulkActionPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for scan results'**
  String get pidBulkActionPending;

  /// No description provided for @pidBulkActionAddConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Add the {count} confirmed'**
  String pidBulkActionAddConfirmed(int count);

  /// No description provided for @pidBulkActionIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Scan data is incomplete'**
  String get pidBulkActionIncomplete;

  /// Nothing was confirmed. Not a claim that the vehicle supports nothing.
  ///
  /// In en, this message translates to:
  /// **'No confirmed supported PIDs'**
  String get pidBulkActionZero;

  /// No description provided for @pidBulkActionAllActive.
  ///
  /// In en, this message translates to:
  /// **'All already enabled'**
  String get pidBulkActionAllActive;

  /// No description provided for @pidBulkActionLocked.
  ///
  /// In en, this message translates to:
  /// **'Cannot change while recording'**
  String get pidBulkActionLocked;

  /// No description provided for @pidPillCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get pidPillCustom;

  /// Only for a PID the vehicle positively disclaimed. Silence is never this.
  ///
  /// In en, this message translates to:
  /// **'Unsupported'**
  String get pidPillUnsupported;

  /// Stale, not live. {units} is the definition's own unit text and is never translated.
  ///
  /// In en, this message translates to:
  /// **'{units} · stale'**
  String pidRowStaleUnits(String units);

  /// No description provided for @pidRowEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get pidRowEdit;

  /// Semantics label for the row switch. {name} is user-authored data and passes through untouched.
  ///
  /// In en, this message translates to:
  /// **'Show {name} on the dashboard'**
  String pidRowShowOnDashboard(String name);

  /// No description provided for @pidArrangeBody.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder. The dashboard fills left to right and top to bottom, so whatever is first is seen first.'**
  String get pidArrangeBody;

  /// No description provided for @pidArrangeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No PID is enabled yet'**
  String get pidArrangeEmptyTitle;

  /// No description provided for @pidArrangeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Enable a few in the list first, then come back to order them.'**
  String get pidArrangeEmptyMessage;

  /// No description provided for @pidActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get pidActionCancel;

  /// No description provided for @pidActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get pidActionDelete;

  /// No description provided for @pidEditorTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New custom PID'**
  String get pidEditorTitleNew;

  /// No description provided for @pidEditorTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit PID'**
  String get pidEditorTitleEdit;

  /// No description provided for @pidEditorDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard unsaved changes?'**
  String get pidEditorDiscardTitle;

  /// No description provided for @pidEditorDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'The changes to this PID have not been saved, and leaving loses them.'**
  String get pidEditorDiscardBody;

  /// No description provided for @pidEditorKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get pidEditorKeepEditing;

  /// No description provided for @pidEditorDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get pidEditorDiscard;

  /// No description provided for @pidEditorDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this PID?'**
  String get pidEditorDeleteTitle;

  /// {name} is the user's own PID name and passes through untranslated.
  ///
  /// In en, this message translates to:
  /// **'The definition for “{name}” is removed, its gauge disappears from the dashboard, and this cannot be undone.'**
  String pidEditorDeleteBody(String name);

  /// A refusal that names the reason and the remedy. A generic 'invalid' would be a regression.
  ///
  /// In en, this message translates to:
  /// **'A custom PID already uses this combination ({name}). Use a different mode + PID, header, or name suffix.'**
  String pidEditorCollision(String name);

  /// No description provided for @pidEditorSectionIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get pidEditorSectionIdentity;

  /// No description provided for @pidEditorFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get pidEditorFieldName;

  /// No description provided for @pidEditorFieldShortName.
  ///
  /// In en, this message translates to:
  /// **'Short name (shown on the gauge)'**
  String get pidEditorFieldShortName;

  /// No description provided for @pidEditorFieldUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get pidEditorFieldUnits;

  /// No description provided for @pidEditorSectionQuery.
  ///
  /// In en, this message translates to:
  /// **'Query'**
  String get pidEditorSectionQuery;

  /// No description provided for @pidEditorFieldModeAndPid.
  ///
  /// In en, this message translates to:
  /// **'Mode + PID'**
  String get pidEditorFieldModeAndPid;

  /// Mode and PID numbers are never localized.
  ///
  /// In en, this message translates to:
  /// **'For example 010C or 221101'**
  String get pidEditorModeAndPidHelper;

  /// No description provided for @pidEditorFieldHeader.
  ///
  /// In en, this message translates to:
  /// **'CAN header'**
  String get pidEditorFieldHeader;

  /// 7E0 is a CAN id and stays byte-identical.
  ///
  /// In en, this message translates to:
  /// **'7E0 = engine'**
  String get pidEditorHeaderHelper;

  /// No description provided for @pidEditorSectionFormula.
  ///
  /// In en, this message translates to:
  /// **'Formula'**
  String get pidEditorSectionFormula;

  /// No description provided for @pidEditorFieldEquation.
  ///
  /// In en, this message translates to:
  /// **'Expression'**
  String get pidEditorFieldEquation;

  /// {valSyntax} carries the literal VAL{PID} token, which cannot be written inline because ARB reads braces as a placeholder.
  ///
  /// In en, this message translates to:
  /// **'A..N map to the response bytes; SIGNED(), ABS(), LOG10(), {valSyntax} and BARO are available'**
  String pidEditorEquationHelper(String valSyntax);

  /// No description provided for @pidEditorFieldSample.
  ///
  /// In en, this message translates to:
  /// **'Test response bytes'**
  String get pidEditorFieldSample;

  /// No description provided for @pidEditorSampleHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter hex to preview the result as you type'**
  String get pidEditorSampleHelper;

  /// No description provided for @pidEditorSectionRangeAndPriority.
  ///
  /// In en, this message translates to:
  /// **'Gauge range and priority'**
  String get pidEditorSectionRangeAndPriority;

  /// No description provided for @pidEditorFieldMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get pidEditorFieldMin;

  /// No description provided for @pidEditorFieldMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get pidEditorFieldMax;

  /// No description provided for @pidEditorSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get pidEditorSave;

  /// No description provided for @pidPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Live preview'**
  String get pidPreviewTitle;

  /// No description provided for @pidPreviewCannotEvaluate.
  ///
  /// In en, this message translates to:
  /// **'Cannot evaluate'**
  String get pidPreviewCannotEvaluate;

  /// {value} comes from the editor's own stand-in constant; never spell the number into the sentence. An estimate stands in for a measurement here, and the sentence must keep saying so.
  ///
  /// In en, this message translates to:
  /// **'The preview substitutes {value} for {dependencies}; the real value comes from that PID once connected.'**
  String pidPreviewSubstituted(double value, String dependencies);

  /// No description provided for @pidPreviewResultLabel.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get pidPreviewResultLabel;

  /// No description provided for @pidPriorityVeryLow.
  ///
  /// In en, this message translates to:
  /// **'Very Low'**
  String get pidPriorityVeryLow;

  /// No description provided for @pidPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get pidPriorityLow;

  /// No description provided for @pidPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get pidPriorityMedium;

  /// No description provided for @pidPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get pidPriorityHigh;

  /// Separator for an inline list of machine tokens. English uses a comma and a space; Chinese uses the enumeration comma.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get pidListSeparator;
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
