import 'package:flutter/material.dart';

import '../generated/public_docs_catalog.g.dart';

typedef ShowcaseGuideLink = ({String id, String title, String url});

/// Supplies the current showcase route and public-link handler to page content.
///
/// This keeps guide discovery in the shared page chrome instead of requiring
/// every showcase page to duplicate hosted documentation URLs.
class ShowcaseGuideScope extends InheritedWidget {
  const ShowcaseGuideScope({
    super.key,
    required this.page,
    required this.onOpenPublicUrl,
    required super.child,
  });

  final String page;
  final ValueChanged<String> onOpenPublicUrl;

  static ShowcaseGuideScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShowcaseGuideScope>();
  }

  @override
  bool updateShouldNotify(ShowcaseGuideScope oldWidget) {
    return page != oldWidget.page ||
        onOpenPublicUrl != oldWidget.onOpenPublicUrl;
  }
}

/// Returns the primary hosted guide for a showcase route, when one exists.
///
/// Chart-family mappings and feature-guide mappings both come from the
/// generated public documentation catalog. Chart Workbench has an additional
/// Grammar mapping, so its dedicated Workbench guide is selected explicitly.
ShowcaseGuideLink? showcaseGuideForPage(String page) {
  final family = publicDocsChartFamilies
      .cast<PublicDocsChartFamilyEntry?>()
      .firstWhere((entry) => entry?.page == page, orElse: () => null);

  final preferredGuideId = switch (page) {
    'chart-workbench' => 'chart-workbench',
    _ => family?.guideId ?? _featureGuideIdForPage(page),
  };
  if (preferredGuideId == null) return null;

  final hosted = publicDocsHostedGuides
      .cast<PublicDocsHostedGuideEntry?>()
      .firstWhere((entry) => entry?.id == preferredGuideId, orElse: () => null);
  if (hosted == null) return null;

  return (
    id: hosted.id,
    title: hosted.title,
    url: '$publicDocsGuidesBaseUrl${hosted.path}',
  );
}

String? _featureGuideIdForPage(String page) {
  return publicDocsGuides
      .cast<PublicDocsGuideEntry?>()
      .firstWhere(
        (entry) => entry?.page == page && entry?.guideId != null,
        orElse: () => null,
      )
      ?.guideId;
}

/// Title-adjacent link used by every mapped chart showcase page.
class ShowcaseGuideButton extends StatelessWidget {
  const ShowcaseGuideButton({
    super.key,
    required this.guide,
    required this.onOpen,
  });

  final ShowcaseGuideLink guide;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open ${guide.title} guide',
      child: TextButton.icon(
        key: const ValueKey('chart-page-guide-button'),
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          visualDensity: VisualDensity.compact,
        ),
        onPressed: () => onOpen(guide.url),
        icon: const Icon(Icons.menu_book_outlined, size: 18),
        label: const Text('Guide'),
      ),
    );
  }
}
