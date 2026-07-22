// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Focused, cross-family verification surface for durable chart selection.
class SelectionShowcasePage extends StatefulWidget {
  const SelectionShowcasePage({super.key});

  @override
  State<SelectionShowcasePage> createState() => _SelectionShowcasePageState();
}

class _SelectionShowcasePageState extends State<SelectionShowcasePage> {
  final BravenChartController _chartController = BravenChartController();
  final ChartWorkbenchController _workbenchController =
      ChartWorkbenchController();
  final ChartOptionsController _chartOptionsController = ChartOptionsController(
    const ChartOptions(
      showDataMarkers: true,
      enableZoom: false,
      enablePan: false,
    ),
  );

  _SelectionFamily _family = _SelectionFamily.line;
  ChartSelectionOperation _operation = ChartSelectionOperation.replace;
  bool _useModifierKeys = true;
  bool _clearOnBackgroundTap = true;
  double _pointHitRadius = 20;
  double _seriesHitRadius = 22;
  double _dataPointHoverScale = 1.5;
  double _dataPointSelectionScale = 2.67;
  double _seriesHoverStrokeScale = 1.75;
  double _seriesSelectionStrokeScale = 1.5;
  bool _showDataPointHoverPopup = true;
  bool _showTrackingInformationPanel = true;
  double _barDimmedOpacity = 0.42;
  double _barSelectionOpacity = 0.14;
  double _barSelectionBorderWidth = 2.5;
  double _scatterHoverScale = 1.35;
  double _scatterSelectionScale = 1.25;
  double _scatterDimmedOpacity = 0.32;
  RadialSelectionEffect _radialSelectionEffect = RadialSelectionEffect.lift;
  double _radialSelectionScale = 1.08;
  double _radialSelectionOffset = 6;
  double _radialBackdropBlur = 1.25;
  ChartSelectionDragActivation _dragActivation =
      ChartSelectionDragActivation.primaryButton;
  ChartSelectionAcquisitionMode _acquisitionMode =
      ChartSelectionAcquisitionMode.point;
  ChartSelectionScope _selectionScope = ChartSelectionScope.markOrWholeSeries;

  @override
  void initState() {
    super.initState();
    final requested = Uri.base.queryParameters['family'];
    _family = _SelectionFamily.values.firstWhere(
      (family) => family.name == requested,
      orElse: () => _SelectionFamily.line,
    );
    _acquisitionMode = _family.defaultAcquisitionMode;
    _selectionScope = _family.defaultSelectionScope;
    _chartOptionsController.addListener(_handleChartOptionsChanged);
  }

