import 'package:flutter/material.dart';
import 'package:eztro/core/widgets/widgets.dart';

class ContractTermsWidget extends StatelessWidget {
  final TextEditingController startDateController;
  final TextEditingController durationController;
  final TextEditingController priceController;
  final TextEditingController depositController;
  final TextEditingController paymentDayController;
  final String endDateDisplay;
  final VoidCallback? onPickDate;
  final Function(String) onDurationChanged;
  final Color themeGreen;

  const ContractTermsWidget({
    super.key,
    required this.startDateController,
    required this.durationController,
    required this.priceController,
    required this.depositController,
    required this.paymentDayController,
    required this.endDateDisplay,
    required this.onPickDate,
    required this.onDurationChanged,
    required this.themeGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomSelectField(
          label: "Ngày bắt đầu *",
          value: startDateController.text,
          onTap: onPickDate,
        ),
        CustomTextField(
          controller: durationController,
          label: "Thời hạn (tháng) *",
          hint: "6",
          keyboardType: TextInputType.number,
          onChanged: onDurationChanged,
        ),
        
        // Thông báo ngày hết hạn
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12, top: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 14),
              const SizedBox(width: 8),
              Text(
                "Dự kiến kết thúc: $endDateDisplay",
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),

        CustomTextField(
          controller: priceController,
          label: "Giá thuê mỗi tháng (VNĐ) *",
          hint: "0",
          keyboardType: TextInputType.number,
        ),
        CustomTextField(
          controller: depositController,
          label: "Tiền cọc đảm bảo *",
          hint: "0",
          keyboardType: TextInputType.number,
        ),
        CustomTextField(
          controller: paymentDayController,
          label: "Ngày thanh toán hàng tháng *",
          hint: "5",
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}
