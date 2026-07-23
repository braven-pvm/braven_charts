// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../generated/public_docs_catalog.g.dart';
import '../platform/open_public_url.dart';
import '../widgets/chart_type_catalog.dart';
import '../widgets/standard_options.dart';

const _guideGroupOrder = <String>[
  'Get started',
  'Interaction and display',
  'Data, authoring, and live updates',
  'Workbench, artifacts, and export',
  'API reference',
];

class DocumentationPage extends StatefulWidget {
  const DocumentationPage({super.key, required this.onOpenPage});

  final ValueChanged<String> onOpenPage;

  @override
  State<DocumentationPage> createState() => _DocumentationPageState();
}

class _DocumentationPageState extends State<DocumentationPage> {
  final _quickStartKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Documentation',
      subtitle:
          'Start with a runnable chart, then move from visual guides to exact API reference',
      chart: CustomScrollView(
        key: const ValueKey('documentation-home'),
        slivers: [
          SliverToBoxAdapter(
            child: _DocumentationIntroduction(
              onBuildFirstChart: _showQuickStart,
              onChooseChart: () => widget.onOpenPage('chart-types'),
              onBrowseApi: () => openPublicUrl(publicDocsApiBaseUrl),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          const SliverToBoxAdapter(
            child: _SectionHeading(
              eyebrow: 'PACKAGE CAPABILITIES',
              title: 'Explore by what you need to build',
              subtitle:
                  'Start with the job; each destination opens a runnable guide.',
            ),
          ),
          _FeatureGrid(onOpenPage: widget.onOpenPage),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _quickStartKey,
              child: const _SectionHeading(
                eyebrow: 'GET STARTED',
                title: 'Two ways to build the same chart',
                subtitle:
                    'Use immutable configuration directly or lower a checked typed Grammar to the same renderer.',
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _QuickStartExamples()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          const SliverToBoxAdapter(
            child: _SectionHeading(
              eyebrow: 'CHART FAMILIES',
              title: 'Choose the visual structure first',
              subtitle:
                  'Every family opens a runnable guide with curated presets and source.',
            ),
          ),
          _FamilyGrid(onOpenPage: widget.onOpenPage),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ..._guideSlivers(),
          const SliverToBoxAdapter(child: _ApiReferenceCallout()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  List<Widget> _guideSlivers() {
    return [
      for (final group in _guideGroupOrder) ...[
        SliverToBoxAdapter(
          child: _SectionHeading(
            eyebrow: 'DOCUMENTATION',
            title: group,
            subtitle: _guideGroupSubtitle(group),
          ),
        ),
        _GuideGrid(
          guides: publicDocsGuides
              .where((guide) => guide.group == group)
              .toList(growable: false),
          onOpen: _openGuide,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    ];
  }

  void _showQuickStart() {
    final context = _quickStartKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  void _openGuide(PublicDocsGuideEntry guide) {
    if (guide.page != null) {
      widget.onOpenPage(guide.page!);
      return;
    }
    if (guide.apiPath != null) {
      openPublicUrl('$publicDocsApiBaseUrl${guide.apiPath}');
      return;
    }
    if (guide.path != null) {
      openPublicUrl('$publicDocsRepositoryBaseUrl${guide.path}');
      return;
    }
    _showQuickStart();
  }
}

class _DocumentationIntroduction extends StatelessWidget {
  const _DocumentationIntroduction({
    required this.onBuildFirstChart,
    required this.onChooseChart,
    required this.onBrowseApi,
  });

  final VoidCallback onBuildFirstChart;
  final VoidCallback onChooseChart;
  final VoidCallback onBrowseApi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build a chart. Understand the system. Find the exact API.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Text(
                    'Start with a runnable chart, choose a family by its data question, or jump to generated member reference.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('docs-build-first-chart'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: onBuildFirstChart,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Build first chart'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('docs-choose-family'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: onChooseChart,
                      icon: const Icon(Icons.show_chart),
                      label: const Text('Choose chart family'),
                    ),
                    TextButton.icon(
                      key: const ValueKey('docs-browse-api'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: onBrowseApi,
                      icon: const Icon(Icons.code),
                      label: const Text('Browse API reference'),
                    ),
                  ],
                ),
              ],
            );

            if (constraints.maxWidth < 980) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  copy,
                  const SizedBox(height: 24),
                  const _ReferenceSummary(horizontal: true),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: copy),
                const SizedBox(width: 32),
                const Expanded(
                  flex: 2,
                  child: _ReferenceSummary(horizontal: false),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReferenceSummary extends StatelessWidget {
  const _ReferenceSummary({required this.horizontal});

  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = [
      ('10', 'families'),
      ('6', 'guide groups'),
      ('1', 'API index'),
    ];
    final children = [
      for (var index = 0; index < items.length; index++) ...[
        if (index > 0)
          SizedBox(width: horizontal ? 20 : 0, height: horizontal ? 0 : 14),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${items[index].$1} ',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              TextSpan(text: items[index].$2),
            ],
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onPrimaryContainer,
          ),
        ),
      ],
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: horizontal
          ? Row(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  if (index.isEven)
                    Expanded(child: children[index])
                  else
                    children[index],
                ],
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.35,
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.onOpenPage});

  final ValueChanged<String> onOpenPage;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.crossAxisExtent / 320)
            .floor()
            .clamp(1, 3)
            .toInt();
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 128,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final feature = publicDocsFeatures[index];
            return _CapabilityCard(
              key: ValueKey('docs-feature-${feature.id}'),
              icon: _featureIcon(feature.id),
              title: feature.title,
              summary: feature.summary,
              actionLabel: _featureAction(feature.id),
              onOpen: () => onOpenPage(feature.page),
            );
          }, childCount: publicDocsFeatures.length),
        );
      },
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({
    super.key,
    required this.icon,
    required this.title,
    required this.summary,
    required this.actionLabel,
    required this.onOpen,
  });

  final IconData icon;
  final String title;
  final String summary;
  final String actionLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: '$title. $summary. $actionLabel.',
      child: ExcludeSemantics(
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(
                            alpha: 0.55,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 18, color: scheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: actionLabel,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyGrid extends StatelessWidget {
  const _FamilyGrid({required this.onOpenPage});

  final ValueChanged<String> onOpenPage;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.crossAxisExtent / 230)
            .floor()
            .clamp(1, 4)
            .toInt();
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 250,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final family = publicDocsChartFamilies[index];
            final runtime = showcaseChartTypeForSlug(family.page);
            return ChartTypeCatalogCard(
              chartType: runtime,
              compact: true,
              onOpen: () => onOpenPage(family.page),
            );
          }, childCount: publicDocsChartFamilies.length),
        );
      },
    );
  }
}

