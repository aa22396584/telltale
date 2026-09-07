/// Why the manual command box will not send what was typed, as identifiers.
///
/// The rule this file exists for is the same one
/// `lib/state/powertrain_battery_profiles.dart` learned: the engine names the
/// refusal, and `lib/ui/screens/settings/manual_command_copy.dart` owns the
/// words. Until this became an enum the refusal *was* the sentence — six
/// Traditional Chinese strings returned from `ObdSession`, thrown as a
/// `TransportException` carrying `issue: null`, and rendered verbatim by the
/// settings panel in every language the app ships. An English driver who typed
/// `04` was answered `清除故障碼請用故障碼畫面的「清除」按鈕。…` on the one
/// screen somebody opens when they are already unsure whether the app works.
///
/// Two of the sentences name a value: the command as it was typed, and the
/// list of what this box does accept. Those travel as **data** on
/// [ManualCommandRefusal] rather than being interpolated into a sentence here,
/// for the reason the ARB metadata for `pidRejectionServiceNotReadOnly`
/// already gives about its own list — copy that named seven queries while the
/// set accepted more was a false statement about what this app takes, read by
/// the one person whose command had just been refused. The number is left out
/// on purpose: it is what drifted, and a count here would drift again on the
/// next entry with nothing failing.
///
/// Nothing in this file is a sentence. That is checkable rather than
/// aspirational: `test/l10n/l05_manual_refusal_guard_test.dart` fails on any
/// Chinese character in any string literal here.
///
/// It is a file of its own rather than a region of `obd_session.dart` for
/// exactly that reason. `obd_session.dart` is full of Traditional Chinese
/// string literals that are supposed to stay — transcript notes and evidence
/// export lines, which are records rather than screen copy — so a scan aimed
/// at it would have to carry an exception list, and an exception list is what
/// this repository's guards fail on.
library;

/// The refusals the manual command box can produce.
///
/// One value per refusal, and the sentence for each lives in the three ARB
/// files. A value added here fails to compile until somebody writes its copy:
/// the switch in `manual_command_copy.dart` has no `_` arm.
enum ManualCommandRefusalReason {
  /// Nothing was typed.
  emptyCommand,

  /// The text carries a terminator or another control character, so it is more
  /// than one command however it looks.
  moreThanOneCommand,

  /// An `AT` command that changes what the adapter is, rather than asking.
  ///
  /// The sentence names the command and the queries that are accepted, so it
  /// carries both.
  adapterStateWouldChange,

  /// Mode 04. Clearing has a button, and the button is where the safeguards
  /// live.
  clearHasItsOwnButton,

  /// The text contains a character no legal OBD request contains.
  charactersNoObdCommandHas,

  /// Hex, well-formed, and not one of the read-only services.
  notAReadOnlyQuery,
}

/// A refusal, with the values its sentence has to name.
///
/// There is no constructor that lets an arm which names a value omit it. The
/// alternative — one optional field and a guard asserting it was passed — is
/// the shape `TransportException.issueDetail` has, and it needed a scan over
/// source to hold it up because `issueDetail: null` analysed clean. Here the
/// compiler does that job, so there is nothing for a scan to miss.
final class ManualCommandRefusal {
  const ManualCommandRefusal._(this.issue, this.command, this.allowed);

  const ManualCommandRefusal.emptyCommand()
    : this._(ManualCommandRefusalReason.emptyCommand, '', const []);

  const ManualCommandRefusal.moreThanOneCommand()
    : this._(ManualCommandRefusalReason.moreThanOneCommand, '', const []);

  const ManualCommandRefusal.adapterStateWouldChange({
    required String command,
    required List<String> allowed,
  }) : this._(
         ManualCommandRefusalReason.adapterStateWouldChange,
         command,
         allowed,
       );

  const ManualCommandRefusal.clearHasItsOwnButton()
    : this._(ManualCommandRefusalReason.clearHasItsOwnButton, '', const []);

  const ManualCommandRefusal.charactersNoObdCommandHas({
    required String command,
  }) : this._(
         ManualCommandRefusalReason.charactersNoObdCommandHas,
         command,
         const [],
       );

  const ManualCommandRefusal.notAReadOnlyQuery({
    required String command,
    required List<String> allowed,
  }) : this._(ManualCommandRefusalReason.notAReadOnlyQuery, command, allowed);

