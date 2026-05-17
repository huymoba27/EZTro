import 'package:flutter/material.dart';
import '../../../../models/invoice_model.dart';
import '../../../../core/utils/format_helper.dart';
import 'package:eztro/core/widgets/widgets.dart';

class InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onTap;

  const InvoiceCard({super.key, required this.invoice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    double roomAmount = 0;
    double electricAmount = 0;
    double waterAmount = 0;
    double otherAmount = 0;

    for (var detail in invoice.details) {
      final name = detail.name.toLowerCase();
      if (name.contains('điện')) {
        electricAmount += detail.subtotal;
      } else if (name.contains('nước')) {
        waterAmount += detail.subtotal;
      } else if (name == 'tiền phòng' || name.startsWith('tiền phòng')) {
        roomAmount += detail.subtotal;
      } else if (name.contains('phòng')) {
        // "Tiền thuê phòng" hoặc các dòng khác chứa "phòng" nhưng không phải là "Tiền phòng"
        otherAmount += detail.subtotal;
      } else {
        otherAmount += detail.subtotal;
      }
    }

    if (roomAmount == 0) roomAmount = invoice.roomAmount;
    final periodText = invoice.billingMonth > 0 && invoice.billingYear > 0
        ? "Tháng ${invoice.billingMonth}/${invoice.billingYear}"
        : "--";

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            // --- HEADER SECTION ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          "Phòng ${invoice.roomName}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xFF263238),
                          ),
                        ),
                      ),
                      const Text(
                        "Kỳ hóa đơn",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppStatusBadge(status: invoice.status),
                      Text(
                        periodText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // --- DETAILS SECTION ---
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- LEFT: Fees ---
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CardKeyValueRow(
                            icon: Icons.home_outlined,
                            label: "Tiền phòng",
                            value: CurrencyHelper.formatVND(roomAmount),
                            iconColor: Colors.blueGrey,
                          ),
                          CardKeyValueRow(
                            icon: Icons.bolt_outlined,
                            label: "Tiền điện",
                            value: CurrencyHelper.formatVND(electricAmount),
                            iconColor: Colors.orange,
                          ),
                          CardKeyValueRow(
                            icon: Icons.water_drop_outlined,
                            label: "Tiền nước",
                            value: CurrencyHelper.formatVND(waterAmount),
                            iconColor: Colors.blue,
                          ),
                          CardKeyValueRow(
                            icon: Icons.more_horiz_outlined,
                            label: "Dịch vụ khác",
                            value: CurrencyHelper.formatVND(otherAmount),
                            iconColor: Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- RIGHT: Payment Info ---
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Tổng tiền",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.normal,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FittedBox(
                                child: Text(
                                  CurrencyHelper.formatVND(invoice.totalAmount),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD32F2F),
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}
