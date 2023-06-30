import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../common.dart';
import 'aqi_common.dart';

// https://pub.dev/packages/fl_chart
class ForecastChart extends StatelessWidget {
  final Map<IAQIRecord, List<ForecastEntry>> data;

  const ForecastChart({Key? key, required this.data}) : super(key: key);

  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, Color> colorMap = {};
    int i = 0;
    double maxValue = 0;
    List<LineChartBarData> barData = data.entries.map((dataSeries) {
      Color seriesColor = Colors.primaries[i++];
      colorMap[dataSeries.key.label] = seriesColor;
      return LineChartBarData(
        spots: dataSeries.value.map((entry) {
          var dateDifference = daysBetween(DateTime.now(), entry.date);
          var value = entry.average.toDouble();
          maxValue = value > maxValue ? value : maxValue;
          return FlSpot(
            dateDifference.toDouble(),
            value,
          );
        }).toList(),
        isCurved: true,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
        color: seriesColor,
      );
    }).toList();
    return Row(children: [
      Expanded(
        flex: 1,
        child: LineChart(
          LineChartData(
            lineTouchData: const LineTouchData(enabled: false),
            gridData: const FlGridData(
              show: true,
              drawVerticalLine: false,
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                ),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: const Text("Date"),
                sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      String text = graphFormat(DateTime.now()
                          .add(Duration(days: value.toInt()))
                          .toLocal());
                      return Text(text, textAlign: TextAlign.center);
                    }),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(
                show: true,
                border: const Border(
                    right: BorderSide(width: 1), bottom: BorderSide(width: 1))),
            lineBarsData: barData,
          ),
        ),
      ),
      buildLegend(context, colorMap),
    ]);
  }

  Widget buildLegend(BuildContext context, Map<String, Color> colorMap) {
    return Wrap(
      direction: Axis.vertical,
      children: [
        for (var e in data.entries)
          Chip(
              avatar: CircleAvatar(backgroundColor: colorMap[e.key.label]),
              label: Text(e.key.label))
      ],
    );
  }
}
