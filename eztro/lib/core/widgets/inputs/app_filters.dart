import 'package:flutter/material.dart';
import '../../../models/house_model.dart';
import '../../../models/room_model.dart';
import 'app_select_modal.dart';
import '../../utils/dialog_helper.dart';

// ============================================================================
// PHẦN 1: DATA MODELS
// ============================================================================

/// Dữ liệu cho 1 nút pill trong bộ lọc trạng thái.
class FilterPillItem {
  final String label;
  final IconData icon;
  final Color color;
  final String value;
  final int count;

  FilterPillItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    this.count = 0,
  });
}

/// Dữ liệu cho 1 item dropdown trong bộ lọc.
class DropdownFilterItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  DropdownFilterItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

// ============================================================================
// PHẦN 2: WIDGETS
// ============================================================================

/// Widget hiển thị dải nút pill (Tất cả / Còn hạn / Hết hạn / ...).
class AppFilterPills extends StatelessWidget {
  final List<FilterPillItem> items;
  final String selectedValue;
  final Function(String) onSelected;
  final bool isEqualWidth;
  final bool showCount;

  const AppFilterPills({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    this.isEqualWidth = false,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: isEqualWidth
          ? Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < items.length - 1 ? 8 : 0,
                      ),
                      child: _buildPillItem(item),
                    ),
                  );
                }).toList(),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildPillItem(item),
                );
              },
            ),
    );
  }

  Widget _buildPillItem(FilterPillItem item) {
    final bool isSelected = selectedValue == item.value;
    return GestureDetector(
      onTap: () => onSelected(item.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? item.color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 14,
              color: isSelected ? item.color : item.color.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? item.color : item.color.withOpacity(0.85),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showCount && item.count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? item.color : item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${item.count}",
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected ? Colors.white : item.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget hiển thị hàng các dropdown filter.
class AppFilterDropdownRow extends StatelessWidget {
  final List<DropdownFilterItem> items;

  const AppFilterDropdownRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < items.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: item.onTap,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 16, color: Colors.black54),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Widget tổng hợp: pills + dropdowns.
class AppFilterBar extends StatelessWidget {
  final List<FilterPillItem>? pillItems;
  final String? selectedPillValue;
  final ValueChanged<String>? onPillSelected;
  final List<DropdownFilterItem>? dropdownItems;
  final bool isEqualWidth;
  final bool showCount;
  final Widget? customFilters;

  const AppFilterBar({
    super.key,
    this.pillItems,
    this.selectedPillValue,
    this.onPillSelected,
    this.dropdownItems,
    this.isEqualWidth = false,
    this.showCount = true,
    this.customFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pillItems != null && pillItems!.isNotEmpty)
            AppFilterPills(
              items: pillItems!,
              selectedValue: selectedPillValue ?? "",
              onSelected: (val) => onPillSelected?.call(val),
              isEqualWidth: isEqualWidth,
              showCount: showCount,
            ),
          if (dropdownItems != null && dropdownItems!.isNotEmpty)
            AppFilterDropdownRow(items: dropdownItems!),
          ?customFilters,
        ],
      ),
    );
  }
}

// ============================================================================
// PHẦN 3: BỘ LỌC DÙNG CHUNG
// ============================================================================

/// Các bộ lọc chuẩn dùng chung cho toàn app (Nhà, Phòng, Thời gian).
class CommonFilters {
  /// Bộ lọc chọn Nhà
  static DropdownFilterItem houseFilter({
    required BuildContext context,
    required List<HouseModel> houses,
    required int currentHouseId,
    required String currentHouseName,
    required Function(int id, String name) onChanged,
    bool showAllOption = true,
  }) {
    return DropdownFilterItem(
      label: currentHouseName,
      icon: Icons.home_work_outlined,
      onTap: () {
        AppSelectModal.show<int>(
          context: context,
          title: "CHỌN NHÀ TRỌ",
          subtitle: "Lọc dữ liệu theo nhà trọ",
          items: [
            if (showAllOption) AppSelectItem(label: "Tất cả nhà", value: 0),
            ...houses.map(
              (h) => AppSelectItem(label: h.houseName, value: h.id),
            ),
          ],
          initialValues: [currentHouseId],
          onSelect: (values) {
            if (values.isNotEmpty) {
              final id = values.first;
              final name = id == 0
                  ? "Tất cả nhà"
                  : houses.firstWhere((h) => h.id == id).houseName;
              onChanged(id, name);
            }
          },
        );
      },
    );
  }