  void _handleChartOptionsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _chartController.dispose();
    _workbenchController.dispose();
    _chartOptionsController
      ..removeListener(_handleChartOptionsChanged)
      ..dispose();
    super.dispose();
  }

  void _selectFamily(_SelectionFamily family) {
    if (_family == family) return;
    _chartController
      ..clearSelection()
      ..clearPointSelection();
    setState(() {
      _family = family;
      _acquisitionMode = family.defaultAcquisitionMode;
      _selectionScope = family.defaultSelectionScope;
    });
  }

  void _selectAcquisitionMode(ChartSelectionAcquisitionMode mode) {
    if (_acquisitionMode == mode) return;
    _clearSelection();
    setState(() => _acquisitionMode = mode);
  }

  void _selectScope(ChartSelectionScope scope) {
    if (_selectionScope == scope) return;
    _clearSelection();
    setState(() => _selectionScope = scope);
  }

  void _clearSelection() {
    _chartController
      ..clearSelection()
      ..clearPointSelection();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Selection lab',
      subtitle:
          'Compare durable point, series, group, range, and radial selection across every chart family',
      actions: [
        OutlinedButton.icon(
          key: const ValueKey('selection-lab-clear-header'),
          onPressed: _clearSelection,
          icon: const Icon(Icons.deselect_outlined, size: 18),
          label: const Text('Clear selection'),
        ),
      ],
      optionsChildren: _buildOptions(),
      chart: _buildWorkspace(),
    );
  }

  List<Widget> _buildOptions() => [
    OptionSection(
      title: 'Test case',
      icon: Icons.category_outlined,
      children: [
        EnumOption<_SelectionFamily>(
          key: const ValueKey('selection-lab-family-option'),
          label: 'Chart family',
          value: _family,
          values: _SelectionFamily.values,
          labelBuilder: (family) => family.label,
          onChanged: _selectFamily,
        ),
        InfoBox(message: _family.testPurpose),
      ],
    ),
    OptionSection(
      title: 'Selection policy',
      icon: Icons.ads_click_outlined,
      children: [
        EnumOption<ChartSelectionAcquisitionMode>(
          key: const ValueKey('selection-lab-acquisition-option'),
          label: 'Acquisition geometry',
          value: _acquisitionMode,
          values: _family.availableAcquisitionModes,
          labelBuilder: (mode) => mode.shortLabel,
          onChanged: _selectAcquisitionMode,
        ),
        EnumOption<ChartSelectionScope>(
          key: const ValueKey('selection-lab-scope-option'),
          label: 'Selection scope',
          value: _selectionScope,
          values: _family.availableSelectionScopes,
          labelBuilder: (scope) => scope.shortLabel,
          onChanged: _selectScope,
        ),
        EnumOption<ChartSelectionOperation>(
          key: const ValueKey('selection-lab-operation'),
          label: 'Default operation',
          value: _operation,
          values: ChartSelectionOperation.values,
          labelBuilder: _operationLabel,
          onChanged: (value) => setState(() => _operation = value),
        ),
        if (_acquisitionMode != ChartSelectionAcquisitionMode.point)
          EnumOption<ChartSelectionDragActivation>(
            key: const ValueKey('selection-lab-drag-activation'),
            label: 'Drag activation',
            value: _dragActivation,
            values: ChartSelectionDragActivation.values,
            labelBuilder: (value) => switch (value) {
              ChartSelectionDragActivation.primaryButton => 'Primary drag',
              ChartSelectionDragActivation.shiftPrimaryButton =>
                'Shift + primary drag',
            },
            onChanged: (value) => setState(() => _dragActivation = value),
          ),
        BoolOption(
          key: const ValueKey('selection-lab-modifiers'),
          label: 'Use modifier keys',
          subtitle: 'Shift adds, Ctrl/Cmd toggles, and Alt subtracts',
          value: _useModifierKeys,
          onChanged: (value) => setState(() => _useModifierKeys = value),
        ),
        BoolOption(
          key: const ValueKey('selection-lab-background-clear'),
          label: 'Clear on background tap',
          value: _clearOnBackgroundTap,
          onChanged: (value) => setState(() => _clearOnBackgroundTap = value),
        ),
      ],
    ),
    if (_family.isPathFamily)
      OptionSection(
        title: 'Path selection feedback',
        icon: Icons.gesture_outlined,
        initiallyExpanded: false,
        children: [
          SliderOption(
            key: const ValueKey('selection-lab-point-hit-radius'),
            label: 'Data point hit radius',
            value: _pointHitRadius,
            min: 4,
            max: 40,
            divisions: 18,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _pointHitRadius = value),
          ),
          SliderOption(
            key: const ValueKey('selection-lab-series-hit-radius'),
            label: 'Complete series hit radius',
            value: _seriesHitRadius,
            min: 4,
            max: 48,
            divisions: 22,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _seriesHitRadius = value),
          ),
          SliderOption(
            key: const ValueKey('selection-lab-point-hover-scale'),
            label: 'Data point hover scale',
            value: _dataPointHoverScale,
            min: 1,
            max: 3,
            divisions: 20,
            suffix: '×',
            decimalPlaces: 2,
            onChanged: (value) => setState(() => _dataPointHoverScale = value),
          ),
          SliderOption(
            key: const ValueKey('selection-lab-point-selection-scale'),
            label: 'Data point selection scale',
            value: _dataPointSelectionScale,
            min: 1,
            max: 4,
            divisions: 30,
            suffix: '×',
            decimalPlaces: 2,
            onChanged: (value) =>
                setState(() => _dataPointSelectionScale = value),
          ),
          SliderOption(
            key: const ValueKey('selection-lab-series-hover-scale'),
            label: 'Complete series hover width',
            value: _seriesHoverStrokeScale,
            min: 1,
            max: 3,
            divisions: 20,
            suffix: '×',
            decimalPlaces: 2,
            onChanged: (value) =>
                setState(() => _seriesHoverStrokeScale = value),
          ),
          SliderOption(
            key: const ValueKey('selection-lab-series-selection-scale'),
            label: 'Complete series selection width',
            value: _seriesSelectionStrokeScale,
            min: 1,
            max: 3,
            divisions: 20,
            suffix: '×',
            decimalPlaces: 2,
            onChanged: (value) =>
                setState(() => _seriesSelectionStrokeScale = value),
          ),
        ],
      ),
    if (_family == _SelectionFamily.bar)
      OptionSection(
        title: 'Bar selection feedback',
        icon: Icons.bar_chart,
        initiallyExpanded: false,
        children: [
          SliderOption(
            key: const ValueKey('selection-lab-bar-dimmed-opacity'),
            label: 'Unselected bar opacity',
            value: _barDimmedOpacity,
            min: 0.05,
            max: 1,
            divisions: 19,
            decimalPlaces: 2,
            onChanged: (value) => setState(() => _barDimmedOpacity = value),
          ),
          SliderOption(
            key: const ValueKey('selection-lab-bar-selection-opacity'),
            label: 'Selection overlay opacity',
            value: _barSelectionOpacity,
            min: 0,
            max: 0.5,
            divisions: 20,
            decimalPlaces: 2,
            onChanged: (value) => setState(() => _barSelectionOpacity = value),
          ),
          SliderOption(
            key: const ValueKey('selection-lab-bar-selection-border'),
            label: 'Selection border width',
            value: _barSelectionBorderWidth,
            min: 0,
            max: 6,
            divisions: 24,
            suffix: 'px',
            decimalPlaces: 2,
            onChanged: (value) =>
                setState(() => _barSelectionBorderWidth = value),
          ),
        ],
      ),
    if (_family == _SelectionFamily.scatter)
      OptionSection(
        title: 'Scatter selection feedback',
        icon: Icons.bubble_chart_outlined,
        initiallyExpanded: false,
        children: [
          SliderOption(
            key: const ValueKey('selection-lab-scatter-hover-scale'),
            label: 'Marker hover scale',
            value: _scatterHoverScale,
            min: 1,
            max: 3,
            divisions: 20,
            suffix: '×',
            decimalPlaces: 2,
            onChanged: (value) => setState(() => _scatterHoverScale = value),
          ),
          SliderOption(
            key: const ValueKey('selection-lab-scatter-selection-scale'),
            label: 'Marker selection scale',
            value: _scatterSelectionScale,
            min: 1,
            max: 3,
            divisions: 20,
            suffix: '×',
            decimalPlaces: 2,
            onChanged: (value) =>
                setState(() => _scatterSelectionScale = value),
          ),
          SliderOption(
            key: const ValueKey('selection-lab-scatter-dimmed-opacity'),
            label: 'Unselected marker opacity',
            value: _scatterDimmedOpacity,
            min: 0.05,
            max: 1,
            divisions: 19,
            decimalPlaces: 2,
            onChanged: (value) => setState(() => _scatterDimmedOpacity = value),
          ),
        ],
      ),
    if (_family.isRadial)
      OptionSection(
        title: 'Radial selection feedback',
        icon: Icons.pie_chart_outline,
        initiallyExpanded: false,
        children: [
          EnumOption<RadialSelectionEffect>(
            key: const ValueKey('selection-lab-radial-effect'),
            label: 'Selection effect',
            value: _radialSelectionEffect,
            values: RadialSelectionEffect.values,
            labelBuilder: (value) => switch (value) {
              RadialSelectionEffect.explode => 'Explode',
              RadialSelectionEffect.lift => 'Lift',
            },
            onChanged: (value) =>
                setState(() => _radialSelectionEffect = value),
          ),
          SliderOption(
            key: const ValueKey('selection-lab-radial-scale'),
            label: 'Selected slice scale',
            value: _radialSelectionScale,
            min: 1,
            max: 1.3,
            divisions: 30,
            suffix: '×',
            decimalPlaces: 2,
            onChanged: (value) => setState(() => _radialSelectionScale = value),
          ),
          SliderOption(
            key: const ValueKey('selection-lab-radial-offset'),
            label: 'Selected slice offset',
            value: _radialSelectionOffset,
            min: 0,
            max: 20,
            divisions: 20,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) =>
                setState(() => _radialSelectionOffset = value),
          ),
          SliderOption(
            key: const ValueKey('selection-lab-radial-blur'),
            label: 'Unselected backdrop blur',
            value: _radialBackdropBlur,
            min: 0,
            max: 5,
            divisions: 20,
            suffix: 'px',
            decimalPlaces: 2,
            onChanged: (value) => setState(() => _radialBackdropBlur = value),
          ),
        ],
      ),
    if (!_family.isRadial)
      OptionSection(
        title: 'Tracking feedback',
        icon: Icons.track_changes_outlined,
        initiallyExpanded: false,
        children: [
          BoolOption(
            key: const ValueKey('selection-lab-point-popup'),
            label: 'Show data point hover popup',
            subtitle: 'Show the standard single-point value popup',
            value: _showDataPointHoverPopup,
            onChanged: (value) =>
                setState(() => _showDataPointHoverPopup = value),
          ),
          BoolOption(
            key: const ValueKey('selection-lab-tracking-panel'),
            label: 'Show tracking information panel',
            subtitle: 'Show the shared multi-series tracking panel',
            value: _showTrackingInformationPanel,
            onChanged: (value) =>
                setState(() => _showTrackingInformationPanel = value),
          ),
        ],
      ),
    StandardChartOptions(
      key: ValueKey('selection-lab-standard-${_family.name}'),
      controller: _chartOptionsController,
      showGridOption: !_family.isRadial,
      showAxisOption: !_family.isRadial,
      showMarkerOption: _family.supportsMarkerVisibility,
      showScrollbarOptions: !_family.isRadial,
      showXScrollbarOption: !_family.isRadial,
      showYScrollbarOption: !_family.isRadial,
      showCrosshairOption: !_family.isRadial,
      showInteractionOptions: !_family.isRadial,
      showLineStyleOption: false,
    ),
    OptionSection(
      title: 'Current selection',
      icon: Icons.fact_check_outlined,
      children: [
        _SelectionStatus(controller: _chartController),
        const SizedBox(height: 8),
        ActionButton(
          key: const ValueKey('selection-lab-clear-option'),
          label: 'Clear selection',
          icon: Icons.deselect_outlined,
          onPressed: _clearSelection,
        ),
      ],
    ),
    const OptionSection(
      title: 'Keyboard and pointer',
      icon: Icons.keyboard_alt_outlined,
      initiallyExpanded: false,
      children: [
        InfoBox(
          message:
              'Click or drag using the active test case. Shift adds, Ctrl/Cmd toggles, and Alt subtracts. Arrow keys move focus; Enter or Space selects; Shift+Space extends ordered marks; Ctrl/Cmd+A selects a bounded chart; Escape clears.',
        ),
      ],
    ),
  ];

  Widget _buildWorkspace() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          key: const ValueKey('selection-family-grid'),
          color: theme.colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: _SelectionChoiceRow<_SelectionFamily>(
              label: 'Chart family',
              value: _family,
              values: _SelectionFamily.values,
              keyPrefix: 'selection-family',
              labelBuilder: (family) => family.label,
              iconBuilder: (family) => family.icon,
              tooltipBuilder: (family) =>
                  '${family.label}: ${family.shortDescription}',
              onChanged: _selectFamily,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ChartCard(
            key: const ValueKey('selection-card'),
            title: _family.exampleTitle,
            subtitle:
                '${_family.exampleSubtitle} · ${_acquisitionMode.shortLabel} · ${_selectionScope.shortLabel}',
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSelectionToolbar(),
                const SizedBox(height: 8),
                Expanded(
                  child: BravenChartWorkbench(
                    key: const ValueKey('selection-workbench'),
                    chartController: _chartController,
                    workbenchController: _workbenchController,
                    availableDisplayModes: const {
                      ChartDisplayMode.chart,
                      ChartDisplayMode.data,
                      ChartDisplayMode.split,
                      ChartDisplayMode.source,
                    },
                    sourceOptions: ChartDartSourceOptions(
                      variableName: '${_family.name}SelectionChart',
                    ),
                    documentOptions: const ChartDocumentExtractOptions(
                      includeViewState: true,
                    ),
                    tableOptions: _family == _SelectionFamily.scatter
                        ? const ChartTableOptions(
                            rowLayout: ChartTableRowLayout.long,
                          )
                        : const ChartTableOptions(),
                    tableRefreshPolicy:
                        ChartTableRefreshPolicy.onDocumentRevision,
                    splitBreakpoint: 760,
                    autoFitTablePane: true,
                    minimumChartPaneExtent: 320,
                    minimumTablePaneExtent: 320,
                    maximumAutoTablePaneExtent: 520,
                    chartBuilder: (context, controller) =>
                        _buildChart(controller),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionToolbar() {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SelectionChoiceRow<ChartSelectionAcquisitionMode>(
              label: 'Selection tool',
              value: _acquisitionMode,
              values: _family.availableAcquisitionModes,
              keyPrefix: 'selection-lab-tool',
              labelBuilder: (mode) => mode.shortLabel,
              iconBuilder: (mode) => mode.icon,
              onChanged: _selectAcquisitionMode,
            ),
            const Divider(height: 12),
            _SelectionChoiceRow<ChartSelectionScope>(
              label: 'Selection target',
              value: _selectionScope,
              values: _family.availableSelectionScopes,
              keyPrefix: 'selection-lab-target',
              labelBuilder: (scope) => scope.shortLabel,
              iconBuilder: (scope) => scope.icon,
              onChanged: _selectScope,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BravenChartController controller) {
    final radial = _family.isRadial;
    final options = _chartOptionsController.options;
    return BravenChartPlus(
      key: ValueKey('selection-chart-${_family.name}'),
      transitionKey: _family,
      bravenChartController: controller,
      series: _seriesForFamily(options),
      title: _family.chartTitle,
      subtitle: _family.chartSubtitle,
      theme: options.theme ?? ChartTheme.light,
      showLegend: options.showLegend,
      showXScrollbar: !radial && options.showXScrollbar,
      showYScrollbar: !radial && options.showYScrollbar,
      concentricDonutConfig: _family == _SelectionFamily.concentricDonut
          ? const ConcentricDonutConfig(
              innerRadiusFactor: 0.24,
              outerRadiusFactor: 0.94,
              ringGap: 5,
            )
          : const ConcentricDonutConfig(),
      grid: GridConfig(
        horizontal: !radial && options.showGrid,
        vertical: !radial && options.showGrid,
      ),
      xAxisConfig: XAxisConfig(
        label: radial ? null : _family.xAxisLabel,
        visible: !radial,
        showAxisLine: !radial && options.showAxisLines,
      ),
      yAxis: YAxisConfig(
        position: radial ? YAxisPosition.hidden : YAxisPosition.left,
        label: radial ? null : _family.yAxisLabel,
        showAxisLine: !radial && options.showAxisLines,
      ),
      interactionConfig: InteractionConfig(
        crosshair: CrosshairConfig(
          enabled: !radial && options.showCrosshair,
          showTrackingTooltip: _showTrackingInformationPanel,
        ),
        tooltip: TooltipConfig(
          enabled: radial || _showDataPointHoverPopup,
          triggerMode: TooltipTriggerMode.both,
        ),
        keyboard: const KeyboardConfig(enabled: true),
        enableZoom: !radial && options.enableZoom,
        enablePan: !radial && options.enablePan,
        showXScrollbar: !radial && options.showXScrollbar,
        showYScrollbar: !radial && options.showYScrollbar,
        enableSelection: true,
        selection: ChartSelectionConfig(
          acquisitionMode: _acquisitionMode,
          scope: _selectionScope,
          operation: _operation,
          dragActivation: _dragActivation,
          clearOnBackgroundTap: _clearOnBackgroundTap,
          useModifierKeys: _useModifierKeys,
          dataPointHitRadius: _pointHitRadius,
          completeSeriesHitRadius: _seriesHitRadius,
          dataPointHoverScale: _dataPointHoverScale,
          dataPointSelectionScale: _dataPointSelectionScale,
          completeSeriesHoverStrokeScale: _seriesHoverStrokeScale,
          completeSeriesSelectionStrokeScale: _seriesSelectionStrokeScale,
        ),
      ),
    );
  }

  List<ChartSeries> _seriesForFamily(ChartOptions options) => switch (_family) {
    _SelectionFamily.line => [
      for (final series in _lineSeries)
        switch (series) {
          LineChartSeries line => line.copyWith(
            showDataPointMarkers: options.showDataMarkers,
          ),
          _ => series,
        },
    ],
    _SelectionFamily.area => [
      for (final series in _areaSeries)
        switch (series) {
          AreaChartSeries area => area.copyWith(
            showDataPointMarkers: options.showDataMarkers,
          ),
          LineChartSeries line => line.copyWith(
            showDataPointMarkers: options.showDataMarkers,
          ),
          _ => series,
        },
    ],
    _SelectionFamily.rangeArea => [
      for (final series in _rangeAreaSeries)
        switch (series) {
          RangeAreaChartSeries range => range.copyWith(
            showBoundaryMarkers: options.showDataMarkers,
          ),
          _ => series,
        },
    ],
    _SelectionFamily.bar => [
      for (final series in _barSeries)
        switch (series) {
          BarChartSeries bar => bar.copyWith(
            barStyle: _barStyleWithInteraction(
              bar.barStyle,
              BarInteractionStyle(
                selectionOpacity: _barSelectionOpacity,
                selectionBorderWidth: _barSelectionBorderWidth,
                dimmedOpacity: _barDimmedOpacity,
              ),
            ),
          ),
          _ => series,
        },
    ],
    _SelectionFamily.scatter => [
      for (final series in _scatterSeries)
        switch (series) {
          ScatterChartSeries scatter => scatter.copyWith(
            interactionStyle: scatter.interactionStyle.copyWith(
              hoverScale: _scatterHoverScale,
              selectionScale: _scatterSelectionScale,
              dimmedOpacity: _scatterDimmedOpacity,
            ),
          ),
          _ => series,
        },
    ],
    _SelectionFamily.candlestick => _candlestickSeries,
    _SelectionFamily.pie => [
      for (final series in _pieSeries)
        switch (series) {
          PieChartSeries pie => pie.copyWith(
            selectionStyle: _radialSelectionStyle,
          ),
          _ => series,
        },
    ],
    _SelectionFamily.donut => [
      for (final series in _donutSeries)
        switch (series) {
          DonutChartSeries donut => donut.copyWith(
            selectionStyle: _radialSelectionStyle,
          ),
          _ => series,
        },
    ],
    _SelectionFamily.concentricDonut => [
      for (final series in _concentricSeries)
        switch (series) {
          DonutChartSeries donut => donut.copyWith(
            selectionStyle: _radialSelectionStyle,
          ),
          _ => series,
        },
    ],
    _SelectionFamily.polarColumn => [
      for (final series in _polarSeries)
        switch (series) {
          PolarColumnChartSeries polar => polar.copyWith(
            selectionStyle: _radialSelectionStyle,
          ),
          _ => series,
        },
    ],
  };

  RadialSelectionStyle get _radialSelectionStyle => RadialSelectionStyle(
    effect: _radialSelectionEffect,
    liftScale: _radialSelectionScale,
    liftOffset: _radialSelectionOffset,
    backdropBlur: _radialBackdropBlur,
  );

  BarChartStyle _barStyleWithInteraction(
    BarChartStyle style,
    BarInteractionStyle interaction,
  ) => BarChartStyle(
    cornerRadius: style.cornerRadius,
    cornerRadiusPolicy: style.cornerRadiusPolicy,
    gradient: style.gradient,
    pattern: style.pattern,
    border: style.border,
    opacity: style.opacity,
    interaction: interaction,
    animationMode: style.animationMode,
    motion: style.motion,
  );
}

class _SelectionChoiceRow<T extends Object> extends StatelessWidget {
  const _SelectionChoiceRow({
    required this.label,
    required this.value,
    required this.values,
    required this.keyPrefix,
    required this.labelBuilder,
    required this.iconBuilder,
    required this.onChanged,
    this.tooltipBuilder,
  });

  final String label;
  final T value;
  final List<T> values;
  final String keyPrefix;
  final String Function(T value) labelBuilder;
  final IconData Function(T value) iconBuilder;
  final ValueChanged<T> onChanged;
  final String Function(T value)? tooltipBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final candidate in values)
          ChoiceChip(
            key: ValueKey('$keyPrefix-${_enumName(candidate)}'),
            selected: value == candidate,
            showCheckmark: false,
            avatar: Icon(iconBuilder(candidate), size: 17),
            label: Text(labelBuilder(candidate)),
            tooltip: tooltipBuilder?.call(candidate) ?? labelBuilder(candidate),
            onSelected: (_) => onChanged(candidate),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
      ],
    );
  }

  String _enumName(T candidate) => candidate.toString().split('.').last;
}

class _SelectionStatus extends StatefulWidget {
  const _SelectionStatus({required this.controller});

  final BravenChartController controller;

  @override
  State<_SelectionStatus> createState() => _SelectionStatusState();
}

class _SelectionStatusState extends State<_SelectionStatus> {
  bool _updateScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scheduleUpdate);
  }

  @override
  void didUpdateWidget(covariant _SelectionStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_scheduleUpdate);
    widget.controller.addListener(_scheduleUpdate);
  }

  void _scheduleUpdate() {
    if (_updateScheduled) return;
    _updateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scheduleUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.controller.selectionSnapshot;
    final pointCount = snapshot?.statistics.pointCount ?? 0;
    final seriesCount = snapshot?.statistics.seriesCount ?? 0;
    final selectedSeries = widget.controller.selectedSeriesIds.length;
    final totalSeries = seriesCount > selectedSeries
        ? seriesCount
        : selectedSeries;
    return Semantics(
      liveRegion: true,
      label: '$pointCount selected points in $totalSeries series',
      child: Container(
        key: const ValueKey('selection-lab-status'),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          pointCount == 0 && totalSeries == 0
              ? 'Nothing selected'
              : '$pointCount ${pointCount == 1 ? 'point' : 'points'} · $totalSeries series',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

enum _SelectionFamily {
  line,
  area,
  rangeArea,
  bar,
  scatter,
  candlestick,
  pie,
  donut,
  concentricDonut,
  polarColumn;

  String get label => switch (this) {
    line => 'Line',
    area => 'Area',
    rangeArea => 'Range Area',
    bar => 'Bar',
    scatter => 'Scatter',
    candlestick => 'Candlestick',
    pie => 'Pie',
    donut => 'Donut',
    concentricDonut => 'Concentric Donut',
    polarColumn => 'Polar Column',
  };

  IconData get icon => switch (this) {
    line => Icons.show_chart,
    area => Icons.area_chart_outlined,
    rangeArea => Icons.stacked_line_chart,
    bar => Icons.bar_chart,
    scatter => Icons.bubble_chart_outlined,
    candlestick => Icons.candlestick_chart_outlined,
    pie => Icons.pie_chart_outline,
    donut => Icons.donut_large,
    concentricDonut => Icons.adjust,
    polarColumn => Icons.rotate_right,
  };

  String get shortDescription => switch (this) {
    line => 'Point or complete series',
    area => 'Point, complete series, or X interval',
    rangeArea => 'Select interval bands',
    bar => 'Category and whole series',
    scatter => 'Free-form lasso',
    candlestick => 'Select session ranges',
    pie => 'Select one or more slices',
    donut => 'Slice plus center context',
    concentricDonut => 'Category across rings',
    polarColumn => 'Category across layers',
  };

  String get testPurpose => switch (this) {
    line =>
      'Direct markers win inside the point corridor; otherwise the nearby stroke resolves a complete series.',
    area =>
      'Select a marker or the nearby boundary as a complete series. Switch to X range to extract an exact continuous interval.',
    rangeArea =>
      'Drag a box through low/high intervals. Each retained interval remains an atomic tuple.',
    bar =>
      'A direct bar selects the same semantic series across all categories. Modifier keys compose selections.',
    scatter =>
      'Draw a free-form boundary around irregular points. Only enclosed marker centers commit.',
    candlestick =>
      'Drag across trading sessions. Every selected candle retains its complete OHLC values.',
    pie =>
      'Select slices directly. The Workbench table and selection actions follow the same categories.',
    donut =>
      'Select slices while retaining donut center context and radial interaction styling.',
    concentricDonut =>
      'Select one category across independent rings to verify grouped radial identity.',
    polarColumn =>
      'Select one angular category across both radial value layers.',
  };

  String get exampleTitle => '$label selection';

  String get exampleSubtitle => switch (this) {
    line => 'Markers and forgiving stroke hit corridors',
    area => 'Marker, boundary, and continuous X-range selection',
    rangeArea => 'Atomic low/high interval selection',
    bar => 'Same series across every category',
    scatter => 'Free-form spatial acquisition',
    candlestick => 'Complete OHLC range selection',
    pie => 'Durable radial slice selection',
    donut => 'Slice selection with center context',
    concentricDonut => 'Shared category selection across rings',
    polarColumn => 'Shared angular category across layers',
  };

  String get chartTitle => switch (this) {
    line => 'Weekly performance paths',
    area => 'Active workload envelope',
    rangeArea => 'Expected recovery range',
    bar => 'Channel performance',
    scatter => 'Account opportunity map',
    candlestick => 'Daily market sessions',
    pie => 'Revenue contribution',
    donut => 'Support workload',
    concentricDonut => 'Revenue mix by period',
    polarColumn => 'Channel profile',
  };

  String get chartSubtitle => switch (this) {
    line => 'Select a marker or the complete nearby series',
    area => 'Select a marker, the complete boundary, or an X interval',
    rangeArea => 'Drag a box through one or more bands',
    bar => 'Select the same colored series in one action',
    scatter => 'Draw around the accounts to retain',
    candlestick => 'Drag across the sessions to extract',
    pie => 'Select one or compose multiple categories',
    donut => 'The center follows the durable slice selection',
    concentricDonut => 'One category is represented in every ring',
    polarColumn => 'One category is represented in both layers',
  };

  String get xAxisLabel => switch (this) {
    scatter => 'Adoption score',
    candlestick => 'Session',
    _ => 'Period',
  };

  String get yAxisLabel => switch (this) {
    rangeArea => 'Recovery score',
    scatter => 'Growth score',
    candlestick => 'Price',
    _ => 'Value',
  };

  bool get isRadial => switch (this) {
    pie || donut || concentricDonut || polarColumn => true,
    _ => false,
  };

  bool get isPathFamily => this == line || this == area;

  bool get supportsMarkerVisibility => switch (this) {
    line || area || rangeArea => true,
    _ => false,
  };

  ChartSelectionAcquisitionMode get defaultAcquisitionMode => switch (this) {
    candlestick => ChartSelectionAcquisitionMode.xInterval,
    rangeArea => ChartSelectionAcquisitionMode.rectangle,
    scatter => ChartSelectionAcquisitionMode.lasso,
    _ => ChartSelectionAcquisitionMode.point,
  };

  ChartSelectionScope get defaultSelectionScope => switch (this) {
    line || area => ChartSelectionScope.markOrWholeSeries,
    bar => ChartSelectionScope.wholeSeries,
    concentricDonut || polarColumn => ChartSelectionScope.category,
    _ => ChartSelectionScope.mark,
  };

  List<ChartSelectionAcquisitionMode> get availableAcquisitionModes => isRadial
      ? const [ChartSelectionAcquisitionMode.point]
      : ChartSelectionAcquisitionMode.values;

  List<ChartSelectionScope> get availableSelectionScopes => switch (this) {
    line || area => const [
      ChartSelectionScope.mark,
      ChartSelectionScope.category,
      ChartSelectionScope.wholeSeries,
      ChartSelectionScope.markOrWholeSeries,
    ],
    bar => const [
      ChartSelectionScope.mark,
      ChartSelectionScope.category,
      ChartSelectionScope.categoryStack,
      ChartSelectionScope.wholeSeries,
    ],
    _ => const [
      ChartSelectionScope.mark,
      ChartSelectionScope.category,
      ChartSelectionScope.wholeSeries,
    ],
  };
}

extension on ChartSelectionAcquisitionMode {
  String get shortLabel => switch (this) {
    ChartSelectionAcquisitionMode.point => 'Point',
    ChartSelectionAcquisitionMode.xInterval => 'X range',
    ChartSelectionAcquisitionMode.yInterval => 'Y range',
    ChartSelectionAcquisitionMode.rectangle => 'Box',
    ChartSelectionAcquisitionMode.lasso => 'Lasso',
  };

  IconData get icon => switch (this) {
    ChartSelectionAcquisitionMode.point => Icons.ads_click_outlined,
    ChartSelectionAcquisitionMode.xInterval => Icons.swap_horiz,
    ChartSelectionAcquisitionMode.yInterval => Icons.swap_vert,
    ChartSelectionAcquisitionMode.rectangle => Icons.crop_free,
    ChartSelectionAcquisitionMode.lasso => Icons.gesture,
  };
}

extension on ChartSelectionScope {
  String get shortLabel => switch (this) {
    ChartSelectionScope.mark => 'Data point',
    ChartSelectionScope.category => 'Category',
    ChartSelectionScope.categoryStack => 'Category stack',
    ChartSelectionScope.wholeSeries => 'Complete series',
    ChartSelectionScope.markOrWholeSeries => 'Point or series',
  };

  IconData get icon => switch (this) {
    ChartSelectionScope.mark => Icons.adjust,
    ChartSelectionScope.category => Icons.view_column_outlined,
    ChartSelectionScope.categoryStack => Icons.layers_outlined,
    ChartSelectionScope.wholeSeries => Icons.timeline,
    ChartSelectionScope.markOrWholeSeries => Icons.call_split,
  };
}

String _operationLabel(ChartSelectionOperation operation) =>
    switch (operation) {
      ChartSelectionOperation.replace => 'Replace selection',
      ChartSelectionOperation.add => 'Add to selection',
      ChartSelectionOperation.subtract => 'Subtract from selection',
      ChartSelectionOperation.toggle => 'Toggle selection',
    };

const _pathPointsA = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 34, pointKey: 'mon'),
  ChartDataPoint(x: 1, y: 42, pointKey: 'tue'),
  ChartDataPoint(x: 2, y: 39, pointKey: 'wed'),
  ChartDataPoint(x: 3, y: 53, pointKey: 'thu'),
  ChartDataPoint(x: 4, y: 49, pointKey: 'fri'),
  ChartDataPoint(x: 5, y: 62, pointKey: 'sat'),
  ChartDataPoint(x: 6, y: 58, pointKey: 'sun'),
];

const _pathPointsB = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 48, pointKey: 'mon'),
  ChartDataPoint(x: 1, y: 45, pointKey: 'tue'),
  ChartDataPoint(x: 2, y: 52, pointKey: 'wed'),
  ChartDataPoint(x: 3, y: 47, pointKey: 'thu'),
  ChartDataPoint(x: 4, y: 59, pointKey: 'fri'),
  ChartDataPoint(x: 5, y: 56, pointKey: 'sat'),
  ChartDataPoint(x: 6, y: 68, pointKey: 'sun'),
];

