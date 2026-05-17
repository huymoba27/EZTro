import 'dart:io';
import 'package:eztro/models/contract_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/house_service.dart';
import '../../../services/room_service.dart';
import '../../../services/service_manage_service.dart';
import '../../../services/vehicle_service.dart';
import '../../../controllers/contract_controller.dart';
import '../../../models/house_model.dart';
import '../../../models/room_model.dart';
import '../../../models/service_model.dart';
import '../../../core/test_tools/demo_data.dart';
import '../../../core/test_tools/dev_autofill_button.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../core/constants/app_colors.dart';
import 'widgets/customer_info_widget.dart';
import 'widgets/contract_terms_widget.dart';
import 'widgets/contract_services_widget.dart';
import '../../../models/deposit_model.dart';
import '../../../services/deposit_service.dart';
import '../../../services/meter_service.dart';

class CreateContractScreen extends StatefulWidget {
  final ContractModel? contractData;
  final DepositModel? depositData;
  final RoomModel? roomData;
  const CreateContractScreen({
    super.key,
    this.contractData,
    this.depositData,
    this.roomData,
  });

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen> {
  // --- Controllers ---
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final birthdayController = TextEditingController();
  final idCardController = TextEditingController();
  final idCardDateController = TextEditingController();
  final idCardPlaceController = TextEditingController();
  final addressController = TextEditingController();

  final startDateController = TextEditingController();
  final durationController = TextEditingController(text: "6");
  final priceController = TextEditingController();
  final depositController = TextEditingController();
  final paymentDayController = TextEditingController(text: "5");

  final startElectricController = TextEditingController(text: "0");
  final startWaterController = TextEditingController(text: "0");
  final noteController = TextEditingController();

  // --- State ---
  List<HouseModel> allHouses = [];
  List<RoomModel> filteredRooms = [];
  List<ServiceModel> houseServices = [];
  List<int> selectedServiceIds = [];

  HouseModel? selectedHouse;
  RoomModel? selectedRoom;
  bool isLoading = false;
  bool isSubmitting = false;
  bool isEditMode = false;
  bool get isFromDeposit => widget.depositData != null;
  bool get isLocationLocked => isEditMode || isFromDeposit;
  String selectedGender = "Nam";
  String endDateDisplay = "Chưa xác định";
  bool hasVehicles = false;
  File? frontImg, backImg;
  int? autoDepositId;

  @override
  void initState() {
    super.initState();
    isEditMode = widget.contractData != null;
    startDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _initData();
    });
  }

  // --- Data Initialization ---

  Future<void> _initData() async {
    setState(() => isLoading = true);
    try {
      allHouses = await HouseService.getHouses();

      if (isEditMode) {
        await _initEditModeFlow();
      } else if (isFromDeposit) {
        await _initFromDepositFlow();
      } else if (widget.roomData != null) {
        await _initFromRoomFlow();
      }
    } catch (e) {
      debugPrint("Lỗi khởi tạo: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        _updateEndDate();
      }
    }
  }

  Future<void> _initEditModeFlow() async {
    final d = widget.contractData!;
    nameController.text = d.tenantName ?? '';
    phoneController.text = d.tenantPhone ?? '';
    emailController.text = d.email ?? '';
    birthdayController.text = d.birthday ?? '';
    idCardController.text = d.idCard ?? '';
    idCardDateController.text = d.idCardDate ?? '';
    idCardPlaceController.text = d.idCardPlace ?? '';
    addressController.text = d.address ?? '';
    selectedGender = d.gender ?? "Nam";

    startDateController.text = d.startDate;
    priceController.text = d.rentPrice.toInt().toString();
    depositController.text = d.depositAmount.toInt().toString();
    paymentDayController.text = d.paymentDay.toString();
    startElectricController.text = d.startElectric.toString();
    startWaterController.text = d.startWater.toString();

    if (d.houseId != null && d.houseId! > 0) {
      selectedHouse = allHouses.firstWhere(
        (h) => h.id == d.houseId,
        orElse: () => allHouses.first,
      );
      await _loadHouseSpecificData(d.houseId!);

      // Gán phòng đã chọn
      final matched = filteredRooms.where((r) => r.id == d.roomId);
      if (matched.isNotEmpty) {
        selectedRoom = matched.first;
      }

      if (d.services != null) {
        selectedServiceIds = d.services!.map((s) => s.id).toList();
      }
      _checkVehicles(roomId: d.roomId);
    }
  }

  Future<void> _initFromDepositFlow() async {
    final dd = widget.depositData!;
    nameController.text = dd.customerName;
    phoneController.text = dd.customerPhone;
    depositController.text = dd.depositAmount.toInt().toString();
    startDateController.text = dd.expectedMoveInDate;

    if (dd.houseId > 0) {
      selectedHouse = allHouses.firstWhere(
        (h) => h.id == dd.houseId,
        orElse: () => allHouses.first,
      );
      await _loadHouseSpecificData(dd.houseId);
      final matched = filteredRooms.where((r) => r.id == dd.roomId);
      if (matched.isNotEmpty) {
        selectedRoom = matched.first;
        priceController.text = selectedRoom!.price.toInt().toString();
        depositController.text = selectedRoom!.deposit.toInt().toString();
        _checkVehicles(roomId: dd.roomId);
        _fetchLastMeterReadings(dd.roomId);
      }
    }
  }

  Future<void> _initFromRoomFlow() async {
    final rd = widget.roomData!;
    if (rd.houseId > 0) {
      selectedHouse = allHouses.firstWhere(
        (h) => h.id == rd.houseId,
        orElse: () => allHouses.first,
      );
      await _loadHouseSpecificData(rd.houseId);
      final matched = filteredRooms.where((r) => r.id == rd.id);
      if (matched.isNotEmpty) {
        selectedRoom = matched.first;
        priceController.text = selectedRoom!.price.toInt().toString();
        depositController.text = selectedRoom!.deposit.toInt().toString();
        _checkVehicles(roomId: rd.id);
        _fetchLastMeterReadings(rd.id);
      }
    }
  }

  Future<void> _loadHouseSpecificData(int houseId) async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        ServiceManageService.getServices(houseId: houseId),
        RoomService.getRooms(houseId: houseId),
      ]);

      final svcs = results[0] as List<ServiceModel>;
      final rooms = results[1] as List<RoomModel>;

      if (mounted) {
        setState(() {
          houseServices = svcs;
          filteredRooms = rooms
              .where(
                (r) =>
                    r.status == 'empty' ||
                    r.status == 'posted' ||
                    r.status == 'deposited' ||
                    r.id == widget.contractData?.roomId,
              )
              .toList();
          _ensureMandatoryServices();
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải dữ liệu nhà: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _ensureMandatoryServices() {
    for (var svc in houseServices) {
      final name = svc.serviceName.toLowerCase();
      if (name.contains("điện") || name.contains("nước")) {
        if (!selectedServiceIds.contains(svc.id)) {
          selectedServiceIds.add(svc.id);
        }
      }
    }
  }

  void _updateEndDate() {
    setState(() {
      endDateDisplay = ContractController.calculateEndDate(
        startDateController.text,
        durationController.text,
      );
    });
  }

  Future<void> _checkVehicles({required int roomId}) async {
    try {
      final tenants = await VehicleService.getTenantsWithVehicles(
        roomId: roomId,
      );
      int total = 0;
      for (var t in tenants) {
        if (t['vehicles'] != null) {
          total += (t['vehicles'] as List).length;
        }
      }
      if (mounted) setState(() => hasVehicles = total > 0);
    } catch (e) {
      debugPrint("Lỗi kiểm tra xe: $e");
    }
  }

  Future<void> _fetchLastMeterReadings(int roomId) async {
    try {
      final res = await MeterService.getLatestRoomReading(roomId);
      if (res['status'] == 'success' && res['data'] != null) {
        final data = res['data'];
        setState(() {
          // Lưu ý: getLastReading trả về old_electric/water là chỉ số mới nhất của phòng
          startElectricController.text = (data['old_electric'] ?? "0")
              .toString();
          startWaterController.text = (data['old_water'] ?? "0").toString();
        });
      }
    } catch (e) {
      debugPrint("Lỗi lấy chỉ số điện nước: $e");
    }
  }

  // --- Handlers ---

  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
        if (controller == startDateController) _updateEndDate();
      });
    }
  }

  Future<void> _fillDemoData() async {
    if (isEditMode) return;

    final data = DemoData.contract;
    nameController.text = data.tenantName;
    phoneController.text = data.tenantPhone;
    emailController.text = data.tenantEmail;
    birthdayController.text = data.birthday;
    idCardController.text = data.idCard;
    idCardDateController.text = data.idCardDate;
    idCardPlaceController.text = data.idCardPlace;
    addressController.text = data.address;
    durationController.text = data.durationMonths;
    paymentDayController.text = data.paymentDay;
    startElectricController.text = data.startElectric;
    startWaterController.text = data.startWater;
    selectedGender = data.gender;

    final house =
        selectedHouse ?? (allHouses.isNotEmpty ? allHouses.first : null);
    if (house != null) {
      selectedHouse = house;
      await _loadHouseSpecificData(house.id);
      if (filteredRooms.isNotEmpty) {
        final room = filteredRooms.first;
        selectedRoom = room;
        priceController.text = room.price.toInt().toString();
        depositController.text = room.deposit.toInt().toString();
        await _fetchLastMeterReadings(room.id);
        await _checkVehicles(roomId: room.id);
      }
    }

    _updateEndDate();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: CustomAppBar(
        title: isEditMode ? "SỬA HỢP ĐỒNG" : "KÝ HỢP ĐỒNG MỚI",
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              if (!isEditMode && !isFromDeposit)
                DevAutofillButton(onPressed: _fillDemoData),
              _buildLocationCard(),
              if (selectedRoom != null) ...[
                const SizedBox(height: 16),
                AppSectionCard(
                  title: "THÔNG TIN KHÁCH THUÊ",
                  child: CustomerInfoWidget(
                    nameController: nameController,
                    phoneController: phoneController,
                    emailController: emailController,
                    birthdayController: birthdayController,
                    idCardController: idCardController,
                    idCardDateController: idCardDateController,
                    idCardPlaceController: idCardPlaceController,
                    addressController: addressController,
                    selectedGender: selectedGender,
                    onGenderChanged: (val) =>
                        setState(() => selectedGender = val),
                    onImagesChanged: (f, b) {
                      frontImg = f;
                      backImg = b;
                    },
                    onSelectCCCDDate: () => _selectDate(idCardDateController),
                    onSelectBirthday: () => _selectDate(birthdayController),
                    readOnly: isEditMode,
                  ),
                ),
                const SizedBox(height: 16),
                AppSectionCard(
                  title: "ĐIỀU KHOẢN HỢP ĐỒNG",
                  child: ContractTermsWidget(
                    startDateController: startDateController,
                    durationController: durationController,
                    priceController: priceController,
                    depositController: depositController,
                    paymentDayController: paymentDayController,
                    endDateDisplay: endDateDisplay,
                    onPickDate: () => _selectDate(startDateController),
                    onDurationChanged: (_) => _updateEndDate(),
                    themeGreen: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildUtilityCard(),
                const SizedBox(height: 16),
                AppSectionCard(
                  title: "DỊCH VỤ SỬ DỤNG",
                  child: ContractServicesWidget(
                    houseServices: houseServices,
                    selectedServiceIds: selectedServiceIds,
                    hasVehicles: hasVehicles,
                    onServiceToggled: (id, isSelected) {
                      setState(() {
                        if (isSelected) {
                          if (!selectedServiceIds.contains(id)) {
                            selectedServiceIds.add(id);
                          }
                        } else {
                          selectedServiceIds.remove(id);
                        }
                      });
                    },
                  ),
                ),
              ],
            ],
          ),
          if (isLoading || isSubmitting)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          if (selectedRoom != null) _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return AppSectionCard(
      title: "VỊ TRÍ THUÊ",
      child: Column(
        children: [
          CustomSelectField(
            label: "Nhà trọ",
            value: selectedHouse?.houseName ?? "Chọn nhà",
            onTap: isLocationLocked ? null : _showHousePicker,
            lockedMessage: isFromDeposit
                ? "Không thể đổi nhà khi ký hợp đồng từ phiếu cọc."
                : isEditMode
                ? "Không thể đổi nhà khi sửa hợp đồng."
                : null,
          ),
          CustomSelectField(
            label: "Phòng",
            value: selectedRoom?.roomName ?? "Chọn phòng",
            onTap: isLocationLocked ? null : _showRoomPicker,
            lockedMessage: isFromDeposit
                ? "Không thể đổi phòng khi ký hợp đồng từ phiếu cọc."
                : isEditMode
                ? "Không thể đổi phòng khi sửa hợp đồng."
                : null,
          ),
        ],
      ),
    );
  }

  void _showHousePicker() {
    if (isFromDeposit) {
      return;
    }
    AppSelectModal.show<int>(
      context: context,
      title: "CHỌN NHÀ TRỌ",
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
          });
          await _loadHouseSpecificData(id);
        }
      },
    );
  }

  void _showRoomPicker() {
    if (isFromDeposit) {
      return;
    }
    if (selectedHouse == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng chọn nhà trước")));
      return;
    }
    AppSelectModal.show<int>(
      context: context,
      title: "CHỌN PHÒNG",
      items: filteredRooms
          .map((r) => AppSelectItem(label: r.roomName, value: r.id))
          .toList(),
      initialValues: selectedRoom != null ? [selectedRoom!.id] : [],
      onSelect: (values) async {
        if (values.isNotEmpty) {
          final id = values.first;
          final room = filteredRooms.firstWhere((r) => r.id == id);
          setState(() {
            selectedRoom = room;
            priceController.text = room.price.toInt().toString();
            depositController.text = room.deposit.toInt().toString();
            autoDepositId = null;
            _fetchLastMeterReadings(id);
          });

          // Tự động điền thông tin nếu phòng đang có cọc
          if (room.status == 'deposited') {
            setState(() => isLoading = true);
            try {
              final deposit = await DepositService.getDepositByRoom(id);
              if (deposit != null) {
                setState(() {
                  autoDepositId = deposit.id;
                  nameController.text = deposit.customerName;
                  phoneController.text = deposit.customerPhone;
                  depositController.text = deposit.depositAmount
                      .toInt()
                      .toString();
                  startDateController.text = deposit.expectedMoveInDate;
                  _updateEndDate();
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Đã tự động điền thông tin từ phiếu cọc"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            } finally {
              if (mounted) setState(() => isLoading = false);
            }
          }
        }
      },
    );
  }

  Widget _buildUtilityCard() {
    return AppSectionCard(
      title: "CHỈ SỐ ĐIỆN NƯỚC BẮT ĐẦU",
      child: Row(
        children: [
          Expanded(
            child: CustomTextField(
              controller: startElectricController,
              label: "Số điện đầu",
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomTextField(
              controller: startWaterController,
              label: "Số nước đầu",
              keyboardType: TextInputType.number,
            ),
          ),
        ],
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
        onConfirm: () {
          ContractController.handleSave(
            context: context,
            isEdit: isEditMode,
            contractData: widget.contractData,
            selectedRoom: selectedRoom,
            nameController: nameController,
            phoneController: phoneController,
            priceController: priceController,
            depositController: depositController,
            paymentDayController: paymentDayController,
            startElectricController: startElectricController,
            startWaterController: startWaterController,
            idCardController: idCardController,
            emailController: emailController,
            birthdayController: birthdayController,
            idCardDateController: idCardDateController,
            idCardPlaceController: idCardPlaceController,
            addressController: addressController,
            startDateController: startDateController,
            endDateDisplay: endDateDisplay,
            selectedGender: selectedGender,
            selectedServiceIds: selectedServiceIds,
            frontImg: frontImg,
            backImg: backImg,
            setSubmitting: (val) => setState(() => isSubmitting = val),
            depositId:
                isFromDeposit && selectedRoom?.id == widget.depositData?.roomId
                ? widget.depositData!.id
                : autoDepositId,
          );
        },
        cancelText: "HỦY BỎ",
        confirmText: isEditMode ? "CẬP NHẬT" : "KÝ HỢP ĐỒNG",
      ),
    );
  }
}
