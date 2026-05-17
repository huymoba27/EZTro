import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../../core/constants/app_colors.dart';

class InvoiceProRataSection extends StatelessWidget {
  final bool isProRata;
  final DateTime? startDate;
  final DateTime? endDate;
  final int selectedMonth;
  final int selectedYear;
  final Function(bool isProRata, DateTime? start, DateTime? end) onChanged;

  const InvoiceProRataSection({
    super.key,
    required this.isProRata,
    required this.startDate,
    required this.endDate,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: "Cấu hình tính theo ngày",
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              "Tính tiền phòng theo ngày thực tế",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            value: isProRata,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              DateTime? s = val ? DateTime(selectedYear, selectedMonth, 1) : null;
              DateTime? e = val ? DateTime(selectedYear, selectedMonth + 1, 0) : null;
              onChanged(val, s, e);
            },
          ),
          if (isProRata) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMinimalSelect(
                    context: context,
                    label: "Từ ngày",
                    value: startDate != null ? DateFormat('dd/MM/yyyy').format(startDate!) : "Chọn ngày",
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime(selectedYear, selectedMonth, 1),
                        firstDate: DateTime(selectedYear, selectedMonth, 1),
                        lastDate: DateTime(selectedYear, selectedMonth + 1, 0),
                      );
                      if (d != null) onChanged(isProRata, d, endDate);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMinimalSelect(
                    context: context,
                    label: "Đến ngày",
                    value: endDate != null ? DateFormat('dd/MM/yyyy').format(endDate!) : "Chọn ngày",
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime(selectedYear, selectedMonth + 1, 0),
                        firstDate: DateTime(selectedYear, selectedMonth, 1),
                        lastDate: DateTime(selectedYear, selectedMonth + 1, 0),
                      );
                      if (d != null) onChanged(isProRata, startDate, d);
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMinimalSelect({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
