import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:team_up/configserver/cf.dart'; // นำเข้า baseUrl จาก cf.dart

class ApiService {
  // ฟังก์ชันสำหรับการสมัครสมาชิก
  Future<Map<String, dynamic>> signup(Map<String, String> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to sign up: ${response.body}');
    }
  }

  // ฟังก์ชันสำหรับเข้าสู่ระบบ
  Future<Map<String, dynamic>> login(Map<String, String> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  // ฟังก์ชันสำหรับดึงข้อมูลโปรไฟล์
  Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch profile: ${response.body}');
    }
  }

  // ฟังก์ชันสำหรับสร้างห้อง
  Future<Map<String, dynamic>> createRoom(Map<String, dynamic> data, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rooms'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create room: ${response.body}');
    }
  }

  // ฟังก์ชันสำหรับดึงข้อมูลห้องทั้งหมด
  Future<List<dynamic>> getRooms({String? province}) async {
    final url = province != null
        ? '$baseUrl/rooms?province=$province'
        : '$baseUrl/rooms';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch rooms: ${response.body}');
    }
  }

  // ฟังก์ชันสำหรับจอยห้อง
  Future<Map<String, dynamic>> joinRoom(String roomId, String userId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rooms/join/$roomId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to join room: ${response.body}');
    }
  }

  // ฟังก์ชันสำหรับยกเลิกการจอยห้อง
  Future<Map<String, dynamic>> leaveRoom(String roomId, String userId, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/rooms/leave/$roomId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to leave room: ${response.body}');
    }
  }
}
