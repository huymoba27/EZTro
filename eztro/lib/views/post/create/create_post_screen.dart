import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/post_service.dart';
import '../../../models/post_model.dart';
import '../../../models/house_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/test_tools/demo_data.dart';
import '../../../core/test_tools/dev_autofill_button.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../house/providers/house_notifier.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  HouseModel? _selectedHouse;
  Map<String, dynamic>? _selectedRoom;
  bool _isLoading = false;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  List<Map<String, dynamic>> _allAvailableRooms = [];
  bool _isLoadingRooms = true;

  final List<Map<String, dynamic>> _commonRules = [
    {'name': 'Giờ giấc tự do', 'icon': Icons.access_time},
    {'name': 'Không nuôi thú cưng', 'icon': Icons.pets},
    {'name': 'Không chung chủ', 'icon': Icons.person_off},
    {'name': 'Để xe trong nhà', 'icon': Icons.directions_car},
    {'name': 'Có camera an ninh', 'icon': Icons.videocam},
    {'name': 'Không hút thuốc', 'icon': Icons.smoke_free},
    {'name': 'Vệ sinh riêng', 'icon': Icons.wc},
    {'name': 'Có chỗ phơi đồ', 'icon': Icons.dry_cleaning},
    {'name': 'Nấu ăn trong phòng', 'icon': Icons.restaurant},
    {'name': 'Bạn bè đến chơi', 'icon': Icons.group},
  ];
  final Set<String> _selectedRules = {};

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    final rooms = await PostService.getAvailableRooms();
    if (mounted) {
      setState(() {
        _allAvailableRooms = rooms;
        _isLoadingRooms = false;
      });
    }
  }

  void _onHouseSelected(int id, String name) {
    final houses = ref.read(houseNotifierProvider).asData?.value ?? [];
    final house = houses.firstWhere((h) => h.id == id);

    setState(() {
      _selectedHouse = house;
      _selectedRoom = null;
      _titleController.clear();
      _descController.clear();
      _priceController.clear();
      _selectedRules.clear();
    });
  }

  void _onRoomSelected(String roomName) {
    final room = _allAvailableRooms.firstWhere(
      (r) =>
          r['room_name'] == roomName &&
          int.parse(r['house_id'].toString()) == _selectedHouse!.id,
    );

    // Lấy thông tin từ API đã được làm giàu (Enriched)
    String fullAddress = HouseModel.formatAddress(
      addressDetail: room['address_detail'],
      ward: room['ward'] ?? "",
      city: room['city'] ?? "",
    );

    final ePrice = room['electric_price'] != null
        ? "${double.parse(room['electric_price'].toString()).toInt()} đ/kWh"
        : "Theo giá nhà nước";
    final wPrice = room['water_price'] != null
        ? "${double.parse(room['water_price'].toString()).toInt()} đ/m3"
        : "Theo giá nhà nước";

    final capacity = room['max_tenants'] ?? "0";
    final area = room['area'] ?? "0";

    setState(() {
      _selectedRoom = room;
      _priceController.text = room['price'].toString();
      _titleController.text =
          "Cho thuê phòng ${room['room_name']} - ${room['house_name']}";

      String desc = "Phòng rộng ${area}m2, sạch sẽ, thoáng mát.\n";
      desc += "Sức chứa: $capacity người.\n";
      desc += "Giá điện: $ePrice, Giá nước: $wPrice.\n";
      desc += "Địa chỉ: $fullAddress.";

      _descController.text = desc;
      _selectedRules.clear();
    });
  }

  Future<void> _submitPost() async {
    if (_selectedRoom == null) {
      DialogHelper.showWarning(context, "Vui lòng chọn một phòng trống");
      return;
    }

    if (_titleController.text.isEmpty) {
      DialogHelper.showWarning(context, "Vui lòng nhập tiêu đề tin đăng");
      return;
    }

    setState(() => _isLoading = true);

    final rulesString = _selectedRules.join(', ');

    final post = PostModel(
      roomId: int.parse(_selectedRoom!['id'].toString()),
      title: _titleController.text,
      description: _descController.text,
      priceDisplay: _priceController.text,
      houseRules: rulesString,
    );

    final result = await PostService.createPost(post);
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['status'] == 'success') {
        DialogHelper.showSuccess(
          context,
          "Đăng tin thành công!",
          onTap: () => Navigator.pop(context, true),
        );
      } else {
        DialogHelper.showError(context, result['message'] ?? "Lỗi đăng tin");
      }
    }
  }

  void _fillDemoData(List<HouseModel> allHouses) {
    if (_allAvailableRooms.isEmpty || allHouses.isEmpty) return;

    Map<String, dynamic>? pickedRoom;
    HouseModel? pickedHouse;
    for (final room in _allAvailableRooms) {
      final houseId = int.tryParse(room['house_id'].toString());
      if (houseId == null) continue;
      for (final house in allHouses) {
        if (house.id == houseId) {
          pickedRoom = room;
          pickedHouse = house;
          break;
        }
      }
      if (pickedRoom != null) break;
    }

    if (pickedRoom == null || pickedHouse == null) return;

    setState(() => _selectedHouse = pickedHouse);
    _onRoomSelected(pickedRoom['room_name'].toString());
    setState(() {
      _selectedRules
        ..clear()
        ..addAll(
          _commonRules
              .take(DemoData.post.ruleCount)
              .map((rule) => rule['name'].toString()),
        );
    });
  }

  void _showMultiSelectRules() {
    AppSelectModal.show<String>(
      context: context,
      title: "NỘI QUY NHÀ TRỌ",
      subtitle: "${_selectedRules.length} nội quy đã chọn",
      isMultiSelect: true,
      items: _commonRules
          .map(
            (r) => AppSelectItem<String>(
              label: r['name'].toString(),
              value: r['name'].toString(),
              icon: r['icon'] as IconData?,
            ),
          )
          .toList(),
      initialValues: _selectedRules.toList(),
      onSelect: (values) {
        setState(() {
          _selectedRules.clear();
          _selectedRules.addAll(values);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final housesAsync = ref.watch(houseNotifierProvider);
    final allHouses = housesAsync.asData?.value ?? [];

    String displayAddress = "";
    if (_selectedRoom != null) {
      displayAddress =
          [
                _selectedRoom!['address_detail']?.toString() ?? "",
                _selectedRoom!['ward']?.toString() ?? "",
                _selectedRoom!['city']?.toString() ?? "",
              ]
              .where(
                (s) =>
                    s.isNotEmpty &&
                    s.toLowerCase() != "null" &&
                    s != "Chưa xác định",
              )
              .toList()
              .join(', ');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: CustomAppBar(
        title: "ĐĂNG TIN CHO THUÊ",
        onBack: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DevAutofillButton(onPressed: () => _fillDemoData(allHouses)),
                _buildSection("PHÒNG CHO THUÊ", [
                  CustomSelectField(
                    label: "Khu trọ / Nhà trọ *",
                    value: _selectedHouse != null
                        ? _selectedHouse!.houseName
                        : "Bấm để chọn khu trọ...",
                    onTap: () {
                      AppSelectModal.show<int>(
                        context: context,
                        title: "CHỌN KHU TRỌ",
                        subtitle: "Vui lòng chọn khu trọ để đăng tin",
                        items: allHouses
                            .map(
                              (h) => AppSelectItem(
                                label: h.houseName,
                                value: h.id,
                              ),
                            )
                            .toList(),
                        initialValues: _selectedHouse != null
                            ? [_selectedHouse!.id]
                            : [],
                        onSelect: (values) {
                          if (values.isNotEmpty) {
                            _onHouseSelected(values.first, "");
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  CustomSelectField(
                    label: "Phòng trống *",
                    value: _selectedRoom != null
                        ? _selectedRoom!['room_name']
                        : "Bấm để chọn phòng...",
                    onTap: () {
                      if (_selectedHouse == null) {
                        DialogHelper.showWarning(
                          context,
                          "Vui lòng chọn Nhà trọ trước",
                        );
                        return;
                      }

                      final filteredRoomNames = _allAvailableRooms
                          .where(
                            (r) =>
                                int.parse(r['house_id'].toString()) ==
                                _selectedHouse!.id,
                          )
                          .map((r) => r['room_name'].toString())
                          .toList();

                      if (filteredRoomNames.isEmpty) {
                        DialogHelper.showWarning(
                          context,
                          "Nhà trọ này hiện không còn phòng trống",
                        );
                        return;
                      }

                      AppSelectModal.show<String>(
                        context: context,
                        title: "CHỌN PHÒNG TRỐNG",
                        subtitle: "Tại ${_selectedHouse!.houseName}",
                        items: filteredRoomNames
                            .map(
                              (name) => AppSelectItem(label: name, value: name),
                            )
                            .toList(),
                        initialValues: _selectedRoom != null
                            ? [_selectedRoom!['room_name']]
                            : [],
                        onSelect: (values) {
                          if (values.isNotEmpty) {
                            _onRoomSelected(values.first);
                          }
                        },
                      );
                    },
                  ),
                ]),
                _buildDivider(),

                if (_selectedRoom != null) ...[
                  _buildSection("THÔNG TIN PHÒNG", [
                    _buildInfoItem(
                      Icons.location_on_outlined,
                      "Địa chỉ",
                      displayAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      Icons.people_outline,
                      "Sức chứa",
                      "${_selectedRoom!['max_tenants'] ?? 0} người",
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      Icons.star_outline,
                      "Tiện ích của nhà",
                      _selectedRoom!['house_amenities'] ?? "Cơ bản",
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      Icons.bolt,
                      "Giá điện",
                      _selectedRoom!['electric_price'] != null
                          ? "${double.parse(_selectedRoom!['electric_price'].toString()).toInt()} đ/kWh"
                          : "Theo giá nhà nước",
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      Icons.water_drop,
                      "Giá nước",
                      _selectedRoom!['water_price'] != null
                          ? "${double.parse(_selectedRoom!['water_price'].toString()).toInt()} đ/m3"
                          : "Theo giá nhà nước",
                    ),
                  ]),
                  _buildDivider(),

                  _buildSection("NỘI DUNG QUẢNG CÁO", [
                    CustomTextField(
                      controller: _titleController,
                      label: "Tiêu đề tin đăng *",
                      hint: "Ví dụ: Phòng đẹp giá rẻ ngay trung tâm...",
                    ),
                    CustomTextField(
                      controller: _priceController,
                      label: "Giá thuê hiển thị (VNĐ) *",
                      hint: "Nhập giá thuê...",
                      keyboardType: TextInputType.number,
                    ),
                    CustomTextField(
                      controller: _descController,
                      label: "Mô tả chi tiết",
                      hint: "Nhập mô tả về căn phòng, tiện nghi xung quanh...",
                      maxLines: 4,
                    ),
                  ]),
                  _buildDivider(),

                  _buildSection("ĐIỀU KHOẢN & NỘI QUY", [
                    CustomSelectField(
                      label: "Nội quy nhà trọ",
                      value: _selectedRules.isEmpty
                          ? "Bấm để chọn nội quy..."
                          : "${_selectedRules.length} nội quy đã chọn",
                      onTap: _showMultiSelectRules,
                    ),
                  ]),
                  const SizedBox(height: 120),
                ],
              ],
            ),
          ),

          if (_isLoading) _buildLoadingOverlay(),

          if (_selectedRoom != null) _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return AppSectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return const SizedBox(height: 10);
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AppBottomButtons(
        onCancel: () => Navigator.pop(context),
        onConfirm: _submitPost,
        cancelText: "Hủy bỏ",
        confirmText: "Đăng tin",
        isSubmitting: _isLoading,
      ),
    );
  }
}
