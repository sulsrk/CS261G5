// interface_report.dart

/// Interface for reports.
abstract class IReport {
  /// TODO: Fix this description
  void printSummary();
  /// Returns the statistics summary in CSV format
  String exportCSV();
}