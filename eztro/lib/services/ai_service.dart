import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'house_service.dart';
import 'room_service.dart';
import 'tenant_service.dart';
import 'invoice_service.dart';
import 'contract_service.dart';
import 'statistics_service.dart';
import 'incident_service.dart';
import 'auth_service.dart';

class AiAssistantService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // Model hiện tại: gemini-3.1-flash-lite-preview
  // Các model khả dụng: gemini-3.1-flash-lite-preview, gemini-3.1-pro-preview, gemini-2.5-flash, gemini-2.5-pro
  static const String _model = 'gemini-3.1-flash-lite-preview';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  // ============================================================
  // ĐỊNH NGHĨA CÁC FUNCTION TOOLS CHO GEMINI
  // ============================================================
  static final List<Map<String, dynamic>> _tools = [
    {
      "function_declarations": [
        {
          "name": "get_houses",
          "description":
              "Lấy danh sách tất cả nhà trọ của chủ trọ. Trả về tên nhà, địa chỉ, số phòng.",
          "parameters": {"type": "OBJECT", "properties": {}},
        },
        {
          "name": "get_all_rooms",
          "description":
              "Lấy danh sách tất cả phòng trọ. Có thể lọc theo nhà cụ thể bằng house_id. Trả về tên phòng, giá thuê, diện tích, trạng thái (trống/có người).",
          "parameters": {
            "type": "OBJECT",
            "properties": {
              "house_id": {
                "type": "INTEGER",
                "description":
                    "ID nhà trọ để lọc phòng. Để 0 hoặc bỏ qua để lấy tất cả.",
              },
            },
          },
        },
        {
          "name": "get_available_rooms",
          "description":
              "Lấy danh sách các phòng trống (chưa có người thuê), sẵn sàng cho thuê.",
          "parameters": {"type": "OBJECT", "properties": {}},
        },
        {
          "name": "get_occupied_rooms",
          "description":
              "Lấy danh sách các phòng đã có người thuê đang ở.",
          "parameters": {"type": "OBJECT", "properties": {}},
        },
        {
          "name": "get_all_tenants",
          "description":
              "Lấy danh sách tất cả khách thuê/người ở trọ. Trả về tên, số điện thoại, phòng đang ở.",
          "parameters": {"type": "OBJECT", "properties": {}},
        },
        {
          "name": "get_invoices",
          "description":
              "Lấy danh sách hóa đơn tiền trọ. Có thể lọc theo nhà. Trả về phòng, số tiền, trạng thái thanh toán.",
          "parameters": {
            "type": "OBJECT",
            "properties": {
              "house_id": {
                "type": "INTEGER",
                "description":
                    "ID nhà trọ để lọc hóa đơn. Để 0 để lấy tất cả.",
              },
            },
          },
        },
        {
          "name": "get_contracts",
          "description":
              "Lấy danh sách hợp đồng thuê trọ. Trả về phòng, khách thuê, giá thuê, ngày bắt đầu/kết thúc.",
          "parameters": {
            "type": "OBJECT",
            "properties": {
              "house_id": {
                "type": "INTEGER",
                "description":
                    "ID nhà trọ để lọc hợp đồng. Để 0 để lấy tất cả.",
              },
            },
          },
        },
        {
          "name": "get_statistics",
          "description":
              "Lấy thống kê tổng quan: tổng nhà, tổng phòng, phòng có người, doanh thu, chi phí, lợi nhuận theo năm.",
          "parameters": {
            "type": "OBJECT",
            "properties": {
              "year": {
                "type": "INTEGER",
                "description":
                    "Năm cần thống kê. Mặc định là năm hiện tại.",
              },
            },
          },
        },
        {
          "name": "get_incidents",
          "description":
              "Lấy danh sách sự cố/vấn đề được báo cáo bởi khách thuê (hỏng đồ, rò rỉ nước, mất điện...).",
          "parameters": {"type": "OBJECT", "properties": {}},
        },
      ],
    },
  ];

  // ============================================================
  // SYSTEM INSTRUCTION (ngắn gọn để tiết kiệm token)
  // ============================================================
  static const String _baseSystemInstruction = """
Trợ lý AI EZTro, CHỈ hỗ trợ quản lý nhà trọ. Trả lời tiếng Việt, ngắn gọn, không emoji.
Dùng function call lấy dữ liệu thực, không bịa. Format tiền: dấu chấm nghìn + VNĐ.
CHỈ trả lời các chủ đề: phòng trọ, khách thuê, hóa đơn, hợp đồng, thống kê, sự cố, tư vấn kinh doanh nhà trọ, luật cho thuê.
Nếu câu hỏi KHÔNG liên quan nhà trọ (toán, lập trình, thời tiết, giải trí...), từ chối lịch sự: "Xin lỗi, tôi chỉ hỗ trợ các vấn đề liên quan đến quản lý nhà trọ. Bạn có thể hỏi tôi về phòng, khách thuê, hóa đơn hoặc thống kê."
""";

  /// Tạo system instruction kèm context user (đã tối ưu)
  static Future<String> _buildSystemInstruction() async {
    String ctx = '';
    try {
      final user = await AuthService.getCurrentUser();
      if (user != null) {
        ctx = '\nUser: ${user.fullName} (${_getRoleLabel(user.role)})';
        if (user.role == 'manager' && user.managedHouseId != null) {
          ctx += '. Chỉ xem nhà ID:${user.managedHouseId}.';
        }
      }
    } catch (_) {}
    return _baseSystemInstruction + ctx;
  }

  static String _getRoleLabel(String role) {
    switch (role) {
      case 'landlord': return 'Chủ trọ';
      case 'manager': return 'Quản lý';
      case 'tenant': return 'Khách thuê';
      default: return role;
    }
  }

  // ============================================================
  // XỬ LÝ FUNCTION CALL - Gọi service thực
  // ============================================================
  static Future<Map<String, dynamic>> _executeFunction(
    String functionName,
    Map<String, dynamic> args,
  ) async {
    developer.log('Executing function: $functionName($args)', name: 'AiService');

    // Giới hạn số lượng items trả về để tiết kiệm token
    List<T> limitList<T>(List<T> list, [int max = 10]) =>
        list.length > max ? list.sublist(0, max) : list;

    try {
      switch (functionName) {
        case 'get_houses':
          final houses = await HouseService.getHouses();
          return {
            "total": houses.length,
            "houses": limitList(houses)
                .map((h) => {
                      "id": h.id,
                      "name": h.houseName,
                      "address": h.fullAddress,
                      "total_rooms": h.totalRooms,
                      "occupied_rooms": h.totalRooms - h.totalEmptyRooms,
                      "empty_rooms": h.totalEmptyRooms,
                    })
                .toList(),
          };

        case 'get_all_rooms':
          final houseId = args['house_id'] as int? ?? 0;
          final rooms = await RoomService.getRooms(houseId: houseId);
          return {
            "total": rooms.length,
            "rooms": limitList(rooms)
                .map((r) => {
                      "id": r.id,
                      "room_name": r.roomName,
                      "house_name": r.houseName ?? "N/A",
                      "price": r.price,
                      "area": r.area,
                      "status": r.statusText,
                      "tenant_name": r.customerName ?? "Trống",
                      "max_tenants": r.maxTenants,
                    })
                .toList(),
          };

        case 'get_available_rooms':
          final rooms = await RoomService.getAvailableRooms();
          return {
            "total": rooms.length,
            "rooms": limitList(rooms)
                .map((r) => {
                      "id": r.id,
                      "room_name": r.roomName,
                      "house_name": r.houseName ?? "N/A",
                      "price": r.price,
                      "area": r.area,
                    })
                .toList(),
          };

        case 'get_occupied_rooms':
          final rooms = await RoomService.getOccupiedRooms();
          return {
            "total": rooms.length,
            "rooms": limitList(rooms)
                .map((r) => {
                      "id": r.id,
                      "room_name": r.roomName,
                      "house_name": r.houseName ?? "N/A",
                      "price": r.price,
                      "tenant_name": r.customerName ?? "N/A",
                    })
                .toList(),
          };

        case 'get_all_tenants':
          final tenants = await TenantService.getAllTenants();
          return {
            "total": tenants.length,
            "tenants": limitList(tenants)
                .map((t) => {
                      "id": t.id,
                      "name": t.tenantName,
                      "phone": t.phone,
                      "room_name": t.roomName ?? "N/A",
                      "house_name": t.houseName ?? "N/A",
                      "gender": t.gender,
                    })
                .toList(),
          };

        case 'get_invoices':
          final houseId = args['house_id'] as int? ?? 0;
          final invoices = await InvoiceService.getInvoices(houseId: houseId);
          return {
            "total": invoices.length,
            "invoices": limitList(invoices)
                .map((inv) => {
                      "id": inv.id,
                      "room_name": inv.roomName,
                      "house_name": inv.houseName ?? "N/A",
                      "total_amount": inv.totalAmount,
                      "status": inv.status,
                      "billing_month": inv.billingMonth,
                      "billing_year": inv.billingYear,
                    })
                .toList(),
          };

        case 'get_contracts':
          final houseId = args['house_id'] as int? ?? 0;
          final contracts = await ContractService.getContracts(houseId: houseId);
          return {
            "total": contracts.length,
            "contracts": limitList(contracts)
                .map((c) => {
                      "id": c.id,
                      "room_name": c.roomName,
                      "tenant_name": c.tenantName,
                      "rent_price": c.rentPrice,
                      "start_date": c.startDate,
                      "end_date": c.endDate,
                    })
                .toList(),
          };

        case 'get_statistics':
          final year = args['year'] as int? ?? DateTime.now().year;
          final stats = await StatisticsService.getStatsSummary(year: year);
          return {
            "year": year,
            "total_houses": stats.summary.totalHouses,
            "total_rooms": stats.summary.totalRooms,
            "occupied_rooms": stats.summary.occupiedRooms,
            "vacant_rooms": stats.summary.totalRooms - stats.summary.occupiedRooms,
            "occupancy_rate": stats.summary.totalRooms > 0
                ? ((stats.summary.occupiedRooms / stats.summary.totalRooms) * 100)
                    .toStringAsFixed(1)
                : "0",
            "total_revenue": stats.summary.totalRevenue,
            "total_expense": stats.summary.totalExpense,
            "net_profit": stats.summary.netProfit,
            "revenue_by_month": stats.revenueChart,
            "expense_by_month": stats.expenseChart,
          };

        case 'get_incidents':
          final user = await AuthService.getCurrentUser();
          if (user != null) {
            final incidents = await IncidentService.getAllIncidents(
              userId: user.id,
              role: user.role,
            );
            return {
              "total": incidents.length,
              "incidents": limitList(incidents)
                  .map((inc) => {
                        "id": inc.id,
                        "title": inc.title,
                        "description": inc.description,
                        "status": inc.status,
                        "room_name": inc.roomName,
                        "reporter": inc.tenantName ?? "N/A",
                        "created_at": inc.createdAt.toIso8601String(),
                      })
                  .toList(),
            };
          }
          return {"total": 0, "incidents": [], "message": "Chưa đăng nhập"};

        default:
          return {"error": "Function không tồn tại: $functionName"};
      }
    } catch (e) {
      developer.log('Function execution error: $e', name: 'AiService');
      return {"error": "Lỗi khi thực thi: $e"};
    }
  }

  // ============================================================
  // HÀM CHÍNH: GỬI TIN NHẮN VỚI FUNCTION CALLING
  // ============================================================
  static Future<String> getResponse(
    String message, {
    List<dynamic>? history,
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY') {
      return "**Thông báo hệ thống:** Vui lòng cấu hình API Key của Google Gemini trong file ai_service.dart để bắt đầu trò chuyện với trợ lý AI.";
    }

    // Lấy system instruction kèm context user
    final systemInstruction = await _buildSystemInstruction();

    try {
      // Chỉ giữ 6 tin nhắn gần nhất (3 lượt hỏi-đáp) để tiết kiệm token
      List<Map<String, dynamic>> contents = [];
      if (history != null && history.isNotEmpty) {
        final trimmed = history.length > 6
            ? history.sublist(history.length - 6)
            : history;
        for (var item in trimmed) {
          contents.add(item as Map<String, dynamic>);
        }
      }

      // Thêm tin nhắn hiện tại
      contents.add({
        "role": "user",
        "parts": [
          {"text": message},
        ],
      });

      // Gọi API lần 1 — Gemini sẽ quyết định có cần gọi function không
      final responseData = await _callGeminiApi(contents, systemInstruction);
      if (responseData == null) return "Lỗi kết nối với AI. Vui lòng thử lại.";

      // Kiểm tra xem Gemini có yêu cầu gọi function không
      final candidates = responseData['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return "Không có câu trả lời.";
      }

      final parts = candidates[0]['content']['parts'] as List;

      // Tìm function call trong response
      final functionCallPart = parts.firstWhere(
        (p) => p.containsKey('functionCall'),
        orElse: () => null,
      );

      if (functionCallPart != null) {
        // Gemini muốn gọi function → thực thi function
        final functionCall = functionCallPart['functionCall'];
        final functionName = functionCall['name'] as String;
        final functionArgs =
            (functionCall['args'] as Map<String, dynamic>?) ?? {};

        developer.log(
          'Gemini requested function: $functionName',
          name: 'AiService',
        );

        // Thực thi function (gọi service thực)
        final functionResult = await _executeFunction(functionName, functionArgs);

        // Thêm response của model (chứa function call) vào contents
        contents.add({
          "role": "model",
          "parts": [functionCallPart],
        });

        // Thêm kết quả function vào contents
        contents.add({
          "role": "user",
          "parts": [
            {
              "functionResponse": {
                "name": functionName,
                "response": functionResult,
              },
            },
          ],
        });

        // Gọi API lần 2 — chỉ gửi function call + result, bỏ history để tiết kiệm token
        final fcContents = [
          {"role": "user", "parts": [{"text": message}]},
          {"role": "model", "parts": [functionCallPart]},
          {
            "role": "user",
            "parts": [
              {
                "functionResponse": {
                  "name": functionName,
                  "response": functionResult,
                },
              },
            ],
          },
        ];
        final finalResponse = await _callGeminiApi(fcContents, systemInstruction);
        if (finalResponse == null) {
          // Fallback: trả về dữ liệu thô nếu API lỗi lần 2
          return _formatFallbackResponse(functionName, functionResult);
        }

        final finalCandidates = finalResponse['candidates'] as List?;
        if (finalCandidates != null && finalCandidates.isNotEmpty) {
          final finalParts = finalCandidates[0]['content']['parts'] as List;
          final textPart = finalParts.firstWhere(
            (p) => p.containsKey('text'),
            orElse: () => {'text': 'Không có câu trả lời.'},
          );
          return textPart['text'] ?? "Không có câu trả lời.";
        }
      }

      // Không có function call → trả về text bình thường
      final textPart = parts.firstWhere(
        (p) => p.containsKey('text'),
        orElse: () => {'text': 'Không có câu trả lời.'},
      );
      return textPart['text'] ?? "Không có câu trả lời.";

    } catch (e) {
      developer.log('AI Exception: $e', name: 'AiService');
      return "Đã xảy ra lỗi: $e";
    }
  }

  // ============================================================
  // GỌI GEMINI API (Dùng chung cho cả 2 lần gọi)
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
          "parts": [
            {"text": systemInstruction},
          ],
        },
        "generationConfig": {
          "maxOutputTokens": 1024,
        },
      };

      developer.log('Calling Gemini API...', name: 'AiService');

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      developer.log(
        'API Response status: ${response.statusCode}',
        name: 'AiService',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 403) {
        developer.log('API Error 403: ${response.body}', name: 'AiService');
        return {
          "candidates": [
            {
              "content": {
                "parts": [
                  {
                    "text":
                        "**API Key không hợp lệ hoặc đã hết hạn.** Vui lòng kiểm tra lại API Key trong Google AI Studio."
                  }
                ]
              }
            }
          ]
        };
      } else if (response.statusCode == 429) {
        return {
          "candidates": [
            {
              "content": {
                "parts": [
                  {
                    "text":
                        "Bạn đã gửi quá nhiều tin nhắn. Vui lòng đợi 30 giây rồi thử lại."
                  }
                ]
              }
            }
          ]
        };
      } else {
        developer.log(
          'API Error ${response.statusCode}: ${response.body}',
          name: 'AiService',
        );
        return null;
      }
    } catch (e) {
      developer.log('API call error: $e', name: 'AiService');
      return null;
    }
  }

  // ============================================================
  // FALLBACK: Format dữ liệu thô khi API lần 2 lỗi
  // ============================================================
  static String _formatFallbackResponse(
    String functionName,
    Map<String, dynamic> data,
  ) {
    final formatter = NumberFormat('#,###', 'vi_VN');

    switch (functionName) {
      case 'get_houses':
        final houses = data['houses'] as List? ?? [];
        if (houses.isEmpty) return "Bạn chưa có nhà trọ nào.";
        String result = "**Danh sách nhà trọ** (${houses.length} nhà):\n\n";
        for (var h in houses) {
          result +=
              "- **${h['name']}** — ${h['address']}\n  ${h['occupied_rooms']}/${h['total_rooms']} phòng có người\n\n";
        }
        return result;

      case 'get_all_rooms':
      case 'get_available_rooms':
      case 'get_occupied_rooms':
        final rooms = data['rooms'] as List? ?? [];
        if (rooms.isEmpty) return "Không có phòng nào.";
        String result = "**Danh sách phòng** (${rooms.length} phòng):\n\n";
        for (var r in rooms) {
          result +=
              "- **${r['room_name']}** (${r['house_name']}) — ${formatter.format(r['price'])} VNĐ\n";
        }
        return result;

      case 'get_statistics':
        return "**Thống kê năm ${data['year']}:**\n"
            "- Nhà: ${data['total_houses']}\n"
            "- Phòng: ${data['occupied_rooms']}/${data['total_rooms']} có người (${data['occupancy_rate']}%)\n"
            "- Doanh thu: ${formatter.format(data['total_revenue'])} VNĐ\n"
            "- Chi phí: ${formatter.format(data['total_expense'])} VNĐ\n"
            "- Lợi nhuận: ${formatter.format(data['net_profit'])} VNĐ";

      default:
        return "Dữ liệu:\n```\n${jsonEncode(data)}\n```";
    }
  }
}
