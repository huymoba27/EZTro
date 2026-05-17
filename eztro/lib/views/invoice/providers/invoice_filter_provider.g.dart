// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredInvoicesHash() => r'f4500b355155818b1ab9268138aeef268cb7d56e';

/// See also [filteredInvoices].
@ProviderFor(filteredInvoices)
final filteredInvoicesProvider =
    AutoDisposeProvider<AsyncValue<List<InvoiceModel>>>.internal(
      filteredInvoices,
      name: r'filteredInvoicesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$filteredInvoicesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredInvoicesRef =
    AutoDisposeProviderRef<AsyncValue<List<InvoiceModel>>>;
String _$invoiceFilterNotifierHash() =>
    r'3a3eba18ec8569b32067246bb183501d504b7c45';

/// See also [InvoiceFilterNotifier].
@ProviderFor(InvoiceFilterNotifier)
final invoiceFilterNotifierProvider =
    AutoDisposeNotifierProvider<
      InvoiceFilterNotifier,
      Map<String, dynamic>
    >.internal(
      InvoiceFilterNotifier.new,
      name: r'invoiceFilterNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$invoiceFilterNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$InvoiceFilterNotifier = AutoDisposeNotifier<Map<String, dynamic>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