class _QuickStartExamples extends StatefulWidget {
  const _QuickStartExamples();

  @override
  State<_QuickStartExamples> createState() => _QuickStartExamplesState();
}

class _QuickStartExamplesState extends State<_QuickStartExamples> {
  var _selectedSnippetId = publicDocsSnippets.first.id;
  var _wrapLines = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final selected = publicDocsSnippets.firstWhere(
          (snippet) => snippet.id == _selectedSnippetId,
        );
        return Container(
          key: const ValueKey('docs-snippet-viewer'),
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SegmentedButton<String>(
                      key: const ValueKey('docs-snippet-form-toggle'),
                      showSelectedIcon: false,
                      segments: [
                        for (final snippet in publicDocsSnippets)
                          ButtonSegment<String>(
                            value: snippet.id,
                            label: Text(_snippetFormLabel(snippet.id)),
                            tooltip: snippet.title,
                          ),
                      ],
                      selected: {_selectedSnippetId},
                      onSelectionChanged: (selection) =>
                          setState(() => _selectedSnippetId = selection.single),
                    ),
                    Text(
                      'Dart · ${selected.title}',
                      style: theme.textTheme.labelLarge,
                    ),
                    IconButton(
                      tooltip: _wrapLines
                          ? 'Disable line wrapping'
                          : 'Wrap lines',
                      onPressed: () => setState(() => _wrapLines = !_wrapLines),
                      icon: Icon(
                        _wrapLines ? Icons.wrap_text : Icons.horizontal_rule,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      key: const ValueKey('docs-copy-snippet'),
                      onPressed: () => _copySnippet(context, selected),
                      icon: const Icon(Icons.copy_all_outlined),
                      label: const Text('Copy code'),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: scheme.outlineVariant),
              SizedBox(
                height: constraints.maxWidth < 600 ? 360 : 420,
                child: KeyedSubtree(
                  key: ValueKey('docs-snippet-${selected.id}'),
                  child: ChartCodeBlock(
                    code: selected.source,
                    wrapLines: _wrapLines,
                    semanticLabel: '${selected.title} Dart example',
                    surfaceKey: const ValueKey('docs-snippet-code-window'),
                    codeKey: const ValueKey('docs-snippet-code'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _copySnippet(
    BuildContext context,
    PublicDocsSnippetEntry snippet,
  ) async {
    await Clipboard.setData(ClipboardData(text: snippet.source));
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null && Scaffold.maybeOf(context) != null) {
      messenger.showSnackBar(
        SnackBar(content: Text('${snippet.title} copied')),
      );
    }
  }
}

class _GuideGrid extends StatelessWidget {
  const _GuideGrid({required this.guides, required this.onOpen});

  final List<PublicDocsGuideEntry> guides;
  final ValueChanged<PublicDocsGuideEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.crossAxisExtent / 340)
            .floor()
            .clamp(1, 3)
            .toInt();
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 154,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final guide = guides[index];
            return _DestinationCard(
              icon: _guideIcon(guide),
              title: guide.title,
              summary: guide.summary,
              actionLabel: _guideAction(guide),
              onOpen: () => onOpen(guide),
            );
          }, childCount: guides.length),
        );
      },
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.icon,
    required this.title,
    required this.summary,
    required this.actionLabel,
    required this.onOpen,
  });

  final IconData icon;
  final String title;
  final String summary;
  final String actionLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 19, color: scheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      actionLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 17, color: scheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApiReferenceCallout extends StatelessWidget {
  const _ApiReferenceCallout();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need an exact constructor, property, or controller?',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'The generated API reference indexes every supported public library and member, with source links and search.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  height: 1.45,
                ),
              ),
            ],
          );
          final action = FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => openPublicUrl(publicDocsApiBaseUrl),
            icon: const Icon(Icons.code),
            label: const Text('Browse generated API'),
          );
          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                copy,
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerLeft, child: action),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 24),
              action,
            ],
          );
        },
      ),
    );
  }
}

