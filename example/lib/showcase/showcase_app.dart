// Copyright 2025 Braven Charts - Showcase App
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pages/annotations_page.dart';
import 'pages/axes_page.dart';
import 'pages/artifact_showcase_page.dart';
import 'pages/bar_lab_page.dart';
import 'pages/chart_types_page.dart';
import 'pages/chart_workbench_page.dart';
import 'pages/candlestick_geometry_lab_page.dart';
import 'pages/candlestick_charts_page.dart';
import 'pages/cartesian_chart_type_pages.dart';
import 'pages/chart_grammar_page.dart';
import 'pages/concentric_donut_page.dart';
import 'pages/donut_charts_page.dart';
import 'pages/documentation_page.dart';
import 'pages/gallery_page.dart';
import 'pages/technical_indicators_page.dart';
import 'pages/interaction_page.dart';
import 'pages/live_streaming_page.dart';
import 'pages/loading_states_page.dart';
import 'pages/multi_axis_page.dart';
import 'pages/mobile_showcase_page.dart';
import 'pages/mobile_interaction_page.dart';
import 'pages/performance_page.dart';
import 'pages/pie_charts_page.dart';
import 'pages/polar_column_page.dart';
import 'pages/range_area_charts_page.dart';
import 'pages/scientific_page.dart';
import 'pages/selection_showcase_page.dart';
import 'pages/theming_page.dart';
import 'pages/baseline_area_demo_page.dart';
import 'pages/series_styling_page.dart';
import 'pages/value_summary_page.dart';
import 'widgets/braven_brand.dart';
import 'widgets/chart_type_catalog.dart';
import 'widgets/donut_gallery_cards.dart';
import 'widgets/polar_column_gallery_cards.dart';
import 'widgets/gallery_flagships.dart';

/// Main showcase application demonstrating all BravenChartPlus capabilities.
///
/// Features adaptive navigation:
/// - Focused chart-family browser on phones (< 600dp width)
/// - Navigation sidebar on tablet/desktop (>= 600dp width)
/// - Extended rail with labels on wide screens (>= 900dp width)
class ShowcaseApp extends StatelessWidget {
  const ShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Braven Charts Showcase',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const ShowcaseHome(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5),
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.all(8),
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationDrawerTheme: const NavigationDrawerThemeData(
        indicatorColor: Colors.transparent,
        indicatorShape: RoundedRectangleBorder(),
      ),
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
    this.routeSlug,
    this.routeAliases = const [],
    this.parentSlug,
    this.reviewProposal,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
  final String? routeSlug;
  final List<String> routeAliases;
  final String? parentSlug;
  final ShowcaseReviewProposal? reviewProposal;

  bool get isNested => parentSlug != null;

  String? get navigationSection => switch (parentSlug) {
    'chart-types' => 'CHART TYPE GUIDES',
    'financial' => 'FINANCIAL',
    _ => null,
  };

  bool matchesSlug(String? requestedSlug) =>
      slug == requestedSlug || routeAliases.contains(requestedSlug);

