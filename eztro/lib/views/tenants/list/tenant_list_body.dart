import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../detail/tenant_detail_screen.dart';
import '../../house/list/widgets/house_list_skeleton.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../models/tenant_model.dart';
import '../widgets/tenant_card.dart';
import '../providers/tenant_notifier.dart';

class TenantListBody extends ConsumerWidget {
  final List<TenantModel> tenants;
  final bool isLoading;
  final VoidCallback? onRefresh; 

  const TenantListBody({
    super.key, 
    required this.tenants, 
    this.isLoading = false,
    this.onRefresh, 
  });

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.people_outline_rounded,
      title: "Chưa có khách thuê nào",
      subtitle: "Dữ liệu khách thuê sẽ hiển thị tại đây",
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return const HouseListSkeleton();
    }

    if (tenants.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: tenants.length,
      separatorBuilder: (context, index) => Container(
        height: 8,
        color: const Color(0xFFF2F2F7),
      ),
      itemBuilder: (context, index) {
        final tenant = tenants[index];
        return TenantCard(
          tenant: tenant,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TenantDetailScreen(tenant: tenant),
              ),
            );
            if (result == true) {
              ref.read(tenantNotifierProvider.notifier).refresh();
            }
          },
        );
      },
    );
  }
}