final _lineSeries = <ChartSeries>[
  const LineChartSeries(
    id: 'observed',
    name: 'Observed',
    points: _pathPointsA,
    color: Color(0xFF2563EB),
    interpolation: LineInterpolation.monotone,
    strokeWidth: 2.5,
    showDataPointMarkers: true,
  ),
  const LineChartSeries(
    id: 'capacity',
    name: 'Capacity',
    points: _pathPointsB,
    color: Color(0xFF0D9488),
    interpolation: LineInterpolation.monotone,
    strokeWidth: 2.5,
    showDataPointMarkers: true,
  ),
];

final _areaSeries = <ChartSeries>[
  const AreaChartSeries(
    id: 'load',
    name: 'Training load',
    points: _pathPointsA,
    color: Color(0xFF4F46E5),
    interpolation: LineInterpolation.monotone,
    strokeWidth: 2.5,
    fillOpacity: 0.32,
    showDataPointMarkers: true,
  ),
  const LineChartSeries(
    id: 'capacity',
    name: 'Capacity',
    points: _pathPointsB,
    color: Color(0xFFEA580C),
    interpolation: LineInterpolation.monotone,
    strokeWidth: 2,
  ),
];

final _rangeAreaSeries = <ChartSeries>[
  RangeAreaChartSeries(
    id: 'recovery-range',
    name: 'Expected range',
    color: const Color(0xFF0891B2),
    interpolation: LineInterpolation.monotone,
    fillOpacity: 0.32,
    showBoundaryMarkers: true,
    points: [
      for (var index = 0; index < 8; index++)
        RangeAreaDataPoint(
          x: index.toDouble(),
          pointKey: 'day-$index',
          low: 42 + index * 1.8 + (index.isEven ? 0 : -3),
          high: 58 + index * 2.1 + (index.isEven ? 3 : 0),
        ),
    ],
  ),
];

