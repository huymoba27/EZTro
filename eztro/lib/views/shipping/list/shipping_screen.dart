import 'package:flutter/material.dart';

class ShippingScreen extends StatelessWidget {
  const ShippingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context),
            const SizedBox(height: 20),
            _buildVehicleCard(
              title: "Xe ba gác vận chuyển trọ",
              description:
                  "Chuyên chở hàng hóa tối đa 400 kg và kích thước hàng hóa không vượt quá 1m7x1m2x1m.",
              price: "Chỉ từ 100,000đ",
              imageUrl:
                  "https://img.freepik.com/free-vector/delivery-truck-isolated-white_1308-41005.jpg", // Placeholder
            ),
            _buildVehicleCard(
              title: "Xe tải chuyển nhà",
              description:
                  "Chuyên chở hàng hóa tối đa 500 kg và kích thước hàng hóa không vượt quá 2m1x1m5x1m5.",
              price: "Chỉ từ 300,000đ",
              imageUrl:
                  "https://img.freepik.com/free-vector/van-delivery-truck-isolated-white_1308-39828.jpg", // Placeholder
            ),
            _buildVehicleCard(
              title: "Xe tải lớn (1.5 - 2 tấn)",
              description:
                  "Phù hợp cho nhà nguyên căn, văn phòng lớn. Tải trọng lên đến 2000kg.",
              price: "Chỉ từ 500,000đ",
              imageUrl:
                  "https://img.freepik.com/free-vector/delivery-truck-with-parcel-boxes_1308-39328.jpg", // Placeholder
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        Container(
          height: 300,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                "https://img.freepik.com/free-photo/courier-checking-parcel-list-while-standing-near-van_23-2148908865.jpg",
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
        // Overlay Badge
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: "CHUYỂN TRỌ ",
                        style: TextStyle(color: Colors.orange),
                      ),
                      TextSpan(
                        text: "GIÁ TỐT - UY TÍN",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Dịch vụ taxi tải vận chuyển uy tín - chuyên nghiệp - chất lượng có giá rẻ nhất tại thành phố Hồ Chí Minh.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleCard({
    required String title,
    required String description,
    required String price,
    required String imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Icon in Circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    children: [
                      const TextSpan(text: "Cước phí: "),
                      TextSpan(
                        text: price,
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
