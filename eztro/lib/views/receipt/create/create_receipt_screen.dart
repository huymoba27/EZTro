import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/receipt_service.dart';
import '../../../services/house_service.dart';
import '../../../services/room_service.dart';
import '../../../models/house_model.dart';
import '../../../models/room_model.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/test_tools/demo_data.dart';
import '../../../core/test_tools/dev_autofill_button.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../core/constants/app_colors.dart';

class CreateReceiptScreen extends StatefulWidget {
  const CreateReceiptScreen({super.key});

  @override
  State<CreateReceiptScreen> createState() => _CreateReceiptScreenState();
}

class _CreateReceiptScreenState extends State<CreateReceiptScreen> {
  final nameCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final typeCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  HouseModel? selectedHouse;
  Map<String, dynamic>? selectedRoom;
  List<HouseModel> houses = [];
  List<RoomModel> rooms = [];

  DateTime receiptDate = DateTime.now();
  String paymentMethod = "Tiền mặt";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHouses();
  }

  Future<void> _loadHouses() async {
    final res = await HouseService.getHouses();
    if (mounted) setState(() => houses = res);
  }

  Future<void> _loadRooms(int houseId) async {
    setState(() => rooms = []);
    final res = await RoomService.getRooms(houseId: houseId);
    if (mounted) setState(() => rooms = res);
  }

  void _submit() async {
    if (selectedHouse == null) {
      return DialogHelper.showWarning(context, "Chọn nhà");
    }
    if (nameCtrl.text.isEmpty) {
      return DialogHelper.showWarning(context, "Nhập tên khách");
    }
    if (amountCtrl.text.isEmpty) {
      return DialogHelper.showWarning(context, "Nhập số tiền");
    }

    final amount = double.tryParse(amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      return DialogHelper.showWarning(context, "Số tiền phải là số lớn hơn 0");
    }

    setState(() => isLoading = true);
    try {
      final res = await ReceiptService.createReceipt(
        houseId: selectedHouse!.id,
        roomId: selectedRoom != null
            ? int.parse(selectedRoom!['id'].toString())
            : null,
        tenantName: nameCtrl.text.trim(),
        amount: amount,
        receiptDate: DateFormat('yyyy-MM-dd').format(receiptDate),
        paymentMethod: paymentMethod,
        receiptType: typeCtrl.text.trim(),
        description: descCtrl.text.trim(),
      );
      if (res['status'] == 'success') {
        DialogHelper.showSuccess(
          context,
          "Thành công",
          onTap: () => Navigator.pop(context, true),
        );
      } else {
        DialogHelper.showError(context, res['message']);
      }
    } catch (e) {
      DialogHelper.showError(context, "Lỗi kết nối: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fillDemoData() async {
    final data = DemoData.receipt;
    final firstHouse =
        selectedHouse ?? (houses.isNotEmpty ? houses.first : null);

    setState(() {
      selectedHouse = firstHouse;
      nameCtrl.text = data.payerName;
      amountCtrl.text = data.amount;
      typeCtrl.text = data.type;
      descCtrl.text = data.description;
      receiptDate = DateTime.now();
    });

    if (firstHouse != null) {
      await _loadRooms(firstHouse.id);
      if (mounted && rooms.isNotEmpty) {
        setState(() => selectedRoom = rooms.first.toJson());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: CustomAppBar(
        title: 'LẬP PHIẾU THU',
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                DevAutofillButton(onPressed: _fillDemoData),
                AppSectionCard(
                  title: "Nguồn thu",
                  child: Column(
                    children: [
                      CustomSelectField(
                        label: "Nhà trọ *",
                        value: selectedHouse?.houseName ?? "Chọn nhà trọ",
                        onTap: () {
                          AppSelectModal.show<int>(
                            context: context,
                            title: "CHỌN NHÀ TRỌ",
                            subtitle: "Vui lòng chọn khu trọ lập phiếu",
                            items: houses
                                .map(
                                  (h) => AppSelectItem(
                                    label: h.houseName,
                                    value: h.id,
                                  ),
                                )
                                .toList(),
                            initialValues: selectedHouse != null
                                ? [selectedHouse!.id]
                                : [],
                            onSelect: (values) {
                              if (values.isNotEmpty) {
                                final id = values.first;
                                setState(() {
                                  selectedHouse = houses.firstWhere(
                                    (h) => h.id == id,
                                  );
                                  selectedRoom = null;
                                });
                                _loadRooms(id);
                              }
                            },
                          );
                        },
                      ),
                      CustomSelectField(
                        label: "Phòng (Tùy chọn)",
                        value:
                            selectedRoom?['room_name'] ?? "Chọn phòng (nếu có)",
                        onTap: () {
                          if (selectedHouse == null) {
                            DialogHelper.showWarning(
                              context,
                              "Chọn nhà trước!",
                            );
                            return;
                          }
                          DialogHelper.showLocationSelect(
                            context: context,
                            title: "CHỌN PHÒNG",
                            subtitle: "Vui lòng chọn phòng",
                            data: rooms.map((r) => r.roomName).toList(),
                            currentValue: selectedRoom?['room_name'] ?? "",
                            onSelect: (val) {
                              final r = rooms.firstWhere(
                                (r) => r.roomName == val,
                              );
                              setState(() => selectedRoom = r.toJson());
                            },
                          );
                        },
                      ),
                      CustomTextField(
                        controller: nameCtrl,
                        label: "Tên người nộp *",
                        hint: "Họ và tên...",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AppSectionCard(
                  title: "Chi tiết khoản thu",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: amountCtrl,
                        label: "Số tiền *",
                        hint: "0",
                        keyboardType: TextInputType.number,
                      ),
                      CustomSelectField(
                        label: "Ngày thu",
                        value: DateFormat('dd/MM/yyyy').format(receiptDate),
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: receiptDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) setState(() => receiptDate = d);
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Phương thức thanh toán",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildPaymentMethodToggle(),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: typeCtrl,
                        label: "Loại khoản thu *",
                        hint: "Tiền phòng, Tiền điện...",
                      ),
                      CustomTextField(
                        controller: descCtrl,
                        label: "Ghi chú/Nội dung",
                        hint: "Nội dung thu tiền...",
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          _buildBottomButtons(),
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodToggle() {
    return Row(
      children: [
        _paymentItem("Tiền mặt", Icons.payments_outlined, Colors.green),
        const SizedBox(width: 12),
        _paymentItem(
          "Chuyển khoản",
          Icons.account_balance_outlined,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _paymentItem(String label, IconData icon, Color color) {
    bool isSelected = paymentMethod == label;
    return Expanded(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: GestureDetector(
          onTap: () => setState(() => paymentMethod = label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade200,
                width: isSelected ? 1.2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? color : Colors.grey.shade400,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? color : Colors.grey.shade600,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AppBottomButtons(
        onCancel: () => Navigator.pop(context),
        onConfirm: _submit,
        cancelText: "Hủy bỏ",
        confirmText: "Lập phiếu ngay",
        isSubmitting: isLoading,
      ),
    );
  }
}
