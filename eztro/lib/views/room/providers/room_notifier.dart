import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/room_model.dart';
import '../../../services/room_service.dart';
import '../../auth/providers/auth_provider.dart';

part 'room_notifier.g.dart';

@riverpod
class RoomNotifier extends _$RoomNotifier {
  @override
  Future<List<RoomModel>> build({int houseId = 0}) async {
    final user = ref.watch(authProvider);
    return await RoomService.getRooms(
      houseId: houseId,
      userId: user?.id,
      role: user?.role,
      managedHouseId: user?.managedHouseId,
    );
  }

  Future<void> refresh({int houseId = 0}) async {
    ref.invalidateSelf();
    await future;
  }

  Future<Map<String, dynamic>> deleteRoom(int roomId, {int houseId = 0}) async {
    final result = await RoomService.deleteRoom(roomId: roomId);
    if (result['status'] == 'success') {
      refresh(houseId: houseId);
    }
    return result;
  }
}

final roomDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, arg) async {
  final parts = arg.split('_');
  final roomId = int.parse(parts[0]);

  return await RoomService.getRoomDetail(roomId: roomId);
});
