import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/format_helper.dart';
import '../../../core/constants/app_colors.dart';
import 'package:eztro/core/widgets/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../services/notification_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/deposit_service.dart';
import '../../../models/user_model.dart';
import '../../../core/utils/dialog_helper.dart';
import '../../../core/test_tools/test_tool_config.dart';

class TenantDepositQrScreen extends StatefulWidget {
  final int depositId;
  final String checkoutUrl;
  final String? qrCode;
  final String expiresAt;
  final int amount;
  final String roomName;
  final String houseName;

  final String? bankBin;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? paymentDescription;

  const TenantDepositQrScreen({
    super.key,
    required this.depositId,
    required this.checkoutUrl,
    this.qrCode,
    required this.expiresAt,
    required this.amount,
    required this.roomName,
    required this.houseName,
    this.bankBin,
    this.bankAccountNumber,
    this.bankAccountName,
    this.paymentDescription,
  });

  @override
  State<TenantDepositQrScreen> createState() => _TenantDepositQrScreenState();
}

class _TenantDepositQrScreenState extends State<TenantDepositQrScreen> {
  Timer? _countdownTimer;
  Timer? _pollTimer;
  int _remainingSeconds = 300;
  bool _isExpired = false;
  bool _isPaid = false;
  bool _isLoading = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _calculateRemaining();
    _startCountdown();
    _startPolling();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) setState(() => _currentUser = user);
  }

  void _calculateRemaining() {
    try {
      if (widget.expiresAt.isEmpty) {
        _remainingSeconds = 300;
        return;
      }
      final expiresStr = widget.expiresAt.replaceAll(' ', 'T');
      final expires = DateTime.parse(expiresStr);
      final now = DateTime.now();
      final isUtc =
          widget.expiresAt.contains('Z') || widget.expiresAt.contains('+');
      final diff = isUtc
          ? expires.difference(now.toUtc()).inSeconds
          : expires.difference(now).inSeconds;
      _remainingSeconds = diff > 0 ? diff : 0;
      if (_remainingSeconds <= 0 || _remainingSeconds > 86400) {
        _remainingSeconds = 300;
      }
    } catch (e) {
      debugPrint("Lỗi parse thời gian: $e");
      _remainingSeconds = 300;
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _isExpired = true;
          timer.cancel();
        }
      });
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || _isPaid || _isExpired) {
        if (_isExpired) timer.cancel();
        return;
      }
      final result = await DepositService.checkDepositStatus(widget.depositId);
      if (result != null && mounted) {
        if (result.status == 'completed' || result.status == 'confirmed') {
          _handlePaymentSuccess();
          timer.cancel();
        }
      }
    });
  }

  Future<void> _handlePaymentSuccess() async {
    if (!mounted) return;
    setState(() {
      _isPaid = true;
      _countdownTimer?.cancel();
    });

    // Gửi thông báo hệ thống
    if (_currentUser != null) {
      // 1. Thông báo cho khách thuê
      await NotificationService.pushNotification(
        userId: _currentUser!.id,
        title: "Đặt cọc thành công",
        description:
            "Bạn đã thanh toán thành công ${CurrencyHelper.formatVND(widget.amount)} cho phòng ${widget.roomName}.",
        type: "payment",
        metadata: {"deposit_id": widget.depositId},
      );

      // 2. Thông báo cho chủ trọ
      await NotificationService.pushNotification(
        userId: 1,
        title: "Khách đã đặt cọc",
        description:
            "Phòng ${widget.roomName} vừa được khách ${_currentUser!.fullName} đặt cọc thành công số tiền ${CurrencyHelper.formatVND(widget.amount)}.",
        type: "payment",
        metadata: {"deposit_id": widget.depositId},
      );
    }

    if (mounted) {
      DialogHelper.showSuccess(
        context,
        "Chúc mừng! Bạn đã đặt cọc thành công phòng ${widget.roomName}. Chủ trọ sẽ sớm liên hệ với bạn.",
        onTap: () => Navigator.pop(context),
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  String get _timeDisplay =>
      "${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}";

  String _getBankName(String? bin) {
    if (bin == "970436") return "Vietcombank";
    if (bin == "970415") return "VietinBank";
    if (bin == "970418") return "BIDV";
    if (bin == "970405") return "Agribank";
    if (bin == "970422") return "MBBank";
    if (bin == "970423") return "TPBank";
    if (bin == "970452") return "KienLongBank";
    return "Ngân hàng liên kết";
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = _isPaid
        ? const Color(0xFF2E7D32)
        : (_isExpired ? Colors.red : Colors.orange);
    Color statusBg = _isPaid
        ? const Color(0xFFE8F5E9)
        : (_isExpired ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "THANH TOÁN ĐẶT CỌC",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // --- STATUS BANNER ---
                Container(
                  width: double.infinity,
                  color: statusBg,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _isPaid
                            ? "ĐÃ THANH TOÁN"
                            : (_isExpired
                                  ? "GIAO DỊCH HẾT HẠN"
                                  : "CHƯA THANH TOÁN"),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        CurrencyHelper.formatVND(widget.amount),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Phòng ${widget.roomName} - ${widget.houseName}",
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- INFO SECTION ---
                AppSectionCard(
                  title: "Thông tin phiếu cọc",
                  child: Column(
                    children: [
                      _buildFlatInfoRow("Mã phiếu cọc", "#${widget.depositId}"),
                      _buildFlatInfoRow(
                        "Dự kiến vào",
                        widget.expiresAt.split(' ')[0],
                      ),
                      _buildFlatInfoRow(
                        "Loại thanh toán",
                        "Đặt cọc giữ chỗ",
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                Container(height: 8, color: const Color(0xFFF2F2F7)),

                // --- QR SECTION ---
                if (!_isPaid && !_isExpired)
                  AppSectionCard(
                    title: "Quét mã QR thanh toán",
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: widget.qrCode != null
                                ? QrImageView(
                                    data: widget.qrCode!,
                                    version: QrVersions.auto,
                                    size: 200,
                                    gapless: false,
                                  )
                                : const SizedBox(
                                    height: 200,
                                    width: 200,
                                    child: Center(child: Text("Lỗi tạo mã QR")),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "Mã hết hạn sau: ",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                _timeDisplay,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Sử dụng App Ngân hàng để quét mã",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (!_isPaid && !_isExpired)
                  Container(height: 8, color: const Color(0xFFF2F2F7)),

                // --- BANK SECTION ---
                if (!_isPaid && !_isExpired)
                  AppSectionCard(
                    title: "Chuyển khoản nhanh",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBankRowLeft(
                          "Ngân hàng",
                          _getBankName(widget.bankBin),
                        ),
                        _buildBankRowLeft(
                          "Số tài khoản",
                          widget.bankAccountNumber ?? "N/A",
                          isGreen: true,
                          canCopy: true,
                        ),
                        _buildBankRowLeft(
                          "Chủ tài khoản",
                          widget.bankAccountName ?? "N/A",
                        ),
                        _buildBankRowLeft(
                          "Nội dung CK",
                          widget.paymentDescription ?? "N/A",
                          isGreen: true,
                          canCopy: true,
                        ),
                      ],
                    ),
                  ),

                if (_isExpired)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Mã QR đã hết hiệu lực. Vui lòng quay lại để tạo đơn mới.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 100),
              ],
            ),
          ),

          // --- BOTTOM BUTTONS ---
          if (!_isPaid && !_isExpired)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AppBottomButtons(
                onCancel: _simulatePayment,
                onConfirm: _openCheckoutUrl,
                cancelText: "GIẢ LẬP T.TOÁN",
                confirmText: "CK NGÂN HÀNG",
                showCancel: TestToolConfig.paymentSimulationEnabled,
              ),
            ),

          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFlatInfoRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF263238),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 0.5, color: Colors.grey[200]),
      ],
    );
  }

  Widget _buildBankRowLeft(
    String label,
    String value, {
    bool isGreen = false,
    bool canCopy = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: canCopy
            ? () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Đã sao chép")));
              }
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canCopy) ...[
                    const Icon(Icons.copy, size: 14, color: Colors.black26),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isGreen
                            ? const Color(0xFF00B050)
                            : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCheckoutUrl() async {
    if (widget.checkoutUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Chưa có link thanh toán.")));
      return;
    }
    final Uri url = Uri.parse(widget.checkoutUrl);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Không thể mở url: $e');
    }
  }

  Future<void> _simulatePayment() async {
    setState(() => _isLoading = true);
    final result = await DepositService.simulateDepositPayment(
      widget.depositId,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['status'] == 'success') {
      _handlePaymentSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Lỗi giả lập')),
      );
    }
  }
}
