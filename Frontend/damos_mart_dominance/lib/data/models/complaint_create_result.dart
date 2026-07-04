class ComplaintCreateResult {
  const ComplaintCreateResult({
    required this.id,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String message;
  final DateTime createdAt;

  String get ticketNumber {
    final year = createdAt.year;
    final numeric = id.hashCode.abs() % 1000;
    return 'CMP-$year-${numeric.toString().padLeft(3, '0')}';
  }
}
