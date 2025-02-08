import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:team_up/screens/welcome_screen.dart';
import 'package:team_up/configserver/cf.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/foundation.dart';

class ProfilePage extends StatefulWidget {
  final String token;

  const ProfilePage({
    super.key,
    required this.token,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Uint8List? _imageBytes;
  String name = '';
  String phone = '';
  String email = '';
  int? _userAge;
  String province = '';
  String profileImage = '';
  bool isLoading = true;

  WebSocketChannel? _channel;

  // รายการจังหวัด (เหมือนเดิม)
  List<String> provinces = [
    'กรุงเทพมหานคร', 'กระบี่', 'กาญจนบุรี', 'กาฬสินธุ์', 'กำแพงเพชร',
    'ขอนแก่น', 'จันทบุรี', 'ฉะเชิงเทรา', 'ชลบุรี', 'ชัยนาท', 'ชัยภูมิ',
    'ชุมพร', 'เชียงราย', 'เชียงใหม่', 'ตรัง', 'ตราด', 'ตาก', 'นครนายก',
    'นครปฐม', 'นครพนม', 'นครราชสีมา', 'นครศรีธรรมราช', 'นครสวรรค์',
    'นนทบุรี', 'นราธิวาส', 'น่าน', 'บึงกาฬ', 'บุรีรัมย์', 'ปทุมธานี',
    'ประจวบคีรีขันธ์', 'ปราจีนบุรี', 'ปัตตานี', 'พระนครศรีอยุธยา', 'พะเยา',
    'พังงา', 'พัทลุง', 'พิจิตร', 'พิษณุโลก', 'เพชรบุรี', 'เพชรบูรณ์',
    'แพร่', 'ภูเก็ต', 'มหาสารคาม', 'มุกดาหาร', 'แม่ฮ่องสอน', 'ยโสธร',
    'ยะลา', 'ร้อยเอ็ด', 'ระนอง', 'ระยอง', 'ราชบุรี', 'ลพบุรี', 'ลำปาง',
    'ลำพูน', 'เลย', 'ศรีสะเกษ', 'สกลนคร', 'สงขลา', 'สตูล', 'สมุทรปราการ',
    'สมุทรสงคราม', 'สมุทรสาคร', 'สระแก้ว', 'สระบุรี', 'สิงห์บุรี', 'สุโขทัย',
    'สุพรรณบุรี', 'สุราษฎร์ธานี', 'สุรินทร์', 'หนองคาย', 'หนองบัวลำภู',
    'อ่างทอง', 'อำนาจเจริญ', 'อุดรธานี', 'อุตรดิตถ์', 'อุทัยธานี', 'อุบลราชธานี',
    'อื่นๆ'
  ];

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
    _fetchUserData();
  }

  void _initializeWebSocket() {
    // ปรับตามเซิร์ฟเวอร์ WebSocket ของคุณ
    if (kIsWeb) {
      _channel = WebSocketChannel.connect(Uri.parse('wss://team-up.up.railway.app'));

    } else {
      _channel = WebSocketChannel.connect(Uri.parse('wss://team-up.up.railway.app'));
    }

    _channel?.stream.listen(
          (message) {
        debugPrint('Message from WebSocket: $message');
      },
      onError: (error) {
        debugPrint('WebSocket Error: $error');
      },
      onDone: () {
        debugPrint('WebSocket closed.');
      },
    );
  }

  /// ฟังก์ชันแจ้งอีเวนต์ต่าง ๆ ไปยัง WebSocket Server
  Future<void> _notifyWebSocket(String event, Map<String, dynamic> payload) async {
    if (_channel == null) return;
    final data = {
      "event": event,
      "payload": payload,
    };
    _channel!.sink.add(jsonEncode(data));
  }

  /// ฟังก์ชัน fetch ข้อมูลโปรไฟล์จากเซิร์ฟเวอร์ครั้งแรก
  Future<void> _fetchUserData() async {
    final String apiUrl = '$baseUrl/auth/profile';
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          name = data['name'] ?? 'No name';
          phone = data['phone'] ?? 'No phone';
          email = data['email'] ?? 'No email';
          _userAge = data['age'];
          province = data['province'] ?? 'No province';
          profileImage = data['profileImage'] ?? '';
          isLoading = false;
        });
      } else {
        _showErrorSnackBar('Failed to load profile data');
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showErrorSnackBar('Error connecting to server');
      setState(() => isLoading = false);
    }
  }

  /// ฟังก์ชันอัปเดตข้อมูลโปรไฟล์
  /// (ปรับให้แก้ไข state ของหน้าเอง โดยไม่เรียก fetchUserData() อีกครั้ง)
  Future<void> _updateUserData(String field, dynamic value, String successMessage) async {
    final String apiUrl = '$baseUrl/auth/profile/update';
    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({field: value}),
      );

      if (response.statusCode == 200) {
        // อัปเดต state ภายในหน้าให้ UI เปลี่ยนได้ทันที (เหมือน RoomListScreen)
        setState(() {
          if (field == 'name') {
            name = value as String;
          } else if (field == 'phone') {
            phone = value as String;
          } else if (field == 'email') {
            email = value as String;
          } else if (field == 'age') {
            _userAge = value as int;
          } else if (field == 'province') {
            province = value as String;
          }
        });

        _showSuccessSnackBar(successMessage);

        // แจ้งผ่าน WebSocket เมื่อแก้ไขข้อมูลสำเร็จ
        await _notifyWebSocket('profileUpdated', {
          'field': field,
          'value': value,
        });
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      _showErrorSnackBar('Error connecting to server');
    }
  }

  void _handleApiError(http.Response response) {
    final error = json.decode(response.body)['message'] ?? 'Unknown error';
    _showErrorSnackBar(error);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// ถ้าอยาก popup แจ้งเตือนแทน SnackBar ให้ใช้ฟังก์ชันนี้แทน
  void _showSuccessPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // อัปเดตผ่าน WebSocket (ปรับ event/payload ตามการใช้งาน)
                await _notifyWebSocket('roomUpdated', {
                  'message': message,
                });
              },
              child: const Text(
                'ตกลง',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  void _changePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เปลี่ยนรหัสผ่าน', style: TextStyle(color: Colors.orange)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'รหัสผ่านปัจจุบัน',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'รหัสผ่านใหม่',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'ยืนยันรหัสผ่านใหม่',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              if (newPasswordController.text != confirmPasswordController.text) {
                _showErrorSnackBar('รหัสผ่านไม่ตรงกัน');
                return;
              }
              if (newPasswordController.text.length < 6) {
                _showErrorSnackBar('รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
                return;
              }
              _performPasswordChange(
                currentPasswordController.text.trim(),
                newPasswordController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performPasswordChange(String currentPassword, String newPassword) async {
    final String apiUrl = '$baseUrl/auth/profile/change-password';
    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar('เปลี่ยนรหัสผ่านสำเร็จ');
        // อัปเดต WebSocket
        await _notifyWebSocket('passwordChanged', {
          'user': widget.token,
        });
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      _showErrorSnackBar('ข้อผิดพลาดในการเชื่อมต่อ');
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildProfileInfo(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _imageBytes != null
                  ? MemoryImage(_imageBytes!)
                  : (profileImage.isNotEmpty
                  ? NetworkImage('https://team-up.up.railway.app$profileImage')
                  : null),
            ),
            _buildEditIcon(),
          ],
        ),
        const SizedBox(height: 16),
        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(email, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildEditIcon() {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
            )
          ],
        ),
        child: const Icon(Icons.edit, color: Colors.orange, size: 20),
      ),
      // ในส่วน onPressed ของ _buildEditIcon
      onPressed: () async {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          final bytes = await pickedFile.readAsBytes();
          setState(() => _imageBytes = bytes);

          // ส่งรูปไปยังเซิร์ฟเวอร์
          final String apiUrl = '$baseUrl/auth/profile/upload';
          var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
          request.headers['Authorization'] = 'Bearer ${widget.token}';
          request.files.add(
            http.MultipartFile.fromBytes(
              'profileImage',
              bytes,
              filename: pickedFile.name,
            ),
          );

          try {
            final response = await request.send();
            if (response.statusCode == 200) {
              _showSuccessSnackBar('อัปโหลดรูปภาพสำเร็จ');
              // ดึงข้อมูลโปรไฟล์ใหม่เพื่ออัปเดตรูป
              await _fetchUserData();
            } else {
              _showErrorSnackBar('อัปโหลดรูปภาพล้มเหลว');
            }
          } catch (e) {
            _showErrorSnackBar('เกิดข้อผิดพลาดในการเชื่อมต่อ');
          }
        }
      },
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        _buildInfoTile('ชื่อ', name, Icons.person,
                () => _editInfoDialog('ชื่อ', name, 'name')),
        _buildInfoTile('เบอร์โทร', phone, Icons.phone,
                () => _editInfoDialog('เบอร์โทร', phone, 'phone')),
        _buildInfoTile('อีเมล', email, Icons.email,
                () => _editInfoDialog('อีเมล', email, 'email')),
        _buildInfoTile('จังหวัด', province, Icons.location_on,
            _editProvinceDialog),
        _buildInfoTile('อายุ', _userAge?.toString() ?? '-', Icons.cake,
            _editAgeDialog),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value.isEmpty ? '-' : value),
      trailing: const Icon(Icons.edit, color: Colors.orange),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.lock_reset, color: Colors.white),
          label: const Text('เปลี่ยนรหัสผ่าน', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: _changePasswordDialog,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text('ออกจากระบบ', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            side: const BorderSide(color: Colors.red),
          ),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
          ),
        ),
      ],
    );
  }

  void _editInfoDialog(String fieldName, String currentValue, String fieldKey) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('แก้ไข$fieldName', style: const TextStyle(color: Colors.orange)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'กรอก$fieldNameใหม่',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _updateUserData(fieldKey, controller.text.trim(), 'แก้ไข${fieldName}สำเร็จ');
                Navigator.pop(context); // ปิด Dialog อย่างเดียว
              }
            },
            child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editProvinceDialog() {
    String searchQuery = '';
    List<String> filteredProvinces = List.from(provinces);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('เลือกจังหวัด', style: TextStyle(color: Colors.orange)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'ค้นหาจังหวัด',
                    prefixIcon: Icon(Icons.search, color: Colors.orange),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                      filteredProvinces = provinces
                          .where((p) => p.toLowerCase().contains(searchQuery))
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 300,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: filteredProvinces.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(filteredProvinces[index]),
                      onTap: () {
                        _updateUserData('province', filteredProvinces[index], 'แก้ไขจังหวัดสำเร็จ');
                        Navigator.pop(context); // ปิด dialog
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _editAgeDialog() {
    final controller = TextEditingController(text: _userAge?.toString() ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขอายุ', style: TextStyle(color: Colors.orange)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'กรอกอายุใหม่',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              final age = int.tryParse(controller.text);
              if (age != null && age > 0 && age <= 100) {
                _updateUserData('age', age, 'แก้ไขอายุสำเร็จ');
                Navigator.pop(context);
              } else {
                _showErrorSnackBar('กรุณากรอกอายุระหว่าง 1-100');
              }
            },
            child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
