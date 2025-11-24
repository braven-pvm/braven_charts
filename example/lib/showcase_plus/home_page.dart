import 'package:flutter/material.dart';

import 'pages/annotations_page.dart';
import 'pages/chart_types_page.dart';
import 'pages/interaction_page.dart';
import 'pages/performance_page.dart';
import 'pages/streaming_page.dart';
import 'pages/theming_page.dart';

class ShowcaseHomePage extends StatefulWidget {
  const ShowcaseHomePage({super.key});

  @override
  State<ShowcaseHomePage> createState() => _ShowcaseHomePageState();
}

class _ShowcaseHomePageState extends State<ShowcaseHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ChartTypesPage(),
    const InteractionPage(),
    const AnnotationsPage(),
    const StreamingPage(),
    const ThemingPage(),
    const PerformancePage(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Types'),
    NavigationDestination(icon: Icon(Icons.touch_app), label: 'Interaction'),
    NavigationDestination(icon: Icon(Icons.label), label: 'Annotations'),
    NavigationDestination(icon: Icon(Icons.stream), label: 'Streaming'),
    NavigationDestination(icon: Icon(Icons.palette), label: 'Theming'),
    NavigationDestination(icon: Icon(Icons.speed), label: 'Performance'),
  ];

  @override
  Widget build(BuildContext context) {
    // Use a layout that adapts to screen width
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          // Mobile/Narrow layout: Bottom Navigation
          return Scaffold(
            body: _pages[_selectedIndex],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: _destinations,
            ),
          );
        } else {
          // Desktop/Wide layout: Navigation Rail
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: _destinations.map((d) {
                    return NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    );
                  }).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: _pages[_selectedIndex],
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
