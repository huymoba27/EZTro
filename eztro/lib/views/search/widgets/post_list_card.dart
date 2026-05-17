import 'package:flutter/material.dart';
import '../../../models/post_model.dart';
import '../../../services/api_constants.dart';
import '../../../core/utils/format_helper.dart';
import 'package:eztro/core/widgets/widgets.dart';

class PostListCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const PostListCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Tách danh sách ảnh để tính số lượng
    List<String> images = (post.images ?? '')
        .split(',')
        .where((e) => e.trim().isNotEmpty)
        .toList();
    String firstImage = images.isNotEmpty ? images.first : '';
    int imageCount = images.length;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 110,
                      height: 110,
                      color: Colors.grey[200],
                      child: firstImage.isNotEmpty
                          ? Image.network(
                              '${ApiConstants.baseUrl}/uploads/rooms/$firstImage',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.image,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
                            )
                          : const Icon(
                              Icons.image,
                              size: 30,
                              color: Colors.grey,
                            ),
                    ),
                  ),

                  // Badge đếm ảnh (Góc trên phải ảnh)
                  if (imageCount > 1)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.photo_library_outlined,
                              color: Colors.white,
                              size: 10,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              imageCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              // Content Section
              Expanded(
                child: SizedBox(
                  height: 110, // Match image height for vertical alignment
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề
                      Text(
                        post.title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700, // Slightly bolder for all caps
                          height: 1.45,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 6),

                      // Địa chỉ
                      CardInfoRow(
                        icon: Icons.location_on_outlined,
                        text: [
                          if (post.ward != null && post.ward!.isNotEmpty && post.ward != "Chưa xác định") _cleanAddressPart(post.ward),
                          if (post.city != null && post.city!.isNotEmpty) _cleanAddressPart(post.city),
                        ].join(' • '),
                      ),

                      const Spacer(),

                      // Price and Area row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 0.5),
                                child: const Icon(
                                  Icons.paid_outlined,
                                  color: Colors.red,
                                  size: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatPriceString(
                                  post.priceDisplay ?? post.originalPrice,
                                ),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),

                          // Area
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 0.5),
                                child: const Icon(
                                  Icons.aspect_ratio, // Match home screen icon
                                  color: Colors.black54,
                                  size: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${post.area} m2",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _cleanAddressPart(String? part) {
    if (part == null) return '';
    return part
        .replaceAll(
          RegExp(
            r'Phường |Quận |Thành phố |Tỉnh |Thị xã |Huyện ',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  String _formatPriceString(String? priceStr) {
    if (priceStr == null || priceStr.isEmpty) return '0 đ';
    String cleanStr = priceStr.replaceFirst(RegExp(r'[.,]\d{1,2}$'), '');
    String cleanDigits = cleanStr.replaceAll(RegExp(r'[^0-9]'), '');
    int value = int.tryParse(cleanDigits) ?? 0;
    return CurrencyHelper.formatVND(value);
  }
}
