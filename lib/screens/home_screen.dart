import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/main_content.dart';
import '../widgets/explore_content.dart';
import '../widgets/settings_content.dart';
import '../widgets/play_history_content.dart';
import '../widgets/favourite_content.dart';
import '../widgets/library_content.dart';
import '../widgets/player_bar.dart';
import '../widgets/add_song_content.dart';
import '../widgets/downloaded_content.dart';
import '../widgets/video_background.dart';
import '../data/songs_data.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSidebarExpanded = true;
  String _currentMenu = 'Home';
  String? _exploreSubPage;

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<AppThemeExtension>()!;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isVideoBackgroundEnabled ? Colors.transparent : theme.backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── [1] Persistent video background ───────────────────────────────
          // Lives at the TOP of the widget tree so it is NEVER removed from
          // the element tree regardless of navigation — guaranteeing stable
          // Player/VideoController state and continuous playback.
          if (themeProvider.isVideoBackgroundEnabled)
            const VideoBackground(
              assetPath: 'assets/videobacground/background.mp4',
              overlayOpacity: 0.62,
            ),

          // ── [2] All UI content on top ──────────────────────────────────────
          Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Sidebar – has its own opaque background, covers video
                    Sidebar(
                      isExpanded: _isSidebarExpanded,
                      onToggle: _toggleSidebar,
                      selectedMenu: _currentMenu,
                      onMenuSelected: (menu) {
                        setState(() {
                          _currentMenu = menu;
                          _exploreSubPage = null; // Reset subpage when navigating from sidebar
                        });
                      },
                    ),

                    // Subtle Divider between Sidebar and Main Content
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: theme.borderColor,
                    ),

                    // Main Content Area – transparent so video shows through
                    Expanded(
                      child: _currentMenu == 'Explore'
                          ? ExploreContent(
                              key: ValueKey('Explore_$_exploreSubPage'),
                              allSongs: allSongsData, 
                              initialSubPage: _exploreSubPage
                            )
                          : _currentMenu == 'Library'
                              ? const LibraryContent()
                               : _currentMenu == 'Settings'
                                  ? const SettingsContent()
                                  : _currentMenu == 'Play History'
                                      ? const PlayHistoryContent()
                                      : _currentMenu == 'Favourite'
                                          ? const FavouriteContent()
                                          : _currentMenu == 'Add Song'
                                              ? AddSongContent(
                                                  onBack: () => setState(
                                                      () => _currentMenu = 'Home'),
                                                )
                                              : _currentMenu == 'Downloaded'
                                                  ? const DownloadedContent()
                                                  : MainContent(
                                                      onViewHistory: () => setState(() {
                                                        _currentMenu = 'Play History';
                                                      }),
                                                      onViewNewReleases: () => setState(() {
                                                        _currentMenu = 'Explore';
                                                        _exploreSubPage = 'New Releases';
                                                      }),
                                                    ),
                    ),
                  ],
                ),
              ),

              // Divider between Content and Player Bar
              Divider(
                height: 1,
                thickness: 1,
                color: theme.borderColor,
              ),

              // Player Bar – has its own opaque background
              const PlayerBar(),
            ],
          ),
        ],
      ),
    );
  }
}
