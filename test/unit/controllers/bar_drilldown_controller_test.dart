import 'dart:async';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BarDrillNode node(
    String id, {
    List<BarDrillNode> children = const [],
    bool lazy = false,
  }) => BarDrillNode(
    id: id,
    label: id.toUpperCase(),
    series: [
      BarChartSeries(
        id: '$id-series',
        name: id,
        points: const [ChartDataPoint(x: 0, y: 1)],
        barWidthPercent: 0.7,
      ),
    ],
    children: children,
    mayHaveLazyChildren: lazy,
  );

  test('navigates down, up, and directly to an ancestor', () async {
    final leaf = node('leaf');
    final branch = node('branch', children: [leaf]);
    final controller = BarDrilldownController(
      config: BarDrilldownConfig(root: node('root', children: [branch])),
    );

    expect(await controller.drillTo('branch'), isTrue);
    expect(await controller.drillTo('leaf'), isTrue);
    expect(controller.path.map((value) => value.id), [
      'root',
      'branch',
      'leaf',
    ]);
    expect(controller.navigateToAncestor('root'), isTrue);
    expect(controller.current.id, 'root');
    expect(controller.up(), isFalse);
  });

  test('rejects duplicate stable node identities', () {
    expect(
      () => BarDrilldownController(
        config: BarDrilldownConfig(
          root: node('root', children: [node('same'), node('same')]),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('ignores a stale lazy response after navigating up', () async {
    final completer = Completer<List<BarDrillNode>>();
    final lazy = node('lazy', lazy: true);
    final controller = BarDrilldownController(
      config: BarDrilldownConfig(root: node('root', children: [lazy])),
      resolver: (_) => completer.future,
    );

    final navigation = controller.drillTo('lazy');
    expect(controller.status, BarDrilldownStatus.loading);
    expect(controller.up(), isTrue);
    completer.complete([node('late')]);
    await navigation;

    expect(controller.current.id, 'root');
    expect(controller.status, BarDrilldownStatus.ready);
  });

  test('surfaces lazy failures and retries the current node', () async {
    var attempts = 0;
    final controller = BarDrilldownController(
      config: BarDrilldownConfig(
        root: node('root', children: [node('lazy', lazy: true)]),
      ),
      resolver: (_) async {
        attempts++;
        if (attempts == 1) throw StateError('offline');
        return [node('resolved')];
      },
    );

    await controller.drillTo('lazy');
    expect(controller.status, BarDrilldownStatus.error);
    await controller.retry();
    expect(controller.status, BarDrilldownStatus.ready);
    expect(controller.current.children.single.id, 'resolved');
  });

  test('reuses resolved lazy children when a level is revisited', () async {
    var calls = 0;
    final controller = BarDrilldownController(
      config: BarDrilldownConfig(
        root: node('root', children: [node('lazy', lazy: true)]),
      ),
      resolver: (_) async {
        calls++;
        return [node('resolved')];
      },
    );

    await controller.drillTo('lazy');
    expect(controller.current.children.single.id, 'resolved');
    controller.up();
    await controller.drillTo('lazy');

    expect(calls, 1);
    expect(controller.current.children.single.id, 'resolved');
  });
}
