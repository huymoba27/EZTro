import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool isSearching;
  final TextEditingController? searchController;
  final Function(String)? onSearchChanged;
  final VoidCallback? onSearchToggle;
  final VoidCallback? onFilterTap;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onBack;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.isSearching = false,
    this.searchController,
    this.onSearchChanged,
    this.onSearchToggle,
    this.onFilterTap,
    this.actions,
    this.bottom,
    this.onBack,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: centerTitle,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: showBackButton && onBack == null,
      leading: showBackButton && onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack,
            )
          : null,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      ),
      title: isSearching
          ? _buildSearchInput()
          : Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.0,
              ),
            ),
      actions: _buildActions(),
      bottom: bottom,
    );
  }

  List<Widget> _buildActions() {
    List<Widget> appActions = [];

    // Nút Search
    if (onSearchToggle != null && !isSearching) {
      appActions.add(
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: onSearchToggle,
        ),
      );
    }

    // Nút Lọc
    if (onFilterTap != null && !isSearching) {
      appActions.add(
        IconButton(
          icon: const Icon(Icons.tune, color: Colors.white),
          onPressed: onFilterTap,
        ),
      );
    }

    // Nút chức năng phụ
    if (actions != null && !isSearching) {
      appActions.addAll(actions!);
    }

    return appActions;
  }

  Widget _buildSearchInput() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: searchController,
        autofocus: true,
        onChanged: onSearchChanged,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          hintText: "Tìm kiếm...",
          hintStyle: const TextStyle(color: Colors.white70),
          suffixIcon: GestureDetector(
            onTap: onSearchToggle,
            child: const Icon(Icons.close, color: Colors.white70, size: 18),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 2.5, left: 20),
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    final double bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }
}
