// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// JSON Schema definitions for LLM function calling / tool use.
///
/// These schemas define the contract between an AI agent and BravenChartPlus,
/// enabling agents to generate charts from natural language requests.
///
/// Compatible with:
/// - Anthropic Claude (tool_use)
/// - OpenAI (function_calling)
/// - Google Gemini (function_declarations)
library;

import 'generated/surface_definitions.dart' as generated;

/// Tool definitions for AI chart generation.
///
/// These can be passed directly to LLM APIs that support function calling.
///
/// Example usage with Claude:
/// ```dart
/// final response = await anthropic.messages.create(
///   model: 'claude-sonnet-4-20250514',
///   tools: ChartToolSchema.tools,
///   messages: [...],
/// );
/// ```
abstract final class ChartToolSchema {
  /// All available chart tools.
  static const List<Map<String, dynamic>> tools = [
    createChartTool,
    modifyChartTool,
    explainDataTool,
  ];

  /// Structural JSON-Schema definitions for the config surface, keyed by
  /// class name — GENERATED from the `@chartSurface` annotations.
  ///
  /// This is ADDITIVE and changes nothing about [tools]. The two describe
  /// different things and are keyed differently on purpose:
  ///
  /// - [tools] is the CALLING vocabulary. Its properties are flat snake_case
  ///   keys (`bar_waterfall_connector_color`, `pie_label_minimum_sweep`)
  ///   invented for the agent protocol and consumed literally by
  ///   `ChartConfigBuilder`. One `style` bag flattens dozens of nested config
  ///   classes, so those names have no mechanical relationship to any class.
  /// - [surfaceDefinitions] is the STRUCTURAL vocabulary: what the config
  ///   classes actually are, in their own Dart parameter names, with defaults,
  ///   enum members, `$ref`s between nested configs, tri-state
  ///   `{value | "none" | "inherit"}` unions, and the constructor couplings a
  ///   schema can soundly express. An agent consults it to reason about the
  ///   surface; it still CALLS [tools].
  ///
  /// Because it is generated it cannot drift from the classes. Mount it at the
  /// `$defs` of a root schema — every cross-reference is a
  /// `{'$ref': '#/$defs/<ClassName>'}` pointer.
  ///
  /// ```dart
  /// final barSeries =
  ///     ChartToolSchema.surfaceDefinitions['BarChartSeries']! as Map;
  /// final schema = {r'$defs': ChartToolSchema.surfaceDefinitions, ...barSeries};
  /// ```
  static const Map<String, Object?> surfaceDefinitions =
      generated.surfaceDefinitions;