  /// Bộ lọc chọn Tháng/Năm
  static DropdownFilterItem monthYearFilter({
    required BuildContext context,
    required int selectedMonth,
    required int selectedYear,
    required Function(int month, int year) onChanged,
    String title = "CHỌN THỜI GIAN",
    String subtitle = "Lọc theo tháng",
  }) {
    String label = "";
    if (selectedMonth == 0 && selectedYear == 0) {
      label = "Tất cả thời gian";
    } else if (selectedMonth == 0) {
      label = "Tất cả tháng/$selectedYear";
    } else if (selectedYear == 0) {
      label = "Tháng $selectedMonth";
    } else {
      label = "Tháng $selectedMonth/$selectedYear";
    }

    return DropdownFilterItem(
      label: label,
      icon: Icons.calendar_today_outlined,
      onTap: () {
        final List<String> options = [
          "Tất cả tháng/$selectedYear",
          ...List.generate(12, (index) => "Tháng ${index + 1}/$selectedYear"),
        ];

        DialogHelper.showLocationSelect(
          context: context,
          title: title,
          subtitle: subtitle,
          data: options,
          currentValue: label,
          onSelect: (val) {
            if (val.contains("Tất cả")) {
              onChanged(0, selectedYear);
            } else {
              int month = int.parse(val.split(" ")[1].split("/")[0]);
              onChanged(month, selectedYear);
            }
          },
        );
      },
    );
  }

  /// Bộ lọc chọn Phòng
  static DropdownFilterItem roomFilter({
    required BuildContext context,
    required List<RoomModel> rooms,
    required String? selectedRoomName,
    required Function(String? roomName) onChanged,
    String title = "CHỌN PHÒNG",
    String subtitle = "Lọc theo phòng",
    String emptyMessage = "Vui lòng chọn Nhà trước hoặc Nhà chưa có phòng!",
  }) {
    return DropdownFilterItem(
      label: selectedRoomName ?? "Tất cả phòng",
      icon: Icons.meeting_room_outlined,
      onTap: () {
        if (rooms.isEmpty) {
          DialogHelper.showWarning(context, emptyMessage);
          return;
        }
        final roomNames = ["Tất cả phòng", ...rooms.map((r) => r.roomName)];
        DialogHelper.showLocationSelect(
          context: context,
          title: title,
          subtitle: subtitle,
          data: roomNames,
          currentValue: selectedRoomName ?? "Tất cả phòng",
          onSelect: (val) {
            onChanged(val == "Tất cả phòng" ? null : val);
          },
        );
      },
    );
  }

  /// Bộ lọc chọn Mức giá
  static DropdownFilterItem priceFilter({
    required BuildContext context,
    required double? minPrice,
    required double? maxPrice,
    required Function(double? min, double? max) onChanged,
  }) {
    // Helper để tạo label hiển thị trên thanh filter
    String getLabel() {
      if (minPrice == null && maxPrice == null) return "Tất cả mức giá";
      if (maxPrice == null) {
        return "Trên ${(minPrice! / 1000000).toStringAsFixed(0)} triệu";
      }
      if (minPrice == null) {
        return "Dưới ${(maxPrice / 1000000).toStringAsFixed(0)} triệu";
      }
      return "${(minPrice / 1000000).toStringAsFixed(0)} - ${(maxPrice / 1000000).toStringAsFixed(0)} triệu";
    }

    // Danh sách các mức giá định sẵn
    final List<Map<String, dynamic>> priceOptions = [
      {'label': "Tất cả mức giá", 'min': null, 'max': null},
      {'label': "Dưới 2 triệu", 'min': null, 'max': 2000000.0},
      {'label': "2 - 4 triệu", 'min': 2000000.0, 'max': 4000000.0},
      {'label': "4 - 7 triệu", 'min': 4000000.0, 'max': 7000000.0},
      {'label': "Trên 7 triệu", 'min': 7000000.0, 'max': null},
    ];

    return DropdownFilterItem(
      label: getLabel(),
      icon: Icons.monetization_on_outlined,
      onTap: () {
        AppSelectModal.show<int>(
          context: context,
          title: "CHỌN MỨC GIÁ",
          subtitle: "Lọc dữ liệu theo giá thuê",
          searchable: false, // Tắt thanh tìm kiếm theo yêu cầu
          heightFactor: 0.5, // Chiều cao vừa vặn cho danh sách ngắn
          items: List.generate(
            priceOptions.length,
            (index) => AppSelectItem(
              label: priceOptions[index]['label'],
              value: index,
            ),
          ),
          initialValues: [
            priceOptions.indexWhere(
              (opt) => opt['min'] == minPrice && opt['max'] == maxPrice,
            ),
          ],
          onSelect: (values) {
            if (values.isNotEmpty) {
              final selectedOpt = priceOptions[values.first];
              onChanged(selectedOpt['min'], selectedOpt['max']);
            }
          },
        );
      },
    );
  }

