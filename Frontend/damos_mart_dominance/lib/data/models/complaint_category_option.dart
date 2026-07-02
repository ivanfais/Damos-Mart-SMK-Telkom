class ComplaintCategoryOption {
  const ComplaintCategoryOption({
    required this.label,
    required this.apiCategory,
  });

  final String label;
  final String apiCategory;

  static const List<ComplaintCategoryOption> values = [
    ComplaintCategoryOption(
      label: 'Produk Tidak Sesuai',
      apiCategory: 'PRODUCT',
    ),
    ComplaintCategoryOption(
      label: 'Produk Rusak/Cacat',
      apiCategory: 'PRODUCT',
    ),
    ComplaintCategoryOption(
      label: 'Kendala Pembayaran',
      apiCategory: 'ORDER',
    ),
    ComplaintCategoryOption(
      label: 'Kendala Pengambilan Pesanan',
      apiCategory: 'QUEUE',
    ),
    ComplaintCategoryOption(
      label: 'Kendala Akun',
      apiCategory: 'OTHER',
    ),
    ComplaintCategoryOption(
      label: 'Lainnya',
      apiCategory: 'OTHER',
    ),
  ];
}
