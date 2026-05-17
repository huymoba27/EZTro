import 'package:flutter/material.dart';
import '../../../services/post_service.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:eztro/core/widgets/widgets.dart';
import '../../house/list/widgets/house_list_skeleton.dart';
import '../widgets/rental_request_card.dart';

class RentalRequestListScreen extends StatefulWidget {
  const RentalRequestListScreen({super.key});

  @override
  State<RentalRequestListScreen> createState() =>
      _RentalRequestListScreenState();
}

class _RentalRequestListScreenState extends State<RentalRequestListScreen> {
  late Future<List<Map<String, dynamic>>> _requestsFuture;
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> allRequests = [];
  List<Map<String, dynamic>> displayedRequests = [];

  @override
  void initState() {
    super.initState();
    _refreshRequests();
  }

  void _refreshRequests() {
    setState(() {
      _requestsFuture = _loadRequests();
    });
  }

  Future<List<Map<String, dynamic>>> _loadRequests() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      final requests = await PostService.getRentalRequests(user.id);
      allRequests = requests;
      displayedRequests = requests;
      return requests;
    }
    return [];
  }

  void _applyFilter(String query) {
    setState(() {
      displayedRequests = allRequests
          .where(
            (r) =>
                r['customer_name'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                r['customer_phone'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                (r['post_title']?.toString().toLowerCase().contains(
                      query.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "YÊU CẦU THUÊ PHÒNG",
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const HouseListSkeleton();
          }

          if (displayedRequests.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshRequests(),
            color: AppColors.primary,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: displayedRequests.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 0.8,
                indent: 16,
                endIndent: 16,
                color: Colors.black.withOpacity(0.22),
              ),
              itemBuilder: (context, index) {
                final req = displayedRequests[index];
                return RentalRequestCard(
                  request: req,
                  onCall: () => _makePhoneCall(req['customer_phone']),
                  onContacted: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Tính năng đánh dấu đã liên hệ sẽ sớm ra mắt!",
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.mail_outline_rounded,
      title: "Chưa có yêu cầu nào",
      subtitle: "Dữ liệu yêu cầu sẽ hiển thị tại đây",
    );
  }
}
