import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MeterListBody extends StatelessWidget {
  final List<dynamic> filteredList;
  final Function(dynamic) onTapRoom;
  final Color themeGreen;
  final int month;
  final int year;

  const MeterListBody({
    super.key,
    required this.filteredList,
    required this.onTapRoom,
    required this.month,
    required this.year,
    this.themeGreen = const Color(0xFF2E7D32),
  });

  @override
  Widget build(BuildContext context) {
    if (filteredList.isEmpty) return _buildEmptyState();

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: filteredList.length,
      separatorBuilder: (context, index) =>
          Container(height: 8, color: const Color(0xFFF2F2F7)),
      itemBuilder: (context, index) => _buildFlatRoomRow(filteredList[index]),
    );
  }

  Widget _buildFlatRoomRow(dynamic room) {
    int nE = int.tryParse(room['new_electric']?.toString() ?? '0') ?? 0;
    int oE = int.tryParse(room['old_electric']?.toString() ?? '0') ?? 0;
    int nW = int.tryParse(room['new_water']?.toString() ?? '0') ?? 0;
    int oW = int.tryParse(room['old_water']?.toString() ?? '0') ?? 0;

    bool isRecorded = room['date_done'] != null;
    String statusText = isRecorded ? "Đã chốt" : "Chưa chốt";
    Color statusColor = isRecorded ? const Color(0xFF2E7D32) : Colors.grey;
    Color statusBgColor = isRecorded
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFF5F5F5);

    // Giả lập giá tiền
    double electricPrice = 3500;
    double waterPrice = 15000;
    int eUsage = nE - oE;
    int wUsage = nW - oW;

    final formatter = NumberFormat("#,###", "vi_VN");

    return InkWell(
      onTap: () => onTapRoom(room),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            // --- HEADER ROW ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dòng 1: Tên phòng (Trái) & Kỳ chốt (Phải) - cùng chân chữ
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Phòng ${room['room_name'] ?? "N/A"}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Color(0xFF263238),
                            ),
                          ),
                          Text(
                            "Kỳ chốt: 01/$_monthStr → 31/$_monthStr",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Dòng 2: Trạng thái (Trái) & Ngày chốt (Phải) - ngang hàng
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusText.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            "Chốt ngày: ${isRecorded ? room['date_done'].toString().split(' ')[0] : '---'}",
                            style: TextStyle(
                              fontSize: 10,
                              color: isRecorded
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- BODY (2 COLUMNS) ---
            IntrinsicHeight(
              child: Row(
                children: [
                  // Electric Column
                  Expanded(
                    child: _meterCol(
                      icon: Icons.bolt_outlined,
                      label: "Điện",
                      oldVal: "$oE",
                      newVal: isRecorded ? "$nE" : "-",
                      usage: isRecorded ? "$eUsage kWh" : "- kWh",
                      cost: isRecorded
                          ? "${formatter.format(eUsage * electricPrice)} đ"
                          : "- đ",
                      color: Colors.orange,
                    ),
                  ),

                  const SizedBox(width: 32),

                  // Water Column
                  Expanded(
                    child: _meterCol(
                      icon: Icons.water_drop_outlined,
                      label: "Nước",
                      oldVal: "$oW",
                      newVal: isRecorded ? "$nW" : "-",
                      usage: isRecorded ? "$wUsage m³" : "- m³",
                      cost: isRecorded
                          ? "${formatter.format(wUsage * waterPrice)} đ"
                          : "- đ",
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _monthStr => "${month.toString().padLeft(2, '0')}/$year";

  Widget _meterCol({
    required IconData icon,
    required String label,
    required String oldVal,
    required String newVal,
    required String usage,
    required String cost,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _detailRow("Chỉ số cũ", oldVal),
        const SizedBox(height: 8),
        _detailRow("Chỉ số mới", newVal),
        const SizedBox(height: 8),
        _detailRow("Tiêu thụ", usage, valueWeight: FontWeight.bold),
        const SizedBox(height: 8),
        _detailRow(
          "Thành tiền",
          cost,
          valueColor: const Color(0xFF2E7D32),
          valueWeight: FontWeight.w900,
        ),
      ],
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
    FontWeight? valueWeight,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: valueColor ?? const Color(0xFF263238),
            fontWeight: valueWeight ?? FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 50,
            color: Colors.black12,
          ),
          SizedBox(height: 12),
          Text(
            "Chưa có dữ liệu chốt số",
            style: TextStyle(color: Colors.black26, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
