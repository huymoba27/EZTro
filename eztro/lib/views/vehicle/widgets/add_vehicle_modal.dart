import 'package:flutter/material.dart';
import 'package:eztro/core/widgets/widgets.dart';

class AddVehicleModal extends StatefulWidget {
  final Function(String plate, String type) onAdd;

  const AddVehicleModal({super.key, required this.onAdd});

  @override
  State<AddVehicleModal> createState() => _AddVehicleModalState();
}

class _AddVehicleModalState extends State<AddVehicleModal> {
  final plateController = TextEditingController();
  final typeController = TextEditingController();

  @override
  void dispose() {
    plateController.dispose();
    typeController.dispose();
    super.dispose();
  }

  void _submit() {
    final plate = plateController.text.trim();
    if (plate.isEmpty) return;

    widget.onAdd(plate, typeController.text.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "THÊM XE MỚI",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: plateController,
            label: "Biển số xe",
            hint: "VD: 59-X1 12345",
          ),
          CustomTextField(
            controller: typeController,
            label: "Loại xe (Tên xe)",
            hint: "VD: Honda Vision",
          ),
          AppBottomButtons(
            showCancel: false,
            confirmText: "Xác nhận",
            onConfirm: _submit,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
