import 'package:eztro/core/widgets/display/empty_state_widget.dart';
import 'package:eztro/core/widgets/layout/app_list_separator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/house_service.dart';
import '../../../models/house_model.dart';
import '../../../models/invoice_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/layout/custom_app_bar.dart';
import '../../../core/widgets/inputs/app_filters.dart';
import '../providers/invoice_notifier.dart';
import '../providers/invoice_filter_provider.dart';
import 'widgets/invoice_card.dart';
import 'package:eztro/views/invoice/create/create_invoice_screen.dart';
import 'package:eztro/views/invoice/detail/invoice_detail_screen.dart';
import 'package:eztro/views/house/list/widgets/house_list_skeleton.dart';
import 'package:eztro/views/auth/providers/auth_provider.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const InvoiceListScreen({super.key, this.onBack});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  List<HouseModel> houses = [];
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final houseData = await HouseService.getHouses();
    if (mounted) {
      setState(() {
        houses = houseData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final bool isTenant = user?.role == 'tenant';
    final bool isLandlord = user?.role == 'landlord';

    final invoicesAsync = ref.watch(filteredInvoicesProvider);
    final filter = ref.watch(invoiceFilterNotifierProvider);
    final currentHouse = houses.firstWhere(
      (h) => h.id == filter['houseId'],
      orElse: () => HouseModel(
        id: 0,
        houseName: "Tất cả nhà",
        image: "",
        status: "",
        city: "",
        ward: "",
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: isTenant ? "HÓA ĐƠN CỦA TÔI" : "QUẢN LÝ HÓA ĐƠN",
        showBackButton: true,
        onBack: widget.onBack,
        isSearching: isSearching,
        searchController: searchController,
        onSearchChanged: (v) =>
            ref.read(invoiceFilterNotifierProvider.notifier).updateQuery(v),
        onSearchToggle: () => setState(() {
          isSearching = !isSearching;
          if (!isSearching) {
            searchController.clear();
            ref.read(invoiceFilterNotifierProvider.notifier).updateQuery("");
          }
        }),
      ),
      floatingActionButton: isTenant
          ? null
          : FloatingActionButton(
              onPressed: () async {
                bool? refresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateInvoiceScreen(
                      initialMonth: filter['month'] != 0
                          ? filter['month']
                          : null,
                      initialYear: filter['year'],
                    ),
                  ),
                );
                if (refresh == true) {
                  ref.read(invoiceNotifierProvider.notifier).refresh();
                }
              },
              backgroundColor: AppColors.primary,
              elevation: 4,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLandlord)
            AppFilterBar(
              selectedPillValue: filter['status'],
              onPillSelected: (val) => ref
                  .read(invoiceFilterNotifierProvider.notifier)
                  .updateStatus(val),
              pillItems: [
                FilterPillItem(
                  label: "Tất cả",
                  icon: Icons.grid_view_outlined,
                  color: Colors.blue,
                  value: "all",
                ),
                FilterPillItem(
                  label: "Chưa thu",
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                  value: "pending",
                ),
                FilterPillItem(
                  label: "Đã thu",
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  value: "paid",
                ),
                FilterPillItem(
                  label: "Thất thu",
                  icon: Icons.money_off,
                  color: const Color(0xFF880E4F),
                  value: "bad_debt",
                ),
              ],
              isEqualWidth: true,
              dropdownItems: [
                CommonFilters.houseFilter(
                  context: context,
                  houses: houses,
                  currentHouseId: filter['houseId'],
                  currentHouseName: currentHouse.houseName,
                  showAllOption: true,
                  onChanged: (id, name) {
                    ref
                        .read(invoiceFilterNotifierProvider.notifier)
                        .updateHouse(id);
                  },
                ),
                CommonFilters.monthYearFilter(
                  context: context,
                  selectedMonth: filter['month'] == 0
                      ? DateTime.now().month
                      : filter['month'],
                  selectedYear: filter['year'],
                  onChanged: (month, year) {
                    ref
                        .read(invoiceFilterNotifierProvider.notifier)
                        .updateMonth(month);
                    ref
                        .read(invoiceFilterNotifierProvider.notifier)
                        .updateYear(year);
                  },
                ),
              ],
            ),
          Expanded(
            child: invoicesAsync.when(
              data: (invoices) => RefreshIndicator(
                onRefresh: () =>
                    ref.read(invoiceNotifierProvider.notifier).refresh(),
                color: AppColors.primary,
                child: Container(
                  color: Colors.white,
                  child: invoices.isEmpty
                      ? _buildEmptyState()
                      : _buildListContent(invoices),
                ),
              ),
              loading: () => const HouseListSkeleton(),
              error: (err, stack) => Center(child: Text("Lỗi: $err")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: "Không có hóa đơn nào",
              subtitle: "Dữ liệu hóa đơn sẽ hiển thị tại đây",
            ),
          ),
        );
      },
    );
  }

  Widget _buildListContent(List<InvoiceModel> invoices) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: invoices.length,
      separatorBuilder: (context, index) => const AppListSeparator(),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return InvoiceCard(
          invoice: invoice,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InvoiceDetailScreen(invoice: invoice),
              ),
            );
            if (result == true) {
              ref.read(invoiceNotifierProvider.notifier).refresh();
            }
          },
        );
      },
    );
  }
}
