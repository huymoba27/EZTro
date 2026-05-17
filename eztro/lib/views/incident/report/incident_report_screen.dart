import 'package:flutter/material.dart';
import '../../../models/incident_model.dart';
import '../../../services/incident_service.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/test_tools/demo_data.dart';
import '../../../core/test_tools/dev_autofill_button.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../services/notification_service.dart';
import '../widgets/incident_card.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  late Future<List<IncidentModel>> _incidentsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshIncidents();
  }

  void _refreshIncidents() {
    setState(() {
      _incidentsFuture = _initIncidents();
    });
  }

  Future<List<IncidentModel>> _initIncidents() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return [];
    return IncidentService.getMyIncidents(userId: user.id, role: user.role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "DANH SÁCH SỰ CỐ",
        showBackButton: true,
        onBack: () => Navigator.pop(context),
      ),
      body: FutureBuilder<List<IncidentModel>>(
        future: _incidentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final incidents = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: () async => _refreshIncidents(),
            color: AppColors.primary,
            child: incidents.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: const EmptyStateWidget(
                        icon: Icons.report_problem_outlined,
                        title: "Không có sự cố nào",
                        subtitle: "Các sự cố bạn báo cáo sẽ hiển thị tại đây",
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: incidents.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                    itemBuilder: (context, index) {
                      return IncidentCard(incident: incidents[index]);
                    },
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReportForm(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  void _showReportForm() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    void fillDemoData() {
      titleController.text = DemoData.incident.title;
      descController.text = DemoData.incident.description;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              DevAutofillButton(onPressed: fillDemoData),
              const Text(
                "BÁO CÁO SỰ CỐ MỚI",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: titleController,
                label: "Tiêu đề sự cố *",
                hint: "Ví dụ: Hỏng vòi nước, Cháy bóng đèn...",
              ),
              CustomTextField(
                controller: descController,
                label: "Mô tả chi tiết *",
                hint: "Mô tả tình trạng sự cố để chủ trọ nắm rõ...",
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (titleController.text.isEmpty ||
                              descController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Vui lòng nhập đầy đủ thông tin"),
                              ),
                            );
                            return;
                          }

                          setModalState(() => _isLoading = true);

                          final user = await AuthService.getCurrentUser();
                          if (user == null) return;

                          final result = await IncidentService.reportIncident(
                            tenantId: user.id,
                            roomId: user.roomId ?? 0,
                            title: titleController.text,
                            description: descController.text,
                          );

                          if (mounted && context.mounted) {
                            setModalState(() => _isLoading = false);
                            Navigator.pop(context);
                            if (result['status'] == 'success') {
                              // Thông báo cho khách thuê
                              NotificationService.pushNotification(
                                userId: user.id,
                                title: "Báo cáo sự cố mới",
                                description:
                                    "Bạn đã gửi báo cáo: ${titleController.text}. Chủ trọ sẽ sớm phản hồi.",
                                type: "incident",
                                metadata: {
                                  "incident_id": result['data']?['id'],
                                },
                              );

                              // Thông báo cho đúng chủ trọ của phòng
                              final landlordId = int.tryParse(
                                result['data']?['landlord_id']?.toString() ??
                                    '0',
                              );
                              if (landlordId != null && landlordId > 0) {
                                NotificationService.pushNotification(
                                  userId: landlordId,
                                  title: "Yêu cầu xử lý sự cố",
                                  description:
                                      "${user.fullName} (Phòng ID: ${user.roomId}) vừa báo cáo sự cố: ${titleController.text}",
                                  type: "incident",
                                  metadata: {
                                    "incident_id": result['data']?['id'],
                                  },
                                );
                              }

                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Gửi báo cáo sự cố thành công!",
                                  ),
                                ),
                              );
                              _refreshIncidents();
                            } else {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text("Lỗi: ${result['message']}"),
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "GỬI BÁO CÁO NGAY",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
