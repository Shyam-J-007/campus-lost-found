import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl =
      'https://campus-lost-found-production-1d75.up.railway.app';
  
  // ── AI Smart Match ────────────────────────────────────────────
// Add this method to your ApiService class in api_service.dart

static Future<Map<String, dynamic>> checkSmartMatch({
  required int userId,
  required String foundItemName,
  required String foundItemDescription,
  required String foundItemLocation,
  required String foundItemDate,
  String? foundImageUrl,
}) async {
  try {
    // If found item has an image URL, fetch it and convert to base64
    String? imageB64;
    String? contentType;

    if (foundImageUrl != null && foundImageUrl.isNotEmpty) {
      try {
        final imageResponse = await http.get(Uri.parse(foundImageUrl));
        if (imageResponse.statusCode == 200) {
          imageB64 = base64Encode(imageResponse.bodyBytes);
          contentType = imageResponse.headers['content-type'] ?? 'image/jpeg';
        }
      } catch (_) {
        // Image fetch failed — proceed with text only
      }
    }

    final body = <String, dynamic>{
      'user_id': userId,
      'found_item_name': foundItemName,
      'found_item_description': foundItemDescription,
      'found_item_location': foundItemLocation,
      'found_item_date': foundItemDate,
    };

    if (imageB64 != null) {
      body['found_image_base64'] = imageB64;
      body['found_image_content_type'] = contentType;
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/ai-smart-match'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    return jsonDecode(response.body);
  } catch (e) {
    return {'error': 'Could not check match: $e', 'matches': []};
  }
}

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
      if (data.containsKey('url')) return '$baseUrl${data['url']}';
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
      if (data.containsKey('url')) return '$baseUrl${data['url']}';
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

  // ── Search items ──────────────────────────────────────────
  static Future<List<dynamic>> searchItems(
    String query, {
    String type = 'lost',
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/search?q=$query&type=$type'))
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return [];
    }
  }

  // ── Check matches ─────────────────────────────────────────
  static Future<List<dynamic>> checkMatches(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/check-matches/$userId'))
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return [];
    }
  }

  // ── Get conversations ─────────────────────────────────────
  static Future<List<dynamic>> getConversations(
      int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/conversations/$userId'))
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return [];
    }
  }

  // ── Get messages ──────────────────────────────────────────
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
    String? newPassword,
  }) async {
    try {
      final body = <String, dynamic>{
        'email': email,
        'student_id': studentId,
      };
      if (newPassword != null) {
        body['new_password'] = newPassword;
      }
      final response = await http
          .post(
            Uri.parse('$baseUrl/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Could not connect to server: $e'};
    }
  }

  // ── AI Match ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> getAIMatches(
      int lostItemId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/ai-match/$lostItemId'))
          .timeout(const Duration(seconds: 30));
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Could not get matches: $e'};
    }
  }

  // ── AI Image Recognition (URL) ────────────────────────────
  static Future<Map<String, dynamic>> identifyImage(
      String imageUrl) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/ai-identify-image'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'image_url': imageUrl}),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Could not identify image: $e'};
    }
  }

  // ── AI Image Recognition (bytes) ──────────────────────────
  static Future<Map<String, dynamic>> identifyImageFromBytes(
      Uint8List bytes, String filename) async {
    try {
      final base64Image = base64Encode(bytes);
      final ext = filename.split('.').last.toLowerCase();
      final contentType =
          ext == 'png' ? 'image/png' : 'image/jpeg';
      final response = await http
          .post(
            Uri.parse('$baseUrl/ai-identify-image'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'image_base64': base64Image,
              'content_type': contentType,
            }),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Could not identify image: $e'};
    }
  }
}