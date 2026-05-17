import 'package:flutter/material.dart';
import '../../../../models/contract_model.dart';
import 'package:eztro/core/widgets/widgets.dart';

class ContractCard extends StatelessWidget {
  final ContractModel contract;
  final VoidCallback onTap;

  const ContractCard({super.key, required this.contract, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Text(
                            "Phòng ${contract.roomName}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF263238),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 32),
                        const Expanded(
                          flex: 4,
                          child: Text(
                            "Bắt đầu:",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- CỘT TRÁI ---
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppStatusBadge(status: contract.status),
                                const SizedBox(height: 8),
                                CardInfoRow(
                                  icon: Icons.person_outline,
                                  text: contract.tenantName ?? "Trống",
                                  textColor: Colors.black,
                                ),
                                const SizedBox(height: 8),
                                CardInfoRow(
                                  icon: Icons.home_outlined,
                                  text: contract.houseName ?? "N/A",
                                ),
                                const SizedBox(height: 8),
                                CardInfoRow(
                                  icon: Icons.monetization_on_outlined,
                                  text:
                                      "${_formatCurrency(contract.rentPrice)} / tháng",
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          // --- CỘT PHẢI ---
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  contract.startDate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const Spacer(), // Đẩy phần bên dưới xuống đáy để bằng với dòng Giá
                                _dateRow("Kết thúc:", contract.endDate),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateRow(String label, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(
          height: 6,
        ), // Đã chỉnh lên 6 cho bằng với khoảng cách của Bắt đầu
        Text(
          date,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return "${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ";
  }
}
