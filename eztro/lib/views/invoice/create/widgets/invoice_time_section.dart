import 'package:flutter/material.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../../core/utils/dialog_helper.dart';

class InvoiceTimeSection extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final Function(int month, int year) onTimeChanged;

  const InvoiceTimeSection({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: "Thời gian lập hóa đơn",
      child: Column(
        children: [
          CustomSelectField(
            label: "Chọn tháng",
            value: "Tháng $selectedMonth",
            onTap: () {
              DialogHelper.showLocationSelect(
                context: context,
                title: "CHỌN THÁNG",
                subtitle: "Lập hóa đơn cho tháng",
                data: List.generate(12, (i) => "Tháng ${i + 1}"),
                currentValue: "Tháng $selectedMonth",
                onSelect: (val) {
                  int month = int.parse(val.replaceAll("Tháng ", ""));
                  onTimeChanged(month, selectedYear);
                },
              );
            },
          ),
          CustomSelectField(
            label: "Chọn năm",
            value: "Năm $selectedYear",
            onTap: () {
              int currY = DateTime.now().year;
              DialogHelper.showLocationSelect(
                context: context,
                title: "CHỌN NĂM",
                subtitle: "Lập hóa đơn cho năm",
                data: List.generate(5, (i) => "${currY - i}"),
                currentValue: "$selectedYear",
                onSelect: (val) {
                  int year = int.parse(val);
                  onTimeChanged(selectedMonth, year);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
