import 'dart:convert';

class ImpedancePoint {
  final List<double> real;
  final List<double> imag;
  final List<double> freq;

  ImpedancePoint({
    required this.real,
    required this.imag,
    required this.freq,
  });

  factory ImpedancePoint.fromRaw(String raw) {
    final decoded = json.decode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Invalid raw format for ImpedancePoint');
    }

    List<double> _toDoubleList(dynamic v) {
      if (v is List) return v.map((e) => (e as num).toDouble()).toList();
      throw FormatException('Expected list for numeric array');
    }

    final real = _toDoubleList(decoded['real']);
    final imag = _toDoubleList(decoded['imag']);
    final freq = _toDoubleList(decoded['freq']);

    return ImpedancePoint(real: real, imag: imag, freq: freq);
  }
}