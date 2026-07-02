class ComplaintCreateResult {
  const ComplaintCreateResult({
    required this.id,
    required this.message,
  });

  final String id;
  final String message;

  String get ticketNumber {
    final numeric = id.hashCode.abs() % 10000;
    return '#TKT-${numeric.toString().padLeft(4, '0')}';
  }
}
