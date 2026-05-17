import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/invoice_model.dart';
import 'invoice_notifier.dart';

part 'invoice_filter_provider.g.dart';

@riverpod
class InvoiceFilterNotifier extends _$InvoiceFilterNotifier {
  @override
  Map<String, dynamic> build() {
    final now = DateTime.now();
    return {
      'houseId': 0,
      'month': now.month,
      'year': now.year,
      'query': '',
      'status': 'all', // all, pending, paid
    };
  }

  void updateHouse(int houseId) {
    state = {...state, 'houseId': houseId};
  }

  void updateMonth(int month) {
    state = {...state, 'month': month};
  }

  void updateYear(int year) {
    state = {...state, 'year': year};
  }

  void updateQuery(String query) {
    state = {...state, 'query': query};
  }

  void updateStatus(String status) {
    state = {...state, 'status': status};
  }
}

@riverpod
AsyncValue<List<InvoiceModel>> filteredInvoices(FilteredInvoicesRef ref) {
  final invoicesAsync = ref.watch(invoiceNotifierProvider);
  final filter = ref.watch(invoiceFilterNotifierProvider);

  return invoicesAsync.whenData((invoices) {
    return invoices.where((i) {
      final matchesMonth =
          filter['month'] == 0 || i.billingMonth == filter['month'];
      final matchesYear =
          filter['year'] == 0 || i.billingYear == filter['year'];
      final matchesHouse =
          filter['houseId'] == 0 || i.houseId == filter['houseId'];
      final matchesStatus =
          filter['status'] == 'all' || i.status == filter['status'];

      final room = i.roomName.toLowerCase();
      final house = (i.houseName ?? "").toLowerCase();
      final query = filter['query'].toLowerCase();
      final matchesQuery =
          query.isEmpty || room.contains(query) || house.contains(query);

      return matchesMonth &&
          matchesYear &&
          matchesHouse &&
          matchesStatus &&
          matchesQuery;
    }).toList();
  });
}
