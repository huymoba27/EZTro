import 'package:flutter/material.dart';
import '../../../models/post_model.dart';
import '../../../services/post_service.dart';
import '../../home/post_detail_screen.dart';
import '../widgets/post_list_card.dart';
import 'package:geolocator/geolocator.dart';

class PublicPostListScreen extends StatefulWidget {
  const PublicPostListScreen({super.key});

  @override
  State<PublicPostListScreen> createState() => _PublicPostListScreenState();
}

class _PublicPostListScreenState extends State<PublicPostListScreen> {
  late Future<List<PostModel>> _postsFuture;
  List<PostModel> _allPosts = [];
  List<PostModel> _displayedPosts = [];
  bool _isLoadingLocation = false;
  final TextEditingController _searchController = TextEditingController();

  // Trạng thái bộ lọc
  double? _minPrice;
  double? _maxPrice;
  double? _minArea;
  double? _maxArea;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    _postsFuture = PostService.getPosts().then((posts) {
      setState(() {
        _allPosts = posts;
        _displayedPosts = List.from(posts);
      });
      return posts;
    });
  }

  /// Hàm áp dụng tất cả các bộ lọc (Search + Price + Area)
  void _applyFilters() {
    final query = _searchController.text.trim();
    final lowercaseQuery = _removeDiacritics(query.toLowerCase());
    final queryWords = lowercaseQuery
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    setState(() {
      _displayedPosts = _allPosts.where((post) {
        // 1. Lọc theo text search
        bool matchesSearch = true;
        if (queryWords.isNotEmpty) {
          final address = _removeDiacritics(
            "${post.addressDetail} ${post.ward} ${post.city}".toLowerCase(),
          );
          final title = _removeDiacritics(post.title.toLowerCase());
          final combined = "$title $address";
          matchesSearch = queryWords.every((word) => combined.contains(word));
        }

        // 2. Lọc theo giá
        bool matchesPrice = true;
        double? price = double.tryParse(post.originalPrice ?? '0');
        if (price != null) {
          if (_minPrice != null && price < _minPrice!) matchesPrice = false;
          if (_maxPrice != null && price > _maxPrice!) matchesPrice = false;
        }

        // 3. Lọc theo diện tích
        bool matchesArea = true;
        double? area = double.tryParse(post.area ?? '0');
        if (area != null) {
          if (_minArea != null && area < _minArea!) matchesArea = false;
          if (_maxArea != null && area > _maxArea!) matchesArea = false;
        }

        return matchesSearch && matchesPrice && matchesArea;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    _applyFilters();
  }

  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white, // Pure white background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Khoảng giá (VNĐ)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildFilterOption(
                "Dưới 2 triệu",
                () => _setPriceFilter(null, 2000000),
              ),
              _buildFilterOption(
                "2 - 5 triệu",
                () => _setPriceFilter(2000000, 5000000),
              ),
              _buildFilterOption(
                "Trên 5 triệu",
                () => _setPriceFilter(5000000, null),
              ),
              _buildFilterOption(
                "Tất cả giá",
                () => _setPriceFilter(null, null),
              ),
            ],
          ),
        );
      },
    );
  }

  void _setPriceFilter(double? min, double? max) {
    setState(() {
      _minPrice = min;
      _maxPrice = max;
    });
    _applyFilters();
    Navigator.pop(context);
  }

  void _showAreaFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white, // Pure white background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Diện tích (m2)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildFilterOption("Dưới 20m2", () => _setAreaFilter(null, 20)),
              _buildFilterOption("20 - 50m2", () => _setAreaFilter(20, 50)),
              _buildFilterOption("Trên 50m2", () => _setAreaFilter(50, null)),
              _buildFilterOption(
                "Tất cả diện tích",
                () => _setAreaFilter(null, null),
              ),
            ],
          ),
        );
      },
    );
  }

  void _setAreaFilter(double? min, double? max) {
    setState(() {
      _minArea = min;
      _maxArea = max;
    });
    _applyFilters();
    Navigator.pop(context);
  }

  Widget _buildFilterOption(String label, VoidCallback onTap) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 15)),
      onTap: onTap,
    );
  }

  String _removeDiacritics(String str) {
    const withFormat =
        "àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ";
    const noFormat =
        "aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD";

    if (str.isEmpty) return str;

    String result = str;
    for (int i = 0; i < withFormat.length; i++) {
      result = result.replaceAll(withFormat[i], noFormat[i]);
    }
    return result;
  }

  Future<void> _sortByNearest() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Dịch vụ định vị đang bị tắt.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Quyền truy cập vị trí bị từ chối');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Quyền truy cập vị trí bị từ chối vĩnh viễn, không thể yêu cầu quyền.',
        );
      }

      Position position = await Geolocator.getCurrentPosition();

      List<PostModel> sorted = List.from(_allPosts);
      sorted.sort((a, b) {
        double distA = (a.latitude != null && a.longitude != null)
            ? Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                a.latitude!,
                a.longitude!,
              )
            : double.infinity;

        double distB = (b.latitude != null && b.longitude != null)
            ? Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                b.latitude!,
                b.longitude!,
              )
            : double.infinity;

        return distA.compareTo(distB);
      });

      setState(() {
        _displayedPosts = sorted;
        _searchController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sắp xếp danh sách trọ gần bạn nhất!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lấy vị trí: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(),
            _buildFilterBar(),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.black.withOpacity(0.12),
            ),
            Expanded(child: _buildListContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.green, width: 1.5),
          boxShadow: const [],
        ),
        child: Row(
          children: [
            IconButton(
              splashRadius: 20,
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black87,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: "Gần trường, công ty...",
                  hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  suffixIcon: Icon(
                    Icons.search,
                    color: Colors.black38,
                    size: 20,
                  ),
                  suffixIconConstraints: BoxConstraints(minWidth: 40),
                  contentPadding: EdgeInsets.only(left: 4, top: 2),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Trạng thái sắp xếp giá: 0: không, 1: thấp-cao, 2: cao-thấp
  int _priceSortOrder = 0;

  void _onPriceSortToggle() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white, // Pure white background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Sắp xếp theo giá",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildFilterOption("Giá thấp đến cao", () => _applyPriceSort(1)),
              _buildFilterOption("Giá cao đến thấp", () => _applyPriceSort(2)),
              _buildFilterOption("Mặc định", () => _applyPriceSort(0)),
            ],
          ),
        );
      },
    );
  }

  void _applyPriceSort(int order) {
    setState(() {
      _priceSortOrder = order;
      if (order == 1) {
        _displayedPosts.sort(
          (a, b) => (double.tryParse(a.originalPrice ?? '0') ?? 0).compareTo(
            double.tryParse(b.originalPrice ?? '0') ?? 0,
          ),
        );
      } else if (order == 2) {
        _displayedPosts.sort(
          (a, b) => (double.tryParse(b.originalPrice ?? '0') ?? 0).compareTo(
            double.tryParse(a.originalPrice ?? '0') ?? 0,
          ),
        );
      } else {
        _applyFilters(); // Reset filters and original order
      }
    });
    Navigator.pop(context);
  }

  Widget _buildFilterBar() {
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: _showPriceFilter,
              child: _buildFilterChip(
                _maxPrice != null
                    ? "≤ ${_maxPrice!.toInt() ~/ 1000000}Tr"
                    : (_minPrice != null
                          ? "≥ ${_minPrice!.toInt() ~/ 1000000}Tr"
                          : ' Chọn giá'),
                icon: Icons.payments_outlined,
                isActive: _minPrice != null || _maxPrice != null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: _showAreaFilter,
              child: _buildFilterChip(
                _maxArea != null
                    ? "≤ ${_maxArea!.toInt()}m2"
                    : (_minArea != null
                          ? "≥ ${_minArea!.toInt()}m2"
                          : ' Diện tích'),
                icon: Icons.straighten_outlined,
                isActive: _minArea != null || _maxArea != null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: _onPriceSortToggle,
              child: _buildFilterChip(
                _priceSortOrder == 1
                    ? 'Thấp-Cao'
                    : (_priceSortOrder == 2 ? 'Cao-Thấp' : 'Xếp giá'),
                isActive: _priceSortOrder != 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label, {
    IconData? icon,
    IconData? iconRight,
    bool isActive = false,
    double? width,
  }) {
    return Container(
      width: width,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isActive ? Colors.green : Colors.black.withOpacity(0.4),
          width: isActive ? 1.2 : 0.8,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.green : Colors.black87,
            ),
            const SizedBox(width: 2),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? Colors.green : Colors.black87,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (iconRight != null) ...[
            const SizedBox(width: 2),
            Icon(
              iconRight,
              size: 13,
              color: isActive ? Colors.green : Colors.black54,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListContent() {
    return FutureBuilder<List<PostModel>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _allPosts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Có lỗi xảy ra: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (_displayedPosts.isEmpty) {
          return const Center(child: Text("Không có bài đăng nào."));
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: _displayedPosts.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 0.8,
            indent: 12,
            endIndent: 12,
            color: Colors.black.withOpacity(0.1),
          ),
          itemBuilder: (context, index) {
            final post = _displayedPosts[index];
            return PostListCard(
              post: post,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PostDetailScreen(postId: post.id ?? 0),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
