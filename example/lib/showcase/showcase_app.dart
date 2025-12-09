// Copyright 2025 Braven Charts - Showcase App
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import 'pages/annotations_page.dart';
import 'pages/chart_types_page.dart';
import 'pages/gallery_page.dart';
import 'pages/interaction_page.dart';
import 'pages/live_streaming_page.dart';
import 'pages/multi_axis_page.dart';
import 'pages/performance_page.dart';
import 'pages/scientific_page.dart';
import 'pages/segment_styling_page.dart';
import 'pages/streaming_page.dart';
import 'pages/theming_page.dart';

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
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.all(8),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.all(8),
        ),
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

  /// Tablet/desktop layout with navigation rail.
  Widget _buildTabletLayout({required bool extended}) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: extended
                  ? const Text(
                      'Braven Charts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Icon(Icons.bar_chart, size: 32),
            ),
            destinations: _destinations.map((dest) {
              return NavigationRailDestination(
                icon: Icon(dest.icon),
                selectedIcon: dest.badge != null
                    ? Badge(
                        label: Text(dest.badge!),
                        child: Icon(dest.selectedIcon),
                      )
                    : Icon(dest.selectedIcon),
                label: Text(dest.label),
              );
            }).toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: _destinations[_selectedIndex].page,
          ),
        ],
      ),
    );
  }
}
