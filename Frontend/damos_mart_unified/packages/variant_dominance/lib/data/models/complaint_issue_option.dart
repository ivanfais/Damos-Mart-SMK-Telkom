/// Opsi jenis kendala granular (UI) dengan mapping ke enum backend.
class ComplaintIssueOption {
  const ComplaintIssueOption({
    required this.label,
    required this.apiCategory,
  });

  final String label;
  final String apiCategory;

  static const List<ComplaintIssueOption> productIssues = [
    ComplaintIssueOption(label: 'Barang Rusak', apiCategory: 'PRODUCT'),
    ComplaintIssueOption(label: 'Barang Kedaluwarsa', apiCategory: 'PRODUCT'),
    ComplaintIssueOption(label: 'Barang Kurang', apiCategory: 'PRODUCT'),
    ComplaintIssueOption(label: 'Salah Produk', apiCategory: 'PRODUCT'),
    ComplaintIssueOption(label: 'Kemasan Rusak', apiCategory: 'PRODUCT'),
    ComplaintIssueOption(label: 'Lainnya', apiCategory: 'OTHER'),
  ];

  static const List<ComplaintIssueOption> cooperativeServiceIssues = [
    ComplaintIssueOption(label: 'Pembayaran', apiCategory: 'ORDER'),
    ComplaintIssueOption(label: 'Pengambilan', apiCategory: 'QUEUE'),
    ComplaintIssueOption(label: 'QR Code', apiCategory: 'QUEUE'),
    ComplaintIssueOption(label: 'Nomor Antrian', apiCategory: 'QUEUE'),
    ComplaintIssueOption(label: 'Pelayanan', apiCategory: 'SERVICE'),
    ComplaintIssueOption(label: 'Lainnya', apiCategory: 'OTHER'),
  ];

  static List<ComplaintIssueOption> fromBackendCategories(
    List<({String label, String apiCategory})> categories,
  ) {
    return categories
        .map(
          (c) => ComplaintIssueOption(
            label: c.label,
            apiCategory: c.apiCategory,
          ),
        )
        .toList();
  }

  /// Maps UI issue labels to backend `reason` enum for POST /complaints.
  String toBackendReason() {
    switch (label) {
      case 'Barang Rusak':
      case 'Barang Kedaluwarsa':
      case 'Kemasan Rusak':
        return 'PRODUCT_DAMAGED';
      case 'Barang Kurang':
      case 'Salah Produk':
        return 'QUANTITY_SHORT';
      default:
        return 'OTHER';
    }
  }
}

/// Parse label jenis kendala dari subject format: `Nama — Jenis Kendala`.
class ComplaintSubjectParser {
  static ({String title, String? issueType}) parse(String subject) {
    final parts = subject.split(' — ');
    if (parts.length >= 2) {
      return (
        title: parts.first.trim(),
        issueType: parts.sublist(1).join(' — ').trim(),
      );
    }
    return (title: subject.trim(), issueType: null);
  }
}
