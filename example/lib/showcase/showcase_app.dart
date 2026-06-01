// Copyright 2025 Braven Charts - Showcase App
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import 'pages/annotations_page.dart';
import 'pages/chart_types_page.dart';
import 'pages/lactate_threshold_page.dart';
import 'pages/gallery_page.dart';
import 'pages/interaction_page.dart';
import 'pages/live_streaming_page.dart';
import 'pages/multi_axis_page.dart';
import 'pages/performance_page.dart';
import 'pages/power_lactate_page.dart';
import 'pages/scientific_page.dart';
import 'pages/segment_styling_page.dart';
import 'pages/streaming_page.dart';
import 'pages/theming_page.dart';
import 'pages/axis_render_range_page.dart';
import 'pages/data_point_labels_page.dart';
import 'pages/minor_ticks_page.dart';
import 'pages/axis_slot_demo_page.dart';
import 'pages/baseline_area_demo_page.dart';
import 'pages/series_styling_page.dart';
import 'pages/tracking_page.dart';

/// Main showcase application demonstrating all BravenChartPlus capabilities.
///
/// Features adaptive navigation:
/// - Bottom navigation on mobile (< 600dp width)
/// - Navigation rail on tablet/desktop (>= 600dp width)
/// - Extended rail with labels on wide screens (>= 900dp width)
class ShowcaseApp extends StatelessWidget {
  const ShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BravenChartPlus Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(elevation: 2, margin: EdgeInsets.all(8)),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(elevation: 2, margin: EdgeInsets.all(8)),
      ),
      themeMode: ThemeMode.system,
      home: const ShowcaseHome(),
    );
  }
}

/// Navigation destination configuration.
class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
    this.badge,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
  final String? badge;
}

/// Home page with adaptive navigation layout.
class ShowcaseHome extends StatefulWidget {
  const ShowcaseHome({super.key});

  @override
  State<ShowcaseHome> createState() => _ShowcaseHomeState();
}

class _ShowcaseHomeState extends State<ShowcaseHome> {
  int _selectedIndex = 0;

