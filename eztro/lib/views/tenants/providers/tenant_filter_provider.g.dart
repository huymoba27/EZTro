// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredTenantsHash() => r'40129697b27127a9e79bd535abfd105c58ad4440';

/// See also [filteredTenants].
@ProviderFor(filteredTenants)
final filteredTenantsProvider = AutoDisposeProvider<List<TenantModel>>.internal(
  filteredTenants,
  name: r'filteredTenantsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredTenantsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredTenantsRef = AutoDisposeProviderRef<List<TenantModel>>;
String _$tenantFilterNotifierHash() =>
    r'aa3750eb505ab10a6e67452f6439208de7b06739';

/// See also [TenantFilterNotifier].
@ProviderFor(TenantFilterNotifier)
final tenantFilterNotifierProvider =
    AutoDisposeNotifierProvider<TenantFilterNotifier, TenantFilter>.internal(
      TenantFilterNotifier.new,
      name: r'tenantFilterNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$tenantFilterNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TenantFilterNotifier = AutoDisposeNotifier<TenantFilter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
