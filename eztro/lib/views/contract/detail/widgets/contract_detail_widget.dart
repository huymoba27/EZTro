import 'package:flutter/material.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/contract_model.dart';
import 'package:eztro/core/widgets/widgets.dart';

class ContractDetailWidget extends StatelessWidget {
  final ContractModel contract;
  final VoidCallback? onUpdate; 

  const ContractDetailWidget({
    super.key, 
    required this.contract, 
    this.onUpdate
  });

  @override
  Widget build(BuildContext context) {
    final services = contract.services ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // KHỐI 1: THÔNG TIN CHUNG
          AppSectionCard(
            title: "THÔNG TIN CHUNG",
            child: Column(
              children: [
                DetailRowWidget(
                  icon: Icons.meeting_room_outlined,
                  label: "Phòng thuê",
                  value: contract.roomName,
                ),
                const DetailDividerWidget(),
                DetailRowWidget(
                  icon: Icons.home_work_outlined,
                  label: "Nhà trọ",
                  value: contract.houseName ?? "N/A",
                ),
                const DetailDividerWidget(),
                DetailRowWidget(
                  icon: Icons.info_outline,
                  label: "Trạng thái",
                  value: "",
                  customValueWidget: Align(
                    alignment: Alignment.centerRight,
                    child: AppStatusBadge(status: contract.status),
                  ),
                ),
              ],
            ),
          ),
          _buildDivider(),

          // KHỐI 2: KHÁCH THUÊ ĐẠI DIỆN
          AppSectionCard(
            title: "KHÁCH THUÊ ĐẠI DIỆN",
            child: Column(
              children: [
                DetailRowWidget(
                  icon: Icons.person_outline,
                  label: "Họ tên",
                  value: contract.tenantName ?? "N/A",
                ),
                const DetailDividerWidget(),
                DetailRowWidget(
                  icon: Icons.phone_android_outlined,
                  label: "Số điện thoại",
                  value: contract.tenantPhone ?? "N/A",
                ),
                const DetailDividerWidget(),
                DetailRowWidget(
                  icon: Icons.badge_outlined,
                  label: "Số CCCD",
                  value: contract.idCard ?? "Chưa cập nhật",
                ),
                const DetailDividerWidget(),
                DetailRowWidget(
                  icon: Icons.location_on_outlined,
                  label: "Thường trú",
                  value: contract.address ?? "Chưa cập nhật",
                ),
              ],
            ),
          ),
          _buildDivider(),
          
          // KHỐI 3: ĐIỀU KHOẢN HỢP ĐỒNG
          AppSectionCard(
            title: "ĐIỀU KHOẢN HỢP ĐỒNG",
            child: Column(
              children: [
                DetailRowWidget(
                  icon: Icons.calendar_today_outlined,
                  label: "Ngày vào ở",
                  value: contract.startDate,
                ),
                const DetailDividerWidget(),
                DetailRowWidget(
                  icon: Icons.event_available_outlined,
                  label: "Ngày hết hạn",
                  value: contract.endDate,
                ),
                const DetailDividerWidget(),
                DetailRowWidget(
                  icon: Icons.monetization_on_outlined,
                  label: "Tiền thuê",
                  value: CurrencyHelper.formatVND(contract.rentPrice),
                  customValueWidget: Text(
                    CurrencyHelper.formatVND(contract.rentPrice),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const DetailDividerWidget(),
                DetailRowWidget(
                  icon: Icons.payments_outlined,
                  label: "Tiền cọc",
                  value: CurrencyHelper.formatVND(contract.depositAmount),
                ),
                const DetailDividerWidget(),
                DetailRowWidget(
                  icon: Icons.today_outlined,
                  label: "Ngày thu tiền",
                  value: "Ngày ${contract.paymentDay} hàng tháng",
                ),
              ],
            ),
          ),
          _buildDivider(),

          // KHỐI 4: DỊCH VỤ & CHỈ SỐ
          AppSectionCard(
            title: "DỊCH VỤ & CHỈ SỐ",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailRowWidget(
                  icon: Icons.bolt,
                  label: "Điện đầu kỳ",
                  value: "${contract.startElectric} kWh",
                ),
                const DetailDividerWidget(),
                DetailRowWidget(
                  icon: Icons.water_drop_outlined,
                  label: "Nước đầu kỳ",
                  value: "${contract.startWater} m³",
                ),
                if (services.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 8),
                    child: Text(
                      "Dịch vụ đăng ký:", 
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey)
                    ),
                  ),
                  for (int i = 0; i < services.length; i++) ...[
                    DetailRowWidget(
                      icon: Icons.check_circle_outline,
                      label: services[i].serviceName,
                      value: "${CurrencyHelper.formatVND(services[i].price)}/${services[i].unit}",
                    ),
                    if (i < services.length - 1) const DetailDividerWidget(),
                  ],
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const SizedBox(height: 8);
  }
}
