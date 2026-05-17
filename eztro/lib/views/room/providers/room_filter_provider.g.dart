// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredRoomsHash() => r'41d38d3202409ec83c6d93894e2d57fa7909cc08';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [filteredRooms].
@ProviderFor(filteredRooms)
const filteredRoomsProvider = FilteredRoomsFamily();

/// See also [filteredRooms].
class FilteredRoomsFamily extends Family<List<RoomModel>> {
  /// See also [filteredRooms].
  const FilteredRoomsFamily();

  /// See also [filteredRooms].
  FilteredRoomsProvider call({int houseId = 0}) {
    return FilteredRoomsProvider(houseId: houseId);
  }

  @override
  FilteredRoomsProvider getProviderOverride(
    covariant FilteredRoomsProvider provider,
  ) {
    return call(houseId: provider.houseId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'filteredRoomsProvider';
}

/// See also [filteredRooms].
class FilteredRoomsProvider extends AutoDisposeProvider<List<RoomModel>> {
  /// See also [filteredRooms].
  FilteredRoomsProvider({int houseId = 0})
    : this._internal(
        (ref) => filteredRooms(ref as FilteredRoomsRef, houseId: houseId),
        from: filteredRoomsProvider,
        name: r'filteredRoomsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$filteredRoomsHash,
        dependencies: FilteredRoomsFamily._dependencies,
        allTransitiveDependencies:
            FilteredRoomsFamily._allTransitiveDependencies,
        houseId: houseId,
      );

  FilteredRoomsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.houseId,
  }) : super.internal();

  final int houseId;

  @override
  Override overrideWith(
    List<RoomModel> Function(FilteredRoomsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FilteredRoomsProvider._internal(
        (ref) => create(ref as FilteredRoomsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        houseId: houseId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<RoomModel>> createElement() {
    return _FilteredRoomsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredRoomsProvider && other.houseId == houseId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, houseId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FilteredRoomsRef on AutoDisposeProviderRef<List<RoomModel>> {
  /// The parameter `houseId` of this provider.
  int get houseId;
}

class _FilteredRoomsProviderElement
    extends AutoDisposeProviderElement<List<RoomModel>>
    with FilteredRoomsRef {
  _FilteredRoomsProviderElement(super.provider);

  @override
  int get houseId => (origin as FilteredRoomsProvider).houseId;
}

String _$roomFilterNotifierHash() =>
    r'da8e8af752b3e68bf1d00b85ae3f075e439382e1';

/// See also [RoomFilterNotifier].
@ProviderFor(RoomFilterNotifier)
final roomFilterNotifierProvider =
    AutoDisposeNotifierProvider<RoomFilterNotifier, RoomFilter>.internal(
      RoomFilterNotifier.new,
      name: r'roomFilterNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$roomFilterNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RoomFilterNotifier = AutoDisposeNotifier<RoomFilter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
