import 'package:flutter_test/flutter_test.dart';

import 'fixtures/inspection_metrics.dart';

void main() {
  test(
    'nearest-rank metrics keep raw input intact and expose sample count',
    () {
      final values = [5, 1, 4, 2, 3];
      expect(inspectionDistribution(values), {
        'count': 5,
        'min': 1,
        'p50': 3,
        'p95': 5,
        'max': 5,
        'sum': 15,
      });
      expect(values, [5, 1, 4, 2, 3]);
      for (final invalid in <List<num>>[
        [],
        [-1],
        [double.nan],
        [double.infinity],
      ]) {
        expect(() => inspectionDistribution(invalid), throwsArgumentError);
      }
    },
  );

  test(
    'OS summary uses one-core CPU and records RSS samples and sampling gaps',
    () {
      final summary = inspectionProcessSummary(const [
        InspectionProcessSample(0, 0, 100),
        InspectionProcessSample(200000, 100000, 300),
        InspectionProcessSample(500000, 750000, 200),
      ]);
      expect(summary['cpu_percent_one_core'], 150);
      expect(summary['rss_start_bytes'], 100);
      expect(summary['rss_end_bytes'], 200);
      expect(summary['max_sample_gap_us'], 300000);
      expect(summary['samples'], hasLength(3));
      expect(summary['rss_distribution_bytes']['p50'], 200);
    },
  );

  test('OS summary refuses invalid or reversed sample counters', () {
    for (final invalid in <List<InspectionProcessSample>>[
      [],
      [const InspectionProcessSample(0, 0, 10)],
      [
        const InspectionProcessSample(1, 0, 10),
        const InspectionProcessSample(1, 0, 20),
      ],
      [
        const InspectionProcessSample(0, 1, 10),
        const InspectionProcessSample(1, 0, 20),
      ],
      [
        const InspectionProcessSample(0, 0, 10),
        const InspectionProcessSample(1, 1, 0),
      ],
    ]) {
      expect(() => inspectionProcessSummary(invalid), throwsArgumentError);
    }
  });
}