  /// Which refusal this is. The key the copy table switches on.
  ///
  /// `issue`, not `reason`, for two reasons that point the same way.
  ///
  /// `PidRejectionReason` in `lib/obd/pid/pid.dart` is this class's structural
  /// twin — an identifier plus the values its sentence names — and it calls
  /// that member `issue`, as does `TransportException`. Converging on the
  /// house name is worth more than the one this started with.
  ///
  /// It also keeps a guard total. `DatumStatus.reason` is a frozen
  /// export-file string, and `export_labels_stay_off_screen_test.dart` reports
  /// **any** `.reason` read under `lib/ui` whatever the receiver is called,
  /// deliberately: it reads names, not types. Spelled `reason`, this field
  /// made that guard report the copy table below, and the alternative was an
  /// entry in its `_allowed` table — which is per symbol per file and would
  /// then have excused a genuine `DatumStatus.reason` read in that same file
  /// for good. Do not rename this back.
  final ManualCommandRefusalReason issue;

  /// The command as it was typed, for the arms whose sentence quotes it.
  ///
  /// Empty for the arms that do not, rather than null: a sentence with a hole
  /// in it is still a sentence, and the arms that leave it empty never print
  /// it.
  final String command;

  /// What this box does accept, for the arms whose sentence lists it.
  ///
  /// A list rather than a joined string, because the separator between items
  /// is `, ` in English and `、` in Chinese. Joining here would put CJK
  /// punctuation in engine code and leave an English reader with it — the
  /// half of a translation that eight of nine earlier waves in this repo
  /// missed.
  final List<String> allowed;
}

/// Raised instead of sending. Carries the identifier, never a sentence.
///
/// Not a `TransportException`. Nothing about a refusal is a transport failure:
/// no link is involved, nothing was written, and the settings panel is the
/// only thing that renders it. Making it a subclass would also inherit
/// `issue: null` and put it back in front of the guard that exists to keep
/// `TransportException`s carrying an identifier.
///
/// [toString] names the identifier rather than the sentence, in English,
/// because the only thing that reads it is a crash report.
final class ManualCommandRefusedException implements Exception {
  const ManualCommandRefusedException(this.refusal);

  final ManualCommandRefusal refusal;

  @override
  String toString() =>
      'ManualCommandRefusedException: ${refusal.issue.name}'
      '${refusal.command.isEmpty ? '' : ' (${refusal.command})'}';
}

/// The `AT` queries this box accepts, without the `AT` prefix.
///
/// Named individually rather than by prefix: `ATDP` and `ATDPN` ask which
/// protocol is in use, `ATD` resets everything to defaults, and a prefix rule
/// would get that exactly backwards.
const Set<String> kManualCommandReadOnlyAtQueries = {
  'I',
  '@1',
  '@2',
  '@3',
  'RV',
  'DP',
  'DPN',
  'PPS',
  'IGN',
  'DESC',
  'CS',
  'CV',
  'RD',
};

/// The OBD services this box accepts.
///
/// Mode 08 is not on this list, and its absence is the point.
///
/// J1979 names it "request control of on-board system, test or component" —
/// it *actuates* things: evaporative-system leak tests, solenoids, pumps. It
/// was sitting on a whitelist whose contract is read-only because its number
/// looks like its neighbours', which is exactly how a control service ends up
/// being sent by a box labelled 查詢.
///
/// `05` is on it, and was missing. J1979 defines it as "request oxygen sensor
/// monitoring test results" — stored results from completed tests, read-only,
/// with a sensor byte rather than a PID. Leaving it out refused a legitimate
/// query on the buses where it is the *only* way to ask: it is defined for
/// pre-CAN implementations only, ISO 9141-2 and the J1850 pair, where Mode 06
/// does not replace it.
const Set<String> kManualCommandReadOnlyServices = {
  '01',
  '02',
  '03',
  '05',
  '06',
  '07',
  '09',
  '0A',
  '22',
};

/// The accepted `AT` queries as a reader sees them, in a stable order.
///
/// Derived from [kManualCommandReadOnlyAtQueries] rather than written out
/// beside it. The two had already drifted once on the other list: Mode 05 was
/// admitted and the sentence that tells somebody what they *can* send still
/// omitted it, so the person whose command had just been refused was told 05
/// was not allowed by the same sentence that was supposed to tell them what
/// is.
List<String> get manualCommandAdvertisedAtQueries =>
    (kManualCommandReadOnlyAtQueries.toList()..sort())
        .map((suffix) => 'AT$suffix')
        .toList(growable: false);

