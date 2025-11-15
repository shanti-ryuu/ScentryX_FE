import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reading.dart';

class GasChart extends StatelessWidget {
  final List<Reading> readings;
  final int dangerThreshold;
  final int warningThreshold;

  const GasChart({
    super.key,
    required this.readings,
    this.dangerThreshold = 500,
    this.warningThreshold = 300,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = readings.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.gasLevelPpm.toDouble(),
      );
    }).toList();

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}');
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (readings.length / 4).clamp(1, 24).toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= readings.length) {
                    return const SizedBox.shrink();
                  }
                  final reading = readings[index];
                  return Text(
                    DateFormat('HH:mm').format(reading.timestamp),
                    style: const TextStyle(fontSize: 10),
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
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: dangerThreshold.toDouble(),
                color: Colors.red,
                strokeWidth: 2,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  labelResolver: (line) => 'Danger: ${line.y.toInt()} PPM',
                  alignment: Alignment.topRight,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                  ),
                ),
              ),
              HorizontalLine(
                y: warningThreshold.toDouble(),
                color: Colors.orange,
                strokeWidth: 2,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  labelResolver: (line) => 'Warning: ${line.y.toInt()} PPM',
                  alignment: Alignment.bottomRight,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
