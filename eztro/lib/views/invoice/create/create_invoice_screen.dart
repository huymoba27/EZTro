import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/invoice_service.dart';
import '../../../models/house_model.dart';
import '../../../models/room_model.dart';
import '../../../core/test_tools/demo_data.dart';
import '../../../core/test_tools/dev_autofill_button.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../core/constants/app_colors.dart';

// Widgets tách riêng
import 'widgets/invoice_time_section.dart';
import 'widgets/invoice_target_section.dart';
import 'widgets/invoice_pro_rata_section.dart';
import 'widgets/invoice_meter_section.dart';
import 'widgets/invoice_summary_section.dart';
import '../../../controllers/invoice_controller.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final int? initialMonth;
  final int? initialYear;
  const CreateInvoiceScreen({super.key, this.initialMonth, this.initialYear});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final currencyFormat = NumberFormat("#,###", "vi_VN");
  bool isLoading = false;

  late int selectedMonth;
  late int selectedYear;
  HouseModel? selectedHouse;
  Map<String, dynamic>? selectedRoom;
  Map<String, dynamic>? billSummary;

  final elecController = TextEditingController();
  final waterController = TextEditingController();

  List<HouseModel> allHouses = [];
  List<RoomModel> allOccupiedRooms = [];
  bool isMeterChecked = false;

  bool isProRata = false;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    selectedMonth = (widget.initialMonth != null && widget.initialMonth! > 0)
        ? widget.initialMonth!
        : DateTime.now().month;
    selectedYear = (widget.initialYear != null && widget.initialYear! > 0)
        ? widget.initialYear!
        : DateTime.now().year;

    elecController.addListener(_updateRealtimeTotal);
    waterController.addListener(_updateRealtimeTotal);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _loadInitialData();
    });
  }

  @override
  void dispose() {
    elecController.dispose();
    waterController.dispose();
    super.dispose();
  }

  void _resetFields() {
    selectedRoom = null;
    billSummary = null;
    allOccupiedRooms = [];
    elecController.clear();
    waterController.clear();
    _loadRoomsForHouse();
  }

  void _updateRealtimeTotal() {
    final updatedSummary = InvoiceController.calculateInvoice(
      billSummary: billSummary,
      newElecStr: elecController.text,
      newWaterStr: waterController.text,
      isProRata: isProRata,
      startDate: startDate,
      endDate: endDate,
      selectedMonth: selectedMonth,
      selectedYear: selectedYear,
    );

    if (updatedSummary != null) {
      setState(() => billSummary = updatedSummary);
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      final houses = await InvoiceService.getHousesForInvoicing(
        selectedMonth,
        selectedYear,
      );
      if (mounted) {
        setState(() => allHouses = houses);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadRoomsForHouse() async {
    if (selectedHouse == null) return;
    setState(() => isLoading = true);
    try {
      final roomsData = await InvoiceService.getRoomsReadyToBill(
        houseId: selectedHouse!.id,
        month: selectedMonth,
        year: selectedYear,
      );
      if (mounted) {
        setState(() {
          allOccupiedRooms = roomsData
              .map((r) => RoomModel.fromJson(r))
              .toList();
        });
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _onRoomSelected(String val) async {
    final room = allOccupiedRooms.firstWhere((r) => r.roomName == val);
    setState(() {
      selectedRoom = room.toJson();
      isLoading = true;
      billSummary = null;
      elecController.clear();
      waterController.clear();
    });

    try {
      final res = await InvoiceService.getBillSummary(
        room.id,
        selectedMonth,
        selectedYear,
      );
      if (res['status'] == 'success' || res['status'] == 'pending') {
        setState(() {
          isMeterChecked = (res['status'] == 'success');
          billSummary = res['data'];
          billSummary!['base_total_amount'] = res['data']['total_amount'];
          if (isMeterChecked) {
            elecController.text = billSummary?['new_elec'].toString() ?? "";
            waterController.text = billSummary?['new_water'].toString() ?? "";
          }
        });
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _submitInvoice() {
    InvoiceController.submitInvoice(
      context: context,
      isMeterChecked: isMeterChecked,
      elecController: elecController,
      waterController: waterController,
      billSummary: billSummary,
      selectedRoom: selectedRoom,
      selectedMonth: selectedMonth,
      selectedYear: selectedYear,
      isProRata: isProRata,
      startDate: startDate,
      endDate: endDate,
      setLoading: (val) => setState(() => isLoading = val),
    );
  }

  Future<void> _fillDemoData() async {
    final house =
        selectedHouse ?? (allHouses.isNotEmpty ? allHouses.first : null);
    if (house == null) return;

    setState(() {
      selectedHouse = house;
      selectedRoom = null;
      billSummary = null;
      elecController.clear();
      waterController.clear();
      isLoading = true;
    });

    try {
      final roomsData = await InvoiceService.getRoomsReadyToBill(
        houseId: house.id,
        month: selectedMonth,
        year: selectedYear,
      );
      final rooms = roomsData.map((r) => RoomModel.fromJson(r)).toList();
      if (rooms.isEmpty) {
        if (mounted) setState(() => allOccupiedRooms = rooms);
        return;
      }

      final room = rooms.first;
      final res = await InvoiceService.getBillSummary(
        room.id,
        selectedMonth,
        selectedYear,
      );

      if (mounted &&
          (res['status'] == 'success' || res['status'] == 'pending')) {
        setState(() {
          allOccupiedRooms = rooms;
          selectedRoom = room.toJson();
          isMeterChecked = (res['status'] == 'success');
          billSummary = res['data'];
          billSummary!['base_total_amount'] = res['data']['total_amount'];
          final oldElec =
              int.tryParse((billSummary?['old_elec'] ?? 0).toString()) ?? 0;
          final oldWater =
              int.tryParse((billSummary?['old_water'] ?? 0).toString()) ?? 0;
          elecController.text = (oldElec + DemoData.invoice.electricDelta)
              .toString();
          waterController.text = (oldWater + DemoData.invoice.waterDelta)
              .toString();
        });
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: "LẬP HÓA ĐƠN",
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      DevAutofillButton(onPressed: _fillDemoData),
                      InvoiceTimeSection(
                        selectedMonth: selectedMonth,
                        selectedYear: selectedYear,
                        onTimeChanged: (m, y) {
                          setState(() {
                            selectedMonth = m;
                            selectedYear = y;
                            _resetFields();
                            _loadInitialData();
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      InvoiceTargetSection(
                        allHouses: allHouses,
                        selectedHouse: selectedHouse,
                        selectedRoom: selectedRoom,
                        allOccupiedRooms: allOccupiedRooms,
                        onHouseSelected: (h) {
                          setState(() {
                            selectedHouse = h;
                            _resetFields();
                          });
                        },
                        onRoomSelected: _onRoomSelected,
                      ),
                      const SizedBox(height: 10),
                      if (selectedRoom != null)
                        InvoiceProRataSection(
                          isProRata: isProRata,
                          startDate: startDate,
                          endDate: endDate,
                          selectedMonth: selectedMonth,
                          selectedYear: selectedYear,
                          onChanged: (val, s, e) {
                            setState(() {
                              isProRata = val;
                              startDate = s;
                              endDate = e;
                              _updateRealtimeTotal();
                            });
                          },
                        ),
                      const SizedBox(height: 10),
                      if (selectedRoom != null && billSummary != null) ...[
                        InvoiceMeterSection(
                          oldElec: billSummary?['old_elec'] ?? 0,
                          oldWater: billSummary?['old_water'] ?? 0,
                          elecController: elecController,
                          waterController: waterController,
                          isMeterChecked: isMeterChecked,
                        ),
                        const SizedBox(height: 10),
                        InvoiceSummarySection(
                          billSummary: billSummary!,
                          isMeterChecked: isMeterChecked,
                          currencyFormat: currencyFormat,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
              if (selectedRoom != null && billSummary != null)
                AppBottomButtons(
                  onCancel: () => Navigator.pop(context),
                  onConfirm: _submitInvoice,
                  cancelText: "Hủy bỏ",
                  confirmText: "Lập hóa đơn",
                  isSubmitting: isLoading,
                ),
            ],
          ),
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
}
