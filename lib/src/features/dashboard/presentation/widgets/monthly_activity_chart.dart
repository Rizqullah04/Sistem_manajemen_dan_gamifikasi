import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MonthlyActivityChart extends StatelessWidget {
  const MonthlyActivityChart({required this.data, super.key});

  final Map<int, int> data;

  @override
  Widget build(BuildContext context) {
    final bars = data.entries
        .map(
          (entry) => BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                width: 14,
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A3DE8), Color(0xFF2F1D73)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ],
          ),
        )
        .toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktivitas Bulanan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Use LayoutBuilder for responsive height
            LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxWidth < 600 ? 200 : 250;
                return SizedBox(
                  height: height.toDouble(),
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: Theme.of(context).textTheme.labelSmall,
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: Theme.of(context).textTheme.labelSmall,
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: bars,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