  /// All navigation destinations in the showcase.
  static final List<NavDestination> _destinations = [
    const NavDestination(
      label: 'Gallery',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      page: GalleryPage(),
      badge: '★', // Featured overview
    ),
    const NavDestination(
      label: 'Chart Types',
      icon: Icons.show_chart_outlined,
      selectedIcon: Icons.show_chart,
      page: ChartTypesPage(),
    ),
    const NavDestination(
      label: 'Segment Styling',
      icon: Icons.format_color_fill_outlined,
      selectedIcon: Icons.format_color_fill,
      page: SegmentStylingPage(),
      badge: '★', // New feature
    ),
    const NavDestination(
      label: 'Interaction',
      icon: Icons.touch_app_outlined,
      selectedIcon: Icons.touch_app,
      page: InteractionPage(),
    ),
    const NavDestination(
      label: 'Tracking Lab',
      icon: Icons.track_changes_outlined,
      selectedIcon: Icons.track_changes,
      page: TrackingPage(),
      badge: '★',
    ),
    const NavDestination(
      label: 'Power + Lactate',
      icon: Icons.directions_bike_outlined,
      selectedIcon: Icons.directions_bike,
      page: PowerLactatePage(),
      badge: 'NEW',
    ),
    const NavDestination(
      label: 'Lactate Threshold',
      icon: Icons.science_outlined,
      selectedIcon: Icons.science,
      page: LactateThresholdPage(),
      badge: 'NEW',
    ),
    const NavDestination(
      label: 'Annotations',
      icon: Icons.edit_note_outlined,
      selectedIcon: Icons.edit_note,
      page: AnnotationsPage(),
    ),
    const NavDestination(
      label: 'Streaming',
      icon: Icons.stream_outlined,
      selectedIcon: Icons.stream,
      page: StreamingPage(),
    ),
    const NavDestination(
      label: 'Live Stream',
      icon: Icons.bolt_outlined,
      selectedIcon: Icons.bolt,
      page: LiveStreamingPage(),
      badge: '★', // New high-performance API
    ),
    // const NavDestination(
    //   label: 'Timer Test',
    //   icon: Icons.timer_outlined,
    //   selectedIcon: Icons.timer,
    //   page: TimerTestPage(),
    //   badge: 'TEST', // Standalone timer test
    // ),
    const NavDestination(
      label: 'Theming',
      icon: Icons.palette_outlined,
      selectedIcon: Icons.palette,
      page: ThemingPage(),
    ),
    const NavDestination(
      label: 'Performance',
      icon: Icons.speed_outlined,
      selectedIcon: Icons.speed,
      page: PerformancePage(),
    ),
    const NavDestination(
      label: 'Multi-Axis',
      icon: Icons.align_vertical_bottom_outlined,
      selectedIcon: Icons.align_vertical_bottom,
      page: MultiAxisPage(),
      badge: '★', // Star feature
    ),
    const NavDestination(
      label: 'Scientific',
      icon: Icons.science_outlined,
      selectedIcon: Icons.science,
      page: ScientificPage(),
    ),
    const NavDestination(
      label: 'Minor Ticks',
      icon: Icons.linear_scale_outlined,
      selectedIcon: Icons.linear_scale,
      page: MinorTicksPage(),
      badge: 'NEW',
    ),
    const NavDestination(
      label: 'Render Range',
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune,
      page: AxisRenderRangePage(),
      badge: 'NEW',
    ),
    const NavDestination(
      label: 'Point Labels',
      icon: Icons.label_outline,
      selectedIcon: Icons.label,
      page: DataPointLabelsPage(),
      badge: 'NEW',
    ),
    const NavDestination(
      label: 'Series Styling',
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome,
      page: SeriesStylingPage(),
      badge: 'NEW',
    ),
    const NavDestination(
      label: 'Axis Slots',
      icon: Icons.swap_vert_outlined,
      selectedIcon: Icons.swap_vert,
      page: AxisSlotDemoPage(),
      badge: 'NEW',
    ),
    const NavDestination(
      label: 'Baseline Fill',
      icon: Icons.area_chart_outlined,
      selectedIcon: Icons.area_chart,
      page: BaselineAreaDemoPage(),
      badge: 'NEW',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Adaptive layout breakpoints
    if (width < 600) {
      return _buildMobileLayout();
    } else if (width < 900) {
      return _buildTabletLayout(extended: false);
    } else {
      return _buildTabletLayout(extended: true);
    }
  }

  /// Mobile layout with bottom navigation bar.
  Widget _buildMobileLayout() {
    return Scaffold(
      body: _destinations[_selectedIndex].page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: _destinations.map((dest) {
          return NavigationDestination(
            icon: Icon(dest.icon),
            selectedIcon: dest.badge != null
                ? Badge(
                    label: Text(dest.badge!),
                    child: Icon(dest.selectedIcon),
                  )
                : Icon(dest.selectedIcon),
            label: dest.label,
          );
        }).toList(),
      ),
    );
  }

  /// Tablet/desktop layout with scrollable navigation sidebar.
  Widget _buildTabletLayout({required bool extended}) {
    return Scaffold(
      body: Row(
        children: [
          _ScrollableNav(
            extended: extended,
            destinations: _destinations,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: _destinations[_selectedIndex].page),
        ],
      ),
    );
  }
}

/// Scrollable navigation sidebar — replaces [NavigationRail] which has no
/// built-in scroll support and overflows when the destination list is long.
class _ScrollableNav extends StatelessWidget {
  const _ScrollableNav({
    required this.extended,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final bool extended;
  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final width = extended ? 256.0 : 88.0;

    return SizedBox(
      width: width,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: extended
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Braven Charts',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : const Icon(Icons.bar_chart, size: 32),
          ),
          // Scrollable destinations
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(destinations.length, (i) {
                  final dest = destinations[i];
                  final isSelected = i == selectedIndex;
                  final icon = Icon(
                    isSelected ? dest.selectedIcon : dest.icon,
                    color: isSelected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                    size: 22,
                  );
                  final badgedIcon = dest.badge != null
                      ? Badge(label: Text(dest.badge!), child: icon)
                      : icon;

                  return InkWell(
                    onTap: () => onDestinationSelected(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      padding: EdgeInsets.symmetric(
                        horizontal: extended ? 12 : 0,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.secondaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: extended
                          ? Row(
                              children: [
                                const SizedBox(width: 4),
                                badgedIcon,
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    dest.label,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: isSelected
                                          ? colorScheme.onSecondaryContainer
                                          : colorScheme.onSurfaceVariant,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : Center(child: badgedIcon),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
