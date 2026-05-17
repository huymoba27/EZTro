import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../services/deposit_service.dart';
import '../../../services/house_service.dart';
import '../../../services/room_service.dart';
import '../../../models/deposit_model.dart';
import '../../../models/house_model.dart';
import '../../../models/room_model.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/input_validation_helper.dart';
import '../../../core/test_tools/demo_data.dart';
import '../../../core/test_tools/dev_autofill_button.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../core/constants/app_colors.dart';

class CreateDepositScreen extends StatefulWidget {
  final DepositModel? depositData;

  const CreateDepositScreen({super.key, this.depositData});

  @override
  State<CreateDepositScreen> createState() => _CreateDepositScreenState();
}

class _CreateDepositScreenState extends State<CreateDepositScreen> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  HouseModel? selectedHouse;
  RoomModel? selectedRoom;
  List<HouseModel> houses = [];
  List<RoomModel> availableRooms = [];

  DateTime depositDate = DateTime.now();
  DateTime moveInDate = DateTime.now().add(const Duration(days: 3));
  bool isLoading = false;
  bool get isEditing => widget.depositData != null;

  @override
  void initState() {
    super.initState();
    _loadHouses();
  }

  Future<void> _loadHouses() async {
    final res = await HouseService.getHouses();
    final editData = widget.depositData;
    if (mounted) {
      setState(() {
        houses = isEditing
            ? res
            : res.where((h) => h.totalEmptyRooms > 0).toList();
      });
    }

    if (editData != null) {
      HouseModel? matchedHouse;
      for (final house in res) {
        if (house.id == editData.houseId) {
          matchedHouse = house;
          break;
        }
      }

      final rooms = await RoomService.getRooms(houseId: editData.houseId);
      RoomModel? matchedRoom;
      for (final room in rooms) {
        if (room.id == editData.roomId) {
          matchedRoom = room;
          break;
        }
      }

      if (mounted) {
        setState(() {
          selectedHouse = matchedHouse;
          availableRooms = rooms;
          selectedRoom = matchedRoom;
          nameCtrl.text = editData.customerName;
          phoneCtrl.text = editData.customerPhone;
          amountCtrl.text = editData.depositAmount.toInt().toString();
          noteCtrl.text = editData.note ?? "";
          depositDate =
              DateTime.tryParse(editData.depositDate) ?? DateTime.now();
          moveInDate =
              DateTime.tryParse(editData.expectedMoveInDate) ??
              DateTime.now().add(const Duration(days: 3));
        });
      }
    }
  }

  void _submit() async {
    if (nameCtrl.text.trim().isEmpty) {
      return DialogHelper.showWarning(context, "Vui lòng nhập tên khách");
    }
    if (phoneCtrl.text.trim().isEmpty) {
      return DialogHelper.showWarning(context, "Vui lòng nhập SĐT");
    }
    final phoneError = InputValidationHelper.phoneError(phoneCtrl.text);
    if (phoneError != null) {
      return DialogHelper.showWarning(context, phoneError);
    }
    if (amountCtrl.text.trim().isEmpty) {
      return DialogHelper.showWarning(context, "Vui lòng nhập tiền cọc");
    }
    if (!isEditing && selectedRoom == null) {
      return DialogHelper.showWarning(context, "Vui lòng chọn phòng");
    }

    final depositAmount = double.tryParse(amountCtrl.text.replaceAll(',', ''));
    if (depositAmount == null || depositAmount <= 0) {
      return DialogHelper.showWarning(context, "Tiền cọc phải là số lớn hơn 0");
    }

    setState(() => isLoading = true);
    try {
      final res = isEditing
          ? await DepositService.updateDeposit(
              depositId: widget.depositData!.id,
              customerName: nameCtrl.text.trim(),
              customerPhone: phoneCtrl.text.trim(),
              depositAmount: depositAmount,
              depositDate: DateFormat('yyyy-MM-dd').format(depositDate),
              expectedMoveInDate: DateFormat('yyyy-MM-dd').format(moveInDate),
              note: noteCtrl.text.trim(),
            )
          : await DepositService.createDeposit(
              houseId: selectedHouse!.id,
              roomId: selectedRoom!.id,
              customerName: nameCtrl.text.trim(),
              customerPhone: phoneCtrl.text.trim(),
              depositAmount: depositAmount,
              depositDate: DateFormat('yyyy-MM-dd').format(depositDate),
              expectedMoveInDate: DateFormat('yyyy-MM-dd').format(moveInDate),
              note: noteCtrl.text.trim(),
            );
      if (!mounted) return;
      if (res['status'] == 'success') {
        DialogHelper.showSuccess(
          context,
          isEditing
              ? "Cập nhật phiếu cọc thành công"
              : "Tạo phiếu cọc thành công",
          onTap: () => Navigator.pop(context, true),
        );
      } else {
        DialogHelper.showError(context, res['message']);
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showError(context, "Lỗi kết nối: $e");
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fillDemoData() async {
    final data = DemoData.deposit;
    final house = selectedHouse ?? (houses.isNotEmpty ? houses.first : null);

    setState(() {
      selectedHouse = house;
      nameCtrl.text = data.customerName;
      phoneCtrl.text = data.customerPhone;
      amountCtrl.text = data.amount;
      noteCtrl.text = data.note;
      depositDate = DateTime.now();
      moveInDate = DateTime.now().add(const Duration(days: 3));
    });

    if (house != null) {
      setState(() => isLoading = true);
      final rooms = await RoomService.getRooms(houseId: house.id);
      if (mounted) {
        setState(() {
          availableRooms = rooms.where((r) => r.status == 'empty').toList();
          selectedRoom = availableRooms.isNotEmpty
              ? availableRooms.first
              : null;
          if (selectedRoom != null) {
            amountCtrl.text = selectedRoom!.deposit.toInt().toString();
          }
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: CustomAppBar(
        title: isEditing ? "SỬA PHIẾU CỌC" : "TẠO PHIẾU CỌC",
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                if (!isEditing) DevAutofillButton(onPressed: _fillDemoData),
                AppSectionCard(
                  title: "Phòng giữ chỗ",
                  child: Column(
                    children: [
                      CustomSelectField(
                        label: "Nhà trọ *",
                        value: selectedHouse?.houseName ?? "Chọn nhà trọ",
                        onTap: () {
                          if (isEditing) {
                            DialogHelper.showWarning(
                              context,
                              "Không thể đổi nhà trọ của phiếu cọc đang sửa",
                            );
                            return;
                          }
                          AppSelectModal.show<int>(
                            context: context,
                            title: "CHỌN NHÀ TRỌ",
                            subtitle: "Vui lòng chọn khu trọ nhận cọc",
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
                            onSelect: (values) async {
                              if (values.isNotEmpty) {
                                final id = values.first;
                                setState(() {
                                  selectedHouse = houses.firstWhere(
                                    (h) => h.id == id,
                                  );
                                  selectedRoom = null;
                                  isLoading = true;
                                });
                                final rooms = await RoomService.getRooms(
                                  houseId: id,
                                );
                                if (mounted) {
                                  setState(() {
                                    availableRooms = rooms
                                        .where((r) => r.status == 'empty')
                                        .toList();
                                    isLoading = false;
                                  });
                                }
                              }
                            },
                          );
                        },
                      ),
                      CustomSelectField(
                        label: "Phòng trống *",
                        value:
                            selectedRoom?.roomName ??
                            widget.depositData?.roomName ??
                            "Chọn phòng trống",
                        onTap: () {
                          if (isEditing) {
                            DialogHelper.showWarning(
                              context,
                              "Không thể đổi phòng của phiếu cọc đang sửa",
                            );
                            return;
                          }
                          if (selectedHouse == null) {
                            DialogHelper.showWarning(
                              context,
                              "Chọn nhà trước!",
                            );
                            return;
                          }
                          if (availableRooms.isEmpty) {
                            DialogHelper.showWarning(
                              context,
                              "Nhà này không còn phòng trống",
                            );
                            return;
                          }
                          DialogHelper.showLocationSelect(
                            context: context,
                            title: "CHỌN PHÒNG",
                            subtitle: "Chỉ hiện phòng trống",
                            data: availableRooms
                                .map((r) => r.roomName)
                                .toList(),
                            currentValue: selectedRoom?.roomName ?? "",
                            onSelect: (val) {
                              final room = availableRooms.firstWhere(
                                (r) => r.roomName == val,
                              );
                              setState(() {
                                selectedRoom = room;
                                amountCtrl.text = room.deposit
                                    .toInt()
                                    .toString();
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AppSectionCard(
                  title: "Thông tin khách hàng",
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: nameCtrl,
                        label: "Tên khách thuê",
                        hint: "Họ và tên...",
                      ),
                      CustomTextField(
                        controller: phoneCtrl,
                        label: "Số điện thoại",
                        hint: "090...",
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 11,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AppSectionCard(
                  title: "Chi tiết tiền cọc",
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: amountCtrl,
                        label: "Số tiền cọc (VNĐ)",
                        hint: "0",
                        keyboardType: TextInputType.number,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: CustomSelectField(
                              label: "Ngày cọc",
                              value: DateFormat(
                                'dd/MM/yyyy',
                              ).format(depositDate),
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: depositDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (d != null) setState(() => depositDate = d);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomSelectField(
                              label: "Dự kiến ở",
                              value: DateFormat(
                                'dd/MM/yyyy',
                              ).format(moveInDate),
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: moveInDate,
                                  firstDate: depositDate,
                                  lastDate: DateTime(2030),
                                );
                                if (d != null) setState(() => moveInDate = d);
                              },
                            ),
                          ),
                        ],
                      ),
                      CustomTextField(
                        controller: noteCtrl,
                        label: "Ghi chú",
                        hint: "Nhập ghi chú (nếu có)...",
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

  Widget _buildBottomButtons() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AppBottomButtons(
        onCancel: () => Navigator.pop(context),
        onConfirm: _submit,
        cancelText: "Hủy bỏ",
        confirmText: isEditing ? "Cập nhật phiếu cọc" : "Tạo phiếu cọc",
        isSubmitting: isLoading,
      ),
    );
  }
}
