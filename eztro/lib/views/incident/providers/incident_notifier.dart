import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../models/incident_model.dart';
import '../../../services/incident_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';

part 'incident_notifier.g.dart';

@riverpod
class IncidentNotifier extends _$IncidentNotifier {
  @override
  Future<List<IncidentModel>> build() async {
    return _fetchData();
  }

  Future<List<IncidentModel>> _fetchData() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return [];

    return await IncidentService.getAllIncidents(
      userId: user.id,
      role: user.role,
    );
  }

  // làm mới dữ liệu
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData());
  }

  // Cập nhật trạng thái sự cố
  Future<Map<String, dynamic>> updateStatus({
    required IncidentModel incident,
    required String status,
    double? repairCost,
  }) async {
    final user = await AuthService.getCurrentUser();
    final res = await IncidentService.updateIncidentStatus(
      incidentId: incident.id!,
      status: status,
      repairCost: repairCost,
      managerId: user?.id,
    );

    if (res['status'] == 'success') {
      // Thông báo cho khách thuê về sự thay đổi trạng thái
      NotificationService.pushNotification(
        userId: incident.tenantId,
        title: "Cập nhật trạng thái sự cố",
        description: "Sự cố '${incident.title}' của bạn đã được chuyển sang trạng thái: ${status == 'processing' ? 'Đang xử lý' : 'Đã hoàn thành'}.",
        type: "incident",
        metadata: {"incident_id": incident.id},
      );
      await refresh();
    }
    return res;
  }

  // Xóa sự cố
  Future<Map<String, dynamic>> deleteIncident(int incidentId) async {
    final res = await IncidentService.deleteIncident(incidentId);
    if (res['status'] == 'success') {
      await refresh();
    }
    return res;
  }
}
