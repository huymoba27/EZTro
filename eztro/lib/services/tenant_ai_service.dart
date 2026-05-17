import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'invoice_service.dart';
import 'contract_service.dart';
import 'incident_service.dart';
import 'post_service.dart';
import 'auth_service.dart';

/// AI Service dành riêng cho khách thuê / khách vãng lai.
/// - Khách đã đăng nhập (tenant): xem hóa đơn, hợp đồng, báo sự cố.
/// - Khách vãng lai (chưa đăng nhập): tìm phòng, xem giá, xem tin đăng.
class TenantAiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _model = 'gemini-3.1-flash-lite-preview';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  // ============================================================
  // FUNCTION TOOLS CHO TENANT / KHÁCH VÃNG LAI
  // ============================================================
  static final List<Map<String, dynamic>> _tools = [
    {
      "function_declarations": [
        {
          "name": "get_posted_rooms",
          "description":
              "Tim phong cho thue. Lay danh sach cac phong da duoc dang bai cong khai. Ai cung xem duoc.",
          "parameters": {"type": "OBJECT", "properties": {}},
        },
        {
          "name": "get_my_invoices",
          "description":
              "Xem hóa đơn của khách thuê đang đăng nhập. Yêu cầu đăng nhập.",
          "parameters": {"type": "OBJECT", "properties": {}},
        },
        {
          "name": "get_my_contract",
          "description":
              "Xem hop dong thue, dia chi nha tro, thong tin lien he chu tro, dich vu phong. Dung khi hoi ve dia chi, vi tri, lien he, dich vu, hop dong. Yeu cau dang nhap.",
          "parameters": {"type": "OBJECT", "properties": {}},
        },
        {
          "name": "get_my_incidents",
          "description":
              "Xem danh sách sự cố đã báo cáo của khách thuê. Yêu cầu đăng nhập.",
          "parameters": {"type": "OBJECT", "properties": {}},
        },
      ],
    },
  ];

  // ============================================================
  // SYSTEM INSTRUCTION
  // ============================================================
  static const String _baseSystemInstruction = """
Trợ lý AI EZTro cho khách thuê/khách tìm phòng. Trả lời tiếng Việt, ngắn gọn, không emoji.
Dùng function call lấy dữ liệu thực, không bịa. Format tiền: dấu chấm nghìn + VNĐ.
CHỈ hỗ trợ: tìm phòng, xem giá, hóa đơn, hợp đồng, sự cố, tư vấn thuê trọ.
Nếu câu hỏi KHÔNG liên quan, từ chối lịch sự.
Nếu khách chưa đăng nhập hỏi về hóa đơn/hợp đồng, nhắc họ đăng nhập trước.
Hướng dẫn sử dụng function:
- Khi hỏi về địa chỉ, vị trí, liên hệ chủ trọ, dịch vụ phòng → gọi get_my_contract (có đầy đủ thông tin).
- Khi hỏi về tiền, hóa đơn, thanh toán → gọi get_my_invoices.
- Khi hỏi về phòng trống, tìm phòng, giá thuê → gọi get_posted_rooms.
- Khi hỏi về sự cố, hư hỏng → gọi get_my_incidents.
""";

  static Future<String> _buildSystemInstruction() async {
    String ctx = '';
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        ctx = '\nUser: ${user.fullName} (Khách thuê)';
        if (user.isRenting && user.roomId != null) {
          ctx += '. Đang thuê phòng ID:${user.roomId}.';
        } else {
          ctx += '. Chưa thuê phòng (đang tìm).';
        }
      } else {
        ctx = '\nKhách vãng lai (chưa đăng nhập). Chỉ xem phòng trống và tin đăng.';
      }
    } catch (_) {}
    return _baseSystemInstruction + ctx;
  }

  // ============================================================
  // THỰC THI FUNCTION CALL
  // ============================================================
  static Future<Map<String, dynamic>> _executeFunction(
    String functionName,
    Map<String, dynamic> args,
  ) async {
    developer.log('Tenant executing: $functionName', name: 'TenantAi');

    List<T> limitList<T>(List<T> list, [int max = 10]) =>
        list.length > max ? list.sublist(0, max) : list;

    try {
      switch (functionName) {
        case 'get_posted_rooms':
          final posts = await PostService.getPosts();
          return {
            "total": posts.length,
            "posts": limitList(posts)
                .map((p) => {
                      "title": p.title,
                      "price": p.priceDisplay ?? p.originalPrice ?? "Liên hệ",
                      "address":
                          [p.addressDetail, p.ward, p.city]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(", "),
                      "area": p.area ?? "N/A",
                    })
                .toList(),
          };

        case 'get_my_invoices':
          final user = await AuthService.getCurrentUser();
          if (user == null) return {"error": "Vui lòng đăng nhập để xem hóa đơn."};
          final invoices = await InvoiceService.getInvoices();
          return {
            "total": invoices.length,
            "invoices": limitList(invoices)
                .map((inv) => {
                      "room_name": inv.roomName,
                      "month": "${inv.billingMonth}/${inv.billingYear}",
                      "total": inv.totalAmount,
                      "status": inv.status == 'paid' ? 'Đã thanh toán' : 'Chưa thanh toán',
                    })
                .toList(),
          };

        case 'get_my_contract':
          final user = await AuthService.getCurrentUser();
          if (user == null) return {"error": "Vui lòng đăng nhập để xem hợp đồng."};
          final contracts = await ContractService.getContracts();
          final active = contracts.where((c) => c.status == 'active').toList();
          if (active.isEmpty) return {"message": "Bạn chưa có hợp đồng nào đang hiệu lực."};
          final c = active.first;
          // Build địa chỉ đầy đủ
          final address = [c.addressDetail, c.ward, c.city]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
          // Build danh sách dịch vụ
          final serviceList = c.services?.map((s) => "${s.serviceName}: ${s.price} VNĐ/${s.unit}").toList() ?? [];
          return {
            "room_name": c.roomName,
            "house_name": c.houseName ?? "N/A",
            "address": address.isNotEmpty ? address : "Chưa cập nhật",
            "owner_name": c.ownerName ?? "N/A",
            "owner_phone": c.ownerPhone ?? "N/A",
            "start_date": c.startDate,
            "end_date": c.endDate,
            "rent_price": c.rentPrice,
            "deposit": c.depositAmount,
            "payment_day": c.paymentDay,
            "services": serviceList,
            "status": "Đang hiệu lực",
          };

        case 'get_my_incidents':
          final user = await AuthService.getCurrentUser();
          if (user == null) return {"error": "Vui lòng đăng nhập để xem sự cố."};
          final incidents = await IncidentService.getMyIncidents(userId: user.id, role: user.role);
          return {
            "total": incidents.length,
            "incidents": limitList(incidents)
                .map((inc) => {
                      "title": inc.title,
                      "status": inc.status,
                      "room_name": inc.roomName,
                      "created_at": inc.createdAt.toIso8601String(),
                    })
                .toList(),
          };

        default:
          return {"error": "Function không tồn tại"};
      }
    } catch (e) {
      developer.log('Function error: $e', name: 'TenantAi');
      return {"error": "Lỗi: $e"};
    }
  }

  // ============================================================
  // HÀM CHÍNH
  // ============================================================
  static Future<String> getResponse(
    String message, {
    List<dynamic>? history,
  }) async {
    if (_apiKey.isEmpty) return "Chưa cấu hình API Key.";

    final systemInstruction = await _buildSystemInstruction();

    try {
      List<Map<String, dynamic>> contents = [];
      if (history != null && history.isNotEmpty) {
        final trimmed =
            history.length > 6 ? history.sublist(history.length - 6) : history;
        for (var item in trimmed) {
          contents.add(item as Map<String, dynamic>);
        }
      }

      contents.add({
        "role": "user",
        "parts": [{"text": message}],
      });

      final responseData = await _callGeminiApi(contents, systemInstruction);
      if (responseData == null) return "Lỗi kết nối. Vui lòng thử lại.";

      final candidates = responseData['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return "Không có câu trả lời.";

      final parts = candidates[0]['content']['parts'] as List;
      final functionCallPart = parts.firstWhere(
        (p) => p.containsKey('functionCall'),
        orElse: () => null,
      );

      if (functionCallPart != null) {
        final fc = functionCallPart['functionCall'];
        final fnName = fc['name'] as String;
        final fnArgs = (fc['args'] as Map<String, dynamic>?) ?? {};

        final result = await _executeFunction(fnName, fnArgs);

        final fcContents = [
          {"role": "user", "parts": [{"text": message}]},
          {"role": "model", "parts": [functionCallPart]},
          {
            "role": "user",
            "parts": [
              {"functionResponse": {"name": fnName, "response": result}},
            ],
          },
        ];

        final finalResponse = await _callGeminiApi(fcContents, systemInstruction);
        if (finalResponse == null) {
          return _formatFallback(fnName, result);
        }

        final fc2 = finalResponse['candidates'] as List?;
        if (fc2 != null && fc2.isNotEmpty) {
          final fp = fc2[0]['content']['parts'] as List;
          final tp = fp.firstWhere(
            (p) => p.containsKey('text'),
            orElse: () => {'text': 'Không có câu trả lời.'},
          );
          return tp['text'] ?? "Không có câu trả lời.";
        }
      }

      final textPart = parts.firstWhere(
        (p) => p.containsKey('text'),
        orElse: () => {'text': 'Không có câu trả lời.'},
      );
      return textPart['text'] ?? "Không có câu trả lời.";
    } catch (e) {
      developer.log('TenantAi error: $e', name: 'TenantAi');
      return "Đã xảy ra lỗi. Vui lòng thử lại.";
    }
  }

  // ============================================================
  // GỌI GEMINI API
  // ============================================================
  static Future<Map<String, dynamic>?> _callGeminiApi(
    List<Map<String, dynamic>> contents,
    String systemInstruction,
  ) async {
    try {
      final body = {
        "contents": contents,
        "tools": _tools,
        "system_instruction": {
          "parts": [{"text": systemInstruction}],
        },
        "generationConfig": {"maxOutputTokens": 1024},
      };

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      developer.log('API error ${response.statusCode}', name: 'TenantAi');
      return null;
    } catch (e) {
      developer.log('API call error: $e', name: 'TenantAi');
      return null;
    }
  }

  // ============================================================
  // FALLBACK
  // ============================================================
  static String _formatFallback(String fnName, Map<String, dynamic> data) {
    if (data.containsKey('error')) return data['error'];
    if (data.containsKey('message')) return data['message'];

    switch (fnName) {
      case 'get_posted_rooms':
        final posts = data['posts'] as List? ?? [];
        if (posts.isEmpty) return "Hiện tại chưa có phòng nào được đăng cho thuê.";
        String result = "**Phòng cho thuê** (${data['total']} tin):\n";
        for (var p in posts) {
          result += "- ${p['title']} - ${p['price']}\n";
        }
        return result;
      default:
        return "Du lieu:\n```\n${jsonEncode(data)}\n```";
    }
  }
}
