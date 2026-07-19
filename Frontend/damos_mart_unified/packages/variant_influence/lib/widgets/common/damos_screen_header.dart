import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/storage/prefs_storage.dart';
import '../../core/utils/damos_system_ui.dart';
import 'damos_brand_header.dart';

/// Green header with logo, tagline, profile avatar, and search bar (Beranda & Katalog).
/// Shows recent search history when the search field is focused.
class DamosScreenHeader extends StatefulWidget {
  const DamosScreenHeader({
    super.key,
    required this.searchController,
    required this.onSearchSubmitted,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchSubmitted;

  static const Color primary = DamosBrandHeaderRow.primary;
  static const Color hint = Color(0xFF6B7280);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  @override
  State<DamosScreenHeader> createState() => _DamosScreenHeaderState();
}

class _DamosScreenHeaderState extends State<DamosScreenHeader> {
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _history = const [];
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _history = PrefsStorage.instance.getSearchHistory();
    _searchFocusNode.addListener(_onFocusChanged);
    widget.searchController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChanged);
    widget.searchController.removeListener(_onTextChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {
      _history = PrefsStorage.instance.getSearchHistory();
      _showHistory = _searchFocusNode.hasFocus && _history.isNotEmpty;
    });
  }

  Future<void> _refreshHistory() async {
    if (!mounted) return;
    setState(() {
      _history = PrefsStorage.instance.getSearchHistory();
      _showHistory = _searchFocusNode.hasFocus && _history.isNotEmpty;
    });
  }

  Future<void> _submit(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    await PrefsStorage.instance.addSearchHistory(trimmed);
    await _refreshHistory();
    _searchFocusNode.unfocus();
    widget.onSearchSubmitted(trimmed);
  }

  Future<void> _selectHistory(String query) async {
    widget.searchController.text = query;
    widget.searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    await _submit(query);
  }

  Future<void> _removeHistory(String query) async {
    await PrefsStorage.instance.removeSearchHistory(query);
    await _refreshHistory();
  }

  Future<void> _clearHistory() async {
    await PrefsStorage.instance.clearSearchHistory();
    await _refreshHistory();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: DamosSystemUi.greenHeader,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: DamosScreenHeader.primary,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DamosBrandHeaderRow(showProfileAvatar: true),
            const SizedBox(height: 16),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              child: Row(
                children: [
                  const Icon(Icons.search, color: DamosScreenHeader.hint, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: widget.searchController,
                      focusNode: _searchFocusNode,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _submit,
                      onTap: () {
                        setState(() {
                          _history = PrefsStorage.instance.getSearchHistory();
                          _showHistory = _history.isNotEmpty;
                        });
                      },
                      style: const TextStyle(
                        fontSize: 14,
                        color: DamosScreenHeader.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintText: 'Cari produk, kategori, atau merek...',
                        hintStyle: TextStyle(
                          color: DamosScreenHeader.hint,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  if (widget.searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        widget.searchController.clear();
                        setState(() {});
                      },
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: DamosScreenHeader.hint,
                      ),
                    ),
                ],
              ),
            ),
            if (_showHistory) ...[
              const SizedBox(height: 10),
              _buildHistoryPanel(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryPanel() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Riwayat Pencarian',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: DamosScreenHeader.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _clearHistory,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Hapus semua',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DamosScreenHeader.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ..._history.map((query) {
              return InkWell(
                onTap: () => _selectHistory(query),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.history,
                        size: 18,
                        color: DamosScreenHeader.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          query,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: DamosScreenHeader.textPrimary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeHistory(query),
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: DamosScreenHeader.hint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