  /// Tool for creating a new chart from data.
  static const Map<String, dynamic> createChartTool = {
    'name': 'create_chart',
    'description': '''
Creates an interactive BravenChartPlus chart from provided data.
Use this tool when the user wants to visualize data as a chart.
Cartesian charts support multiple overlaid series, axes, pan, zoom, and crosshair.
Range Area series use one atomic low/high interval per X value, or an explicit
gap, and can compose with ordinary Line, Area, Scatter, or Candlestick series.
Candlestick charts require finite X/open/high/low/close values per point and
support Line, Area, or Scatter overlays at matching X coordinates.
Bar charts additionally support grouped, overlaid, stacked, normalized, range,
waterfall, horizontal, benchmark, uncertainty, sequenced motion, and
collision-aware label models.
Pie and Donut charts support one categorical series, slice tooltips, selection,
labels, legend entries, and a Category / Value / Share data-table alternative.
Pie charts do not use axes, crosshair, pan, or zoom. Donut charts follow the
same radial interaction contract.
''',
    'input_schema': {
      'type': 'object',
      'properties': {
        'title': {
          'type': 'string',
          'description': 'Chart title displayed above the chart',
        },
        'chart_type': {
          'type': 'string',
          'enum': [
            'line',
            'area',
            'bar',
            'scatter',
            'candlestick',
            'heatmap',
            'pie',
            'donut',
          ],
          'description':
              'Type of chart to render. Pie and Donut show part-to-whole category contributions and require exactly one series.',
        },
        'series': {
          'type': 'array',
          'description':
              'One or more Cartesian series, or exactly one series for Pie and Donut.',
          'items': {
            'type': 'object',
            'properties': {
              'id': {
                'type': 'string',
                'description':
                    'Unique identifier for this series (e.g., "revenue", "temperature")',
              },
              'name': {
                'type': 'string',
                'description':
                    'Display name shown in legend (e.g., "Monthly Revenue")',
              },
              'color': {
                'type': 'string',
                'description':
                    'Hex color code (e.g., "#FF5733") or named color (e.g., "blue", "red")',
              },
              'unit': {
                'type': 'string',
                'description':
                    'Unit for Y-axis values (e.g., "W", "°C", "USD", "km/h")',
              },
              'type': {
                'type': 'string',
                'enum': [
                  'line',
                  'area',
                  'rangeArea',
                  'bar',
                  'scatter',
                  'candlestick',
                  'heatmap',
                  'pie',
                  'donut',
                ],
                'description':
                    'Optional concrete series family. Use rangeArea for atomic low/high intervals; it may be composed with other Cartesian series.',
              },
              'bar_group_id': {
                'type': 'string',
                'description':
                    'Bar-only named stack or overlay group. Series sharing an ID share one category slot.',
              },
              'bar_diverging_role': {
                'type': 'string',
                'enum': ['negative', 'neutral', 'positive'],
                'description':
                    'Per-series side in a diverging_stacked Likert composition. Source values remain positive magnitudes.',
              },
              'bar_overlay_width_factor': {
                'type': 'number',
                'exclusiveMinimum': 0,
                'maximum': 1,
                'description':
                    'Bar-only width of this overlaid layer relative to its resolved slot.',
              },
              'bar_overlay_offset_factor': {
                'type': 'number',
                'minimum': -1,
                'maximum': 1,
                'description':
                    'Bar-only category-axis shift for this overlaid layer.',
              },
              'bar_gradient_colors': {
                'type': 'array',
                'minItems': 2,
                'items': {'type': 'string'},
                'description':
                    'Bar-only per-series gradient override. Prefer this over a chart-level fixed gradient when series use distinct colors.',
              },
              'bar_gradient_stops': {
                'type': 'array',
                'minItems': 2,
                'items': {'type': 'number', 'minimum': 0, 'maximum': 1},
                'description':
                    'Per-series stops aligned with bar_gradient_colors.',
              },
              'bar_pattern': {
                'type': 'string',
                'enum': [
                  'none',
                  'diagonal_up',
                  'diagonal_down',
                  'crosshatch',
                  'horizontal',
                  'vertical',
                ],
                'description':
                    'Optional per-series non-color fill encoding for monochrome readability.',
              },
              'bar_pattern_color': {
                'type': 'string',
                'description':
                    'Optional per-series pattern color; omit for automatic contrast.',
              },
              'bar_pattern_spacing': {
                'type': 'number',
                'exclusiveMinimum': 0,
                'description': 'Per-series pattern spacing in pixels.',
              },
              'bar_pattern_stroke_width': {
                'type': 'number',
                'exclusiveMinimum': 0,
                'description': 'Per-series pattern stroke width in pixels.',
              },
              'bar_pattern_opacity': {
                'type': 'number',
                'minimum': 0,
                'maximum': 1,
                'description': 'Per-series pattern opacity.',
              },
              'bar_border_color': {
                'type': 'string',
                'description': 'Optional per-series bar-border override.',
              },
              'bar_track_color': {
                'type': 'string',
                'description': 'Optional per-series capacity-track override.',
              },
              'bar_bullet_ranges': {
                'type': 'array',
                'minItems': 1,
                'items': {
                  'type': 'object',
                  'properties': {
                    'end': {'type': 'number'},
                    'color': {'type': 'string'},
                    'label': {'type': 'string'},
                  },
                  'required': ['end', 'color'],
                },
                'description':
                    'Per-series qualitative bullet ranges ordered from the baseline outward.',
              },
              'bar_bullet_measure_thickness': {
                'type': 'number',
                'exclusiveMinimum': 0,
                'maximum': 1,
                'description':
                    'Actual measure thickness relative to its bullet range background.',
              },
              'bar_bullet_corner_radius': {
                'type': 'number',
                'minimum': 0,
                'description': 'Bullet range frame corner radius.',
              },
              'bar_label_color': {
                'type': 'string',
                'description': 'Optional per-series bar-label color override.',
              },
              'bar_animation_order': {
                'type': 'string',
                'enum': [
                  'together',
                  'forward',
                  'reverse',
                  'center_out',
                  'edges_in',
                ],
                'description':
                    'Optional per-series category sequencing override.',
              },
              'bar_animation_stagger': {
                'type': 'number',
                'minimum': 0,
                'exclusiveMaximum': 1,
                'description': 'Optional per-series stagger fraction override.',
              },
              'radius_label': {
                'type': 'string',
                'description':
                    'Radial-only label for the optional radius metric (for example, "Total area").',
              },
              'radius_unit': {
                'type': 'string',
                'description':
                    'Radial-only unit for the optional radius metric (for example, "km²").',
              },
              'heatmap_color_scale': {
                'type': 'object',
                'description':
                    'Heatmap-only numeric color mapping. Required for Heatmap series.',
                'properties': {
                  'type': {
                    'type': 'string',
                    'enum': ['sequential', 'diverging', 'threshold'],
                  },
                  'colors': {
                    'type': 'array',
                    'minItems': 1,
                    'items': {'type': 'string'},
                    'description':
                        'Sequential ramp colors, or threshold band colors.',
                  },
                  'low_color': {
                    'type': 'string',
                    'description': 'Diverging scale low color.',
                  },
                  'midpoint_color': {
                    'type': 'string',
                    'description': 'Diverging scale midpoint color.',
                  },
                  'high_color': {
                    'type': 'string',
                    'description': 'Diverging scale high color.',
                  },
                  'midpoint': {
                    'type': 'number',
                    'description': 'Diverging scale semantic midpoint.',
                  },
                  'thresholds': {
                    'type': 'array',
                    'items': {'type': 'number'},
                    'description':
                        'Strictly increasing threshold boundaries. Supply one more color than thresholds.',
                  },
                  'band_labels': {
                    'type': 'array',
                    'items': {'type': 'string'},
                    'description':
                        'Optional threshold label for every color band.',
                  },
                  'minimum': {'type': 'number'},
                  'maximum': {'type': 'number'},
                  'reverse': {'type': 'boolean'},
                  'clamp': {'type': 'boolean'},
                  'missing_color': {'type': 'string'},
                  'label': {'type': 'string'},
                  'unit': {'type': 'string'},
                  'show_legend': {'type': 'boolean'},
                },
                'required': ['type'],
              },
              'heatmap_cell_width': {'type': 'number', 'exclusiveMinimum': 0},
              'heatmap_cell_height': {'type': 'number', 'exclusiveMinimum': 0},
              'heatmap_gap_fraction': {
                'type': 'number',
                'minimum': 0,
                'exclusiveMaximum': 1,
              },
              'heatmap_border_color': {'type': 'string'},
              'heatmap_border_width': {'type': 'number', 'minimum': 0},
              'heatmap_corner_radius': {'type': 'number', 'minimum': 0},
              'heatmap_show_cell_labels': {'type': 'boolean'},
              'heatmap_cell_label_color': {'type': 'string'},
              'heatmap_cell_label_font_size': {
                'type': 'number',
                'exclusiveMinimum': 0,
              },
              'data': {
                'type': 'array',
                'description': 'Array of data points',
                'items': {
                  'type': 'object',
                  'properties': {
                    'x': {
                      'type': 'number',
                      'description':
                          'X-axis value for Cartesian charts. For Pie and Donut, this is only a stable finite ordering index.',
                    },
                    'y': {
                      'type': 'number',
                      'description':
                          'Y-axis value for Cartesian charts. For Pie and Donut, this is a finite non-negative contribution.',
                    },
                    'value': {
                      'type': 'number',
                      'description':
                          'Heatmap-only independent measured value encoded by color. Required unless missing is true.',
                    },
                    'missing': {
                      'type': 'boolean',
                      'description':
                          'Heatmap-only explicit missing cell. When true, omit value; the X/Y cell identity remains present.',
                    },
                    'open': {
                      'type': 'number',
                      'description':
                          'Candlestick-only opening value. Required for every candlestick point.',
                    },
                    'high': {
                      'type': 'number',
                      'description':
                          'Candlestick high, or Range Area upper bound. Must not be below the matching low value.',
                    },
                    'low': {
                      'type': 'number',
                      'description':
                          'Candlestick low, or Range Area lower bound. Must not exceed the matching high value.',
                    },
                    'close': {
                      'type': 'number',
                      'description':
                          'Candlestick-only closing value. Required instead of generic y.',
                    },
                    'gap': {
                      'type': 'boolean',
                      'description':
                          'Range Area-only explicit missing interval. When true, omit low, high, and y.',
                    },
                    'label': {
                      'type': 'string',
                      'description':
                          'Optional Cartesian point label. Required and non-empty for every Pie or Donut category.',
                    },
                    'point_key': {
                      'type': 'string',
                      'minLength': 1,
                      'description':
                          'Optional stable point identity, unique within its series. Preserves selection across reorder or stream eviction.',
                    },
                    'color': {
                      'type': 'string',
                      'description':
                          'Optional radial-slice color as a hex code or named color.',
                    },
                    'radius': {
                      'type': 'number',
                      'minimum': 0,
                      'description':
                          'Optional radial second metric controlling slice radius. Supply it for every radial point when used.',
                    },
                    'timestamp': {
                      'type': 'string',
                      'description':
                          'ISO 8601 timestamp if this is time-series data',
                    },
                    'bar_start': {
                      'type': 'number',
                      'description':
                          'Bar-only explicit start value for a floating range. Omit for a baseline bar.',
                    },
                    'bar_target': {
                      'type': 'number',
                      'description': 'Bar-only passive benchmark marker value.',
                    },
                    'bar_error_lower': {
                      'type': 'number',
                      'description':
                          'Bar-only lower uncertainty endpoint. Supply with bar_error_upper.',
                    },
                    'bar_error_upper': {
                      'type': 'number',
                      'description':
                          'Bar-only upper uncertainty endpoint. Supply with bar_error_lower.',
                    },
                    'bar_total': {
                      'type': 'boolean',
                      'description':
                          'Bar-only waterfall total column resolved from the running cumulative value.',
                    },
                  },
                  'required': ['x'],
                },
              },
            },
            'required': ['id', 'data'],
          },
        },
        'x_axis': {
          'type': 'object',
          'description':
              'Cartesian X-axis configuration. Omit when chart_type is pie or donut.',
          'properties': {
            'position': {
              'type': 'string',
              'enum': ['bottom', 'top', 'both'],
              'description':
                  'Visual edge used by the Cartesian X-axis, or both edges.',
            },
            'label': {
              'type': 'string',
              'description': 'Axis label (e.g., "Time", "Distance")',
            },
            'unit': {
              'type': 'string',
              'description': 'Unit suffix (e.g., "s", "km")',
            },
            'min': {
              'type': 'number',
              'description':
                  'Explicit minimum value (auto-calculated if omitted)',
            },
            'max': {
              'type': 'number',
              'description':
                  'Explicit maximum value (auto-calculated if omitted)',
            },
            'tick_label_rotation': {
              'type': 'number',
              'minimum': -90,
              'maximum': 90,
              'description':
                  'Clockwise rotation for every X-axis tick label in screen-space degrees.',
            },
            'tick_label_collision_policy': {
              'type': 'string',
              'enum': ['auto', 'show_all'],
              'description':
                  'Measure rotated X-axis labels and retain a readable subset, or paint every label.',
            },
            'tick_label_collision_padding': {
              'type': 'number',
              'minimum': 0,
              'description':
                  'Minimum horizontal gap in logical pixels between automatically retained X-axis labels.',
            },
            'categories': {
              'type': 'array',
              'minItems': 1,
              'items': {'type': 'string', 'minLength': 1},
              'description':
                  'Ordered category labels mapped to integer X values. Preferred for categorical bar charts.',
            },
            'category_label_density': {
              'type': 'string',
              'enum': ['auto', 'show_all'],
              'description':
                  'Thin category labels automatically or paint every visible label.',
            },
            'category_label_overflow': {
              'type': 'string',
              'enum': ['wrap', 'ellipsis'],
              'description': 'Wrap or truncate long category labels.',
            },
            'category_minimum_extent': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'description':
                  'Minimum logical pixels reserved per readable category.',
            },
            'category_maximum_label_extent': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'description':
                  'Maximum category-label width, including horizontal bars.',
            },
            'category_max_label_lines': {
              'type': 'integer',
              'minimum': 1,
              'description': 'Maximum wrapped lines for each category label.',
            },
            'category_label_rotation': {
              'type': 'number',
              'minimum': -90,
              'maximum': 90,
              'description':
                  'Clockwise category-label rotation in screen-space degrees.',
            },
            'category_auto_viewport': {
              'type': 'boolean',
              'description':
                  'Open a readable initial category window when all labels cannot fit.',
            },
          },
        },
        'y_axis': {
          'type': 'object',
          'description':
              'Cartesian Y-axis configuration. Omit for Pie and Donut; use series.unit for Cartesian multi-axis charts.',
          'properties': {
            'label': {
              'type': 'string',
              'description': 'Axis label (e.g., "Power", "Temperature")',
            },
            'unit': {
              'type': 'string',
              'description': 'Unit suffix (e.g., "W", "°C")',
            },
            'min': {'type': 'number', 'description': 'Explicit minimum value'},
            'max': {'type': 'number', 'description': 'Explicit maximum value'},
            'position': {
              'type': 'string',
              'enum': ['left', 'right'],
              'description': 'Which side to show the Y-axis',
            },
          },
        },
        'interactions': {
          'type': 'object',
          'description': 'Interaction configuration',
          'properties': {
            'enable_pan': {
              'type': 'boolean',
              'description':
                  'Allow horizontal panning for Cartesian charts. Always false for pie.',
            },
            'enable_zoom': {
              'type': 'boolean',
              'description':
                  'Allow pinch/scroll zoom for Cartesian charts. Always false for pie.',
            },
            'show_crosshair': {
              'type': 'boolean',
              'description':
                  'Show a Cartesian crosshair on hover. Always false for pie.',
            },
            'show_tooltip': {
              'type': 'boolean',
              'description': 'Show value tooltip on hover (default: true)',
            },
            'enable_selection': {
              'type': 'boolean',
              'description': 'Allow durable chart selection (default: true)',
            },
            'selection_scope': {
              'type': 'string',
              'enum': [
                'mark',
                'category',
                'category_stack',
                'whole_series',
                'mark_or_whole_series',
              ],
              'description':
                  'Select one represented mark, every compatible mark at its category, contributors in that category stack, the complete owning series, or whichever of a mark or complete series the pointer targets.',
            },
            'selection_operation': {
              'type': 'string',
              'enum': ['replace', 'add', 'subtract', 'toggle'],
              'description':
                  'Set operation applied when a Cartesian point is selected.',
            },
            'selection_drag_activation': {
              'type': 'string',
              'enum': ['primary_button', 'shift_primary_button'],
              'description':
                  'Primary-button chord reserved by rectangle or lasso selection. Point selection remains tap-only.',
            },
            'selection_clear_on_background_tap': {
              'type': 'boolean',
              'description':
                  'Clear point selection when the plot background is tapped.',
            },
            'selection_use_modifier_keys': {
              'type': 'boolean',
              'description':
                  'Let Ctrl/Command toggle, Shift add, and Alt/Option subtract.',
            },
            'selection_data_point_hit_radius': {
              'type': 'number',
              'minimum': 0,
              'description':
                  'Screen-space hover and selection radius around data points.',
            },
            'selection_complete_series_hit_radius': {
              'type': 'number',
              'minimum': 0,
              'description':
                  'Screen-space hover and selection radius around complete Line or Area paths.',
            },
            'selection_data_point_hover_scale': {
              'type': 'number',
              'minimum': 1,
              'description': 'Hover scale for Line or Area data-point markers.',
            },
            'selection_data_point_selection_scale': {
              'type': 'number',
              'minimum': 1,
              'description':
                  'Durable selection-halo scale for Line or Area data points.',
            },
            'selection_complete_series_hover_stroke_scale': {
              'type': 'number',
              'minimum': 1,
              'description':
                  'Stroke-width scale for a hovered complete Line or Area series.',
            },
            'selection_complete_series_selection_stroke_scale': {
              'type': 'number',
              'minimum': 1,
              'description':
                  'Stroke-width scale for a selected complete Line or Area series.',
            },
          },
        },
        'style': {
          'type': 'object',
          'description': 'Visual styling options',
          'properties': {
            'line_interpolation': {
              'type': 'string',
              'enum': ['linear', 'bezier', 'stepped', 'monotone'],
              'description':
                  'How to interpolate between points for line/area charts',
            },
            'show_grid': {
              'type': 'boolean',
              'description': 'Show background grid lines (default: true)',
            },
            'show_legend': {
              'type': 'boolean',
              'description': 'Show legend for multiple series (default: true)',
            },
            'scatter_render_mode': {
              'type': 'string',
              'enum': [
                'points',
                'clusters',
                'rectangular_bins',
                'hexbin',
                'density',
              ],
              'description':
                  'Scatter-only explicit rendering strategy. Dense modes aggregate visible observations in screen space while retaining raw source data.',
            },
            'scatter_marker_radius': {
              'type': 'number',
              'minimum': 0,
              'description': 'Scatter point marker radius in logical pixels.',
            },
            'scatter_cluster_cell_size': {
              'type': 'number',
              'minimum': 8,
              'maximum': 256,
              'description':
                  'Scatter cluster aggregation cell size in logical pixels.',
            },
            'scatter_cluster_minimum_points': {
              'type': 'integer',
              'minimum': 2,
              'description':
                  'Observations required before a screen-space cell becomes a cluster.',
            },
            'scatter_cluster_minimum_radius': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'maximum': 128,
              'description': 'Radius of the smallest visible Scatter cluster.',
            },
            'scatter_cluster_maximum_radius': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'maximum': 128,
              'description': 'Radius of the largest visible Scatter cluster.',
            },
            'scatter_cluster_show_labels': {
              'type': 'boolean',
              'description': 'Show observation counts inside Scatter clusters.',
            },
            'scatter_cluster_label_minimum_points': {
              'type': 'integer',
              'minimum': 2,
              'description':
                  'Smallest cluster count that receives an on-marker label.',
            },
            'scatter_cluster_show_zones': {
              'type': 'boolean',
              'description':
                  'Show the subtle screen-space extent represented by each Scatter cluster.',
            },
            'scatter_cluster_zone_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Fill opacity used by Scatter cluster zones.',
            },
            'scatter_cluster_drill_on_tap': {
              'type': 'boolean',
              'description':
                  'Narrow the existing viewport to a cluster source extent when activated.',
            },
            'scatter_cluster_drill_padding': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description':
                  'Fractional data-space padding around drill-to-cluster bounds.',
            },
            'scatter_bin_cell_size': {
              'type': 'number',
              'minimum': 12,
              'maximum': 256,
              'description':
                  'Rectangular cell width or flat-top hexagon diameter in logical pixels.',
            },
            'scatter_bin_gap': {
              'type': 'number',
              'minimum': 0,
              'maximum': 16,
              'description': 'Visual separation between adjacent Scatter bins.',
            },
            'scatter_bin_minimum_points': {
              'type': 'integer',
              'minimum': 1,
              'description':
                  'Observations required before an occupied Scatter bin is rendered.',
            },
            'scatter_bin_minimum_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Opacity of the least populated visible bin.',
            },
            'scatter_bin_maximum_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Opacity of the highest aggregate visible bin.',
            },
            'scatter_bin_aggregate': {
              'type': 'string',
              'enum': [
                'count',
                'sum',
                'mean',
                'minimum',
                'maximum',
                'proportion',
              ],
              'description':
                  'Statistic mapped to bin opacity and optional labels.',
            },
            'scatter_bin_value_source': {
              'type': 'string',
              'enum': ['x', 'y', 'magnitude', 'color_value', 'opacity_value'],
              'description':
                  'Point field used by sum, mean, minimum, and maximum aggregates.',
            },
            'scatter_bin_show_labels': {
              'type': 'boolean',
              'description': 'Show aggregate values inside Scatter bins.',
            },
            'scatter_bin_label_minimum_points': {
              'type': 'integer',
              'minimum': 1,
              'description':
                  'Smallest bin count that receives an on-bin label.',
            },
            'scatter_density_grid_cell_size': {
              'type': 'number',
              'minimum': 4,
              'maximum': 64,
              'description':
                  'Spacing between Scatter density samples in logical pixels.',
            },
            'scatter_density_bandwidth': {
              'type': 'number',
              'minimum': 4,
              'maximum': 256,
              'description':
                  'Gaussian smoothing bandwidth for Scatter density in logical pixels.',
            },
            'scatter_density_contour_count': {
              'type': 'integer',
              'minimum': 2,
              'maximum': 12,
              'description': 'Number of relative-density isolines.',
            },
            'scatter_density_minimum': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'exclusiveMaximum': 1,
              'description':
                  'Lowest relative density included in the contours.',
            },
            'scatter_density_minimum_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Opacity of the outermost density contour.',
            },
            'scatter_density_maximum_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Opacity of the innermost density contour.',
            },
            'scatter_density_line_width': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'maximum': 12,
              'description': 'Density contour stroke width in logical pixels.',
            },
            'scatter_density_show_points': {
              'type': 'boolean',
              'description':
                  'Render raw observations above the density contours.',
            },
            'height': {
              'type': 'number',
              'description': 'Chart height in pixels (default: 300)',
            },
            'bar_layout': {
              'type': 'string',
              'enum': [
                'grouped',
                'overlaid',
                'stacked',
                'normalized_stacked',
                'diverging_stacked',
                'waterfall',
              ],
              'description': 'Bar-only category-slot composition mode.',
            },
            'bar_orientation': {
              'type': 'string',
              'enum': ['vertical', 'horizontal'],
              'description': 'Bar-only screen orientation.',
            },
            'bar_width_percent': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Bar width as a fraction of its category slot.',
            },
            'bar_min_width': {
              'type': 'number',
              'minimum': 0,
              'description': 'Minimum rendered bar thickness.',
            },
            'bar_max_width': {
              'type': 'number',
              'minimum': 0,
              'description': 'Maximum rendered bar thickness.',
            },
            'bar_gap': {
              'type': 'number',
              'minimum': 0,
              'description': 'Logical-pixel gap between grouped bars.',
            },
            'bar_baseline': {
              'type': 'number',
              'description':
                  'Value-axis baseline from which ordinary bars grow.',
            },
            'bar_minimum_length': {
              'type': 'number',
              'minimum': 0,
              'description': 'Minimum visible value-axis bar length in pixels.',
            },
            'bar_corner_radius': {
              'type': 'number',
              'minimum': 0,
              'description': 'Bar corner radius in logical pixels.',
            },
            'bar_corner_policy': {
              'type': 'string',
              'enum': ['value_end', 'all'],
              'description':
                  'Round only the exposed value end or every corner.',
            },
            'bar_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Base bar opacity.',
            },
            'bar_animation_mode': {
              'type': 'string',
              'enum': ['grow', 'none'],
              'description': 'Bar entrance and data-update animation behavior.',
            },
            'bar_animation_order': {
              'type': 'string',
              'enum': [
                'together',
                'forward',
                'reverse',
                'center_out',
                'edges_in',
              ],
              'description':
                  'Category order used to sequence bar entrance and updates.',
            },
            'bar_animation_stagger': {
              'type': 'number',
              'minimum': 0,
              'exclusiveMaximum': 1,
              'description':
                  'Fraction of the shared animation timeline used for staggered starts.',
            },
            'bar_gradient_colors': {
              'type': 'array',
              'minItems': 2,
              'items': {'type': 'string'},
              'description':
                  'Bar gradient colors ordered from baseline to value end.',
            },
            'bar_gradient_stops': {
              'type': 'array',
              'minItems': 2,
              'items': {'type': 'number', 'minimum': 0, 'maximum': 1},
              'description':
                  'Optional stops aligned one-for-one with bar_gradient_colors.',
            },
            'bar_pattern': {
              'type': 'string',
              'enum': [
                'none',
                'diagonal_up',
                'diagonal_down',
                'crosshatch',
                'horizontal',
                'vertical',
              ],
              'description':
                  'Non-color fill encoding shared by bar series unless overridden.',
            },
            'bar_pattern_color': {
              'type': 'string',
              'description':
                  'Pattern color; omit to derive black or white from the bar fill.',
            },
            'bar_pattern_spacing': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'description': 'Pattern spacing in logical pixels.',
            },
            'bar_pattern_stroke_width': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'description': 'Pattern stroke width in logical pixels.',
            },
            'bar_pattern_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Pattern opacity.',
            },
            'bar_border_color': {
              'type': 'string',
              'description': 'Optional bar outline color.',
            },
            'bar_border_width': {
              'type': 'number',
              'minimum': 0,
              'description': 'Bar outline width.',
            },
            'bar_track_enabled': {
              'type': 'boolean',
              'description': 'Show a passive capacity track behind each bar.',
            },
            'bar_track_color': {
              'type': 'string',
              'description': 'Capacity-track fill color.',
            },
            'bar_track_value': {
              'type': 'number',
              'description':
                  'Explicit capacity value; omit to use the visible axis boundary.',
            },
            'bar_track_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Capacity-track opacity.',
            },
            'bar_track_corner_radius': {
              'type': 'number',
              'minimum': 0,
              'description': 'Capacity-track corner radius.',
            },
            'bar_lollipop_enabled': {
              'type': 'boolean',
              'description':
                  'Replace each filled bar with a stem and circular value marker.',
            },
            'bar_lollipop_stem_width': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'description': 'Lollipop stem width in logical pixels.',
            },
            'bar_lollipop_head_radius': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'description': 'Lollipop value-marker radius in logical pixels.',
            },
            'bar_lollipop_stem_color': {
              'type': 'string',
              'description':
                  'Optional stem color; omit to inherit the series or point color.',
            },
            'bar_lollipop_head_color': {
              'type': 'string',
              'description':
                  'Optional marker color; omit to inherit the series or point color.',
            },
            'bar_lollipop_head_border_color': {
              'type': 'string',
              'description': 'Optional lollipop marker outline color.',
            },
            'bar_lollipop_head_border_width': {
              'type': 'number',
              'minimum': 0,
              'description': 'Lollipop marker outline width.',
            },
            'bar_bullet_ranges': {
              'type': 'array',
              'minItems': 1,
              'items': {
                'type': 'object',
                'properties': {
                  'end': {'type': 'number'},
                  'color': {'type': 'string'},
                  'label': {'type': 'string'},
                },
                'required': ['end', 'color'],
              },
              'description':
                  'Qualitative bullet ranges ordered from the baseline outward. Pair with per-point bar_target values for comparison markers.',
            },
            'bar_bullet_measure_thickness': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'maximum': 1,
              'description':
                  'Actual measure thickness relative to its bullet range background.',
            },
            'bar_bullet_corner_radius': {
              'type': 'number',
              'minimum': 0,
              'description': 'Bullet range frame corner radius.',
            },
            'bar_diverging_center_line_show': {
              'type': 'boolean',
              'description':
                  'Show the shared baseline through a diverging_stacked composition.',
            },
            'bar_diverging_center_line_color': {
              'type': 'string',
              'description': 'Diverging composition center-line color.',
            },
            'bar_diverging_center_line_width': {
              'type': 'number',
              'minimum': 0,
              'description': 'Diverging composition center-line width.',
            },
            'bar_diverging_center_line_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Diverging composition center-line opacity.',
            },
            'bar_target_color': {
              'type': 'string',
              'description': 'Color for per-point bar_target markers.',
            },
            'bar_target_width': {
              'type': 'number',
              'minimum': 0,
              'description': 'Benchmark marker stroke width.',
            },
            'bar_target_length_factor': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'description': 'Benchmark span relative to the bar thickness.',
            },
            'bar_target_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Benchmark marker opacity.',
            },
            'bar_error_color': {
              'type': 'string',
              'description': 'Color for bar uncertainty stems and caps.',
            },
            'bar_error_width': {
              'type': 'number',
              'minimum': 0,
              'description': 'Uncertainty line width.',
            },
            'bar_error_cap_length_factor': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'description': 'Uncertainty cap span relative to bar thickness.',
            },
            'bar_error_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Uncertainty line opacity.',
            },
            'bar_waterfall_increase_color': {
              'type': 'string',
              'description': 'Waterfall-only positive-delta color.',
            },
            'bar_waterfall_decrease_color': {
              'type': 'string',
              'description': 'Waterfall-only negative-delta color.',
            },
            'bar_waterfall_total_color': {
              'type': 'string',
              'description': 'Waterfall-only cumulative-total color.',
            },
            'bar_waterfall_connector_show': {
              'type': 'boolean',
              'description': 'Draw cumulative waterfall connector lines.',
            },
            'bar_waterfall_connector_color': {
              'type': 'string',
              'description': 'Waterfall connector color.',
            },
            'bar_waterfall_connector_width': {
              'type': 'number',
              'minimum': 0,
              'description': 'Waterfall connector width.',
            },
            'bar_hover_color': {
              'type': 'string',
              'description': 'Optional hover overlay color.',
            },
            'bar_hover_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Hover overlay opacity.',
            },
            'bar_hover_border_width': {
              'type': 'number',
              'minimum': 0,
              'description': 'Hover outline width.',
            },
            'bar_pressed_color': {
              'type': 'string',
              'description': 'Pressed-state overlay color.',
            },
            'bar_pressed_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Pressed-state overlay opacity.',
            },
            'bar_selection_color': {
              'type': 'string',
              'description': 'Durable selected-bar overlay color.',
            },
            'bar_selection_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Selected-bar overlay opacity.',
            },
            'bar_selection_border_width': {
              'type': 'number',
              'minimum': 0,
              'description': 'Selected-bar outline width.',
            },
            'bar_focus_color': {
              'type': 'string',
              'description': 'Keyboard-focus outline color.',
            },
            'bar_focus_border_width': {
              'type': 'number',
              'minimum': 0,
              'description': 'Keyboard-focus outline width.',
            },
            'bar_focus_gap': {
              'type': 'number',
              'minimum': 0,
              'description': 'Gap between a focused bar and its outline.',
            },
            'bar_dimmed_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description':
                  'Opacity multiplier for unselected bars while a selection is active.',
            },
            'bar_labels_show': {
              'type': 'boolean',
              'description': 'Show bar-native value labels.',
            },
            'bar_label_position': {
              'type': 'string',
              'enum': [
                'auto',
                'inside_end',
                'inside_center',
                'outside_end',
                'range_ends',
              ],
              'description': 'Requested label placement relative to each bar.',
            },
            'bar_label_value_mode': {
              'type': 'string',
              'enum': ['value', 'range', 'percentage', 'waterfall'],
              'description': 'Value represented by each bar label.',
            },
            'bar_label_color': {
              'type': 'string',
              'description':
                  'Optional fixed label color; omit for automatic contrast.',
            },
            'bar_label_font_size': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'description': 'Bar-label font size.',
            },
            'bar_label_font_weight': {
              'type': 'integer',
              'enum': [100, 200, 300, 400, 500, 600, 700, 800, 900],
              'description': 'Bar-label font weight.',
            },
            'bar_label_show_unit': {
              'type': 'boolean',
              'description': 'Append the series unit to bar labels.',
            },
            'bar_label_padding': {
              'type': 'number',
              'minimum': 0,
              'description': 'Gap between an end label and its bar edge.',
            },
            'bar_label_collision': {
              'type': 'string',
              'enum': ['none', 'reposition', 'hide'],
              'description': 'Chart-wide label collision policy.',
            },
            'bar_label_plot_edge_aware': {
              'type': 'boolean',
              'description': 'Keep label boxes inside the visible plot.',
            },
            'bar_label_collision_padding': {
              'type': 'number',
              'minimum': 0,
              'description': 'Minimum gap around accepted label boxes.',
            },
            'bar_label_background_color': {
              'type': 'string',
              'description': 'Optional compact bar-label background color.',
            },
            'bar_label_border_color': {
              'type': 'string',
              'description': 'Optional bar-label box outline color.',
            },
            'bar_label_border_width': {
              'type': 'number',
              'minimum': 0,
              'description': 'Bar-label box outline width.',
            },
            'bar_label_border_radius': {
              'type': 'number',
              'minimum': 0,
              'description': 'Bar-label box corner radius.',
            },
            'bar_label_background_padding': {
              'type': 'number',
              'minimum': 0,
              'description': 'Inset between label text and its box.',
            },
            'bar_label_callout_show': {
              'type': 'boolean',
              'description': 'Connect displaced labels to their value ends.',
            },
            'bar_label_callout_color': {
              'type': 'string',
              'description': 'Optional fixed callout-line color.',
            },
            'bar_label_callout_width': {
              'type': 'number',
              'minimum': 0,
              'description': 'Callout-line width.',
            },
            'bar_label_callout_minimum_length': {
              'type': 'number',
              'minimum': 0,
              'description': 'Shortest callout line eligible to paint.',
            },
            'bar_label_show_stack_total': {
              'type': 'boolean',
              'description':
                  'Show one resolved total at each exposed stack end.',
            },
            'donut_inner_radius_factor': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'exclusiveMaximum': 1,
              'description':
                  'Donut-only circular opening as a fraction of the outer radius (default: 0.58).',
            },
            'donut_sweep_angle': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'maximum': 360,
              'description':
                  'Donut-only total angular span in degrees (default: 360).',
            },
            'donut_center_visible': {
              'type': 'boolean',
              'description':
                  'Show portable text content inside the Donut opening.',
            },
            'donut_center_value_mode': {
              'type': 'string',
              'enum': [
                'total',
                'selected_value',
                'selected_or_total',
                'custom',
              ],
              'description':
                  'Donut center value source. Selected modes follow the durable slice selection.',
            },
            'donut_center_label': {
              'type': 'string',
              'description':
                  'Optional short label above the Donut center value.',
            },
            'donut_center_custom_value': {
              'type': 'string',
              'description':
                  'Portable custom center text required when donut_center_value_mode is custom.',
            },
            'pie_start_angle': {
              'type': 'number',
              'description':
                  'Radial Pie/Donut starting angle in degrees (default: -90).',
            },
            'pie_clockwise': {
              'type': 'boolean',
              'description':
                  'Radial Pie/Donut slice direction (default: clockwise).',
            },
            'pie_radius_factor': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'maximum': 1,
              'description':
                  'Radial Pie/Donut outer-radius factor in the range (0, 1].',
            },
            'pie_radius_minimum_factor': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description':
                  'Radial Pie/Donut minimum variable slice radius as a fraction of the maximum radius.',
            },
            'pie_radius_scale': {
              'type': 'string',
              'enum': ['area', 'linear'],
              'description':
                  'Radial Pie/Donut mapping for optional per-point radius values. Area is the perceptual default.',
            },
            'pie_slice_gap': {
              'type': 'number',
              'minimum': 0,
              'description':
                  'Radial Pie/Donut logical-pixel gap between slices.',
            },
            'pie_border_width': {
              'type': 'number',
              'minimum': 0,
              'description': 'Radial Pie/Donut slice-border width.',
            },
            'pie_border_color': {
              'type': 'string',
              'description':
                  'Radial Pie/Donut fixed shared slice-border color. When supplied, this overrides the border color mode.',
            },
            'pie_border_color_mode': {
              'type': 'string',
              'enum': ['chart_theme', 'slice'],
              'description':
                  'Radial Pie/Donut fallback border policy: chart axis color or a color derived independently from each slice.',
            },
            'pie_border_hue_shift': {
              'type': 'number',
              'description':
                  'Hue rotation in degrees for slice-derived radial borders.',
            },
            'pie_border_saturation_shift': {
              'type': 'number',
              'minimum': -1,
              'maximum': 1,
              'description':
                  'Additive HSL saturation shift for slice-derived radial borders.',
            },
            'pie_border_lightness_shift': {
              'type': 'number',
              'minimum': -1,
              'maximum': 1,
              'description':
                  'Additive HSL lightness shift for slice-derived radial borders; negative values create darker borders.',
            },
            'pie_gradient_enabled': {
              'type': 'boolean',
              'description':
                  'Whether the radial Pie/Donut slice gradient is enabled. A disabled series gradient can opt out of a theme gradient.',
            },
            'pie_gradient_type': {
              'type': 'string',
              'enum': ['linear', 'radial'],
              'description':
                  'Radial Pie/Donut gradient geometry shared across all slices.',
            },
            'pie_gradient_start_color': {
              'type': 'string',
              'description':
                  'Optional fixed first gradient-stop color. Omit to derive it from each slice color.',
            },
            'pie_gradient_end_color': {
              'type': 'string',
              'description':
                  'Optional fixed final gradient-stop color. Omit to derive it from each slice color.',
            },
            'pie_gradient_start_lightness_shift': {
              'type': 'number',
              'minimum': -1,
              'maximum': 1,
              'description':
                  'Additive HSL lightness shift for a derived first gradient stop.',
            },
            'pie_gradient_end_lightness_shift': {
              'type': 'number',
              'minimum': -1,
              'maximum': 1,
              'description':
                  'Additive HSL lightness shift for a derived final gradient stop.',
            },
            'pie_gradient_angle': {
              'type': 'number',
              'description':
                  'Linear radial-slice gradient direction in screen-space degrees; zero points right and 90 points down.',
            },
            'pie_selection_explode_offset': {
              'type': 'number',
              'minimum': 0,
              'description':
                  'Radial Pie/Donut offset applied to a selected slice.',
            },
            'pie_selection_effect': {
              'type': 'string',
              'enum': ['explode', 'lift'],
              'description':
                  'Pie-only selected-slice treatment: move outward or lift towards the viewer.',
            },
            'pie_selection_lift_scale': {
              'type': 'number',
              'minimum': 1,
              'maximum': 1.5,
              'description':
                  'Pie-only final scale applied around a lifted slice centroid.',
            },
            'pie_selection_lift_offset': {
              'type': 'number',
              'minimum': 0,
              'maximum': 40,
              'description':
                  'Pie-only radial offset that pulls a lifted slice away from the chart center.',
            },
            'pie_selection_backdrop_blur': {
              'type': 'number',
              'minimum': 0,
              'maximum': 20,
              'description':
                  'Pie-only blur sigma applied to unselected slices during a lift.',
            },
            'pie_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description':
                  'Radial Pie/Donut slice opacity in the range [0, 1].',
            },
            'pie_corner_radius': {
              'type': 'number',
              'minimum': 0,
              'description':
                  'Radial Pie/Donut rounded-corner radius in logical pixels.',
            },
            'pie_corner_treatment': {
              'type': 'string',
              'enum': ['round_all', 'outer_only', 'circular_center'],
              'description':
                  'Radial Pie/Donut policy for rounding every corner, only outer corners, or creating a uniform circular center gap.',
            },
            'pie_shadow_color': {
              'type': 'string',
              'description': 'Optional radial-slice shadow color.',
            },
            'pie_shadow_blur': {
              'type': 'number',
              'minimum': 0,
              'description': 'Radial-slice shadow blur radius.',
            },
            'pie_shadow_spread': {
              'type': 'number',
              'minimum': 0,
              'description': 'Radial-slice shadow spread radius.',
            },
            'pie_shadow_offset_x': {
              'type': 'number',
              'description': 'Horizontal radial-slice shadow offset.',
            },
            'pie_shadow_offset_y': {
              'type': 'number',
              'description': 'Vertical radial-slice shadow offset.',
            },
            'pie_shadow_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Radial-slice shadow opacity.',
            },
            'pie_selected_glow_color': {
              'type': 'string',
              'description':
                  'Optional fixed selected-slice glow color; omit to derive it from each slice.',
            },
            'pie_selected_glow_blur': {
              'type': 'number',
              'minimum': 0,
              'description': 'Blur radius for selected-slice elevation.',
            },
            'pie_selected_glow_spread': {
              'type': 'number',
              'minimum': 0,
              'description': 'Spread radius for selected-slice elevation.',
            },
            'pie_selected_glow_offset_x': {
              'type': 'number',
              'description': 'Horizontal selected-slice elevation offset.',
            },
            'pie_selected_glow_offset_y': {
              'type': 'number',
              'description': 'Vertical selected-slice elevation offset.',
            },
            'pie_selected_glow_opacity': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Selected-slice elevation opacity.',
            },
            'pie_animation_mode': {
              'type': 'string',
              'enum': ['none', 'grow', 'sweep', 'fade'],
              'description': 'Radial Pie/Donut entrance animation mode.',
            },
            'pie_grouping_minimum_share': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'exclusiveMaximum': 1,
              'description':
                  'Group positive Pie/Donut categories below this fractional share into one visible slice. Original rows remain available to tables and exports.',
            },
            'pie_grouping_minimum_source_count': {
              'type': 'integer',
              'minimum': 2,
              'description':
                  'Minimum number of qualifying source categories required before a grouped slice is created.',
            },
            'pie_grouping_label': {
              'type': 'string',
              'minLength': 1,
              'description': 'Label for the grouped radial slice.',
            },
            'pie_grouping_color': {
              'type': 'string',
              'description':
                  'Optional fixed color for the grouped radial slice.',
            },
            'show_data_labels': {
              'type': 'boolean',
              'description': 'Show labels on eligible Pie/Donut slices.',
            },
            'pie_label_position': {
              'type': 'string',
              'enum': ['inside', 'outside'],
              'description': 'Radial Pie/Donut data-label placement.',
            },
            'pie_label_content': {
              'type': 'string',
              'enum': [
                'category',
                'value',
                'percentage',
                'category_and_value',
                'category_and_percentage',
                'value_and_percentage',
                'category_value_and_percentage',
              ],
              'description': 'Radial Pie/Donut label content.',
            },
            'pie_secondary_label_content': {
              'type': 'string',
              'enum': [
                'category',
                'value',
                'percentage',
                'category_and_value',
                'category_and_percentage',
                'value_and_percentage',
                'category_value_and_percentage',
              ],
              'description':
                  'Optional second radial label layer, such as a percentage badge inside a slice whose category label is outside.',
            },
            'pie_secondary_label_position': {
              'type': 'string',
              'enum': ['inside', 'outside'],
              'description':
                  'Placement for the optional secondary label. It must differ from pie_label_position.',
            },
            'pie_label_minimum_share': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description': 'Minimum radial-slice share eligible for a label.',
            },
            'pie_label_minimum_sweep': {
              'type': 'number',
              'minimum': 0,
              'maximum': 360,
              'description':
                  'Minimum radial-slice sweep in degrees eligible for a label.',
            },
            'pie_inside_label_offset': {
              'type': 'number',
              'description':
                  'Signed logical-pixel radial offset for inside Pie/Donut labels. Positive moves toward the outer edge; negative moves toward the center.',
            },
            'pie_label_offset': {
              'type': 'number',
              'minimum': 0,
              'description':
                  'Horizontal logical-pixel gap between the Pie/Donut and outside labels. Zero keeps labels tight to the chart.',
            },
            'candlestick_body_fill': {
              'type': 'string',
              'enum': ['hollow_rising', 'filled'],
              'description':
                  'Candlestick-only: body fill treatment. hollow_rising draws rising candles hollow; filled fills every body.',
            },
            'candlestick_body_width_factor': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'maximum': 1,
              'description':
                  'Candlestick-only: candle body width relative to its X slot.',
            },
            'candlestick_border_width': {
              'type': 'number',
              'minimum': 0,
              'description': 'Candlestick-only: candle body outline width.',
            },
            'candlestick_wick_width': {
              'type': 'number',
              'minimum': 0,
              'description': 'Candlestick-only: candle wick stroke width.',
            },
            'candlestick_corner_radius': {
              'type': 'number',
              'minimum': 0,
              'description': 'Candlestick-only: candle body corner radius.',
            },
            'candlestick_animation_mode': {
              'type': 'string',
              'enum': ['none', 'reveal'],
              'description': 'Candlestick-only: entrance animation behavior.',
            },
            'candlestick_animation_stagger': {
              'type': 'number',
              'minimum': 0,
              'maximum': 1,
              'description':
                  'Candlestick-only: fraction of the reveal timeline used to stagger candles.',
            },
            'candlestick_density_grouping': {
              'type': 'boolean',
              'description':
                  'Candlestick-only: combine dense visible candles into OHLC groups. Source points are unchanged; grouping is a render/interaction projection.',
            },
            'candlestick_target_group_width': {
              'type': 'number',
              'exclusiveMinimum': 0,
              'description':
                  'Candlestick-only: desired plot-space width in logical pixels per grouped candle. Grouping activates only when visible density would fall below this.',
            },
            'candlestick_minimum_points_per_group': {
              'type': 'integer',
              'minimum': 2,
              'description':
                  'Candlestick-only: smallest number of source candles represented by a grouped candle.',
            },
          },
        },
      },
      'allOf': [
        {
          'if': {
            'properties': {
              'chart_type': {'const': 'candlestick'},
            },
            'required': ['chart_type'],
          },
          'then': {
            'properties': {
              'series': {
                'items': {
                  'properties': {
                    'data': {
                      'items': {
                        'required': ['x', 'open', 'high', 'low', 'close'],
                      },
                    },
                  },
                },
              },
            },
          },
          'else': {
            'properties': {
              'series': {
                'items': {
                  'properties': {
                    'data': {
                      'items': {
                        'anyOf': [
                          {
                            'required': ['x', 'y'],
                          },
                          {
                            'required': ['x', 'low', 'high'],
                          },
                          {
                            'properties': {
                              'gap': {'const': true},
                            },
                            'required': ['x', 'gap'],
                          },
                        ],
                      },
                    },
                  },
                },
              },
            },
          },
        },
      ],
      'required': ['series'],
    },
  };

  /// Tool for modifying an existing chart.
  static const Map<String, dynamic> modifyChartTool = {
    'name': 'modify_chart',
    'description': '''
Modifies an existing chart by updating its configuration or data.
Use this when the user wants to change aspects of a chart that was already created.
''',
    'input_schema': {
      'type': 'object',
      'properties': {
        'chart_id': {
          'type': 'string',
          'description': 'ID of the chart to modify',
        },
        'action': {
          'type': 'string',
          'enum': [
            'add_series',
            'remove_series',
            'update_series',
            'change_type',
            'update_axis',
            'add_annotation',
            'zoom_to_range',
            'reset_view',
          ],
          'description': 'The modification action to perform',
        },
        'parameters': {
          'type': 'object',
          'description': 'Action-specific parameters',
        },
      },
      'required': ['chart_id', 'action'],
    },
  };

  /// Tool for analyzing/explaining data patterns.
  static const Map<String, dynamic> explainDataTool = {
    'name': 'explain_data',
    'description': '''
Analyzes data and explains patterns, trends, or anomalies.
Use this tool to provide insights about the data being visualized.
Returns statistical analysis and natural language explanations.
''',
    'input_schema': {
      'type': 'object',
      'properties': {
        'chart_id': {
          'type': 'string',
          'description': 'ID of the chart containing the data to analyze',
        },
        'analysis_type': {
          'type': 'string',
          'enum': [
            'summary',
            'trends',
            'anomalies',
            'correlations',
            'comparison',
          ],
          'description': 'Type of analysis to perform',
        },
        'series_ids': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': 'Specific series to analyze (all if omitted)',
        },
      },
      'required': ['analysis_type'],
    },
  };

  /// Returns the tool schema in Anthropic's format.
  static List<Map<String, dynamic>> toAnthropicFormat() {
    return tools.map((tool) {
      return {
        'name': tool['name'],
        'description': tool['description'],
        'input_schema': tool['input_schema'],
      };
    }).toList();
  }

  /// Returns the tool schema in OpenAI's format.
  static List<Map<String, dynamic>> toOpenAIFormat() {
    return tools.map((tool) {
      return {
        'type': 'function',
        'function': {
          'name': tool['name'],
          'description': tool['description'],
          'parameters': tool['input_schema'],
        },
      };
    }).toList();
  }
}
