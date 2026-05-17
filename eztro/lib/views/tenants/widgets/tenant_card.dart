import 'package:flutter/material.dart';
import '../../../models/tenant_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_helper.dart';
import 'package:eztro/core/widgets/widgets.dart';

class TenantCard extends StatelessWidget {
  final TenantModel tenant;
  final VoidCallback onTap;

  const TenantCard({super.key, required this.tenant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String initials = "U";
    if (tenant.tenantName.trim().isNotEmpty) {
      List<String> nameParts = tenant.tenantName.trim().split(' ');
      initials = nameParts.last[0].toUpperCase();
    }

    String roomDisplay = tenant.roomName ?? "Chưa có phòng";

    return Column(
      children: [
        Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar Circle
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: tenant.isLead
                          ? Colors.orange.withAlpha(26)
                          : AppColors.primary.withAlpha(26),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: tenant.isLead
                            ? Colors.orange.withAlpha(51)
                            : AppColors.primary.withAlpha(51),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: tenant.isLead
                              ? Colors.orange.shade800
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                StringHelper.capitalizeEachWord(
                                  tenant.tenantName,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Color(0xFF263238),
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        CardInfoRow(
                          icon: Icons.phone_android_outlined,
                          text: tenant.phone ?? "Không có số",
                        ),
                        const SizedBox(height: 6),
                        CardInfoRow(
                          icon: Icons.home_outlined,
                          text:
                              "${tenant.houseName ?? 'Chưa rõ nhà'} - $roomDisplay",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    bool isInactive = tenant.status == 'inactive';
    if (!isInactive) return _buildRoleBadge(tenant.isLead);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(26),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        "ĐÃ CHUYỂN",
        style: TextStyle(
          color: Colors.red,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(bool isLead) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLead
            ? Colors.orange.shade700.withAlpha(26)
            : AppColors.primary.withAlpha(26),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isLead ? "CHỦ HỘ" : "THÀNH VIÊN",
        style: TextStyle(
          color: isLead ? const Color(0xFFD84315) : AppColors.primary,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