/// The accepted services as a reader sees them, in a stable order.
List<String> get manualCommandAdvertisedServices =>
    kManualCommandReadOnlyServices.toList()..sort();

/// Why a typed command will not be sent, or null if it will.
///
/// Serialising the box onto the ordinary command chain stopped it
/// *interleaving* with the poll loop. It did not stop it changing the
/// adapter underneath the app's model of it, and that is the part that
/// produces a wrong number:
///
///   a poll selects `7E0` and the client caches it
///   the user types `ATSH 7E1`, the adapter says OK
///   the next built-in `010C` trusts the cache, sends no `ATSH`,
///   and the transmission answers 1000 rpm as the engine's
///
/// Nothing on screen says which controller replied, and the number is
/// entirely plausible. `ATZ`, `ATD`, `ATSP`, `ATE1`, the filter and mask
/// commands and the monitoring commands all invalidate the negotiated model
/// the same way.
///
/// And Mode 04 is worse than a wrong number: typed here it skips the
/// confirmation dialog, the coverage check, the acknowledgement check and
/// the lifecycle guard, clears whichever controller happens to be selected,
/// and resets the readiness monitors while the app's own model of the scan
/// knows nothing happened.
///
/// So the box asks questions. It does not change anything.
ManualCommandRefusal? manualCommandRefusal(String command) {
  final c = command.trim().toUpperCase().replaceAll(' ', '');
  if (c.isEmpty) return const ManualCommandRefusal.emptyCommand();
  // Before anything is classified, because everything below classifies *one*
  // command and a control character means there is more than one.
  //
  // `\r` is the ELM327's command terminator, so `03\r04` is not a Mode 03
  // request containing an odd character — it is two requests, and the second
  // is a Mode 04 clear. Every check below reads the first two characters,
  // saw `03`, and let the whole string through: the read-only box erased the
  // vehicle's fault memory, skipping the confirmation, the coverage check
  // and the response validation that the 清除 button exists to enforce.
  //
  // Nobody types this. Pasting is how it arrives — a command copied off a
  // forum post or out of a log brings its line ending with it, and the
  // trailing one is harmless only because `trim` already took it.
  if (c.codeUnits.any((u) => u < 0x20 || u == 0x7F)) {
    return const ManualCommandRefusal.moreThanOneCommand();
  }
  if (c.startsWith('AT')) {
    final at = c.substring(2);
    if (kManualCommandReadOnlyAtQueries.contains(at)) return null;
    return ManualCommandRefusal.adapterStateWouldChange(
      command: command,
      allowed: manualCommandAdvertisedAtQueries,
    );
  }
  // OBD services. Only the read-only ones, and never Mode 04 — clearing has
  // its own button, and that button is where every safeguard lives.
  final service = c.length >= 2 ? c.substring(0, 2) : '';
  if (c == '04' || c.startsWith('04')) {
    return const ManualCommandRefusal.clearHasItsOwnButton();
  }
  // The whole command, not its first two characters.
  //
  // Everything above is a whitelist and this line was not: it matched a
  // prefix and passed the rest through unread, so `03;04` was a Mode 03
  // request as far as this was concerned. A reviewer names `;` as a command
  // separator on STN-based adapters (OBDLink); the datasheet search did not
  // confirm that, and the decision does not depend on it — no legal OBD
  // request contains a character outside `0-9A-F`, so requiring them costs
  // nothing, and being wrong in the other direction sends a clear.
  //
  // The same rule the response parser uses, pointed the other way: accept
  // what is recognisably legal rather than reject what is recognisably not.
  // A blacklist of separators is a list somebody has to keep complete.
  if (!RegExp(r'^[0-9A-F]+$').hasMatch(c)) {
    return ManualCommandRefusal.charactersNoObdCommandHas(command: command);
  }
  if (kManualCommandReadOnlyServices.contains(service)) return null;
  return ManualCommandRefusal.notAReadOnlyQuery(
    command: command,
    allowed: manualCommandAdvertisedServices,
  );
}
