import 'dart:math' as math;

/// Test-only nearest-rank summary. No claims of significance from small samples.
Map<String, num> inspectionDistribution(List<num> values) {
  if (values.isEmpty || values.any((v) => !v.isFinite || v < 0)) {
    throw ArgumentError('Expected nonempty finite nonnegative samples');
  }
  final sorted = List<num>.of(values)..sort();
  num percentile(double rank) => sorted[(sorted.length * rank).ceil() - 1];
  return {
    'count': sorted.length,
    'min': sorted.first,
    'p50': percentile(.5),
    'p95': percentile(.95),
    'max': sorted.last,
    'sum': sorted.fold<num>(0, (sum, value) => sum + value),
  };
}

class InspectionProcessSample {
  final int wallMicros;
  final int cpuMicros;
  final int rssBytes;

  const InspectionProcessSample(this.wallMicros, this.cpuMicros, this.rssBytes);

  Map<String, int> toJson() => {
    'wall_us': wallMicros,
    'cpu_us': cpuMicros,
    'rss_bytes': rssBytes,
  };
}

Map<String, dynamic> inspectionProcessSummary(
  List<InspectionProcessSample> samples,
) {
  if (samples.length < 2) throw ArgumentError('Need at least two OS samples');
  for (var i = 0; i < samples.length; i++) {
    final current = samples[i];
    if (current.cpuMicros < 0 ||
        current.rssBytes <= 0 ||
        (i > 0 &&
            (current.wallMicros <= samples[i - 1].wallMicros ||
                current.cpuMicros < samples[i - 1].cpuMicros))) {
      throw ArgumentError('Invalid OS sample ordering/counter');
    }
  }
  final elapsed = samples.last.wallMicros - samples.first.wallMicros;
  final cpu = samples.last.cpuMicros - samples.first.cpuMicros;
  return {
    'wall_us': elapsed,
    'cpu_us': cpu,
    'cpu_percent_one_core': cpu / elapsed * 100,
    'rss_start_bytes': samples.first.rssBytes,
    'rss_end_bytes': samples.last.rssBytes,
    'rss_distribution_bytes': inspectionDistribution(
      samples.map((s) => s.rssBytes).toList(),
    ),
    'max_sample_gap_us': List.generate(
      samples.length - 1,
      (i) => samples[i + 1].wallMicros - samples[i].wallMicros,
    ).reduce(math.max),
    'samples': samples.map((s) => s.toJson()).toList(),
  };
}
