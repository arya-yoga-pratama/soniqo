import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Band labels (for UI) ──────────────────────────────────────────────────────
const List<String> kEqBandLabels = ['60Hz', '230Hz', '910Hz', '4kHz', '14kHz'];

// ── EQ Presets definition ─────────────────────────────────────────────────────
// Values are gain in dB for each of the 5 bands: [60, 230, 910, 4k, 14k]
const Map<String, List<double>> kEqPresets = {
  'Normal':     [ 0.0,  0.0,  0.0,  0.0,  0.0],
  'Bass Boost': [ 7.0,  5.0,  0.0, -1.0, -2.0],
  'Treble Boost':[-1.0,-1.0,  0.0,  5.0,  7.0],
  'Vocal':      [-2.0,  1.0,  5.0,  4.0,  2.0],
  'Pop':        [ 2.0,  3.0,  4.0,  3.0,  2.0],
  'Rock':       [ 5.0,  3.0, -1.0,  2.0,  5.0],
  'Jazz':       [ 3.0,  2.0,  0.0,  2.0,  3.0],
  'Classical':  [ 3.0,  2.0,  0.0,  2.0,  4.0],
  'Electronic': [ 6.0,  4.0,  0.0,  3.0,  5.0],
  'Hip Hop':    [ 7.0,  6.0, -1.0,  2.0,  3.0],
  'Custom':     [ 0.0,  0.0,  0.0,  0.0,  0.0],
};

const double kEqMinDb = -12.0;
const double kEqMaxDb = 12.0;

class EqualizerProvider extends ChangeNotifier {
  bool _isEnabled = true;
  String _activePreset = 'Normal';
  List<double> _customBands = [0.0, 0.0, 0.0, 0.0, 0.0];

  bool get isEnabled => _isEnabled;
  String get activePreset => _activePreset;
  List<double> get customBands => List.unmodifiable(_customBands);

  /// Returns the current active band gains (dB)
  List<double> get activeBands {
    if (_activePreset == 'Custom') return List.unmodifiable(_customBands);
    return List.unmodifiable(kEqPresets[_activePreset] ?? [0, 0, 0, 0, 0]);
  }

  /// Computes a 0.0–2.0 volume multiplier from the EQ bands.
  /// This is a best-effort simulation on platforms without native EQ support.
  /// Uses an average weighted-gain approach so bass/treble presets have
  /// audible impact via overall volume scaling.
  double get simulatedVolumeMultiplier {
    if (!_isEnabled) return 1.0;
    final bands = activeBands;
    // Weighted average: low bands have 40%, mid 20%, high 40%
    const weights = [0.20, 0.20, 0.20, 0.20, 0.20];
    double weightedDb = 0.0;
    for (int i = 0; i < bands.length; i++) {
      weightedDb += bands[i] * weights[i];
    }
    // Convert dB gain to linear multiplier (clamped 0.5–1.5)
    final multiplier = _dbToLinear(weightedDb);
    return multiplier.clamp(0.5, 1.5);
  }

  double _dbToLinear(double db) {
    return (db == 0.0) ? 1.0 : (10.0 * (db / 20.0)).roundToDouble() == 0
        ? 1.0
        : _pow10(db / 20.0);
  }

  double _pow10(double x) {
    // Manual pow10 without dart:math to keep import-free
    // e^(x * ln(10)) = e^(x * 2.302585)
    return _exp(x * 2.302585092994046);
  }

  double _exp(double x) {
    // Taylor series is imprecise; use iterative for accuracy
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 20; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('eq_enabled') ?? true;
      _activePreset = prefs.getString('eq_preset') ?? 'Normal';

      final customJson = prefs.getString('eq_custom_bands');
      if (customJson != null) {
        final List<dynamic> decoded = json.decode(customJson);
        _customBands = decoded.map<double>((v) => (v as num).toDouble()).toList();
        if (_customBands.length != 5) _customBands = [0, 0, 0, 0, 0];
      }

      // Validate stored preset still exists
      if (!kEqPresets.containsKey(_activePreset)) _activePreset = 'Normal';

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading EQ settings: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('eq_enabled', _isEnabled);
      await prefs.setString('eq_preset', _activePreset);
      await prefs.setString('eq_custom_bands', json.encode(_customBands));
    } catch (e) {
      debugPrint('Error saving EQ settings: $e');
    }
  }

  void setEnabled(bool val) {
    _isEnabled = val;
    _save();
    notifyListeners();
  }

  void selectPreset(String preset) {
    if (!kEqPresets.containsKey(preset)) return;
    _activePreset = preset;
    if (preset != 'Custom') {
      // Also copy preset values into customBands so switching to Custom starts from it
      _customBands = List.from(kEqPresets[preset]!);
    }
    _save();
    notifyListeners();
  }

  void setCustomBand(int index, double db) {
    if (index < 0 || index >= _customBands.length) return;
    _customBands[index] = db.clamp(kEqMinDb, kEqMaxDb);
    _activePreset = 'Custom';
    _save();
    notifyListeners();
  }

  void resetToNormal() {
    _activePreset = 'Normal';
    _customBands = [0, 0, 0, 0, 0];
    _save();
    notifyListeners();
  }
}
