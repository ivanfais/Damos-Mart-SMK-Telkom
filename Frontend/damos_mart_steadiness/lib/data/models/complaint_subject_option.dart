class ComplaintSubjectOption {
  const ComplaintSubjectOption({
    required this.label,
    required this.apiCategory,
  });

  final String label;
  final String apiCategory;

  static const List<ComplaintSubjectOption> values = [
    ComplaintSubjectOption(label: 'Kualitas Produk', apiCategory: 'PRODUCT'),
    ComplaintSubjectOption(label: 'Masalah Aplikasi', apiCategory: 'SERVICE'),
    ComplaintSubjectOption(label: 'Stok Kosong', apiCategory: 'PRODUCT'),
    ComplaintSubjectOption(label: 'Kendala Pembayaran', apiCategory: 'ORDER'),
    ComplaintSubjectOption(label: 'Kendala Antrean', apiCategory: 'QUEUE'),
    ComplaintSubjectOption(label: 'Lainnya', apiCategory: 'OTHER'),
  ];
}