List<ChartDataPoint> _categoryPoints(List<double> values) => [
  for (final (index, value) in values.indexed)
    ChartDataPoint(
      x: index.toDouble(),
      y: value,
      pointKey: 'category-$index',
      label: const ['North', 'South', 'East', 'West', 'Central'][index],
    ),
];

final _barSeries = <ChartSeries>[
  BarChartSeries(
    id: 'actual',
    name: 'Actual',
    points: _categoryPoints([54, 72, 61, 88, 69]),
    color: const Color(0xFF0891B2),
    layoutMode: BarLayoutMode.stacked,
    groupId: 'performance',
    barWidthPercent: 0.72,
    barGap: 5,
  ),
  BarChartSeries(
    id: 'plan',
    name: 'Plan',
    points: _categoryPoints([42, 64, 79, 58, 83]),
    color: const Color(0xFFFF7058),
    layoutMode: BarLayoutMode.stacked,
    groupId: 'performance',
    barWidthPercent: 0.72,
    barGap: 5,
  ),
  BarChartSeries(
    id: 'forecast',
    name: 'Forecast',
    points: _categoryPoints([62, 75, 88, 28, 41]),
    color: const Color(0xFF6D5BD0),
    layoutMode: BarLayoutMode.stacked,
    groupId: 'outlook',
    barWidthPercent: 0.72,
    barGap: 5,
  ),
  BarChartSeries(
    id: 'baseline',
    name: 'Baseline',
    points: _categoryPoints([35, 48, 52, 44, 57]),
    color: const Color(0xFFD89B18),
    layoutMode: BarLayoutMode.stacked,
    groupId: 'outlook',
    barWidthPercent: 0.72,
    barGap: 5,
  ),
];

