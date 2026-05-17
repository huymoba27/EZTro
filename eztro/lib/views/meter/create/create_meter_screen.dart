import 'dart:io';
import 'package:flutter/material.dart';
import '../../../services/meter_service.dart';
import '../../../models/house_model.dart';
import '../../../controllers/meter_controller.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/test_tools/demo_data.dart';
import '../../../core/test_tools/dev_autofill_button.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/api_constants.dart';
import '../../../core/utils/custom_painters.dart';

class CreateMeterScreen extends StatefulWidget {
  final Map<String, dynamic>? meterData;
  const CreateMeterScreen({super.key, this.meterData});

  @override
  State<CreateMeterScreen> createState() => _CreateMeterScreenState();
}

class _CreateMeterScreenState extends State<CreateMeterScreen> {
  bool _isLoading = false;
  bool _isSubmitting = false;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  HouseModel? selectedHouse;
  Map<String, dynamic>? selectedRoom;

  File? _electricImage;
  File? _waterImage;
  bool _electricImageDeleted = false;
  bool _waterImageDeleted = false;

  List<HouseModel> allHouses = [];
  List<Map<String, dynamic>> availableRooms = [];

  int oldE = 0, oldW = 0, contractId = 0;
  final electricController = TextEditingController();
  final waterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.meterData != null) {
      _setupEditMode();
    } else {
      _fetchFilteredHouses();
    }
  }

  Future<void> _fetchFilteredHouses() async {
    setState(() => _isLoading = true);
    try {
      final houses = await MeterService.getHousesWithPending(
        month: selectedMonth,
        year: selectedYear,
      );
      if (mounted) {
        setState(() {
          allHouses = houses;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupEditMode() {
    final d = widget.meterData!;
    selectedMonth =
        int.tryParse(d['billing_month'].toString()) ?? DateTime.now().month;
    selectedYear =
        int.tryParse(d['billing_year'].toString()) ?? DateTime.now().year;
    oldE = int.tryParse(d['old_electric'].toString()) ?? 0;
    oldW = int.tryParse(d['old_water'].toString()) ?? 0;
    contractId = int.tryParse(d['contract_id'].toString()) ?? 0;
    selectedRoom = {'id': d['room_id'] ?? d['id'], 'room_name': d['room_name']};

    final meterId = d['id']?.toString();
    if (meterId != null && meterId != '0' && meterId != '') {
      electricController.text = d['new_electric']?.toString() ?? "";
      waterController.text = d['new_water']?.toString() ?? "";
    }

    setState(() {});
  }

  void _submit() {
    final meterId = widget.meterData?['id']?.toString();
    bool isEdit = meterId != null && meterId != '0' && meterId != '';

    MeterController.submitData(
      context: context,
      isEdit: isEdit,
      meterData: widget.meterData,
      selectedRoom: selectedRoom,
      electricController: electricController,
      waterController: waterController,
      oldE: oldE,
      oldW: oldW,
      contractId: contractId,
      selectedMonth: selectedMonth,
      selectedYear: selectedYear,
      electricImage: _electricImage,
      waterImage: _waterImage,
      setSubmitting: (val) => setState(() => _isSubmitting = val),
      onSuccess: () => Navigator.pop(context, true),
    );
  }

  Future<void> _fillDemoData() async {
    final data = DemoData.meter;
    final house =
        selectedHouse ?? (allHouses.isNotEmpty ? allHouses.first : null);
    if (house == null) return;

    setState(() {
      selectedHouse = house;
      selectedRoom = null;
      _isLoading = true;
    });

    try {
      final rooms = await MeterService.getPendingRooms(
        houseId: house.id,
        month: selectedMonth,
        year: selectedYear,
      );
      if (rooms.isEmpty) {
        if (mounted) {
          setState(() {
            availableRooms = rooms;
            _isLoading = false;
          });
        }
        return;
      }

      final room = rooms.first;
      final res = await MeterService.getLastReading(
        int.parse(room['id'].toString()),
      );

      if (mounted && res['status'] == 'success' && res['data'] != null) {
        setState(() {
          availableRooms = rooms;
          selectedRoom = room;
          oldE = int.tryParse(res['data']['old_electric'].toString()) ?? 0;
          oldW = int.tryParse(res['data']['old_water'].toString()) ?? 0;
          contractId = int.tryParse(res['data']['contract_id'].toString()) ?? 0;
          electricController.text = (oldE + data.electricDelta).toString();
          waterController.text = (oldW + data.waterDelta).toString();
          _isLoading = false;
        });
      } else if (mounted) {
        DialogHelper.showWarning(
          context,
          res['message']?.toString() ??
              "Không tìm thấy hợp đồng đang hoạt động của phòng này.",
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meterId = widget.meterData?['id']?.toString();
    bool isEdit = meterId != null && meterId != '0' && meterId != '';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: isEdit ? "CẬP NHẬT CHỐT SỐ" : "TẠO CHỐT ĐIỆN NƯỚC",
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      if (!isEdit) DevAutofillButton(onPressed: _fillDemoData),
                      AppSectionCard(
                        title: "Thời gian chốt số",
                        child: Column(
                          children: [
                            CustomSelectField(
                              label: "Chọn tháng",
                              value: "Tháng $selectedMonth",
                              onTap: isEdit ? null : _selectMonth,
                              lockedMessage: isEdit
                                  ? "Không thể đổi tháng của bản ghi đã chốt."
                                  : null,
                            ),
                            CustomSelectField(
                              label: "Chọn năm",
                              value: "Năm $selectedYear",
                              onTap: isEdit ? null : _selectYear,
                              lockedMessage: isEdit
                                  ? "Không thể đổi năm của bản ghi đã chốt."
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      AppSectionCard(
                        title: "Địa điểm chốt số",
                        child: Column(
                          children: [
                            CustomSelectField(
                              label: "Nhà trọ",
                              value:
                                  selectedHouse?.houseName ??
                                  widget.meterData?['house_name'] ??
                                  "Chọn nhà",
                              onTap: isEdit ? null : () => _showHouseModal(),
                              lockedMessage: isEdit
                                  ? "Không thể đổi nhà của bản ghi đã chốt."
                                  : null,
                            ),
                            CustomSelectField(
                              label: "Phòng trọ",
                              value: selectedRoom?['room_name'] ?? "Chọn phòng",
                              onTap: isEdit ? null : _handleRoomSelection,
                              lockedMessage: isEdit
                                  ? "Không thể đổi phòng của bản ghi đã chốt."
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (selectedRoom != null) ...[
                        AppSectionCard(
                          title: "Chỉ số Điện",
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      label: "Số cũ",
                                      controller: TextEditingController(
                                        text: "$oldE",
                                      ),
                                      readOnly: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: CustomTextField(
                                      label: "Số mới *",
                                      hint: "Nhập số điện mới",
                                      controller: electricController,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        AppSectionCard(
                          title: "Chỉ số Nước",
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      label: "Số cũ",
                                      controller: TextEditingController(
                                        text: "$oldW",
                                      ),
                                      readOnly: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: CustomTextField(
                                      label: "Số mới *",
                                      hint: "Nhập số nước mới",
                                      controller: waterController,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(height: 12, color: const Color(0xFFF5F5F5)),
                        AppSectionCard(
                          title: "Hình ảnh minh chứng",
                          child: Row(
                            children: [
                              Expanded(
                                child: _imagePickerBox(
                                  "Ảnh Điện",
                                  _electricImage,
                                  _electricImageDeleted
                                      ? null
                                      : widget.meterData?['electric_image'],
                                  (file) => setState(() {
                                    _electricImage = file;
                                    if (file == null) {
                                      _electricImageDeleted = true;
                                    } else {
                                      _electricImageDeleted = false;
                                    }
                                  }),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _imagePickerBox(
                                  "Ảnh Nước",
                                  _waterImage,
                                  _waterImageDeleted
                                      ? null
                                      : widget.meterData?['water_image'],
                                  (file) => setState(() {
                                    _waterImage = file;
                                    if (file == null) {
                                      _waterImageDeleted = true;
                                    } else {
                                      _waterImageDeleted = false;
                                    }
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
              if (selectedRoom != null) _buildBottomButtons(isEdit),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showHouseModal() {
    AppSelectModal.show<int>(
      context: context,
      title: "CHỌN NHÀ TRỌ",
      subtitle: "Vui lòng chọn khu trọ cần chốt số",
      items: allHouses
          .map((h) => AppSelectItem(label: h.houseName, value: h.id))
          .toList(),
      initialValues: selectedHouse != null ? [selectedHouse!.id] : [],
      onSelect: (values) async {
        if (values.isNotEmpty) {
          final id = values.first;
          setState(() {
            selectedHouse = allHouses.firstWhere((h) => h.id == id);
            selectedRoom = null;
            _isLoading = true;
          });
          final rooms = await MeterService.getPendingRooms(
            houseId: id,
            month: selectedMonth,
            year: selectedYear,
          );
          setState(() {
            availableRooms = rooms;
            _isLoading = false;
          });
        }
      },
    );
  }

  Widget _buildBottomButtons(bool isEdit) {
    return AppBottomButtons(
      onCancel: () => Navigator.pop(context),
      onConfirm: _submit,
      cancelText: "HỦY",
      confirmText: isEdit ? "LƯU CẬP NHẬT" : "XÁC NHẬN CHỐT",
      isSubmitting: _isSubmitting,
    );
  }

  void _selectMonth() {
    DialogHelper.showLocationSelect(
      context: context,
      title: "CHỌN THÁNG",
      subtitle: "Chốt số điện nước",
      data: List.generate(12, (index) => "Tháng ${index + 1}"),
      currentValue: "Tháng $selectedMonth",
      onSelect: (val) {
        setState(() {
          selectedMonth = int.parse(val.replaceAll("Tháng ", ""));
          selectedHouse = null;
          selectedRoom = null;
        });
        _fetchFilteredHouses();
      },
    );
  }

  void _selectYear() {
    int currentYear = DateTime.now().year;
    List<String> years = List.generate(
      5,
      (index) => (currentYear - index).toString(),
    );
    DialogHelper.showLocationSelect(
      context: context,
      title: "CHỌN NĂM",
      subtitle: "Chốt số điện nước",
      data: years,
      currentValue: selectedYear.toString(),
      onSelect: (val) {
        setState(() {
          selectedYear = int.parse(val);
          selectedHouse = null;
          selectedRoom = null;
        });
        _fetchFilteredHouses();
      },
    );
  }

  void _handleRoomSelection() {
    if (selectedHouse == null) {
      return DialogHelper.showWarning(context, "Vui lòng chọn nhà trọ trước!");
    }
    if (availableRooms.isEmpty) {
      return DialogHelper.showWarning(
        context,
        "Nhà này đã chốt hết tất cả các phòng!",
      );
    }

    DialogHelper.showLocationSelect(
      context: context,
      title: "CHỌN PHÒNG",
      subtitle: "Chỉ hiện phòng chưa chốt tháng $selectedMonth",
      data: availableRooms.map((r) => r['room_name'].toString()).toList(),
      currentValue: selectedRoom?['room_name'] ?? "",
      onSelect: (val) async {
        final room = availableRooms.firstWhere((r) => r['room_name'] == val);
        setState(() => _isLoading = true);
        try {
          final res = await MeterService.getLastReading(
            int.parse(room['id'].toString()),
          );
          if (res['status'] == 'success' && res['data'] != null) {
            setState(() {
              selectedRoom = room;
              oldE = int.tryParse(res['data']['old_electric'].toString()) ?? 0;
              oldW = int.tryParse(res['data']['old_water'].toString()) ?? 0;
              contractId =
                  int.tryParse(res['data']['contract_id'].toString()) ??
                  int.tryParse(room['contract_id']?.toString() ?? '0') ??
                  0;
            });
          } else {
            DialogHelper.showWarning(
              context,
              res['message']?.toString() ??
                  "Không tìm thấy hợp đồng đang hoạt động của phòng này.",
            );
          }
        } finally {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  Widget _imagePickerBox(
    String label,
    File? imageFile,
    String? networkImage,
    Function(File?) onPicked,
  ) {
    bool hasImage =
        imageFile != null || (networkImage != null && networkImage.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () => DialogHelper.showImagePicker(
                context: context,
                onImagesPicked: (files) {
                  if (files.isNotEmpty) onPicked(files.first);
                },
              ),
              child: CustomPaint(
                painter: DashedRectPainter(
                  color: Colors.black.withOpacity(0.15),
                  dash: 5,
                  gap: 3,
                  strokeWidth: 1.0,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageFile != null
                          ? Image.file(imageFile, fit: BoxFit.cover)
                          : (networkImage != null && networkImage.isNotEmpty)
                          ? Image.network(
                              "${ApiConstants.serverUrl}/uploads/meters/$networkImage",
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.add_a_photo_outlined,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            if (hasImage)
              Positioned(
                right: -8,
                top: -8,
                child: GestureDetector(
                  onTap: () => onPicked(null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
