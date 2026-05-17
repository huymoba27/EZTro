import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/utils/input_validation_helper.dart';
import '../../../services/api_constants.dart';
import '../../../services/auth_service.dart';
import '../../house/list/widgets/house_list_skeleton.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../widgets/staff_card.dart';
import '../../../models/house_model.dart';
import '../../../services/house_service.dart';

class ManagerStaffListScreen extends StatefulWidget {
  const ManagerStaffListScreen({super.key});

  @override
  State<ManagerStaffListScreen> createState() => _ManagerStaffListScreenState();
}

class _ManagerStaffListScreenState extends State<ManagerStaffListScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  int? _selectedHouseId;
  HouseModel? _selectedHouse;
  List<HouseModel> _houses = [];
  List<dynamic> _allStaff = [];
  List<dynamic> _displayedStaff = [];

  bool _isLoading = false;
  bool _isFetchingStaff = true;
  bool isSearching = false;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isFetchingStaff = true);
    await _fetchHouses();
    await _fetchStaff();
    if (mounted) setState(() => _isFetchingStaff = false);
  }

  Future<void> _fetchHouses() async {
    try {
      final houses = await HouseService.getHouses();
      if (mounted) {
        setState(() {
          _houses = houses;
          if (_houses.isNotEmpty && _selectedHouseId == null) {
            _selectedHouseId = _houses[0].id;
            _selectedHouse = _houses[0];
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching houses: $e");
    }
  }

  Future<void> _fetchStaff() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) return;

      final response = await http.get(
        Uri.parse(
          "${ApiConstants.serverUrl}/backend_api/auth/get_staff_list.php?user_id=${user.id}",
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _allStaff = data['data'];
            _displayedStaff = List.from(_allStaff);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching staff: $e");
    }
  }

  void _applyFilter(String query) {
    setState(() {
      _displayedStaff = _allStaff
          .where(
            (s) =>
                s['full_name'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                s['phone'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                (s['house_name']?.toString().toLowerCase().contains(
                      query.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    });
  }

  Future<void> _createManager() async {
    if (_phoneController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _selectedHouseId == null) {
      DialogHelper.showWarning(
        context,
        'Vui lòng nhập đủ thông tin và chọn nhà trọ',
      );
      return;
    }
    final phoneError = InputValidationHelper.phoneError(_phoneController.text);
    if (phoneError != null) {
      DialogHelper.showWarning(context, phoneError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        throw Exception('Bạn cần đăng nhập để cấp quyền quản lý');
      }
      final response = await http.post(
        Uri.parse(
          "${ApiConstants.serverUrl}/backend_api/auth/create_manager.php",
        ),
        body: {
          'user_id': user.id.toString(),
          'phone': _phoneController.text,
          'full_name': _nameController.text,
          'managed_house_id': _selectedHouseId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        if (data['status'] == 'success') {
          _phoneController.clear();
          _nameController.clear();
          Navigator.pop(context);
          _refreshData();
          DialogHelper.showSuccess(
            context,
            data['message'] ?? 'Cấp quyền quản lý thành công',
          );
        } else {
          DialogHelper.showError(
            context,
            data['message'] ?? 'Không thể cấp quyền quản lý',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showError(context, 'Lỗi kết nối: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddStaffModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "THÊM NHÂN VIÊN MỚI",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Hệ thống sẽ tự động tạo tài khoản với Mật khẩu mặc định là Số điện thoại.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: "Tên nhân viên",
                hint: "Nhập tên nhân viên",
                controller: _nameController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: "Số điện thoại",
                hint: "Nhập số điện thoại",
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 11,
              ),
              const SizedBox(height: 16),
              CustomSelectField(
                label: "Nhà trọ quản lý",
                value: _selectedHouse?.houseName ?? "Chọn nhà trọ",
                onTap: () {
                  FocusScope.of(context).unfocus();

                  AppSelectModal.show<int>(
                    context: context,
                    title: "CHỌN NHÀ TRỌ",
                    subtitle: "Chọn nhà trọ để quản lý",
                    items: _houses
                        .map(
                          (h) => AppSelectItem(label: h.houseName, value: h.id),
                        )
                        .toList(),
                    initialValues: _selectedHouseId != null
                        ? [_selectedHouseId!]
                        : [],
                    onSelect: (values) {
                      if (values.isNotEmpty) {
                        setModalState(() {
                          _selectedHouseId = values.first;
                          _selectedHouse = _houses.firstWhere(
                            (h) => h.id == _selectedHouseId,
                          );
                        });
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createManager,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                        "CẤP QUYỀN QUẢN LÝ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "QUẢN LÝ NHÂN VIÊN",
        isSearching: isSearching,
        searchController: searchController,
        onSearchToggle: () => setState(() {
          isSearching = !isSearching;
          if (!isSearching) {
            searchController.clear();
            _applyFilter("");
          }
        }),
        onSearchChanged: _applyFilter,
      ),
      body: _isFetchingStaff
          ? const HouseListSkeleton()
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: AppColors.primary,
              child: _displayedStaff.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _displayedStaff.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 10,
                        thickness: 10,
                        color: Color(0xFFF2F2F7),
                      ),
                      itemBuilder: (context, index) {
                        final staff = _displayedStaff[index];
                        return StaffCard(
                          staff: staff,
                          onEdit: () {
                            DialogHelper.showWarning(
                              context,
                              "Tính năng sửa đang phát triển!",
                            );
                          },
                          onDelete: () {
                            DialogHelper.showWarning(
                              context,
                              "Tính năng xóa đang phát triển!",
                            );
                          },
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStaffModal,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.people_outline_rounded,
      title: "Chưa có nhân viên nào",
      subtitle: "Dữ liệu nhân viên sẽ hiển thị tại đây",
    );
  }
}
