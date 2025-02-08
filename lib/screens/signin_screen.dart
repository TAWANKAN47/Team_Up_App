import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:team_up/screens/signup_screen.dart';
import 'package:team_up/widgets/custom_scaffold.dart';
import 'package:team_up/screens/home_screen.dart';
import '../theme/theme.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_up/configserver/cf.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formSignInKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool rememberPassword = true;
  bool _isLoading = false; // สำหรับแสดงสถานะ Loading

  Future<void> _loginUser() async {
    final String apiUrl = '$baseUrl/auth/login'; // ใช้ baseUrl จาก cf.dart

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    setState(() {
      _isLoading = true; // เริ่มแสดง Loading
    });

    try {
      // ส่งคำขอไปยัง API
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      // ตรวจสอบสถานะการตอบกลับ
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String token = data['token'] ?? ''; // ดึง JWT Token จากการตอบกลับ
        final String userId = data['userId'] ?? ''; // ดึง userId จากการตอบกลับ

        if (token.isNotEmpty && userId.isNotEmpty) {
          // เก็บ Token และ userId ลง SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          await prefs.setString('user_id', userId);

          print('Token and User ID saved successfully.');
          print('Saved Token: ${prefs.getString('jwt_token')}');
          print('Saved User ID: ${prefs.getString('user_id')}');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ')),
          );

          // ไปยังหน้า HomeScreen และส่ง Token
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(token: token),
            ),
          );
        } else {
          print('Error: Token or User ID is empty');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถบันทึก Token หรือ User ID ได้')),
          );
        }
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? 'ข้อมูลไม่ถูกต้อง')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาด')),
        );
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีการเชื่อมต่ออินเทอร์เน็ต')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อกับเซิร์ฟเวอร์')),
      );
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false; // ปิด Loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          const Expanded(
            flex: 1,
            child: SizedBox(height: 10),
          ),
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formSignInKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'ยินดีต้อนรับกลับมา',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w900,
                          color: lightColorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      TextFormField(
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณากรอกอีเมล';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text('อีเมล'),
                          hintText: 'กรอกอีเมลของคุณ',
                          hintStyle: const TextStyle(color: Colors.black26),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        obscuringCharacter: '*',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณากรอกรหัสผ่าน';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text('รหัสผ่าน'),
                          hintText: 'กรอกรหัสผ่านของคุณ',
                          hintStyle: const TextStyle(color: Colors.black26),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: rememberPassword,
                                onChanged: (bool? value) {
                                  setState(() {
                                    rememberPassword = value!;
                                  });
                                },
                                activeColor: lightColorScheme.primary,
                              ),
                              const Text(
                                'จดจำฉัน',
                                style: TextStyle(color: Colors.black45),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              // ฟังก์ชัน Forgot Password สามารถเพิ่มได้ในที่นี้
                            },
                            child: Text(
                              'ลืมรหัสผ่าน?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: lightColorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25.0),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formSignInKey.currentState!.validate()) {
                              FocusScope.of(context).unfocus(); // ปิดแป้นพิมพ์
                              _loginUser();
                            }
                          },
                          child: const Text('เข้าสู่ระบบ'),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'ยังไม่มีบัญชี? ',
                            style: TextStyle(color: Colors.black45),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (e) => const SignUpScreen()),
                              );
                            },
                            child: Text(
                              'สมัครสมาชิก',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: lightColorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
