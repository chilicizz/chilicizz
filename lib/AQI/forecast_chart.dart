import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

import 'aqi_common.dart';

class ForecastChart extends StatelessWidget {
  late List<charts.Series<ForecastEntry, DateTime>> seriesList;
  final bool animate;

  ForecastChart(series, List<ForecastEntry> forecast,
      {Key? key, this.animate = true})
      : super(key: key) {
    seriesList = [
      charts.Series<ForecastEntry, DateTime>(
        id: series,
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (ForecastEntry entry, _) => entry.date,
        measureFn: (ForecastEntry entry, _) => entry.average,
        data: forecast,
        displayName: series,
      ),
    ];
  }

  ForecastChart.fromMap(Map<IAQIRecord, List<ForecastEntry>>? data,
      {Key? key, this.animate = true})
      : super(key: key) {
    if (data != null) {
      seriesList = data.entries.map(generateFromEntry).toList();
    } else {
      seriesList = [];
    }
  }

  charts.Series<ForecastEntry, DateTime> generateFromEntry(
      MapEntry<IAQIRecord, List<ForecastEntry>> entry) {
    var chartSeries = charts.Series<ForecastEntry, DateTime>(
      id: entry.key.code,
      //colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      domainFn: (ForecastEntry entry, _) => entry.date,
      measureFn: (ForecastEntry entry, _) => entry.average,
      measureLowerBoundFn: (entry, _) => entry.min,
      measureUpperBoundFn: (entry, _) => entry.max,
      data: entry.value,
      displayName: entry.key.label,
    );
    if (entry.key.code == "uvi") {
      return chartSeries..setAttribute(charts.measureAxisIdKey, 'uvi');
    }
    return chartSeries;
  }

  @override
  Widget build(BuildContext context) {
    return charts.TimeSeriesChart(
      seriesList,
      animate: animate,
      // Optionally pass in a [DateTimeFactory] used by the chart. The factory
      // should create the same type of [DateTime] as the data provided. If none
      // specified, the default creates local date time.
      dateTimeFactory: const charts.LocalDateTimeFactory(),
      defaultRenderer: charts.LineRendererConfig(includePoints: true),

      behaviors: [
        charts.SeriesLegend(
          position: charts.BehaviorPosition.end,
          showMeasures: true,
          cellPadding: const EdgeInsets.only(right: 4.0, bottom: 4.0),
        ),
      ],
      primaryMeasureAxis: const charts.NumericAxisSpec(
        viewport: charts.NumericExtents(0, 300),
        tickProviderSpec:
            charts.BasicNumericTickProviderSpec(desiredTickCount: 5),
      ),
      secondaryMeasureAxis: const charts.NumericAxisSpec(
        viewport: charts.NumericExtents(0, 11),
        tickProviderSpec:
            charts.BasicNumericTickProviderSpec(desiredTickCount: 5),
      ),
    );
  }
}
