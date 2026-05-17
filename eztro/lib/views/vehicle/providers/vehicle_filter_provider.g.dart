// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredVehiclesHash() => r'098b74e3b48a68ba990ea7da14fe6a5e8ed1386a';

/// See also [filteredVehicles].
@ProviderFor(filteredVehicles)
final filteredVehiclesProvider =
    AutoDisposeProvider<AsyncValue<List<VehicleModel>>>.internal(
      filteredVehicles,
      name: r'filteredVehiclesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$filteredVehiclesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredVehiclesRef =
    AutoDisposeProviderRef<AsyncValue<List<VehicleModel>>>;
String _$vehicleFilterNotifierHash() =>
    r'03d677eea93e1d708b3c00691b22e75e28f3ef9a';

/// See also [VehicleFilterNotifier].
@ProviderFor(VehicleFilterNotifier)
final vehicleFilterNotifierProvider =
    AutoDisposeNotifierProvider<VehicleFilterNotifier, VehicleFilter>.internal(
      VehicleFilterNotifier.new,
      name: r'vehicleFilterNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$vehicleFilterNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$VehicleFilterNotifier = AutoDisposeNotifier<VehicleFilter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
