class ComplaintCreateResult {
  const ComplaintCreateResult({
    required this.id,
    required this.message,
    required this.createdAt,
    this.ticketNumber,
  });

  final String id;
  final String message;
  final DateTime createdAt;
  final String? ticketNumber;

  String get displayTicketNumber {
    if (ticketNumber != null && ticketNumber!.isNotEmpty) {
      return ticketNumber!;
    }
    final year = createdAt.year;
    final numeric = id.hashCode.abs() % 1000;
    return 'CMP-$year-${numeric.toString().padLeft(3, '0')}';
  }
}
