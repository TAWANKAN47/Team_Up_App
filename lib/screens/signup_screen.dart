import 'dart:convert';
import 'dart:io'; // สำหรับจัดการ SocketException
import 'package:flutter/material.dart';
import 'package:team_up/widgets/custom_scaffold.dart'; // นำเข้า CustomScaffold
import 'package:team_up/theme/theme.dart'; // นำเข้า theme
import 'package:team_up/screens/signin_screen.dart'; // นำเข้าหน้าสำหรับลงชื่อเข้าใช้
import 'package:http/http.dart' as http;
import 'package:team_up/configserver/cf.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formSignUpKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool agreePersonalData = true;

  // ฟังก์ชันสำหรับสมัครสมาชิก
  Future<void> _signupUser() async {
    const String apiUrl = '$baseUrl/auth/signup'; // URL ของ API

    final String name = _nameController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สมัครสมาชิกสำเร็จ')),
        );
        _showSuccessDialog(name); // แสดง Dialog แจ้งเตือนเมื่อสมัครสำเร็จ
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? 'ข้อมูลไม่ถูกต้อง')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง')),
        );
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มีการเชื่อมต่ออินเทอร์เน็ต')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้')),
      );
    }
  }

  // แสดง Dialog เมื่อสมัครสำเร็จ
  void _showSuccessDialog(String name) {
    showDialog(
      context: context,
      barrierDismissible: false, // ไม่ให้ปิด Dialog ด้วยการกดด้านนอก
      builder: (context) {
        return AlertDialog(
          backgroundColor: lightColorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 50,
          ),
          content: Text(
            'สมัครสมาชิกสำเร็จ คุณ $name',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // ปิด Dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                );
              },
              child: const Text(
                'ตกลง',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ตรวจสอบความถูกต้องของอีเมล
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกอีเมล';
    }
    String pattern =
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$'; // รูปแบบของอีเมล
    RegExp regExp = RegExp(pattern);

    if (!regExp.hasMatch(value)) {
      return 'กรุณากรอกอีเมลที่ถูกต้อง';
    }
    return null;
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
                  key: _formSignUpKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'เริ่มต้นการใช้งาน',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w900,
                          color: lightColorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      TextFormField(
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณากรอกชื่อ';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text('ชื่อเต็ม'),
                          hintText: 'กรอกชื่อเต็มของคุณ',
                          hintStyle: const TextStyle(color: Colors.black26),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      TextFormField(
                        controller: _emailController,
                        validator: _validateEmail,
                        decoration: InputDecoration(
                          label: const Text('อีเมล'),
                          hintText: 'กรอกอีเมลของคุณ',
                          hintStyle: const TextStyle(color: Colors.black26),
                          border: OutlineInputBorder(
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      Row(
                        children: [
                          Checkbox(
                            value: agreePersonalData,
                            onChanged: (bool? value) {
                              setState(() {
                                agreePersonalData = value!;
                              });
                            },
                            activeColor: lightColorScheme.primary,
                          ),
                          const Text(
                            'ฉันยอมรับการประมวลผลข้อมูลส่วนบุคคล',
                            style: TextStyle(color: Colors.black45),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formSignUpKey.currentState!.validate() &&
                                agreePersonalData) {
                              _signupUser();
                            } else if (!agreePersonalData) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('กรุณายอมรับข้อตกลง')),
                              );
                            }
                          },
                          child: const Text('สมัครสมาชิก'),
                        ),
                      ),
                      const SizedBox(height: 30.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'มีบัญชีอยู่แล้ว? ',
                            style: TextStyle(color: Colors.black45),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (e) => const SignInScreen()),
                              );
                            },
                            child: Text(
                              'เข้าสู่ระบบ',
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
