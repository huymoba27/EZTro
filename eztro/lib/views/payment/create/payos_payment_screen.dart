import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/api_constants.dart';
import '../../../services/auth_service.dart';
import '../../../services/invoice_service.dart';
import '../../../models/invoice_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/test_tools/test_tool_config.dart';
import 'package:eztro/core/widgets/widgets.dart';
import '../../../core/utils/format_helper.dart';
import '../../../core/utils/dialog_helper.dart';

class PayOSPaymentScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const PayOSPaymentScreen({super.key, required this.invoice});

  @override
  State<PayOSPaymentScreen> createState() => _PayOSPaymentScreenState();
}

class _PayOSPaymentScreenState extends State<PayOSPaymentScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _checkoutUrl;
  String? _qrData;
  String? _bankBin;
  String? _bankAccountNumber;
  String? _bankAccountName;
  String? _paymentDescription;
  Timer? _pollTimer;
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    _createPaymentLink();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || _isPaid) return;

      final result = await InvoiceService.checkInvoiceStatus(widget.invoice.id);
      if (result['status'] == 'success' && result['invoice_status'] == 'paid') {
        setState(() => _isPaid = true);
        timer.cancel();
        _showSuccessDialog();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _createPaymentLink() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.getCurrentUser();
      final response = await http
          .post(
            Uri.parse('${ApiConstants.payment}/create_payos_payment.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'invoice_id': widget.invoice.id,
              'user_id': user?.id ?? 0,
              'role': user?.role ?? 'tenant',
              'managed_house_id': user?.managedHouseId ?? 0,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        if (mounted) {
          setState(() {
            _checkoutUrl = data['checkoutUrl'];
            _qrData = data['qrCode'];
            _bankBin = data['bank_bin'];
            _bankAccountNumber = data['bank_account_number'];
            _bankAccountName = data['bank_account_name'];
            _paymentDescription = data['payment_description'];
            _isLoading = false;
          });
        }
      } else {
        throw Exception(data['message'] ?? 'Lỗi tạo liên kết thanh toán');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              "Không thể kết nối dịch vụ thanh toán. Vui lòng thử lại.";
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    DialogHelper.showSuccess(
      context,
      'Hóa đơn #${widget.invoice.id} đã được thanh toán và cập nhật vào hệ thống.',
      onTap: () {
        Navigator.pop(context, true);
      },
    );
  }

  Future<void> _simulateSuccess() async {
    setState(() => _isLoading = true);
    final res = await InvoiceService.updateInvoiceStatus(
      widget.invoice.id,
      'paid',
    );
    setState(() => _isLoading = false);
    if (res['status'] == 'success') {
      setState(() => _isPaid = true);
      _showSuccessDialog();
    }
  }

  void _openCheckoutUrl() async {
    if (_checkoutUrl == null) return;
    final Uri url = Uri.parse(_checkoutUrl!);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

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
    if (_isLoading) return _buildLoadingView();
    if (_errorMessage != null) return _buildErrorView();

    Color statusColor = _isPaid ? const Color(0xFF2E7D32) : Colors.orange;
    Color statusBg = _isPaid
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFF3E0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          "THANH TOÁN HÓA ĐƠN",
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
                        _isPaid ? "ĐÃ THANH TOÁN" : "CHỜ THANH TOÁN",
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        CurrencyHelper.formatVND(widget.invoice.totalAmount),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Hóa đơn tháng ${widget.invoice.billingMonth}/${widget.invoice.billingYear} - Phòng ${widget.invoice.roomName}",
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
                  title: "Thông tin hóa đơn",
                  child: Column(
                    children: [
                      _buildFlatInfoRow("Mã hóa đơn", "#${widget.invoice.id}"),
                      _buildFlatInfoRow(
                        "Ngày lập",
                        widget.invoice.createdAt.split(' ')[0],
                      ),
                      _buildFlatInfoRow(
                        "Loại phí",
                        "Tiền phòng & Dịch vụ",
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                Container(height: 8, color: const Color(0xFFF2F2F7)),

                // --- QR SECTION ---
                if (!_isPaid)
                  AppSectionCard(
                    title: "Quét mã QR để thanh toán",
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
                            child: _qrData != null
                                ? QrImageView(
                                    data: _qrData!,
                                    version: QrVersions.auto,
                                    size: 220,
                                    gapless: false,
                                  )
                                : const SizedBox(
                                    height: 220,
                                    width: 220,
                                    child: Center(
                                      child: Text("Mã QR đang được tạo..."),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
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

                if (!_isPaid)
                  Container(height: 8, color: const Color(0xFFF2F2F7)),

                // --- BANK SECTION ---
                if (!_isPaid && _bankAccountNumber != null)
                  AppSectionCard(
                    title: "Chuyển khoản nhanh",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBankRowLeft("Ngân hàng", _getBankName(_bankBin)),
                        _buildBankRowLeft(
                          "Số tài khoản",
                          _bankAccountNumber!,
                          isGreen: true,
                          canCopy: true,
                        ),
                        _buildBankRowLeft(
                          "Chủ tài khoản",
                          _bankAccountName ?? "N/A",
                        ),
                        _buildBankRowLeft(
                          "Nội dung CK",
                          _paymentDescription ?? "N/A",
                          isGreen: true,
                          canCopy: true,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 120),
              ],
            ),
          ),

          // --- BOTTOM BUTTONS ---
          if (!_isPaid)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AppBottomButtons(
                onCancel: _simulateSuccess,
                onConfirm: _openCheckoutUrl,
                cancelText: "GIẢ LẬP T.TOÁN",
                confirmText: "MỞ NGÂN HÀNG",
                showCancel: TestToolConfig.paymentSimulationEnabled,
              ),
            ),
        ],
      ),
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

  Widget _buildLoadingView() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 20),
            const Text(
              "Đang khởi tạo thanh toán...",
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _createPaymentLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  "Thử lại",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
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
}
