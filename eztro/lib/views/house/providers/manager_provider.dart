import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../services/auth_service.dart';

part 'manager_provider.g.dart';

@riverpod
Future<List<String>> allManagers(Ref ref) async {
  final data = await AuthService.getManagersAndLandlords();
  return data
      .map((e) => e['full_name']?.toString() ?? '')
      .where((name) => name.isNotEmpty)
      .toSet()
      .toList();
}
