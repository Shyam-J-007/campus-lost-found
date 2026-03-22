import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
static const String baseUrl = 'https://campus-lost-found-production-1d75.up.railway.app/';
  // ── Upload image (mobile) ─────────────────────────────────
  static Future<String?> uploadImage(String imagePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-image'),
      );

      final ext = imagePath.split('.').last.toLowerCase();
      final mediaType = ext == 'png'
          ? MediaType('image', 'png')
          : MediaType('image', 'jpeg');

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imagePath,
        contentType: mediaType,
      ));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);

      if (data.containsKey('url')) {
        return '$baseUrl${data['url']}';
      }
      return null;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  // ── Upload image (web) ────────────────────────────────────
  static Future<String?> uploadImageWeb(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-image'),
      );

      request.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imageFile.name,
        contentType:
            MediaType('image', imageFile.name.split('.').last),
      ));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);

      if (data.containsKey('url')) {
        return '$baseUrl${data['url']}';
      }
      return null;
    } catch (e) {
      print('Web upload error: $e');
      return null;
    }
  }

  // ── Register ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String studentId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'student_id': studentId,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Could not connect to server: $e'};
    }
  }

  // ── Login ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Could not connect to server: $e'};
    }
  }

  // ── Report lost item ──────────────────────────────────────
  static Future<Map<String, dynamic>> reportLostItem({
    required int userId,
    required String itemName,
    required String description,
    required String location,
    required String date,
    String? imageUrl,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/lost-item'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'item_name': itemName,
              'description': description,
              'location': location,
              'date': date,
              'image_url': imageUrl,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Could not connect to server: $e'};
    }
  }

  // ── Report found item ─────────────────────────────────────
  static Future<Map<String, dynamic>> reportFoundItem({
    required int userId,
    required String itemName,
    required String description,
    required String location,
    required String date,
    String? imageUrl,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/found-item'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'item_name': itemName,
              'description': description,
              'location': location,
              'date': date,
              'image_url': imageUrl,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Could not connect to server: $e'};
    }
  }

  // ── Search items (lost or found) ──────────────────────────
  static Future<List<dynamic>> searchItems(
    String query, {
    String type = 'lost',
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/search?q=$query&type=$type'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return [];
    }
  }

  // ── Check matches for user ────────────────────────────────
  static Future<List<dynamic>> checkMatches(int userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/check-matches/$userId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return [];
    }
  }

  // ── Get conversations ─────────────────────────────────────
static Future<List<dynamic>> getConversations(int userId) async {
  try {
    final response = await http
        .get(Uri.parse('$baseUrl/conversations/$userId'))
        .timeout(const Duration(seconds: 10));
    return jsonDecode(response.body);
  } catch (e) {
    return [];
  }
}

// ── Get messages between two users ────────────────────────
static Future<List<dynamic>> getMessages(
    int userId, int otherId) async {
  try {
    final response = await http
        .get(Uri.parse('$baseUrl/messages/$userId/$otherId'))
        .timeout(const Duration(seconds: 10));
    return jsonDecode(response.body);
  } catch (e) {
    return [];
  }
}

// ── Send message ──────────────────────────────────────────
static Future<Map<String, dynamic>> sendMessage({
  required int senderId,
  required int receiverId,
  required String message,
  String matchItemName = '',
}) async {
  try {
    final response = await http
        .post(
          Uri.parse('$baseUrl/send-message'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sender_id': senderId,
            'receiver_id': receiverId,
            'message': message,
            'match_item_name': matchItemName,
          }),
        )
        .timeout(const Duration(seconds: 10));
    return jsonDecode(response.body);
  } catch (e) {
    return {'error': 'Could not send message: $e'};
  }
}

// ── Get unread count ──────────────────────────────────────
static Future<int> getUnreadCount(int userId) async {
  try {
    final response = await http
        .get(Uri.parse('$baseUrl/unread-count/$userId'))
        .timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body);
    return data['count'] ?? 0;
  } catch (e) {
    return 0;
  }
}

// ── Recover item ──────────────────────────────────────────
static Future<Map<String, dynamic>> recoverItem({
  required int userId,
  required String itemName,
}) async {
  try {
    final response = await http
        .post(
          Uri.parse('$baseUrl/recover-item'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'item_name': itemName,
          }),
        )
        .timeout(const Duration(seconds: 10));
    return jsonDecode(response.body);
  } catch (e) {
    return {'error': 'Could not connect: $e'};
  }
}
// ── Forgot password ───────────────────────────────────────
static Future<Map<String, dynamic>> forgotPassword({
  required String email,
  required String studentId,
}) async {
  try {
    final response = await http
        .post(
          Uri.parse('$baseUrl/forgot-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'student_id': studentId,
          }),
        )
        .timeout(const Duration(seconds: 10));
    return jsonDecode(response.body);
  } catch (e) {
    return {'error': 'Could not connect to server: $e'};
  }
}


}