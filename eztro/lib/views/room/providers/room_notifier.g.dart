// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$roomNotifierHash() => r'69418d92c0ed2e07cdbaf3cf8cff63cfa9162cbc';

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

abstract class _$RoomNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<RoomModel>> {
  late final int houseId;

  FutureOr<List<RoomModel>> build({int houseId = 0});
}

/// See also [RoomNotifier].
@ProviderFor(RoomNotifier)
const roomNotifierProvider = RoomNotifierFamily();

/// See also [RoomNotifier].
class RoomNotifierFamily extends Family<AsyncValue<List<RoomModel>>> {
  /// See also [RoomNotifier].
  const RoomNotifierFamily();

  /// See also [RoomNotifier].
  RoomNotifierProvider call({int houseId = 0}) {
    return RoomNotifierProvider(houseId: houseId);
  }

  @override
  RoomNotifierProvider getProviderOverride(
    covariant RoomNotifierProvider provider,
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
  String? get name => r'roomNotifierProvider';
}

/// See also [RoomNotifier].
class RoomNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<RoomNotifier, List<RoomModel>> {
  /// See also [RoomNotifier].
  RoomNotifierProvider({int houseId = 0})
    : this._internal(
        () => RoomNotifier()..houseId = houseId,
        from: roomNotifierProvider,
        name: r'roomNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$roomNotifierHash,
        dependencies: RoomNotifierFamily._dependencies,
        allTransitiveDependencies:
            RoomNotifierFamily._allTransitiveDependencies,
        houseId: houseId,
      );

  RoomNotifierProvider._internal(
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
  FutureOr<List<RoomModel>> runNotifierBuild(covariant RoomNotifier notifier) {
    return notifier.build(houseId: houseId);
  }

  @override
  Override overrideWith(RoomNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: RoomNotifierProvider._internal(
        () => create()..houseId = houseId,
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
  AutoDisposeAsyncNotifierProviderElement<RoomNotifier, List<RoomModel>>
  createElement() {
    return _RoomNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RoomNotifierProvider && other.houseId == houseId;
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
mixin RoomNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<RoomModel>> {
  /// The parameter `houseId` of this provider.
  int get houseId;
}

class _RoomNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<RoomNotifier, List<RoomModel>>
    with RoomNotifierRef {
  _RoomNotifierProviderElement(super.provider);

  @override
  int get houseId => (origin as RoomNotifierProvider).houseId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
