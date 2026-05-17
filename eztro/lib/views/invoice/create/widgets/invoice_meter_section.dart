import 'package:flutter/material.dart';
import 'package:eztro/core/widgets/widgets.dart';

class InvoiceMeterSection extends StatelessWidget {
  final int oldElec;
  final int oldWater;
  final TextEditingController elecController;
  final TextEditingController waterController;
  final bool isMeterChecked;

  const InvoiceMeterSection({
    super.key,
    required this.oldElec,
    required this.oldWater,
    required this.elecController,
    required this.waterController,
    required this.isMeterChecked,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: "Chỉ số điện nước",
      child: Column(
        children: [
          Row(
            children: [
              _buildOldMeterBox("Điện cũ", oldElec),
              const SizedBox(width: 12),
              _buildOldMeterBox("Nước cũ", oldWater),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputMeter("Điện mới *", elecController, isMeterChecked),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputMeter("Nước mới *", waterController, isMeterChecked),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputMeter(String label, TextEditingController ctrl, bool readOnly) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        CustomTextField(
          controller: ctrl,
          label: "",
          hint: "0",
          keyboardType: TextInputType.number,
          readOnly: readOnly,
        ),
      ],
    );
  }

  Widget _buildOldMeterBox(String label, int value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            height: 52,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: Text(
              "$value",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
