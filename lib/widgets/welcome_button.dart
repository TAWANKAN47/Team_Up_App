import 'package:flutter/material.dart';

class WelcomeButton extends StatelessWidget {
  const WelcomeButton({
    Key? key,
    required this.buttonText,
    required this.onTap,
    required this.color,
    required this.textColor,
  }) : super(key: key);

  final String buttonText;     // ข้อความที่จะแสดงบนปุ่ม
  final Widget onTap;          // หน้าจอที่ต้องการนำทางเมื่อกดปุ่ม
  final Color color;           // สีพื้นหลังของปุ่ม
  final Color textColor;       // สีข้อความในปุ่ม

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // เมื่อกดปุ่มจะ Navigator.push ไปหน้าที่กำหนดใน onTap
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => onTap,
          ),
        );
      },
      child: Container(
        // Padding รอบปุ่ม
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 12.0),
        // สามารถปรับค่าตามต้องการ
        decoration: BoxDecoration(
          color: color, // สีพื้นหลังของปุ่ม
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50), // มุมโค้งที่มุมซ้ายบน
          ),
        ),
        child: Text(
          buttonText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
