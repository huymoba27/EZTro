import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/amenity_helper.dart';
import '../../../../core/utils/custom_painters.dart';
import '../../../../core/utils/dialog_helper.dart';
import 'package:eztro/core/widgets/widgets.dart';

// =============================================================================
// 1. CHỌN ẢNH NHÀ TRỌ (HouseImagePicker)
// =============================================================================
class HouseImagePicker extends StatelessWidget {
  final XFile? imageFile;
  final String? initialImageUrl;
  final Function(XFile?) onImageSelected;

  const HouseImagePicker({
    super.key,
    this.imageFile,
    this.initialImageUrl,
    required this.onImageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage =
        imageFile != null ||
        (initialImageUrl != null && initialImageUrl!.isNotEmpty);

    return GestureDetector(
      onTap: () => DialogHelper.showImagePicker(
        context: context,
        onImagesPicked: (files) {
          if (files.isNotEmpty) {
            onImageSelected(XFile(files.first.path));
          }
        },
      ),
      child: CustomPaint(
        painter: hasImage
            ? null
            : DashedRectPainter(
                color: Colors.black.withOpacity(0.15),
                dash: 5,
                gap: 3,
                strokeWidth: 1.0,
              ),
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: imageFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(imageFile!.path), fit: BoxFit.cover),
                )
              : initialImageUrl != null && initialImageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(initialImageUrl!, fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Nhấn để chọn ảnh khu trọ",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// =============================================================================
// 2. CHỌN ĐỊA CHỈ (AddressSelectorGroup)
// =============================================================================
class AddressSelectorGroup extends StatelessWidget {
  final List<Map<String, dynamic>> cities;
  final List<Map<String, dynamic>> subUnits;
  final String selectedCity;
  final String selectedWard;
  final Function(int, String) onCityChanged;
  final Function(String) onWardChanged;

  const AddressSelectorGroup({
    super.key,
    required this.cities,
    required this.subUnits,
    required this.selectedCity,
    required this.selectedWard,
    required this.onCityChanged,
    required this.onWardChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomSelectField(
            label: "Tỉnh/Thành phố *",
            value: selectedCity,
            onTap: () => AppSelectModal.show<dynamic>(
              context: context,
              title: "CHỌN TỈNH THÀNH",
              subtitle: "Vui lòng chọn tỉnh thành phố",
              items: cities
                  .map(
                    (c) => AppSelectItem(
                      label: c['name'].toString(),
                      value: c['code'],
                    ),
                  )
                  .toList(),
              initialValues: [selectedCity],
              onSelect: (values) {
                if (values.isNotEmpty) {
                  final code = values.first;
                  final name = cities
                      .firstWhere((c) => c['code'] == code)['name']
                      .toString();
                  onCityChanged(code as int, name);
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomSelectField(
            label: "Phường/Quận *",
            value: selectedWard,
            onTap: subUnits.isEmpty
                ? null
                : () => AppSelectModal.show<dynamic>(
                    context: context,
                    title: "CHỌN KHU VỰC",
                    subtitle: "Vui lòng chọn phường/xã/quận",
                    items: subUnits
                        .map(
                          (s) => AppSelectItem(
                            label: s['name'].toString(),
                            value: s['name'],
                          ),
                        )
                        .toList(),
                    initialValues: [selectedWard],
                    onSelect: (values) {
                      if (values.isNotEmpty) {
                        onWardChanged(values.first.toString());
                      }
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 3. CHỌN TIỆN ÍCH (AmenityPickerGrid)
// =============================================================================
class AmenityPickerGrid extends StatelessWidget {
  final List<Map<String, dynamic>> allAmenities;
  final List<int> selectedAmenityIds;
  final Function(int) onToggle;

  const AmenityPickerGrid({
    super.key,
    required this.allAmenities,
    required this.selectedAmenityIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allAmenities.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final amenity = allAmenities[index];
        final id = int.tryParse(amenity['id'].toString()) ?? 0;
        final name = amenity['name'] ?? "";
        final isSelected = selectedAmenityIds.contains(id);
        final iconData = AmenityHelper.getIcon(name);

        return InkWell(
          onTap: () => onToggle(id),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.grey.withOpacity(0.2),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  iconData,
                  color: isSelected ? AppColors.primary : Colors.grey[600],
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? AppColors.primary : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