final _scatterSeries = <ChartSeries>[
  const ScatterChartSeries(
    id: 'priority',
    name: 'Priority',
    color: Color(0xFF0E7490),
    points: [
      ChartDataPoint(x: 2.8, y: 4.4, pointKey: 'a'),
      ChartDataPoint(x: 3.2, y: 6.9, pointKey: 'b'),
      ChartDataPoint(x: 4.2, y: 7.4, pointKey: 'c'),
      ChartDataPoint(x: 4.8, y: 6.6, pointKey: 'd'),
      ChartDataPoint(x: 5.4, y: 7.2, pointKey: 'e'),
      ChartDataPoint(x: 6.6, y: 8.2, pointKey: 'f'),
      ChartDataPoint(x: 7.3, y: 6.9, pointKey: 'g'),
      ChartDataPoint(x: 8.1, y: 7.7, pointKey: 'h'),
    ],
  ),
  const ScatterChartSeries(
    id: 'monitor',
    name: 'Monitor',
    color: Color(0xFFEA580C),
    markerShape: SeriesMarkerShape.diamond,
    points: [
      ChartDataPoint(x: 1.4, y: 3.0, pointKey: 'i'),
      ChartDataPoint(x: 3.8, y: 5.5, pointKey: 'j'),
      ChartDataPoint(x: 4.5, y: 6.3, pointKey: 'k'),
      ChartDataPoint(x: 5.1, y: 6.8, pointKey: 'l'),
      ChartDataPoint(x: 5.7, y: 7.0, pointKey: 'm'),
      ChartDataPoint(x: 6.9, y: 5.7, pointKey: 'n'),
      ChartDataPoint(x: 7.8, y: 4.9, pointKey: 'o'),
      ChartDataPoint(x: 8.5, y: 3.8, pointKey: 'p'),
    ],
  ),
];