  String get slug =>
      routeSlug ??
      label
          .toLowerCase()
          .replaceAll('+', ' ')
          .replaceAll(RegExp('[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'(^-|-$)'), '');
}

/// Release-review note for a page that may be merged, renamed, or removed.
///
/// These proposals are deliberately visual only. No destination is removed
/// until the release information architecture is approved.
class ShowcaseReviewProposal {
  const ShowcaseReviewProposal({required this.action, required this.reason});

  final String action;
  final String reason;
}

/// Home page with adaptive navigation layout.
class ShowcaseHome extends StatefulWidget {
  const ShowcaseHome({super.key, this.requestedPageOverride});

  /// Test and embedder override for the initial direct-route destination.
  ///
  /// The hosted application leaves this null and reads `?page=` from
  /// [Uri.base].
  final String? requestedPageOverride;

  @override
  State<ShowcaseHome> createState() => _ShowcaseHomeState();
}

class _ShowcaseHomeState extends State<ShowcaseHome> {
  late int _selectedIndex;
  late final List<NavDestination> _destinations;
  late final ChartWorkbenchGroupController _workbenchGroupController;

  /// All navigation destinations in the showcase.
  List<NavDestination> _buildDestinations() => [
    NavDestination(
      label: 'Gallery',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      page: GalleryPage(onOpenChartType: _selectSlug),
    ),
    NavDestination(
      label: 'Chart Types',
      icon: Icons.show_chart_outlined,
      selectedIcon: Icons.show_chart,
      page: ChartTypesPage(onOpenChartType: _selectSlug),
    ),
    NavDestination(
      label: 'Documentation',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      page: DocumentationPage(onOpenPage: _selectSlug),
      routeSlug: 'docs',
    ),
    ...showcaseChartTypes
        .where((chartType) => chartType.slug != 'candlestick-charts')
        .map(
          (chartType) => NavDestination(
            label: '${chartType.label} Charts',
            icon: chartType.icon,
            selectedIcon: chartType.icon,
            page: _pageForChartType(chartType.slug),
            routeSlug: chartType.slug,
            routeAliases: chartType.slug == 'bar-charts'
                ? const ['bar-lab']
                : const [],
            parentSlug: 'chart-types',
          ),
        ),
    const NavDestination(
      label: 'Candlestick Charts',
      icon: Icons.candlestick_chart_outlined,
      selectedIcon: Icons.candlestick_chart,
      page: CandlestickChartsPage(),
      routeSlug: 'candlestick-charts',
      parentSlug: 'financial',
    ),
    const NavDestination(
      label: 'Technical Indicators',
      icon: Icons.monitor_heart_outlined,
      selectedIcon: Icons.monitor_heart,
      page: TechnicalIndicatorsPage(),
      routeSlug: 'technical-indicators',
      parentSlug: 'financial',
    ),
    const NavDestination(
      label: 'Interaction',
      icon: Icons.touch_app_outlined,
      selectedIcon: Icons.touch_app,
      page: InteractionPage(),
    ),
    const NavDestination(
      label: 'Mobile Interaction',
      icon: Icons.touch_app_outlined,
      selectedIcon: Icons.touch_app,
      page: MobileInteractionPage(),
      routeSlug: 'mobile-interaction',
    ),
    const NavDestination(
      label: 'Selection',
      icon: Icons.select_all_outlined,
      selectedIcon: Icons.select_all,
      page: SelectionShowcasePage(),
      routeSlug: 'selection',
    ),
    const NavDestination(
      label: 'Tracking & Value Display',
      icon: Icons.summarize_outlined,
      selectedIcon: Icons.summarize,
      page: ValueSummaryPage(),
      routeSlug: 'value-summary',
    ),
    const NavDestination(
      label: 'Chart Grammar',
      icon: Icons.auto_awesome_motion_outlined,
      selectedIcon: Icons.auto_awesome_motion,
      page: ChartGrammarPage(),
      routeSlug: 'chart-grammar',
    ),
    const NavDestination(
      label: 'Annotations',
      icon: Icons.edit_note_outlined,
      selectedIcon: Icons.edit_note,
      page: AnnotationsPage(),
    ),
    const NavDestination(
      label: 'Live Stream',
      icon: Icons.bolt_outlined,
      selectedIcon: Icons.bolt,
      page: LiveStreamingPage(),
    ),
    // const NavDestination(
    //   label: 'Timer Test',
    //   icon: Icons.timer_outlined,
    //   selectedIcon: Icons.timer,
    //   page: TimerTestPage(),
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
      label: 'Axes',
      icon: Icons.grid_4x4_outlined,
      selectedIcon: Icons.grid_4x4,
      page: AxesPage(),
    ),
    const NavDestination(
      label: 'Multi-Axis',
      icon: Icons.align_vertical_bottom_outlined,
      selectedIcon: Icons.align_vertical_bottom,
      page: MultiAxisPage(),
    ),
    const NavDestination(
      label: 'Scientific',
      icon: Icons.science_outlined,
      selectedIcon: Icons.science,
      page: ScientificPage(),
    ),
    const NavDestination(
      label: 'Series Styling',
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome,
      page: SeriesStylingPage(),
    ),
    const NavDestination(
      label: 'Baseline Fill',
      icon: Icons.area_chart_outlined,
      selectedIcon: Icons.area_chart,
      page: BaselineAreaDemoPage(),
    ),
    const NavDestination(
      label: 'Loading States',
      icon: Icons.hourglass_empty_outlined,
      selectedIcon: Icons.hourglass_top,
      page: LoadingStatesPage(),
    ),
    const NavDestination(
      label: 'Chart Artifacts',
      icon: Icons.hub_outlined,
      selectedIcon: Icons.hub,
      page: ArtifactShowcasePage(),
      routeSlug: 'artifact-showcase',
    ),
    const NavDestination(
      label: 'Chart Workbench',
      icon: Icons.view_week_outlined,
      selectedIcon: Icons.view_week,
      page: ChartWorkbenchPage(),
      routeSlug: 'chart-workbench',
    ),
  ];

  Widget _pageForChartType(String slug) => switch (slug) {
    'line-charts' => const LineChartsPage(),
    'area-charts' => const AreaChartsPage(),
    'range-area-charts' => const RangeAreaChartsPage(),
    'bar-charts' => const BarLabPage(),
    'scatter-charts' => const ScatterChartsPage(),
    'candlestick-charts' => const CandlestickChartsPage(),
    'pie-charts' => const PieChartsPage(),
    'donut-charts' => const DonutChartsPage(),
    'concentric-donut' => const ConcentricDonutPage(),
    'polar-column' => const PolarColumnPage(),
    _ => throw StateError('No showcase page is registered for $slug'),
  };

  @override
  void initState() {
    super.initState();
    _workbenchGroupController = ChartWorkbenchGroupController(
      initialDisplayMode: _requestedWorkbenchMode,
    );
    _destinations = _buildDestinations();
    final requestedPage =
        widget.requestedPageOverride ?? Uri.base.queryParameters['page'];
    final requestedIndex = _destinations.indexWhere(
      (destination) => destination.matchesSlug(requestedPage),
    );
    _selectedIndex = requestedIndex < 0 ? 0 : requestedIndex;
  }

  ChartDisplayMode get _requestedWorkbenchMode {
    final requested = Uri.base.queryParameters['view'];
    return ChartDisplayMode.values.firstWhere(
      (mode) => mode.name == requested,
      orElse: () => ChartDisplayMode.chart,
    );
  }

  @override
  void dispose() {
    _workbenchGroupController.dispose();
    super.dispose();
  }

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
    final location = Uri(
      path: Uri.base.path,
      queryParameters: {'page': _destinations[index].slug},
    ).toString();
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(location),
      replace: true,
    );
  }

  void _selectSlug(String slug) {
    final index = _destinations.indexWhere(
      (destination) => destination.matchesSlug(slug),
    );
    if (index >= 0) _selectDestination(index);
  }

  @override
  Widget build(BuildContext context) {
    return ChartWorkbenchScope(
      controller: _workbenchGroupController,
      child: _buildScopedContent(context),
    );
  }

  Widget _buildScopedContent(BuildContext context) {
    final capture = Uri.base.queryParameters['capture'];
    if (capture == 'candlestick-geometry') {
      return const CandlestickGeometryLabPage();
    }
    if (capture == 'hero-threshold' || capture == 'hero-session') {
      return const _HeroMediaCapture(
        panel: PerformanceIntelligenceHeroPanel.sessionProfile,
      );
    }
    if (capture == 'hero-duration') {
      return const _HeroMediaCapture(
        panel: PerformanceIntelligenceHeroPanel.powerDuration,
      );
    }
    if (capture == 'interaction-session') {
      return const _MediaCaptureFrame(
        child: PerformanceIntelligenceGalleryHero(
          panel: PerformanceIntelligenceHeroPanel.sessionProfile,
        ),
      );
    }
    if (capture == 'interaction-duration') {
      return const _MediaCaptureFrame(
        child: PerformanceIntelligenceGalleryHero(
          panel: PerformanceIntelligenceHeroPanel.powerDuration,
          showTracking: false,
        ),
      );
    }
    if (capture == 'donut-revenue') {
      return const _MediaCaptureFrame(child: RevenueRingGalleryCard());
    }
    if (capture == 'donut-gallery') {
      return const DonutGalleryMediaPanel();
    }
    if (capture == 'polar-column-gallery') {
      return const PolarColumnGalleryMediaPanel();
    }
    final width = MediaQuery.of(context).size.width;
    final selectedDestination = _destinations[_selectedIndex];

    if (selectedDestination.slug == 'docs' && width < 600) {
      return selectedDestination.page;
    }

    // Adaptive layout breakpoints
    if (width < 600) {
      final selectedSlug = _destinations[_selectedIndex].slug;
      if (selectedSlug == 'mobile-interaction') {
        return _destinations[_selectedIndex].page;
      }
      return MobileShowcasePage(
        initialChartSlug:
            showcaseChartTypes.any(
              (chartType) => chartType.slug == selectedSlug,
            )
            ? selectedSlug
            : null,
        onChartTypeSelected: _selectSlug,
      );
    } else if (width < 900) {
      return _buildTabletLayout(extended: false);
    } else {
      return _buildTabletLayout(extended: true);
    }
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
            onDestinationSelected: _selectDestination,
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: _buildSelectedPage()),
        ],
      ),
    );
  }

  Widget _buildSelectedPage() {
    final destination = _destinations[_selectedIndex];
    final proposal = destination.reviewProposal;
    if (proposal == null) return destination.page;

    return Column(
      children: [
        _ReviewProposalBanner(proposal: proposal),
        Expanded(child: destination.page),
      ],
    );
  }
}

