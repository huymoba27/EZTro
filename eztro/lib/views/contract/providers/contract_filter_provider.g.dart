// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredContractsHash() => r'fc8651dbe41dd53d90bfa47e9113d9c0ebfe9921';

/// See also [filteredContracts].
@ProviderFor(filteredContracts)
final filteredContractsProvider =
    AutoDisposeProvider<AsyncValue<List<ContractModel>>>.internal(
      filteredContracts,
      name: r'filteredContractsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$filteredContractsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredContractsRef =
    AutoDisposeProviderRef<AsyncValue<List<ContractModel>>>;
String _$contractFilterNotifierHash() =>
    r'd30ce306a8a5853be770421500f4e7f9dc6827f2';

/// See also [ContractFilterNotifier].
@ProviderFor(ContractFilterNotifier)
final contractFilterNotifierProvider =
    AutoDisposeNotifierProvider<
      ContractFilterNotifier,
      Map<String, dynamic>
    >.internal(
      ContractFilterNotifier.new,
      name: r'contractFilterNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$contractFilterNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ContractFilterNotifier = AutoDisposeNotifier<Map<String, dynamic>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
