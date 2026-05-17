import 'package:flutter/material.dart';
import 'package:eztro/services/house_service.dart';
import 'package:eztro/models/house_model.dart';
import 'package:eztro/controllers/service_controller.dart';
import 'package:eztro/core/test_tools/demo_data.dart';
import 'package:eztro/core/test_tools/dev_autofill_button.dart';
import 'package:eztro/core/widgets/widgets.dart';
import 'package:eztro/core/constants/app_colors.dart';

class CreateServiceScreen extends StatefulWidget {
  final Map<String, dynamic>? serviceData;
  const CreateServiceScreen({super.key, this.serviceData});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();

  String selectedUnit = "kwh";
  String selectedChargeType = "per_meter";
  List<HouseModel> houses = [];
  List<int> selectedHouseIds = [];
  String? selectedType;
  bool isEditMode = false;
  bool _isLoading = false;

  final List<Map<String, String>> serviceTypes = [
    {
      "name": "Điện",
      "unit": "kwh",
      "type": "per_meter",
      "category": "electric",
    },
    {"name": "Nước", "unit": "m3", "type": "per_meter", "category": "water"},
    {
      "name": "Gửi xe",
      "unit": "xe",
      "type": "per_vehicle",
      "category": "other",
    },
    {
      "name": "Vệ sinh",
      "unit": "người",
      "type": "per_person",
      "category": "trash",
    },
    {
      "name": "Internet",
      "unit": "tháng",
      "type": "fixed",
      "category": "internet",
    },
    {"name": "Rác", "unit": "người", "type": "per_person", "category": "trash"},
    {
      "name": "Khác (/phòng)",
      "unit": "phòng",
      "type": "fixed",
      "category": "other",
    },
    {
      "name": "Khác (/người)",
      "unit": "người",
      "type": "per_person",
      "category": "other",
    },
  ];

  @override
  void initState() {
    super.initState();
    isEditMode = widget.serviceData != null;
    _loadHouses();
    if (isEditMode) {
      nameController.text = widget.serviceData!['service_name'] ?? "";
      priceController.text =
          (double.tryParse(widget.serviceData!['price'].toString()) ?? 0)
              .toInt()
              .toString();
      selectedUnit = widget.serviceData!['unit'] ?? "kwh";
      selectedChargeType = widget.serviceData!['charge_type'] ?? "fixed";
      selectedType =
          serviceTypes.any(
            (e) =>
                e['name'] == widget.serviceData!['service_name'] ||
                e['category'] == widget.serviceData!['service_type'],
          )
          ? serviceTypes.firstWhere(
              (e) =>
                  e['name'] == widget.serviceData!['service_name'] ||
                  e['category'] == widget.serviceData!['service_type'],
            )['name']
          : "Khác (/phòng)";
    }
  }

  Future<void> _loadHouses() async {
    final data = await HouseService.getHouses();
    if (mounted) setState(() => houses = data);
  }

  void _submit() {
    final currentTypeData = serviceTypes.firstWhere(
      (e) => e['name'] == selectedType,
      orElse: () => serviceTypes.last,
    );

    ServiceController.submitService(
      context: context,
      isEditMode: isEditMode,
      serviceId: widget.serviceData != null
          ? int.tryParse(widget.serviceData!['id'].toString())
          : null,
      name: nameController.text.trim(),
      priceText: priceController.text.trim(),
      unit: selectedUnit,
      chargeType: selectedChargeType,
      serviceType: currentTypeData['category'] ?? 'other',
      houseIds: selectedHouseIds,
      setLoading: (val) => setState(() => _isLoading = val),
    );
  }

  void _fillDemoData() {
    final data = DemoData.service;
    final typeData = serviceTypes.firstWhere(
      (item) => item['name'] == data.typeName,
      orElse: () => serviceTypes.last,
    );
    setState(() {
      selectedType = typeData['name'];
      selectedUnit = typeData['unit'] ?? data.unit;
      selectedChargeType = typeData['type'] ?? data.chargeType;
      nameController.text = typeData['name'] ?? data.typeName;
      priceController.text = data.price;
      selectedHouseIds = houses.map((h) => h.id).toList();
    });
  }

  void _showHousePicker() {
    AppSelectModal.show<int>(
      context: context,
      title: "CHỌN NHÀ ÁP DỤNG",
      subtitle: "Đã chọn ${selectedHouseIds.length} nhà",
      isMultiSelect: true,
      items: houses
          .map((h) => AppSelectItem(label: h.houseName, value: h.id))
          .toList(),
      initialValues: selectedHouseIds,
      onSelect: (newList) => setState(() => selectedHouseIds = newList),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: isEditMode ? "CẬP NHẬT DỊCH VỤ" : "TẠO DỊCH VỤ MỚI",
        onBack: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (!isEditMode) DevAutofillButton(onPressed: _fillDemoData),
                  AppSectionCard(
                    title: "Thông tin dịch vụ",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Loại dịch vụ *",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildServiceGrid(),
                        if (selectedType != null &&
                            selectedType!.contains("Khác")) ...[
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: nameController,
                            label: "Tên dịch vụ *",
                            hint: "VD: Tiền rác, Internet...",
                          ),
                        ],
                        const SizedBox(height: 20),
                        const Text(
                          "Đơn giá & Đơn vị *",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPriceInput(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppSectionCard(
                    title: "Phạm vi áp dụng",
                    child: CustomSelectField(
                      label: "Chọn nhà sử dụng *",
                      value: selectedHouseIds.isEmpty
                          ? "Chưa chọn nhà nào"
                          : "Đã chọn ${selectedHouseIds.length} nhà",
                      onTap: isEditMode ? null : _showHousePicker,
                      lockedMessage: isEditMode
                          ? "Không thể đổi phạm vi áp dụng khi sửa dịch vụ."
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return AppBottomButtons(
      onCancel: () => Navigator.pop(context),
      onConfirm: _submit,
      cancelText: "Hủy bỏ",
      confirmText: isEditMode ? "Lưu thay đổi" : "Tạo dịch vụ",
      isSubmitting: _isLoading,
    );
  }

  Widget _buildServiceGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.4,
      ),
      itemCount: serviceTypes.length,
      itemBuilder: (context, index) {
        bool isSel = selectedType == serviceTypes[index]['name'];
        return GestureDetector(
          onTap: isEditMode
              ? null
              : () => setState(() {
                  selectedType = serviceTypes[index]['name'];
                  selectedUnit = serviceTypes[index]['unit']!;
                  selectedChargeType = serviceTypes[index]['type']!;
                  nameController.text = (selectedType!.contains("Khác"))
                      ? ""
                      : selectedType!;
                }),
          child: Container(
            decoration: BoxDecoration(
              color: isSel ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSel ? AppColors.primary : Colors.grey.withAlpha(51),
                width: 1,
              ),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(76),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                serviceTypes[index]['name']!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: "Nhập giá tiền...",
              hintStyle: const TextStyle(fontSize: 14, color: Colors.black26),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.black.withAlpha(38),
                  width: 0.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 50,
          width: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(51),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            "đ/$selectedUnit",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
