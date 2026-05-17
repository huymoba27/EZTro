import 'package:flutter/material.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../../models/house_model.dart';
import '../../../../models/room_model.dart';
import '../../../../core/utils/dialog_helper.dart';

class InvoiceTargetSection extends StatelessWidget {
  final List<HouseModel> allHouses;
  final HouseModel? selectedHouse;
  final Map<String, dynamic>? selectedRoom;
  final List<RoomModel> allOccupiedRooms;
  final Function(HouseModel house) onHouseSelected;
  final Function(String roomName) onRoomSelected;

  const InvoiceTargetSection({
    super.key,
    required this.allHouses,
    required this.selectedHouse,
    required this.selectedRoom,
    required this.allOccupiedRooms,
    required this.onHouseSelected,
    required this.onRoomSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: "Đối tượng lập hóa đơn",
      child: Column(
        children: [
          CustomSelectField(
            label: "Nhà trọ",
            value: selectedHouse?.houseName ?? "Chọn nhà",
            onTap: () {
              AppSelectModal.show<int>(
                context: context,
                title: "CHỌN NHÀ TRỌ",
                subtitle: "Vui lòng chọn khu trọ lập hóa đơn",
                items: allHouses
                    .map((h) => AppSelectItem(label: h.houseName, value: h.id))
                    .toList(),
                initialValues: selectedHouse != null ? [selectedHouse!.id] : [],
                onSelect: (values) {
                  if (values.isNotEmpty) {
                    final house = allHouses.firstWhere((h) => h.id == values.first);
                    onHouseSelected(house);
                  }
                },
              );
            },
          ),
          CustomSelectField(
            label: "Phòng thuê",
            value: selectedRoom?['room_name'] ?? "Chọn phòng chưa lập hóa đơn",
            onTap: () {
              if (selectedHouse == null) {
                DialogHelper.showWarning(context, "Chọn nhà trước!");
                return;
              }
              DialogHelper.showLocationSelect(
                context: context,
                title: "CHỌN PHÒNG",
                subtitle: "Phòng đang thuê",
                data: allOccupiedRooms.map((r) => r.roomName).toList(),
                currentValue: selectedRoom?['room_name'] ?? "",
                onSelect: onRoomSelected,
              );
            },
          ),
        ],
      ),
    );
  }
}
