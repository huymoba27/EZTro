import 'package:flutter/material.dart';

class MonthTabSlider extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final ScrollController scrollController;
  final Function(int) onMonthTap;
  final Color themeGreen;

  const MonthTabSlider({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.scrollController,
    required this.onMonthTap,
    this.themeGreen = const Color(0xFF2E7D32),
  });

  @override
  Widget build(BuildContext context) {
    double itemWidth = MediaQuery.of(context).size.width / 3;

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        itemBuilder: (context, index) {
          int month = index + 1;
          bool isSelected = selectedMonth == month;
          
          return GestureDetector(
            onTap: () => onMonthTap(month),
            child: Container(
              width: itemWidth, // 🎯 Đã đổi thành itemWidth (3 tháng/màn hình)
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${month.toString().padLeft(2, '0')}/$selectedYear",
                    style: TextStyle(
                      color: isSelected ? themeGreen : Colors.black45,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
                    width: isSelected ? 40 : 0, // Tăng width vạch xanh lên một chút cho cân xứng
                    decoration: BoxDecoration(
                      color: themeGreen,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}