IconData _featureIcon(String id) => switch (id) {
  'chart-families' => Icons.show_chart,
  'interaction-selection' => Icons.select_all,
  'multi-axis-analysis' => Icons.align_vertical_bottom,
  'typed-authoring' => Icons.auto_awesome_motion_outlined,
  'live-rendering' => Icons.bolt,
  'product-surfaces' => Icons.view_week_outlined,
  _ => Icons.article_outlined,
};

String _featureAction(String id) => switch (id) {
  'chart-families' => 'Choose a chart',
  'interaction-selection' => 'Explore selection',
  'multi-axis-analysis' => 'Explore multi-axis',
  'typed-authoring' => 'Open Chart Grammar',
  'live-rendering' => 'Open live data',
  'product-surfaces' => 'Open Workbench',
  _ => 'Open guide',
};

String _snippetFormLabel(String id) => switch (id) {
  'basic-line' => 'Direct',
  'basic-grammar' => 'Grammar',
  _ => 'Example',
};

IconData _guideIcon(PublicDocsGuideEntry guide) {
  if (guide.apiPath != null) return Icons.code;
  if (guide.snippet != null) return Icons.play_arrow_rounded;
  if (guide.page != null) return Icons.open_in_browser;
  return Icons.article_outlined;
}

String _guideAction(PublicDocsGuideEntry guide) {
  if (guide.apiPath != null) return 'Browse API';
  if (guide.snippet != null && guide.page == null) return 'View starter code';
  if (guide.page != null) return 'Open runnable guide';
  return 'Open guide';
}

String _guideGroupSubtitle(String group) => switch (group) {
  'Get started' =>
    'Install the package, create a chart, and choose the right family.',
  'Interaction and display' =>
    'Compose the feedback, navigation, axes, and presentation users experience.',
  'Data, authoring, and live updates' =>
    'Choose an authoring model and keep changing datasets efficient.',
  'Workbench, artifacts, and export' =>
    'Move charts between interactive, tabular, generated, and portable forms.',
  'API reference' =>
    'Move from capability-level guidance to exact public symbols.',
  _ => '',
};
