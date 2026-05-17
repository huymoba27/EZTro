// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'incident_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredIncidentsHash() => r'e8796f923782a51e480a9f653731284aea1c6744';

/// See also [filteredIncidents].
@ProviderFor(filteredIncidents)
final filteredIncidentsProvider =
    AutoDisposeProvider<AsyncValue<List<IncidentModel>>>.internal(
      filteredIncidents,
      name: r'filteredIncidentsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$filteredIncidentsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredIncidentsRef =
    AutoDisposeProviderRef<AsyncValue<List<IncidentModel>>>;
String _$incidentFilterNotifierHash() =>
    r'205a9c6a852a71a7e96c54dca7def0b4161990b5';

/// See also [IncidentFilterNotifier].
@ProviderFor(IncidentFilterNotifier)
final incidentFilterNotifierProvider =
    AutoDisposeNotifierProvider<
      IncidentFilterNotifier,
      IncidentFilterState
    >.internal(
      IncidentFilterNotifier.new,
      name: r'incidentFilterNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$incidentFilterNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$IncidentFilterNotifier = AutoDisposeNotifier<IncidentFilterState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
