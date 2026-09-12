/// Bounded ISO-TP assembler for host-visible (`ATCAF0`) PCI frames.
///
/// Partial, ambiguous, or wrong-source data is unavailable. This never
/// returns a shortened payload for a decoder to consume.
library;

/// Reassembles one controller's ISO-TP frames, or returns null.
///
/// PCI high nibbles, ELM327 datasheet p.44-45:
/// `0` Single Frame (length in the low nibble),
/// `1` First Frame (low nibble plus the next byte = 12-bit total),
/// `2` Consecutive Frame (low nibble = sequence),
/// `3` Flow Control (CTS / WAIT / overflow) — never payload.
final class IsoTpAssembler {
  /// ISO 15765-2 twelve-bit length maximum.
  static const int maxPduBytes = 4095;

  /// Single-Frame PCI for an OBD request the host sends after `ATCAF0`.
  ///
  /// Auto-format off applies to transmit as well as receive: a bare `010C`
  /// would go on the bus without a PCI byte. Returns compact uppercase hex,
  /// or null when [command] is not a ≤7-byte hex request (AT commands, odd
  /// nibbles, or a payload that needs First/Consecutive frames).
  static String? frameObdRequest(String command) {
    final upper = command.trim().toUpperCase().replaceAll(' ', '');
    if (upper.isEmpty || upper.startsWith('AT')) return null;
    if (upper.length.isOdd || !RegExp(r'^[0-9A-F]+$').hasMatch(upper)) {
      return null;
    }
    final payload = <int>[];
    for (var i = 0; i < upper.length; i += 2) {
      payload.add(int.parse(upper.substring(i, i + 2), radix: 16));
    }
    if (payload.isEmpty || payload.length > 7) return null;
    final framed = <int>[payload.length & 0x0F, ...payload];
    return framed
        .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
        .join();
  }

  /// Reassemble [raw] PCI frames from one source.
  ///
  /// [maxPduBytes] is the host bound. A First Frame that declares more than
  /// this, or more than the twelve-bit ISO-TP maximum, is refused.
  static List<int>? reassemble(
    List<List<int>> raw, {
    int maxPduBytes = IsoTpAssembler.maxPduBytes,
  }) {
    if (raw.isEmpty) return null;
    final first = raw.first;
    if (first.isEmpty) return null;
    final cap = maxPduBytes < IsoTpAssembler.maxPduBytes
        ? maxPduBytes
        : IsoTpAssembler.maxPduBytes;

    switch (first[0] >> 4) {
      case 0x0:
        final length = first[0] & 0x0F;
        if (length == 0 || length > 7) return null;
        if (raw.length != 1) return null;
        if (first.length > 8 || first.length < 1 + length) return null;
        return first.sublist(1, 1 + length);

      case 0x1:
        // Classic-CAN First Frames are eight bytes (2-byte PCI + six data).
        // A truncated FF would shift CF padding into the declared PDU.
        if (first.length != 8) return null;
        final total = ((first[0] & 0x0F) << 8) | first[1];
        // A First Frame exists because the payload does not fit in a Single
        // Frame. One declaring seven bytes or fewer is a contradiction.
        if (total <= 7) return null;
        if (total > cap) return null;
        final out = <int>[...first.sublist(2)];
        var expected = 1;
        for (final frame in raw.skip(1)) {
          // Trailing CF after the declared length is corruption, not padding
          // to ignore — refuse rather than silently truncating.
          if (out.length >= total) return null;
          if (frame.isEmpty || frame.length > 8) return null;
          final pci = frame[0] >> 4;
          if (pci == 0x3) return null;
          if (pci != 0x2) return null;
          if ((frame[0] & 0x0F) != (expected & 0x0F)) return null;
          expected++;
          final data = frame.sublist(1);
          // Classic-CAN ISO-TP: every non-final CF carries seven data bytes.
          // A short intermediate CF would shift later padding into the PDU.
          if (out.length + data.length < total && data.length != 7) {
            return null;
          }
          out.addAll(data);
        }
        if (out.length < total) return null;
        return out.sublist(0, total);

      case 0x3:
        // WAIT (FS=1), overflow (FS=2), or unexpected CTS: not a PDU.
        return null;

      default:
        return null;
    }
  }
}