final _candlestickSeries = <ChartSeries>[
  CandlestickChartSeries(
    id: 'price',
    name: 'Price',
    points: [
      for (var index = 0; index < 12; index++)
        CandlestickDataPoint(
          x: index.toDouble(),
          pointKey: 'session-$index',
          open: 100 + index * 1.4 + (index.isEven ? -2 : 2),
          high: 106 + index * 1.5,
          low: 96 + index * 1.1,
          close: 101 + index * 1.35 + (index % 3 == 0 ? 3 : -1),
        ),
    ],
  ),
];

const _radialValues = <String, num>{
  'Subscriptions': 42,
  'Services': 28,
  'Hardware': 16,
  'Training': 9,
  'Other': 5,
};

final _pieSeries = <ChartSeries>[
  PieChartSeries.fromMap(
    id: 'revenue',
    name: 'Revenue',
    values: _radialValues,
    pieStyle: const PieChartStyle(sliceGap: 3, cornerRadius: 6),
    selectionStyle: const RadialSelectionStyle(
      effect: RadialSelectionEffect.explode,
    ),
    dataLabels: const PieDataLabelConfig(
      isVisible: true,
      position: PieDataLabelPosition.inside,
      content: PieDataLabelContent.percentage,
    ),
  ),
];

final _donutSeries = <ChartSeries>[
  DonutChartSeries.fromMap(
    id: 'support',
    name: 'Support',
    values: _radialValues,
    donutStyle: const DonutChartStyle(sliceGap: 3, cornerRadius: 6),
    selectionStyle: const RadialSelectionStyle(
      effect: RadialSelectionEffect.lift,
    ),
    centerContent: const DonutCenterContent(
      label: 'Selected or total',
      valueMode: DonutCenterValueMode.selectedOrTotal,
    ),
  ),
];

