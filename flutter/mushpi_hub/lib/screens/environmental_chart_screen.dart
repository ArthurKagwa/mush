import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

import '../data/database/app_database.dart';
import '../providers/readings_provider.dart';
import '../providers/current_farm_provider.dart';
import '../providers/farms_provider.dart';

/// Environmental Chart Screen displaying trend data with customizable time range.
///
/// Shows line charts for:
/// - Temperature (°C)
/// - Humidity (%)
/// - CO₂ (ppm)
/// - Light (raw value)
///
/// Automatically loads data for the currently selected monitoring farm.
/// Supports custom date range selection (defaults to last 24 hours).
class EnvironmentalChartScreen extends ConsumerStatefulWidget {
  const EnvironmentalChartScreen({super.key});

  @override
  ConsumerState<EnvironmentalChartScreen> createState() =>
      _EnvironmentalChartScreenState();
}

class _EnvironmentalChartScreenState
    extends ConsumerState<EnvironmentalChartScreen> {
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _useCustomRange = false;

  @override
  Widget build(BuildContext context) {
    final selectedFarmId = ref.watch(selectedMonitoringFarmIdProvider);
    final farmsAsync = ref.watch(activeFarmsProvider);

    // Use custom range provider if custom range is selected, otherwise use 24-hour provider
    final readingsAsync = _useCustomRange &&
            _customStartDate != null &&
            _customEndDate != null &&
            selectedFarmId != null
        ? ref.watch(readingsByPeriodProvider((
            farmId: selectedFarmId,
            start: _customStartDate!,
            end: _customEndDate!,
          )))
        : ref.watch(last24HoursReadingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Environmental Trends'),
        actions: [
          if (_useCustomRange)
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: () {
                setState(() {
                  _useCustomRange = false;
                  _customStartDate = null;
                  _customEndDate = null;
                });
                ref.invalidate(last24HoursReadingsProvider);
              },
              tooltip: 'Reset to Last 24 Hours',
            ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _showDateRangePicker(context),
            tooltip: 'Select Date Range',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              developer.log(
                'Refreshing readings',
                name: 'EnvironmentalChartScreen',
              );
              if (_useCustomRange &&
                  _customStartDate != null &&
                  _customEndDate != null) {
                ref.invalidate(readingsByPeriodProvider((
                  farmId: selectedFarmId!,
                  start: _customStartDate!,
                  end: _customEndDate!,
                )));
              } else {
                ref.invalidate(last24HoursReadingsProvider);
              }
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: farmsAsync.when(
        data: (farms) {
          if (selectedFarmId == null || farms.isEmpty) {
            return _EmptyChartView();
          }

          final selectedFarm = farms.firstWhere(
            (f) => f.id == selectedFarmId,
            orElse: () => farms.first,
          );

          return readingsAsync.when(
            data: (readings) {
              if (readings.isEmpty) {
                return _NoDataView(farmName: selectedFarm.name);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  if (_useCustomRange &&
                      _customStartDate != null &&
                      _customEndDate != null) {
                    ref.invalidate(readingsByPeriodProvider((
                      farmId: selectedFarmId,
                      start: _customStartDate!,
                      end: _customEndDate!,
                    )));
                  } else {
                    ref.invalidate(last24HoursReadingsProvider);
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FarmHeader(
                        farmName: selectedFarm.name,
                        timeRange: _useCustomRange &&
                                _customStartDate != null &&
                                _customEndDate != null
                            ? '${DateFormat('MMM dd, yyyy').format(_customStartDate!)} - ${DateFormat('MMM dd, yyyy').format(_customEndDate!)}'
                            : 'Last 24 Hours',
                      ),
                      const SizedBox(height: 16),
                      _DataSummary(readings: readings),
                      const SizedBox(height: 24),
                      _EnvironmentalChart(
                        readings: readings,
                        title: 'Temperature',
                        unit: '°C',
                        icon: Icons.thermostat,
                        color: Colors.orange,
                        minValue: 15.0,
                        maxValue: 35.0,
                        getValue: (r) => r.temperatureC,
                      ),
                      const SizedBox(height: 24),
                      _EnvironmentalChart(
                        readings: readings,
                        title: 'Humidity',
                        unit: '%',
                        icon: Icons.water_drop,
                        color: Colors.blue,
                        minValue: 70.0,
                        maxValue: 110.0,
                        getValue: (r) => r.relativeHumidity,
                      ),
                      const SizedBox(height: 24),
                      _EnvironmentalChart(
                        readings: readings,
                        title: 'CO₂',
                        unit: 'ppm',
                        icon: Icons.air,
                        color: Colors.green,
                        minValue: 300.0,
                        maxValue: 4000.0,
                        getValue: (r) => r.co2Ppm.toDouble(),
                      ),
                      const SizedBox(height: 24),
                      _EnvironmentalChart(
                        readings: readings,
                        title: 'Light',
                        unit: 'raw',
                        icon: Icons.light_mode,
                        color: Colors.amber,
                        minValue: 100.0,
                        maxValue: 600.0,
                        getValue: (r) => r.lightRaw.toDouble(),
                      ),
                      const SizedBox(height: 80), // Bottom padding
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) {
              developer.log(
                'Error loading readings',
                name: 'EnvironmentalChartScreen',
                error: error,
                stackTrace: stack,
                level: 1000,
              );
              return _ErrorView(error: error.toString());
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => _ErrorView(error: error.toString()),
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final selectedFarmId = ref.read(selectedMonitoringFarmIdProvider);
    if (selectedFarmId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a farm first')),
      );
      return;
    }

    final now = DateTime.now();
    final initialStart =
        _customStartDate ?? now.subtract(const Duration(hours: 24));
    final initialEnd = _customEndDate ?? now;

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange:
          _useCustomRange && _customStartDate != null && _customEndDate != null
              ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
              : DateTimeRange(
                  start: initialStart,
                  end: initialEnd,
                ),
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Select Date Range',
      cancelText: 'Cancel',
      confirmText: 'Apply',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
          0,
          0,
          0,
        );
        _customEndDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
        _useCustomRange = true;
      });

      // Invalidate the provider to fetch new data
      ref.invalidate(readingsByPeriodProvider((
        farmId: selectedFarmId,
        start: _customStartDate!,
        end: _customEndDate!,
      )));
    }
  }
}

/// Farm header showing the selected farm name
class _FarmHeader extends StatelessWidget {
  final String farmName;
  final String timeRange;

  const _FarmHeader({required this.farmName, this.timeRange = 'Last 24 Hours'});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.agriculture,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farmName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    timeRange,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.show_chart,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Data summary showing count and time range
class _DataSummary extends StatelessWidget {
  final List<Reading> readings;

  const _DataSummary({required this.readings});

  @override
  Widget build(BuildContext context) {
    final earliest = readings.first.timestamp;
    final latest = readings.last.timestamp;
    final timeFormat = DateFormat('MMM dd, HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dataset,
                  size: 20,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${readings.length} Data Points',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${timeFormat.format(earliest)} → ${timeFormat.format(latest)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable environmental chart widget
class _EnvironmentalChart extends StatelessWidget {
  final List<Reading> readings;
  final String title;
  final String unit;
  final IconData icon;
  final Color color;
  final double minValue;
  final double maxValue;
  final double Function(Reading) getValue;

  const _EnvironmentalChart({
    required this.readings,
    required this.title,
    required this.unit,
    required this.icon,
    required this.color,
    required this.minValue,
    required this.maxValue,
    required this.getValue,
  });

  @override
  Widget build(BuildContext context) {
    final spots = _createSpots(readings, getValue, minValue, maxValue);

    return _ChartCard(
      title: title,
      unit: unit,
      icon: icon,
      color: color,
      minValue: minValue,
      maxValue: maxValue,
      spots: spots,
      readings: readings,
    );
  }
}

/// Generic chart card widget
class _ChartCard extends StatefulWidget {
  final String title;
  final String unit;
  final IconData icon;
  final Color color;
  final double minValue;
  final double maxValue;
  final List<FlSpot> spots;
  final List<Reading> readings;

  const _ChartCard({
    required this.title,
    required this.unit,
    required this.icon,
    required this.color,
    required this.minValue,
    required this.maxValue,
    required this.spots,
    required this.readings,
  });

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  // Scroll position (in milliseconds)
  double _scrollOffset = 0;

  // Visible window size (in milliseconds) - default to 6 hours
  static const double _defaultWindowMs = 6 * 60 * 60 * 1000; // 6 hours
  double _visibleWindowMs = _defaultWindowMs;

  @override
  void initState() {
    super.initState();
    // Start by showing the most recent data
    if (widget.spots.isNotEmpty) {
      final latestTime = widget.spots.last.x;
      _scrollOffset = latestTime - _visibleWindowMs;
      if (_scrollOffset < 0) _scrollOffset = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final avgValue = widget.spots.isEmpty
        ? 0.0
        : widget.spots.map((s) => s.y).reduce((a, b) => a + b) /
            widget.spots.length;

    if (widget.spots.isEmpty) {
      return _buildEmptyCard(context, avgValue);
    }

    final minTime = widget.spots.first.x;
    final maxTime = widget.spots.last.x;
    final totalDuration = maxTime - minTime;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, avgValue),
            const SizedBox(height: 16),
            // Zoom controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.zoom_out),
                  onPressed: () {
                    setState(() {
                      // Increase visible window (zoom out)
                      _visibleWindowMs = (_visibleWindowMs * 1.5).clamp(
                        _defaultWindowMs,
                        totalDuration,
                      );
                    });
                  },
                  tooltip: 'Zoom Out',
                ),
                Text(
                  _getTimeRangeLabel(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_in),
                  onPressed: () {
                    setState(() {
                      // Decrease visible window (zoom in)
                      _visibleWindowMs = (_visibleWindowMs / 1.5).clamp(
                        60 * 60 * 1000, // Minimum 1 hour
                        totalDuration,
                      );
                    });
                  },
                  tooltip: 'Zoom In',
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Horizontal scrollable chart
            SizedBox(
              height: 200,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    // Pan the chart
                    final sensitivity =
                        _visibleWindowMs / 200; // Adjust sensitivity
                    _scrollOffset -= details.delta.dx * sensitivity;
                    _scrollOffset = _scrollOffset.clamp(
                      0.0,
                      (maxTime - _visibleWindowMs).clamp(0, double.infinity),
                    );
                  });
                },
                child: LineChart(
                  _buildChartData(context, minTime, maxTime),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Time navigation slider
            if (totalDuration > _visibleWindowMs)
              Slider(
                value: _scrollOffset,
                min: 0,
                max: (maxTime - _visibleWindowMs).clamp(0, double.infinity),
                onChanged: (value) {
                  setState(() {
                    _scrollOffset = value;
                  });
                },
                label: _getScrollPositionLabel(minTime),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context, double avgValue) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, avgValue),
            const SizedBox(height: 16),
            const SizedBox(
              height: 200,
              child: Center(
                child: Text('No data available'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double avgValue) {
    return Row(
      children: [
        Icon(widget.icon, color: widget.color),
        const SizedBox(width: 8),
        Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Avg: ${avgValue.toStringAsFixed(1)} ${widget.unit}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            // Show data range instead of fixed Y-axis range
            Text(
              _getDataRangeLabel(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  String _getDataRangeLabel() {
    if (widget.spots.isEmpty) {
      return 'Y-axis: ${widget.minValue.toStringAsFixed(0)} - ${widget.maxValue.toStringAsFixed(0)}';
    }
    final dataMin =
        widget.spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final dataMax =
        widget.spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return 'Data: ${dataMin.toStringAsFixed(1)} - ${dataMax.toStringAsFixed(1)}';
  }

  LineChartData _buildChartData(
      BuildContext context, double minTime, double maxTime) {
    final visibleMinX = _scrollOffset;
    final visibleMaxX = _scrollOffset + _visibleWindowMs;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: (widget.maxValue - widget.minValue) / 4,
        verticalInterval: _visibleWindowMs / 6, // Show ~6 vertical grid lines
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color:
                Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color:
                Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: (widget.maxValue - widget.minValue) / 4,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(0),
                style: Theme.of(context).textTheme.bodySmall,
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _visibleWindowMs / 4, // Show 4-5 time labels
            getTitlesWidget: (value, meta) {
              final dateTime =
                  DateTime.fromMillisecondsSinceEpoch(value.toInt());
              final timeFormat = _visibleWindowMs > 12 * 60 * 60 * 1000
                  ? DateFormat('MMM dd HH:mm') // Show date if > 12 hours
                  : DateFormat('HH:mm'); // Just time if <= 12 hours
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  timeFormat.format(dateTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                      ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
          left: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      minX: visibleMinX,
      maxX: visibleMaxX,
      // Use fixed Y-axis range without padding
      minY: widget.minValue,
      maxY: widget.maxValue,
      lineBarsData: [
        LineChartBarData(
          spots: widget.spots,
          isCurved: true,
          color: widget.color,
          barWidth: 3,
          dotData: FlDotData(
            show: _visibleWindowMs <
                3 * 60 * 60 * 1000, // Show dots if zoomed in (< 3 hours)
          ),
          belowBarData: BarAreaData(
            show: true,
            color: widget.color.withOpacity(0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final dateTime =
                  DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              final timeFormat = DateFormat('MMM dd, HH:mm:ss');
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} ${widget.unit}\n${timeFormat.format(dateTime)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  String _getTimeRangeLabel() {
    final hours = _visibleWindowMs / (60 * 60 * 1000);
    if (hours < 1) {
      final minutes = _visibleWindowMs / (60 * 1000);
      return '${minutes.toStringAsFixed(0)}m view';
    } else if (hours < 24) {
      return '${hours.toStringAsFixed(1)}h view';
    } else {
      final days = hours / 24;
      return '${days.toStringAsFixed(1)}d view';
    }
  }

  String _getScrollPositionLabel(double minTime) {
    final currentTime =
        DateTime.fromMillisecondsSinceEpoch((_scrollOffset + minTime).toInt());
    return DateFormat('MMM dd, HH:mm').format(currentTime);
  }
}

/// Helper function to create FlSpot list from readings with timestamp-based x-axis
/// Filters out zero, negative values, and values exceeding max
List<FlSpot> _createSpots(
  List<Reading> readings,
  double Function(Reading) getValue,
  double minValue,
  double maxValue,
) {
  return readings
      .map((reading) {
        final value = getValue(reading);
        // Filter out zero, negative values, and values exceeding max
        if (value <= 0 || value > maxValue || value < minValue) return null;
        // Use milliseconds since epoch as x-value to show accurate time gaps
        return FlSpot(
          reading.timestamp.millisecondsSinceEpoch.toDouble(),
          value,
        );
      })
      .whereType<FlSpot>()
      .toList();
}

/// Empty state when no farm is selected
class _EmptyChartView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Farm Selected',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please select a farm from the Monitoring screen to view charts.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// No data state when readings are empty
class _NoDataView extends StatelessWidget {
  final String farmName;

  const _NoDataView({required this.farmName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.data_usage,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Data Available',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'No sensor readings found for $farmName in the last 24 hours.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Charts will appear once data is collected.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state
class _ErrorView extends StatelessWidget {
  final String error;

  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Charts',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
