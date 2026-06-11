import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/equalizer_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

/// Opens the equalizer dialog from anywhere in the app.
Future<void> showEqualizerDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (_) => const _EqualizerDialog(),
  );
}

class _EqualizerDialog extends StatefulWidget {
  const _EqualizerDialog();

  @override
  State<_EqualizerDialog> createState() => _EqualizerDialogState();
}

class _EqualizerDialogState extends State<_EqualizerDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: const _EqualizerPanel(),
          ),
        ),
      ),
    );
  }
}

class _EqualizerPanel extends StatelessWidget {
  const _EqualizerPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    final accent = context.watch<ThemeProvider>().accentColor;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: 4,
          ),
          const BoxShadow(
            color: Colors.black,
            blurRadius: 60,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, theme, accent),
          const Divider(height: 1, color: Color(0xFF1E1E1E)),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildWindowsFallbackBanner(theme),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPresetGrid(context, theme, accent),
                        const SizedBox(height: 28),
                        _buildBandSliders(context, theme, accent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeExtension theme, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 16, 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.graphic_eq_rounded, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Equalizer', style: TextStyle(
                  color: theme.textColor, fontSize: 20,
                  fontWeight: FontWeight.bold, letterSpacing: -0.3,
                )),
                Text('Adjust your audio tone', style: TextStyle(
                  color: theme.textSecondaryColor, fontSize: 12,
                )),
              ],
            ),
          ),
          // Enable toggle
          Consumer<EqualizerProvider>(
            builder: (_, eq, _x) => Consumer<ThemeProvider>(
              builder: (_, tp, _y) => Row(
                children: [
                  Text('On', style: TextStyle(color: theme.textSecondaryColor, fontSize: 13)),
                  const SizedBox(width: 8),
                  Switch(
                    value: eq.isEnabled,
                    onChanged: eq.setEnabled,
                    activeThumbColor: accent,
                    activeTrackColor: accent.withValues(alpha: 0.4),
                    inactiveThumbColor: theme.textSecondaryColor,
                    inactiveTrackColor: Colors.white12,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: theme.textSecondaryColor, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowsFallbackBanner(AppThemeExtension theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Native per-band EQ is not supported by the audio driver on Windows. '
              'Preset selection adjusts overall loudness as a simulation.',
              style: TextStyle(
                color: Colors.amber.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetGrid(BuildContext context, AppThemeExtension theme, Color accent) {
    final presets = kEqPresets.keys.toList();

    return Consumer<EqualizerProvider>(
      builder: (_, eq, _z) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Presets', style: TextStyle(
              color: theme.textColor, fontSize: 15,
              fontWeight: FontWeight.w600, letterSpacing: -0.2,
            )),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((preset) {
                final isActive = eq.activePreset == preset;
                return _PresetChip(
                  label: preset,
                  isActive: isActive,
                  enabled: eq.isEnabled,
                  accent: accent,
                  onTap: () => eq.selectPreset(preset),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBandSliders(BuildContext context, AppThemeExtension theme, Color accent) {
    return Consumer<EqualizerProvider>(
      builder: (_, eq, _z2) {
        final isCustom = eq.activePreset == 'Custom';
        final bands = isCustom ? eq.customBands : (kEqPresets[eq.activePreset] ?? List.filled(5, 0.0));

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: eq.isEnabled ? 1.0 : 0.4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Frequency Bands', style: TextStyle(
                    color: theme.textColor, fontSize: 15,
                    fontWeight: FontWeight.w600, letterSpacing: -0.2,
                  )),
                  if (eq.activePreset != 'Normal')
                    TextButton.icon(
                      icon: Icon(Icons.refresh_rounded, size: 14, color: accent),
                      label: Text('Reset', style: TextStyle(color: accent, fontSize: 12)),
                      onPressed: eq.isEnabled ? eq.resetToNormal : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(5, (i) {
                  return Expanded(
                    child: _BandSlider(
                      label: kEqBandLabels[i],
                      value: bands[i],
                      isEditable: isCustom && eq.isEnabled,
                      accent: accent,
                      theme: theme,
                      onChanged: (val) => eq.setCustomBand(i, val),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('+12dB', style: TextStyle(color: theme.textSecondaryColor.withValues(alpha: 0.4), fontSize: 10)),
                  Text('0dB', style: TextStyle(color: theme.textSecondaryColor.withValues(alpha: 0.4), fontSize: 10)),
                  Text('-12dB', style: TextStyle(color: theme.textSecondaryColor.withValues(alpha: 0.4), fontSize: 10)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Preset chip ───────────────────────────────────────────────────────────────
class _PresetChip extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isActive,
    required this.enabled,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_PresetChip> createState() => _PresetChipState();
}

class _PresetChipState extends State<_PresetChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;

    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.accent
                : _hovered
                    ? widget.accent.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: widget.isActive
                  ? widget.accent
                  : _hovered
                      ? widget.accent.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: widget.isActive
                ? [BoxShadow(color: widget.accent.withValues(alpha: 0.35), blurRadius: 12)]
                : [],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isActive
                  ? Colors.white
                  : theme.textSecondaryColor,
              fontSize: 13,
              fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Band Slider (vertical) ────────────────────────────────────────────────────
class _BandSlider extends StatelessWidget {
  final String label;
  final double value;       // dB
  final bool isEditable;
  final Color accent;
  final AppThemeExtension theme;
  final ValueChanged<double> onChanged;

  const _BandSlider({
    required this.label,
    required this.value,
    required this.isEditable,
    required this.accent,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = (value - kEqMinDb) / (kEqMaxDb - kEqMinDb); // 0–1
    final isPositive = value >= 0;

    return Column(
      children: [
        // dB label
        Text(
          value == 0 ? '0' : '${value > 0 ? '+' : ''}${value.toStringAsFixed(1)}',
          style: TextStyle(
            color: isPositive ? accent : Colors.redAccent,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // Vertical slider wrapped in RotatedBox
        SizedBox(
          height: 130,
          child: RotatedBox(
            quarterTurns: -1,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: isPositive ? accent : Colors.redAccent,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                thumbColor: isPositive ? accent : Colors.redAccent,
                overlayColor: (isPositive ? accent : Colors.redAccent).withValues(alpha: 0.25),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: normalized,
                min: 0.0,
                max: 1.0,
                onChanged: isEditable
                    ? (v) => onChanged(kEqMinDb + v * (kEqMaxDb - kEqMinDb))
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Frequency label
        Text(
          label,
          style: TextStyle(color: theme.textSecondaryColor, fontSize: 11),
        ),
      ],
    );
  }
}