final _concentricSeries = <ChartSeries>[
  DonutChartSeries.fromMap(
    id: 'current',
    name: 'Current',
    values: _radialValues,
    donutStyle: const DonutChartStyle(sliceGap: 2, cornerRadius: 4),
    selectionStyle: const RadialSelectionStyle(
      effect: RadialSelectionEffect.lift,
    ),
  ),
  DonutChartSeries.fromMap(
    id: 'previous',
    name: 'Previous',
    values: const {
      'Subscriptions': 36,
      'Services': 31,
      'Hardware': 18,
      'Training': 10,
      'Other': 5,
    },
    donutStyle: const DonutChartStyle(sliceGap: 2, cornerRadius: 4),
    selectionStyle: const RadialSelectionStyle(
      effect: RadialSelectionEffect.lift,
    ),
  ),
  DonutChartSeries.fromMap(
    id: 'forecast',
    name: 'Forecast',
    values: const {
      'Subscriptions': 48,
      'Services': 24,
      'Hardware': 14,
      'Training': 8,
      'Other': 6,
    },
    donutStyle: const DonutChartStyle(sliceGap: 2, cornerRadius: 4),
    selectionStyle: const RadialSelectionStyle(
      effect: RadialSelectionEffect.lift,
    ),
  ),
];

final _polarSeries = <ChartSeries>[
  PolarColumnChartSeries.fromMap(
    id: 'actual',
    name: 'Actual',
    values: const {
      'Search': 86,
      'Social': 58,
      'Email': 72,
      'Direct': 64,
      'Referral': 48,
      'Other': 36,
    },
    color: const Color(0xFF2563EB),
    polarStyle: const PolarColumnStyle(),
    selectionStyle: const RadialSelectionStyle(
      effect: RadialSelectionEffect.lift,
    ),
  ),
  PolarColumnChartSeries.fromMap(
    id: 'target',
    name: 'Target',
    values: const {
      'Search': 72,
      'Social': 66,
      'Email': 78,
      'Direct': 58,
      'Referral': 54,
      'Other': 42,
    },
    color: const Color(0xFFF97316),
    polarStyle: const PolarColumnStyle(),
    selectionStyle: const RadialSelectionStyle(
      effect: RadialSelectionEffect.lift,
    ),
  ),
];
