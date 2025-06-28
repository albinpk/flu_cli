/// Some useful analyzer packages
enum AnalyzerPackages {
  flutterLints('include: package:flutter_lints/flutter.yaml'),
  veryGoodAnalysis('include: package:very_good_analysis/analysis_options.yaml'),
  none(''); // no analyzer

  const AnalyzerPackages(this.analysisOptionsEntry);

  /// The entry to add to the `analysis_options.yaml`.
  final String analysisOptionsEntry;
}
