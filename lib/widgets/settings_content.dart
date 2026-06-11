import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/equalizer_provider.dart';
import '../theme/app_theme.dart';
import 'equalizer_dialog.dart';

class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  String _selectedCategory = 'Playback';
  bool _normalizeVolume = true;
  bool _autoDownload = false;
  double _crossfade = 5.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your preferences',
            style: TextStyle(fontSize: 16, color: theme.textSecondaryColor),
          ),
          const SizedBox(height: 32),

          // Two-column Layout
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT PANEL (category navigation)
                Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: theme.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryItem(
                          'Playback',
                          Icons.play_circle_outline,
                        ),
                        _buildCategoryItem(
                          'Downloads',
                          Icons.download_outlined,
                        ),
                        _buildCategoryItem(
                          'Notifications',
                          Icons.notifications_none,
                        ),
                        _buildCategoryItem(
                          'Appearance',
                          Icons.color_lens_outlined,
                        ),
                        _buildCategoryItem('Account', Icons.person_outline),
                        _buildCategoryItem(
                          'Advanced',
                          Icons.settings_applications_outlined,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 32),

                // RIGHT PANEL (settings detail)
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildSelectedSettingsDetail(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSettingsDetail() {
    switch (_selectedCategory) {
      case 'Playback':
        return _buildSettingsSection('Playback', [
          _buildDropdownSetting('Audio Quality', 'High', [
            'Low',
            'Normal',
            'High',
            'Very High',
          ]),
          _buildEqualizerSetting(context),
          _buildSliderSetting('Crossfade', _crossfade, 'sec', 0, 12, (val) {
            setState(() => _crossfade = val);
          }),
          _buildToggleSetting('Normalize Volume', _normalizeVolume, (val) {
            setState(() => _normalizeVolume = val);
          }),
        ]);
      case 'Downloads':
        return _buildSettingsSection('Downloads', [
          _buildDropdownSetting('Download Quality', 'High', [
            'Normal',
            'High',
            'Very High',
          ]),
          _buildToggleSetting('Auto Download', _autoDownload, (val) {
            setState(() => _autoDownload = val);
          }),
          _buildArrowSetting('Storage Location', 'Internal Storage'),
          _buildButtonSetting('Clear Cache', 'Clear'),
        ]);
      case 'Appearance':
        return _buildAppearanceSettings();
      default:
        return Center(
          child: Builder(
            builder: (context) {
              final theme = Theme.of(context).extension<AppThemeExtension>()!;
              return Text(
                '$_selectedCategory settings coming soon',
                style: TextStyle(color: theme.textSecondaryColor),
              );
            }
          ),
        );
    }
  }

  Widget _buildAppearanceSettings() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return _buildSettingsSection('Appearance', [

          _buildDropdownSetting('Display Language', 'English (US)', [
            'English (US)',
            'Bahasa Indonesia',
            'Español',
          ]),
          _buildToggleSetting('Dark Mode', themeProvider.isDarkMode, (val) {
            themeProvider.toggleDarkMode(val);
          }),
          _buildToggleSetting('Show Desktop Lyrics', false, (val) {}),
          _buildToggleSetting('Video Background', themeProvider.isVideoBackgroundEnabled, (val) {
            themeProvider.toggleVideoBackground(val);
          }),
          _buildDropdownSetting('Font Size', 'Medium', [
            'Small',
            'Medium',
            'Large',
          ]),
        ]);
      },
    );
  }

  Widget _buildCustomRow(String title, Widget trailing) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context).extension<AppThemeExtension>()!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: theme.textColor, fontSize: 16)),
            trailing,
          ],
        );
      }
    );
  }

  Widget _buildCategoryItem(String title, IconData icon) {
    final isActive = _selectedCategory == title;
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final accentColor = themeProvider.accentColor;
        final theme = Theme.of(context).extension<AppThemeExtension>()!;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedCategory = title;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isActive ? accentColor : Colors.transparent,
                  width: 3,
                ),
              ),
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        accentColor.withOpacity(0.15),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? accentColor : theme.textSecondaryColor,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isActive ? theme.textColor : theme.textSecondaryColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context).extension<AppThemeExtension>()!;
        return Container(
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.borderColor),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 24),
              ...children
                  .expand(
                    (widget) => [
                      widget,
                      Divider(color: theme.borderColor, height: 32),
                    ],
                  )
                  .toList()
                ..removeLast(),
            ],
          ),
        );
      }
    );
  }

  Widget _buildEqualizerSetting(BuildContext context) {
    return Consumer<EqualizerProvider>(
      builder: (context, eq, _) {
        final theme = Theme.of(context).extension<AppThemeExtension>()!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Equalizer', style: TextStyle(color: theme.textColor, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: eq.isEnabled ? const Color(0xFF7C3AED) : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      eq.isEnabled ? eq.activePreset : 'Off',
                      style: TextStyle(color: theme.textSecondaryColor, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => showEqualizerDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.backgroundColor,
                foregroundColor: theme.textColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: theme.borderColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text('Open'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String currentValue,
    List<String> options,
  ) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context).extension<AppThemeExtension>()!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: theme.textColor, fontSize: 16)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.borderColor),
              ),
              child: Row(
                children: [
                  Text(
                    currentValue,
                    style: TextStyle(color: theme.textColor, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.textSecondaryColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildButtonSetting(String title, String buttonText) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context).extension<AppThemeExtension>()!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: theme.textColor, fontSize: 16)),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.backgroundColor,
                foregroundColor: theme.textColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: theme.borderColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: Text(buttonText),
            ),
          ],
        );
      }
    );
  }

  Widget _buildSliderSetting(
    String title,
    double value,
    String unit,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final accentColor = themeProvider.accentColor;
        final theme = Theme.of(context).extension<AppThemeExtension>()!;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(color: theme.textColor, fontSize: 16),
            ),
            Row(
              children: [
                SizedBox(
                  width: 150,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: accentColor,
                      inactiveTrackColor: theme.borderColor,
                      thumbColor: accentColor,
                      overlayColor: accentColor.withOpacity(0.2),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                    ),
                    child: Slider(
                      value: value,
                      min: min,
                      max: max,
                      onChanged: onChanged,
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    '${value.toInt()} $unit',
                    style: TextStyle(color: theme.textSecondaryColor, fontSize: 14),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildToggleSetting(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final accentColor = themeProvider.accentColor;
        final theme = Theme.of(context).extension<AppThemeExtension>()!;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(color: theme.textColor, fontSize: 16),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: accentColor,
              activeTrackColor: accentColor.withOpacity(0.5),
              inactiveThumbColor: theme.textSecondaryColor,
              inactiveTrackColor: theme.borderColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildArrowSetting(String title, String subtitle) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context).extension<AppThemeExtension>()!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: theme.textColor, fontSize: 16)),
            Row(
              children: [
                Text(
                  subtitle,
                  style: TextStyle(color: theme.textSecondaryColor, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: theme.textSecondaryColor,
                  size: 14,
                ),
              ],
            ),
          ],
        );
      }
    );
  }
}