/// Deterministic, navigation-free surface used by the media capture tool.
class _HeroMediaCapture extends StatelessWidget {
  const _HeroMediaCapture({required this.panel});

  final PerformanceIntelligenceHeroPanel panel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 552,
          height: 444,
          child: PerformanceIntelligenceGalleryHero(panel: panel),
        ),
      ),
    );
  }
}

/// Large, deterministic frame for focused animated package media.
///
/// The child is one of the same reusable compositions shown in the Gallery;
/// this surface only removes navigation and other showcase chrome.
class _MediaCaptureFrame extends StatelessWidget {
  const _MediaCaptureFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: SizedBox(width: 1200, height: 720, child: child)),
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
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: extended ? 16 : 12,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: BravenBrand(compact: !extended),
            ),
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
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 22,
                  );
                  final destinationTile = InkWell(
                    onTap: () => onDestinationSelected(i),
                    hoverColor: colorScheme.primary.withValues(alpha: 0.05),
                    highlightColor: colorScheme.primary.withValues(alpha: 0.08),
                    splashColor: colorScheme.primary.withValues(alpha: 0.08),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.fromLTRB(
                        dest.isNested && extended ? 16 : 0,
                        0,
                        8,
                        0,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: extended ? 12 : 0,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: extended
                            ? Border(
                                left: BorderSide(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : dest.isNested
                                      ? colorScheme.outlineVariant
                                      : Colors.transparent,
                                  width: isSelected ? 3 : 1,
                                ),
                              )
                            : null,
                      ),
                      child: extended
                          ? Row(
                              children: [
                                const SizedBox(width: 4),
                                icon,
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    dest.label,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (dest.reviewProposal != null) ...[
                                  const SizedBox(width: 6),
                                  const _ReviewBadge(compact: true),
                                ],
                              ],
                            )
                          : Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  icon,
                                  if (dest.reviewProposal != null)
                                    const Positioned(
                                      right: -6,
                                      top: -5,
                                      child: _ReviewDot(),
                                    ),
                                ],
                              ),
                            ),
                    ),
                  );
                  final tile = extended
                      ? destinationTile
                      : Tooltip(message: dest.label, child: destinationTile);
                  final startsNestedGroup =
                      dest.navigationSection != null &&
                      (i == 0 ||
                          dest.navigationSection !=
                              destinations[i - 1].navigationSection);
                  final endsNestedGroup =
                      i > 0 &&
                      destinations[i - 1].navigationSection != null &&
                      dest.navigationSection == null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (startsNestedGroup && extended)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 14, 12, 4),
                          child: Text(
                            dest.navigationSection!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      if (endsNestedGroup)
                        const Divider(indent: 16, endIndent: 16),
                      tile,
                    ],
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

class _ReviewBadge extends StatelessWidget {
  const _ReviewBadge({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.55)),
      ),
      child: Text(
        'Review',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onTertiaryContainer,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 9 : null,
        ),
      ),
    );
  }
}

class _ReviewDot extends StatelessWidget {
  const _ReviewDot();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Review candidate',
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: scheme.tertiary,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.surface, width: 1.5),
        ),
      ),
    );
  }
}

class _ReviewProposalBanner extends StatelessWidget {
  const _ReviewProposalBanner({required this.proposal});

  final ShowcaseReviewProposal proposal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.tertiaryContainer.withValues(alpha: 0.72),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: scheme.tertiary.withValues(alpha: 0.45)),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.rate_review_outlined, color: scheme.onTertiaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Review candidate · ',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: '${proposal.action}. ${proposal.reason}'),
                    const TextSpan(text: ' Nothing has been removed.'),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onTertiaryContainer,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
