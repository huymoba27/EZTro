import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Item dùng cho AppSelectModal
class AppSelectItem<T> {
  final String label;
  final T value;
  final String? subtitle;
  final IconData? icon;

  AppSelectItem({
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
  });
}

/// Modal lựa chọn dùng chung (Single & Multi Select, Searchable)
class AppSelectModal<T> extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<AppSelectItem<T>> items;
  final List<T> initialValues;
  final bool isMultiSelect;
  final bool searchable;
  final String searchPlaceholder;
  final Function(List<T> values) onSelect;
  final String confirmText;

  const AppSelectModal({
    super.key,
    required this.title,
    this.subtitle = "Vui lòng chọn thông tin bên dưới",
    required this.items,
    this.initialValues = const [],
    this.isMultiSelect = false,
    this.searchable = true,
    this.searchPlaceholder = "Tìm kiếm...",
    required this.onSelect,
    this.heightFactor,
    this.confirmText = "XÁC NHẬN",
  });

  static void show<T>({
    required BuildContext context,
    required String title,
    String subtitle = "Vui lòng chọn thông tin bên dưới",
    required List<AppSelectItem<T>> items,
    List<T> initialValues = const [],
    bool isMultiSelect = false,
    bool searchable = true,
    String searchPlaceholder = "Tìm kiếm...",
    double? heightFactor,
    required Function(List<T> values) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppSelectModal<T>(
        title: title,
        subtitle: subtitle,
        items: items,
        initialValues: initialValues,
        isMultiSelect: isMultiSelect,
        searchable: searchable,
        searchPlaceholder: searchPlaceholder,
        heightFactor: heightFactor,
        onSelect: onSelect,
      ),
    );
  }

  final double? heightFactor;

  @override
  State<AppSelectModal<T>> createState() => _AppSelectModalState<T>();
}

class _AppSelectModalState<T> extends State<AppSelectModal<T>> {
  late List<T> selectedValues;
  late List<AppSelectItem<T>> filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedValues = List.from(widget.initialValues);
    filteredItems = widget.items;
  }

  void _filterItems(String query) {
    setState(() {
      filteredItems = widget.items
          .where((item) =>
              item.label.toLowerCase().contains(query.toLowerCase()) ||
              (item.subtitle?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (selectedValues.length == widget.items.length) {
        selectedValues.clear();
      } else {
        selectedValues = widget.items.map((item) => item.value).toList();
      }
    });
  }

  void _toggleValue(T value) {
    setState(() {
      if (widget.isMultiSelect) {
        if (selectedValues.contains(value)) {
          selectedValues.remove(value);
        } else {
          selectedValues.add(value);
        }
      } else {
        selectedValues = [value];
        // Nếu là chọn đơn thì đóng modal luôn
        widget.onSelect(selectedValues);
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    final double defaultHeight = MediaQuery.of(context).size.height * (widget.heightFactor ?? 0.8);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: defaultHeight,
        minHeight: 0,
      ),
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Giúp co lại nếu nội dung ngắn
        children: [
          const SizedBox(height: 12),
          // Handle Bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        widget.title.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48), // Spacer for balance
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          if (widget.searchable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _filterItems,
                decoration: InputDecoration(
                  hintText: widget.searchPlaceholder,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ),
          
          if (widget.searchable) const SizedBox(height: 16),

          // List Items
          Flexible(
            child: filteredItems.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(bottom: bottomPadding + 20),
                    itemCount: widget.isMultiSelect 
                        ? filteredItems.length + 1 
                        : filteredItems.length,
                    itemBuilder: (context, index) {
                      if (widget.isMultiSelect && index == 0) {
                        final isAllSelected = selectedValues.length == widget.items.length;
                        return _buildSelectAllTile(isAllSelected);
                      }
                      
                      final itemIndex = widget.isMultiSelect ? index - 1 : index;
                      final item = filteredItems[itemIndex];
                      final isSelected = selectedValues.contains(item.value);

                      return _buildItemTile(item, isSelected);
                    },
                  ),
          ),

          // Footer for MultiSelect
          if (widget.isMultiSelect)
            Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Đã chọn ${selectedValues.length} mục",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSelect(selectedValues);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.confirmText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectAllTile(bool isAllSelected) {
    return InkWell(
      onTap: _toggleSelectAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: isAllSelected ? AppColors.primary.withOpacity(0.03) : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.08), width: 1),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                "Chọn tất cả",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isAllSelected ? FontWeight.bold : FontWeight.w500,
                  color: isAllSelected ? AppColors.primary : Colors.black87,
                ),
              ),
            ),
            Icon(
              isAllSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: isAllSelected ? AppColors.primary : Colors.black12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(AppSelectItem<T> item, bool isSelected) {
    return InkWell(
      onTap: () => _toggleValue(item.value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.03) : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.08), width: 1),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.isMultiSelect)
              Icon(
                isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: isSelected ? AppColors.primary : Colors.black12,
              )
            else if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text(
            "Không tìm thấy kết quả nào",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
