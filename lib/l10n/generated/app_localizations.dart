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

  /// App bar of the vehicle-specific traction-battery catalog.
  ///
  /// In en, this message translates to:
  /// **'Powertrain battery catalog'**
  String get powertrainCatalogTitle;

  /// No description provided for @powertrainCatalogLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline catalog could not load'**
  String get powertrainCatalogLoadFailedTitle;

  /// Fail-closed: says what did NOT happen. Never soften to 'try again later'.
  ///
  /// In en, this message translates to:
  /// **'Integrity verification did not pass, so no vehicle data is shown or installed.'**
  String get powertrainCatalogLoadFailedBody;

  /// No description provided for @powertrainCatalogRevalidate.
  ///
  /// In en, this message translates to:
  /// **'Verify again'**
  String get powertrainCatalogRevalidate;

  /// Both counts are derived from the verified catalog; never spell a number into the copy. English uses a label form because neither count has a fixed plurality.
  ///
  /// In en, this message translates to:
  /// **'Profiles: {profiles} · Experimental one-shot reads: {probeable}'**
  String powertrainCatalogCounts(int profiles, int probeable);

  /// Load-bearing: separates 'a candidate exists' from 'this works on your car'. Never drop either half.
  ///
  /// In en, this message translates to:
  /// **'The catalog is wide, but “we found data” is not “your car is supported”. Research-only entries never carry a command; experimental entries still read one command at a time, each after its own confirmation.'**
  String get powertrainCatalogScopeNote;

  /// No description provided for @powertrainCatalogSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search make, model, variant or market…'**
  String get powertrainCatalogSearchHint;

  /// The 'no powertrain filter' chip. The other chips are the acronyms PHEV, HEV, BEV, MHEV, REEV, FCEV and are never translated.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get powertrainFilterAll;

  /// No description provided for @powertrainNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching vehicle'**
  String get powertrainNoMatchTitle;

  /// No description provided for @powertrainNoMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Try a make or model name, or switch to another powertrain type.'**
  String get powertrainNoMatchBody;

  /// PowertrainProfileStatus.ready. A claim about the SOURCE, not about the vehicle: it must never read as 'verified on your car'.
  ///
  /// In en, this message translates to:
  /// **'Fuller source data'**
  String get powertrainStatusReady;

  /// PowertrainProfileStatus.community. Cross-corroborated by independent sources, still never driven by this project. Both halves are required. Shortened from 'Community data · unverified', which overflowed the card header at 360dp — a shorter true phrase, not an ellipsis that hides the tier.
  ///
  /// In en, this message translates to:
  /// **'Community · unverified'**
  String get powertrainStatusCommunity;

  /// PowertrainProfileStatus.experimental on a profile that can also be installed.
  ///
  /// In en, this message translates to:
  /// **'Experimental · unverified'**
  String get powertrainStatusExperimental;

  /// PowertrainProfileStatus.experimental on a profile that can only be read once, never installed. Kept short because the pill shares the card header row with the profile name at 360dp; 'Experimental · one-shot read-only' overflowed it. A shorter true phrase, never an ellipsis.
  ///
  /// In en, this message translates to:
  /// **'Experimental · read once'**
  String get powertrainStatusExperimentalProbeOnly;

  /// PowertrainProfileStatus.researchOnly. Metadata index with no commands. Must never read as installable or supported.
  ///
  /// In en, this message translates to:
  /// **'Research only'**
  String get powertrainStatusResearchOnly;

  /// PowertrainProfileEvidence.sourceBacked: an external source supports the mapping. NOT evidence produced by Telltale on a vehicle.
  ///
  /// In en, this message translates to:
  /// **'Source data'**
  String get powertrainEvidenceSourceBacked;

  /// PowertrainProfileEvidence.syntheticRig: a deterministic simulator exercised the path. Establishes nothing about a real ECU.
  ///
  /// In en, this message translates to:
  /// **'Synthetic rig'**
  String get powertrainEvidenceSyntheticRig;

  /// PowertrainProfileEvidence.physicalVehicle: a retained run this project performed. Still bounded to the recorded market, variant, adapter and conditions.
  ///
  /// In en, this message translates to:
  /// **'Project vehicle'**
  String get powertrainEvidencePhysicalVehicle;

  /// Scoped to this connection, not permanent, and reconnecting is what lifts it. Kept to the pill width at 360dp: 'Quarantined for this connection' overflowed the card header row.
  ///
  /// In en, this message translates to:
  /// **'Quarantined · reconnect'**
  String get powertrainQuarantinedPill;

  /// Rendered inside a middle-dot separated provenance line. Label form in English so it is correct at any count.
  ///
  /// In en, this message translates to:
  /// **'Signals: {count}'**
  String powertrainSignalCount(int count);

  /// No description provided for @powertrainInstallButton.
  ///
  /// In en, this message translates to:
  /// **'Install battery signals'**
  String get powertrainInstallButton;

  /// No description provided for @powertrainInstalledRemoveButton.
  ///
  /// In en, this message translates to:
  /// **'Installed · remove signals'**
  String get powertrainInstalledRemoveButton;

  /// Disabled probe button after a structural-mismatch quarantine.
  ///
  /// In en, this message translates to:
  /// **'Reconnect, then try again'**
  String get powertrainProbeReconnectFirst;

  /// No description provided for @powertrainProbeConnectToTryOnce.
  ///
  /// In en, this message translates to:
  /// **'Connect to try one read first'**
  String get powertrainProbeConnectToTryOnce;

  /// No description provided for @powertrainProbeInProgress.
  ///
  /// In en, this message translates to:
  /// **'Reading once…'**
  String get powertrainProbeInProgress;

  /// No description provided for @powertrainProbeTryOnceFirst.
  ///
  /// In en, this message translates to:
  /// **'Try one read first'**
  String get powertrainProbeTryOnceFirst;

  /// No description provided for @powertrainProbeEnableLabFirst.
  ///
  /// In en, this message translates to:
  /// **'Turn on the laboratory in Settings first'**
  String get powertrainProbeEnableLabFirst;

  /// No description provided for @powertrainProbeConnectForOneShot.
  ///
  /// In en, this message translates to:
  /// **'Connect for a one-shot read-only query'**
  String get powertrainProbeConnectForOneShot;

  /// No description provided for @powertrainProbePickOneRead.
  ///
  /// In en, this message translates to:
  /// **'Pick one command, read once'**
  String get powertrainProbePickOneRead;

  /// The permanently disabled button on a researchOnly row. It states a refusal, not a temporary unavailability.
  ///
  /// In en, this message translates to:
  /// **'Research only — never queries'**
  String get powertrainResearchOnlyNeverQueries;

  /// No description provided for @powertrainNotInstallableInThisRelease.
  ///
  /// In en, this message translates to:
  /// **'Not installable in this release'**
  String get powertrainNotInstallableInThisRelease;

  /// No description provided for @powertrainInstallDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Install this model\'s battery signals'**
  String get powertrainInstallDialogTitle;

  /// Source names and licence identifiers are identifiers and are never translated.
  ///
  /// In en, this message translates to:
  /// **'Primary source: {name} ({license})'**
  String powertrainPrimarySource(String name, String license);

  /// No description provided for @powertrainSecondarySource.
  ///
  /// In en, this message translates to:
  /// **'Independent corroboration: {name} ({license})'**
  String powertrainSecondarySource(String name, String license);

  /// No description provided for @powertrainVehicleYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Model year'**
  String get powertrainVehicleYearLabel;

  /// Shown when the profile covers exactly one year, so there is nothing to choose.
  ///
  /// In en, this message translates to:
  /// **'Model year: {year}'**
  String powertrainVehicleYearFixed(int year);

  /// No description provided for @powertrainInstallIdentityAck.
  ///
  /// In en, this message translates to:
  /// **'My vehicle matches the market, model and model year above'**
  String get powertrainInstallIdentityAck;

  /// No description provided for @powertrainCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get powertrainCancel;

  /// No description provided for @powertrainInstallConfirm.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get powertrainInstallConfirm;

  /// PowertrainProfileStatus.ready. Whole sentence, not a shared prefix plus a fragment: English word order will not survive concatenation. The closing 'still not a manufacturer guarantee' is load-bearing in all four variants.
  ///
  /// In en, this message translates to:
  /// **'Installing only adds read-only battery PIDs to PID management. Before any reading starts, every connection asks you to confirm on the dashboard that this car is that model. The source data is fuller; it is still not a manufacturer guarantee.'**
  String get powertrainInstallDisclosureReady;

  /// PowertrainProfileStatus.community. 'Independently corroborated' is a claim about sources agreeing, never about this vehicle.
  ///
  /// In en, this message translates to:
  /// **'Installing only adds read-only battery PIDs to PID management. Before any reading starts, every connection asks you to confirm on the dashboard that this car is that model. The data comes from community sources and has been independently corroborated; it is still not a manufacturer guarantee.'**
  String get powertrainInstallDisclosureCommunity;

  /// PowertrainProfileStatus.experimental. Three separate hedges: experimental, no corroboration requirement, unverified on this vehicle. Dropping any one of them overstates the tier.
  ///
  /// In en, this message translates to:
  /// **'Installing only adds read-only battery PIDs to PID management. Before any reading starts, every connection asks you to confirm on the dashboard that this car is that model. This is an experimental decode with no independent-corroboration requirement, unverified on this vehicle, and still not a manufacturer guarantee.'**
  String get powertrainInstallDisclosureExperimental;

  /// PowertrainProfileStatus.researchOnly. Must never read as installable or supported.
  ///
  /// In en, this message translates to:
  /// **'Installing only adds read-only battery PIDs to PID management. Before any reading starts, every connection asks you to confirm on the dashboard that this car is that model. This entry is for research only and should not be installed.'**
  String get powertrainInstallDisclosureResearchOnly;

  /// No description provided for @powertrainChooseCommandTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose one pinned read-only query'**
  String get powertrainChooseCommandTitle;

  /// Mirrors README.md: 'no identifier scan, batch, automatic retry'. The three negations are the promise.
  ///
  /// In en, this message translates to:
  /// **'One command per attempt: no scan, no batch, no automatic retry.'**
  String get powertrainChooseCommandNote;

  /// No description provided for @powertrainExperimentalDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'One-shot experimental read-only confirmation'**
  String get powertrainExperimentalDialogTitle;

  /// RX, the CAN responder id and the unit 'bytes' are never translated.
  ///
  /// In en, this message translates to:
  /// **'Accepts RX {responder} only, payload length {bytes} bytes'**
  String powertrainExperimentalWireLine(String responder, int bytes);

  /// A truncated identifier the reader may paste into a search. Never translated, never reformatted.
  ///
  /// In en, this message translates to:
  /// **'Source file SHA-256: {hash}…'**
  String powertrainSourceSha256(String hash);

  /// Four load-bearing claims: candidate not guarantee; the transcript keeps it locally; nothing is auto-uploaded; nothing is installed or shown on a gauge. Cancelling is safe. Dropping any clause changes what the driver is consenting to.
  ///
  /// In en, this message translates to:
  /// **'This is a candidate read labelled by the source\'s authors, not a manufacturer or cross-model safety guarantee; ELM327 only forwards the command. The raw command and reply stay in the local diagnostic transcript and are not uploaded automatically by this feature; decoded values are never installed as a PID or added to a gauge. Cancelling does not affect ordinary OBD functions.'**
  String get powertrainExperimentalDataDisclosure;

  /// 'the source knows' is the hedge: the source's identity evidence, not a confirmed match.
  ///
  /// In en, this message translates to:
  /// **'I have checked the market, model and model year the source knows, and I accept the unconfirmed fields'**
  String get powertrainExperimentalIdentityAck;

  /// Safety-critical. Keep both halves: parked, and the value may not apply.
  ///
  /// In en, this message translates to:
  /// **'The vehicle is safely parked; I understand this reads once and the number may still not apply'**
  String get powertrainExperimentalParkedAck;

  /// No description provided for @powertrainProbeOnceButton.
  ///
  /// In en, this message translates to:
  /// **'Read once only'**
  String get powertrainProbeOnceButton;

  /// {fields} is a middle-dot list of 'field level' pairs; {unconfirmed} lists the fields the source could not establish, joined by powertrainFieldListSeparator.
  ///
  /// In en, this message translates to:
  /// **'Source identity evidence: {fields}\nUnconfirmed fields: {unconfirmed}'**
  String powertrainIdentityEvidenceSummary(String fields, String unconfirmed);

  /// Joins the unconfirmed-field names. Chinese uses the enumeration comma U+3001, English a comma and a space; this is why it is a message and not a constant.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get powertrainFieldListSeparator;

  /// No description provided for @powertrainFieldMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get powertrainFieldMarket;

  /// No description provided for @powertrainFieldModelYear.
  ///
  /// In en, this message translates to:
  /// **'Model year'**
  String get powertrainFieldModelYear;

  /// No description provided for @powertrainFieldModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get powertrainFieldModel;

  /// No description provided for @powertrainFieldVariant.
  ///
  /// In en, this message translates to:
  /// **'Variant'**
  String get powertrainFieldVariant;

  /// PowertrainIdentityEvidenceLevel.exact. Evidence about the SOURCE record, not a match with the car in front of the driver.
  ///
  /// In en, this message translates to:
  /// **'direct evidence'**
  String get powertrainIdentityEvidenceExact;

  /// PowertrainIdentityEvidenceLevel.sourcePartial. Partial is not confirmed; it must stay distinct from both exact and unknown.
  ///
  /// In en, this message translates to:
  /// **'partial evidence'**
  String get powertrainIdentityEvidenceSourcePartial;

  /// PowertrainIdentityEvidenceLevel.unknown. The source said nothing about this field. Never render as 'not applicable' or 'none'.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get powertrainIdentityEvidenceUnknown;

  /// Fills 'Unconfirmed fields:' when every field has evidence. It says the LIST is empty, not that a field is unknown.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get powertrainIdentityEvidenceNone;

  /// No description provided for @powertrainProbePassedTitle.
  ///
  /// In en, this message translates to:
  /// **'One-shot query passed'**
  String get powertrainProbePassedTitle;

  /// No description provided for @powertrainProbeRefusedTitle.
  ///
  /// In en, this message translates to:
  /// **'One-shot query refused'**
  String get powertrainProbeRefusedTitle;

  /// Names exactly the checks that ran. It is not a statement that the value is correct for this vehicle.
  ///
  /// In en, this message translates to:
  /// **'Passed the responder, echo, exact length, formula and range checks.'**
  String get powertrainProbeChecksPassed;

  /// No description provided for @powertrainProbeNoValuePublished.
  ///
  /// In en, this message translates to:
  /// **'No value was published; a structural or decode error is quarantined until you reconnect.'**
  String get powertrainProbeNoValuePublished;

  /// No description provided for @powertrainClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get powertrainClose;

  /// No description provided for @powertrainEnableLabInSettings.
  ///
  /// In en, this message translates to:
  /// **'Turn on the experimental battery laboratory in Settings first.'**
  String get powertrainEnableLabInSettings;

  /// No description provided for @powertrainConnectFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect first; experimental authorization is never kept across connections.'**
  String get powertrainConnectFirst;

  /// {reason} is produced by the consent notifier, not by this screen.
  ///
  /// In en, this message translates to:
  /// **'Quarantined for this connection: {reason}'**
  String powertrainQuarantinedSnack(String reason);

  /// No description provided for @powertrainNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Not authorized: {reason}'**
  String powertrainNotAuthorized(String reason);

  /// Says what did NOT happen. An unfinished probe must never read as a failed vehicle.
  ///
  /// In en, this message translates to:
  /// **'The one-shot query did not finish; no value was published or kept.'**
  String get powertrainProbeDidNotFinish;

  /// No description provided for @powertrainCatalogNotVerified.
  ///
  /// In en, this message translates to:
  /// **'The catalog has not passed verification, so nothing can be installed.'**
  String get powertrainCatalogNotVerified;

  /// Retryable, and says so. Distinct from powertrainCatalogNotVerified, which is not retryable.
  ///
  /// In en, this message translates to:
  /// **'A storage error happened while restoring earlier installs. It has been rescheduled — try again.'**
  String get powertrainRestoreStorageErrorRetry;

  /// {reason} is a technical message raised by the installer, not copy this screen owns.
  ///
  /// In en, this message translates to:
  /// **'Cannot install: {reason}'**
  String powertrainInstallFailed(String reason);

  /// Installing is not authorizing: the per-connection vehicle confirmation is still required, and the sentence must keep saying so.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Installed 1 signal. Add it to the dashboard from the PID page; every connection needs a vehicle confirmation.} other{Installed {count} signals. Add them to the dashboard from the PID page; every connection needs a vehicle confirmation.}}'**
  String powertrainInstalledSignalsSnack(int count);

  /// {name} is the profile display name from the catalog; it is data and is not translated.
  ///
  /// In en, this message translates to:
  /// **'Removed the installed signals for {name}.'**
  String powertrainUninstalledSignalsSnack(String name);
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
