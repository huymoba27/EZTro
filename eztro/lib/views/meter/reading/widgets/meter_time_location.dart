import 'package:flutter/material.dart';
import 'package:eztro/core/widgets/widgets.dart';

class MeterTimeLocationWidget extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final String? houseName;
  final String? roomName;
  final bool isEdit;
  final Function(int) onMonthChanged;
  final Function(int) onYearChanged;
  final VoidCallback onOpenHouse;
  final VoidCallback onOpenRoom;

  const MeterTimeLocationWidget({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    this.houseName,
    this.roomName,
    required this.isEdit,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onOpenHouse,
    required this.onOpenRoom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dòng chọn Tháng và Năm
        Row(
          children: [
            Expanded(
              child: CustomSelectField(
                label: "Tháng",
                value: "Tháng $selectedMonth",
                onTap: isEdit
                    ? null
                    : () => _showPicker(
                        context,
                        "THÁNG",
                        List.generate(12, (i) => "Tháng ${i + 1}"),
                        "Tháng $selectedMonth",
                        (v) => onMonthChanged(
                          int.parse(v.replaceAll("Tháng ", "")),
                        ),
                      ),
                lockedMessage: isEdit
                    ? "Không thể đổi tháng của bản ghi đã chốt."
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomSelectField(
                label: "Năm",
                value: "Năm $selectedYear",
                onTap: isEdit
                    ? null
                    : () => _showPicker(
                        context,
                        "NĂM",
                        List.generate(5, (i) => "${2024 + i}"),
                        selectedYear.toString(),
                        (v) => onYearChanged(int.parse(v)),
                      ),
                lockedMessage: isEdit
                    ? "Không thể đổi năm của bản ghi đã chốt."
                    : null,
              ),
            ),
          ],
        ),

        // Chọn Nhà trọ
        CustomSelectField(
          label: "Nhà trọ *",
          value: houseName ?? "Chọn nhà trọ",
          onTap: isEdit ? null : onOpenHouse,
          lockedMessage: isEdit
              ? "Không thể đổi nhà của bản ghi đã chốt."
              : null,
        ),

        // Chọn Phường thuê
        CustomSelectField(
          label: "Phòng thuê *",
          value: roomName ?? "Chọn phòng",
          onTap: isEdit ? null : onOpenRoom,
          lockedMessage: isEdit
              ? "Không thể đổi phòng của bản ghi đã chốt."
              : null,
        ),
      ],
    );
  }

  void _showPicker(
    BuildContext context,
    String title,
    List<String> data,
    String current,
    Function(String) onSel,
  ) {
    AppSelectModal.show<String>(
      context: context,
      title: "CHỌN $title",
      subtitle: "Thời gian chốt số",
      items: data.map((v) => AppSelectItem(label: v, value: v)).toList(),
      initialValues: [current],
      onSelect: (values) {
        if (values.isNotEmpty) {
          onSel(values.first);
        }
      },
    );
  }
}
