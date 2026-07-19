import 'package:flutter/material.dart';

/// Kategori komplain selaras dengan enum backend: PRODUCT, SERVICE, ORDER, QUEUE, OTHER.
class ComplaintCategoryOption {
  const ComplaintCategoryOption({
    required this.label,
    required this.apiCategory,
  });

  final String label;
  final String apiCategory;

  static const List<ComplaintCategoryOption> all = [
    ComplaintCategoryOption(
      label: 'Produk',
      apiCategory: 'PRODUCT',
    ),
    ComplaintCategoryOption(
      label: 'Pelayanan',
      apiCategory: 'SERVICE',
    ),
    ComplaintCategoryOption(
      label: 'Pesanan & Transaksi',
      apiCategory: 'ORDER',
    ),
    ComplaintCategoryOption(
      label: 'Antrean/Pengambilan',
      apiCategory: 'QUEUE',
    ),
    ComplaintCategoryOption(
      label: 'Lainnya',
      apiCategory: 'OTHER',
    ),
  ];

  static List<ComplaintCategoryOption> forProductComplaint() => all;

  static List<ComplaintCategoryOption> forServiceComplaint() => all;

  static ComplaintCategoryOption? fromApiCategory(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final option in all) {
      if (option.apiCategory == value) return option;
    }
    return null;
  }
}

/// Opsi masalah proses pesanan pada halaman Pilih Produk.
class ComplaintServiceIssueOption {
  const ComplaintServiceIssueOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.defaultCategory,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String defaultCategory;

  static const List<ComplaintServiceIssueOption> values = [
    ComplaintServiceIssueOption(
      id: 'payment',
      title: 'Pembayaran',
      subtitle: 'Masalah pembayaran, promo, refund, atau QRIS',
      icon: Icons.credit_card_outlined,
      defaultCategory: 'ORDER',
    ),
    ComplaintServiceIssueOption(
      id: 'pickup',
      title: 'Pengambilan Pesanan',
      subtitle: 'Nomor antrian, pengambilan barang, atau QR code',
      icon: Icons.shopping_bag_outlined,
      defaultCategory: 'QUEUE',
    ),
    ComplaintServiceIssueOption(
      id: 'order_status',
      title: 'Status Pesanan',
      subtitle: 'Status tidak berubah atau informasi tidak sesuai',
      icon: Icons.assignment_outlined,
      defaultCategory: 'ORDER',
    ),
    ComplaintServiceIssueOption(
      id: 'cooperative_service',
      title: 'Pelayanan Koperasi',
      subtitle: 'Pelayanan petugas atau kendala lainnya',
      icon: Icons.headset_mic_outlined,
      defaultCategory: 'SERVICE',
    ),
  ];

  static ComplaintServiceIssueOption? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final option in values) {
      if (option.id == id) return option;
    }
    return null;
  }
}
