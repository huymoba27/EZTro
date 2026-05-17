import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Models & Providers
import '../../../models/house_model.dart';
import '../providers/create_house_provider.dart';
import '../../../views/auth/providers/auth_provider.dart';

// Core Resources
import '../../../core/constants/app_colors.dart';
import '../../../core/test_tools/demo_data.dart';
import '../../../core/test_tools/dev_autofill_button.dart';
import 'package:eztro/core/widgets/widgets.dart';

// Widgets & Components
import 'widgets/house_form_widgets.dart';
import '../../../controllers/house_controller.dart';
import '../../../services/api_constants.dart';
import 'map_picker_screen.dart';

class CreateHouseScreen extends ConsumerStatefulWidget {
  final HouseModel? house;
  const CreateHouseScreen({super.key, this.house});

  @override
  ConsumerState<CreateHouseScreen> createState() => _CreateHouseScreenState();
}

class _CreateHouseScreenState extends ConsumerState<CreateHouseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController addressDetailController;
  late TextEditingController areaController;
  late TextEditingController floorController;
  late TextEditingController creatorNameController;
  late TextEditingController creatorPhoneController;

  @override
  void initState() {
    super.initState();
    final house = widget.house;
    nameController = TextEditingController(text: house?.houseName ?? "");
    addressDetailController = TextEditingController(
      text: house?.addressDetail ?? "",
    );
    areaController = TextEditingController(
      text:
          house?.totalArea?.toStringAsFixed(
            house.totalArea?.truncateToDouble() == house.totalArea ? 0 : 1,
          ) ??
          "",
    );
    floorController = TextEditingController(
      text: house?.floors?.toString() ?? "",
    );

    // Initialize these controllers properly
    creatorNameController = TextEditingController();
    creatorPhoneController = TextEditingController();

    if (house != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(createHouseProvider.notifier)
            .initForEdit(
              house.city,
              house.ward,
              house.amenityIds,
              house.latitude ?? 10.0385,
              house.longitude ?? 105.7876,
            );
        // If editing, use the house's owner info
        creatorNameController.text = house.ownerName ?? "";
        creatorPhoneController.text = house.ownerPhone ?? "";
      });
    } else {
      // If creating new, try to load current user info immediately if available
      final user = ref.read(authProvider);
      if (user != null) {
        creatorNameController.text = user.fullName;
        creatorPhoneController.text = user.phoneNumber ?? user.username;
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    addressDetailController.dispose();
    areaController.dispose();
    floorController.dispose();
    creatorNameController.dispose();
    creatorPhoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final state = ref.read(createHouseProvider);
    final user = ref.read(authProvider);

    HouseController.submitHouse(
      context: context,
      userId: user?.id ?? 1,
      isEditMode: widget.house != null,
      existingHouse: widget.house,
      name: nameController.text,
      city: state.selectedCity,
      ward: state.selectedWard,
      addressDetail: addressDetailController.text,
      selectedAmenities: state.selectedAmenityIds,
      imageFile: state.imageFile,
      setLoading: (val) =>
          ref.read(createHouseProvider.notifier).setLoading(val),
      latitude: state.latitude,
      longitude: state.longitude,
      totalArea: double.tryParse(areaController.text),
      floors: int.tryParse(floorController.text),
      ownerName: creatorNameController.text,
      ownerPhone: creatorPhoneController.text,
    );
  }

  Future<void> _fillDemoData() async {
    final data = DemoData.house;
    nameController.text = data.name;
    addressDetailController.text = data.addressDetail;
    areaController.text = data.area;
    floorController.text = data.floors;

    final notifier = ref.read(createHouseProvider.notifier);
    notifier.setLocation(data.latitude, data.longitude);

    final state = ref.read(createHouseProvider);
    if (state.cities.isNotEmpty) {
      final city = state.cities.first;
      final cityCode = int.tryParse(city['code'].toString());
      if (cityCode != null) {
        await notifier.onCityChanged(cityCode, city['name'].toString());
        final nextState = ref.read(createHouseProvider);
        if (nextState.subUnits.isNotEmpty) {
          notifier.onWardChanged(nextState.subUnits.first['name'].toString());
        }
      }
    }

    if (mounted) setState(() {});
  }

  void _showMultiSelectAmenities(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(createHouseProvider);

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "TIỆN ÍCH CÓ SẴN",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${state.selectedAmenityIds.length} tiện ích đã chọn",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  state.allAmenities.isEmpty
                      ? const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Expanded(
                          child: SingleChildScrollView(
                            child: AmenityPickerGrid(
                              allAmenities: state.allAmenities,
                              selectedAmenityIds: state.selectedAmenityIds,
                              onToggle: (id) => ref
                                  .read(createHouseProvider.notifier)
                                  .toggleAmenity(id),
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Xác nhận lựa chọn",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth changes to auto-fill when creating new house
    ref.listen(authProvider, (previous, next) {
      if (widget.house == null && next != null) {
        if (creatorNameController.text.isEmpty) {
          creatorNameController.text = next.fullName;
        }
        if (creatorPhoneController.text.isEmpty) {
          creatorPhoneController.text = next.phoneNumber ?? next.username;
        }
      }
    });

    final state = ref.watch(createHouseProvider);
    final isEditMode = widget.house != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: isEditMode ? "CẬP NHẬT KHU TRỌ" : "TẠO KHU TRỌ MỚI",
        onBack: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isEditMode)
                      DevAutofillButton(onPressed: _fillDemoData),
                    _buildSection("THÔNG TIN CHUNG", [
                      CustomTextField(
                        label: "Tên nhà trọ *",
                        controller: nameController,
                      ),
                      CustomTextField(
                        label: "Người quản lý",
                        controller: creatorNameController,
                        readOnly: true,
                      ),
                      CustomTextField(
                        label: "Số điện thoại",
                        controller: creatorPhoneController,
                        readOnly: true,
                      ),
                    ]),
                    _buildDivider(),
                    _buildSection("VỊ TRÍ", [
                      CustomSelectField(
                        label: "Vị trí bản đồ",
                        value: state.latitude == 0
                            ? "Nhấn để ghim vị trí"
                            : "Tọa độ: ${state.latitude.toStringAsFixed(6)}, ${state.longitude.toStringAsFixed(6)}",
                        onTap: () async {
                          final dynamic result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MapPickerScreen(
                                initialLat: state.latitude,
                                initialLng: state.longitude,
                                initialAddressQuery:
                                    "${addressDetailController.text}, ${state.selectedWard}, ${state.selectedCity}",
                              ),
                            ),
                          );
                          if (result is MapPickerResult) {
                            ref
                                .read(createHouseProvider.notifier)
                                .updateLocationFull(
                                  lat: result.lat,
                                  lng: result.lng,
                                  city: result.cityName,
                                  ward: result.wardName,
                                );
                            addressDetailController.text =
                                result.streetName ?? '';
                          }
                        },
                      ),
                      AddressSelectorGroup(
                        cities: state.cities,
                        subUnits: state.subUnits,
                        selectedCity: state.selectedCity,
                        selectedWard: state.selectedWard,
                        onCityChanged: (code, name) => ref
                            .read(createHouseProvider.notifier)
                            .onCityChanged(code, name),
                        onWardChanged: (name) => ref
                            .read(createHouseProvider.notifier)
                            .onWardChanged(name),
                      ),
                      CustomTextField(
                        label: "Số nhà, tên đường *",
                        controller: addressDetailController,
                      ),
                    ]),
                    _buildDivider(),
                    _buildSection("CƠ SỞ VẬT CHẤT", [
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: "Diện tích (m²)",
                              controller: areaController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              label: "Số tầng",
                              controller: floorController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      CustomSelectField(
                        label: "Tiện ích của nhà trọ",
                        value: state.selectedAmenityIds.isEmpty
                            ? "Chưa chọn tiện ích nào"
                            : "${state.selectedAmenityIds.length} tiện ích đã chọn",
                        onTap: () => _showMultiSelectAmenities(context, ref),
                      ),
                    ]),
                    _buildDivider(),
                    _buildSection("HÌNH ẢNH", [
                      HouseImagePicker(
                        imageFile: state.imageFile,
                        initialImageUrl:
                            isEditMode && widget.house!.image.isNotEmpty
                            ? "${ApiConstants.serverUrl}/uploads/houses/${widget.house!.image}"
                            : null,
                        onImageSelected: (file) => ref
                            .read(createHouseProvider.notifier)
                            .setImage(file),
                      ),
                    ]),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomAction(state),
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

  Widget _buildBottomAction(dynamic state) {
    return AppBottomButtons(
      onCancel: () => Navigator.pop(context),
      onConfirm: _submit,
      cancelText: "Hủy bỏ",
      confirmText: widget.house != null ? "Lưu cập nhật" : "Tạo ngay",
      isSubmitting: state.isLoading,
    );
  }
}
