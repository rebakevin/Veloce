enum FinancePeriod {
  thisMonth('This month'),
  thisYear('This year');

  const FinancePeriod(this.label);
  final String label;

  /// Query parameter that carries the period between pages.
  static const String queryKey = 'period';

  /// The period named [name] (an enum name), [thisMonth] when null or unknown.
  static FinancePeriod fromName(String? name) => values.firstWhere(
    (period) => period.name == name,
    orElse: () => thisMonth,
  );
}