  /// Bộ lọc trạng thái Khách thuê (Dùng cho Pills)
  static List<FilterPillItem> tenantStatusPills() {
    return [
      FilterPillItem(
        label: "Tất cả",
        icon: Icons.group_outlined,
        color: Colors.blue,
        value: "all",
      ),
      FilterPillItem(
        label: "Chủ hộ",
        icon: Icons.person_outline,
        color: Colors.orange,
        value: "lead",
      ),
      FilterPillItem(
        label: "Thành viên",
        icon: Icons.people_outline,
        color: Colors.green,
        value: "member",
      ),
    ];
  }

  /// Bộ lọc chọn Thành phố/Tỉnh
  static DropdownFilterItem cityFilter({
    required BuildContext context,
    required List<String> cities,
    required String selectedCity,
    required Function(String city) onChanged,
  }) {
    return DropdownFilterItem(
      label: selectedCity == 'all' ? "Tất cả khu vực" : selectedCity,
      icon: Icons.location_city_outlined,
      onTap: () {
        AppSelectModal.show<String>(
          context: context,
          title: "CHỌN KHU VỰC",
          subtitle: "Lọc theo thành phố/tỉnh",
          items: [
            AppSelectItem(label: "Tất cả khu vực", value: 'all'),
            ...cities.map((c) => AppSelectItem(label: c, value: c)),
          ],
          initialValues: [selectedCity],
          onSelect: (values) {
            if (values.isNotEmpty) {
              onChanged(values.first);
            }
          },
        );
      },
    );
  }

  /// Bộ lọc chọn Người quản lý
  static DropdownFilterItem managerFilter({
    required BuildContext context,
    required List<String> managers,
    required String selectedManager,
    required Function(String manager) onChanged,
  }) {
    return DropdownFilterItem(
      label: selectedManager == 'all' ? "Tất cả quản lý" : selectedManager,
      icon: Icons.person_pin_outlined,
      onTap: () {
        AppSelectModal.show<String>(
          context: context,
          title: "CHỌN NGƯỜI QUẢN LÝ",
          subtitle: "Lọc theo người quản lý khu trọ",
          items: [
            AppSelectItem(label: "Tất cả quản lý", value: 'all'),
            ...managers.map((m) => AppSelectItem(label: m, value: m)),
          ],
          initialValues: [selectedManager],
          onSelect: (values) {
            if (values.isNotEmpty) {
              onChanged(values.first);
            }
          },
        );
      },
    );
  }

  /// Bộ lọc trạng thái Nhà trọ (Dùng cho Pills)
  static List<FilterPillItem> houseStatusPills() {
    return [
      FilterPillItem(
        label: "Tất cả",
        icon: Icons.home_work_outlined,
        color: Colors.blue,
        value: "all",
      ),
      FilterPillItem(
        label: "Đang hoạt động",
        icon: Icons.check_circle_outline,
        color: Colors.green,
        value: "active",
      ),
      FilterPillItem(
        label: "Tạm dừng",
        icon: Icons.pause_circle_outline,
        color: Colors.orange,
        value: "inactive",
      ),
    ];
  }
}
