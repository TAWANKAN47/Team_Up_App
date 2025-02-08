# Team UP

##

Team Up เป็นแอพเกี่ยวกับการนัดบอร์ดเล่นกีฬา  โดยมีฟังก์ชั่นดังนี้\
-ระบบล็อคอิน สมัครสมาชิก\
-ระบบสร้างห้อง\
-ระบบจอยห้อง ลบห้อง\
-ระบบตั้งค่าห้อง\
-ระบบตั้งค่าโปรไฟล์ผู้ใช้งาน\
-ระบบแผนที่\
โดยไฟล์จะแบ่งเป็นฝั่งเซิฟเวอร์ (`auth-system`) และแอปพลิเคชัน (`NewCodeMba-main`) ที่พัฒนาโดยใช้ Node.js และ Flutter โครงการนี้มีโครงสร้างหลายส่วนซึ่งรวมถึงระบบการรับรองตัวตนและฟีเจอร์ต่าง ๆ ที่เกี่ยวข้องกับการจัดการข้อมูลผู้ใช้
ไฟล์เซิฟเวอร์ อยู่ในนี้
https://github.com/Jerry4709/server
## โครงสร้างโครงการ

```
Team_Up_App/
│-- auth-system/               # ระบบยืนยันตัวตน (Node.js)
│   │-- config/               # ไฟล์คอนฟิกของระบบ
│   │   │-- config.js         # กำหนดค่าพื้นฐานของระบบ
│   │   │-- db.js             # ตั้งค่าการเชื่อมต่อฐานข้อมูล
│   │-- controllers/          # ไฟล์ควบคุมการทำงานของ API
│   │   │-- authController.js  # จัดการการล็อคอินและสมัครสมาชิก
│   │   │-- roomController.js  # จัดการข้อมูลห้อง
│   │-- middleware/           # ไฟล์ middleware ที่ใช้ในระบบ
│   │   │-- authMiddleware.js  # ตรวจสอบสิทธิ์ของผู้ใช้
│   │   │-- upload.js          # จัดการอัปโหลดไฟล์
│   │-- models/               # ไฟล์โมเดลสำหรับฐานข้อมูล
│   │   │-- Room.js           # โครงสร้างข้อมูลของห้อง
│   │   │-- User.js           # โครงสร้างข้อมูลของผู้ใช้
│   │-- routes/               # เส้นทาง API ของระบบ
│   │   │-- auth.js           # กำหนด API เกี่ยวกับผู้ใช้
│   │   │-- roomRoutes.js     # กำหนด API เกี่ยวกับห้อง
│   │-- uploads/              # ไฟล์ที่ถูกอัปโหลดโดยผู้ใช้
│   │-- package.json          # ไฟล์ dependencies ของ Node.js
│   │-- server.js             # ไฟล์เซิร์ฟเวอร์ (มีการเปิดใช้งานอยู่แล้ว ไม่ต้องรันเอง)
│
│-- NewCodeMba-main/          # แอปพลิเคชัน (Flutter)
│   │-- lib/                  # ไฟล์โค้ดหลักของ Flutter
│   │   │-- main.dart         # จุดเริ่มต้นของแอปพลิเคชัน
│   │   │-- configserver/     # การตั้งค่าเซิร์ฟเวอร์ API
│   │   │   │-- api_service.dart  # ไฟล์เชื่อมต่อ API
│   │   │   │-- cf.dart           # ไฟล์กำหนดค่าคอนฟิก
│   │   │-- screens/         # ไฟล์ที่เกี่ยวกับ UI ของแต่ละหน้าจอ
│   │   │   │-- home_screen.dart       # หน้าหลักของแอป
│   │   │   │-- profile_page.dart      # หน้าโปรไฟล์ผู้ใช้
│   │   │   │-- room_list_screen.dart  # หน้ารายการห้อง
│   │   │   │-- signin_screen.dart     # หน้าเข้าสู่ระบบ
│   │   │   │-- signup_screen.dart     # หน้าสมัครสมาชิก
│   │   │   │-- welcome_screen.dart    # หน้าเริ่มต้นแอป
│   │   │-- theme/           # ไฟล์กำหนดธีมของแอปพลิเคชัน
│   │   │   │-- theme.dart           # ไฟล์กำหนดธีม UI
│   │   │-- widgets/         # คอมโพเนนต์ UI ที่ใช้ซ้ำในแอป
│   │   │   │-- create_room_dialog.dart    # หน้าต่างสร้างห้อง
│   │   │   │-- custom_popup.dart         # ป๊อปอัปแบบกำหนดเอง
│   │   │   │-- custom_scaffold.dart      # แม่แบบ UI หลัก
│   │   │   │-- open_map.dart             # หน้าต่างเปิดแผนที่
│   │   │   │-- room_card.dart            # คอมโพเนนต์แสดงห้อง
│   │   │   │-- room_details_dialog.dart  # หน้าต่างรายละเอียดห้อง
│   │   │   │-- select_location_screen.dart  # หน้าจอเลือกตำแหน่ง
│   │   │   │-- welcome_button.dart       # หน้าแรกเข้าแอพ
│   │-- android/              # ไฟล์สำหรับ Android
│   │-- ios/                  # ไฟล์สำหรับ iOS
│   │-- pubspec.yaml          # รายการ dependencies ของ Flutter
│
│-- README.md                 # ไฟล์คำแนะนำสำหรับโครงการ
```



## การติดตั้งและตั้งค่า

### ติดตั้ง Node.js และ Flutter

1. ติดตั้ง [Flutter](https://flutter.dev/docs/get-started/install)
2. คลิกโค้ดจาก GitHub หรือแตกไฟล์ลงในโฟลเดอร์ที่ต้องการ

### หมายเหตุ ไฟล์ฝั่ง Server ไม่ต้องรันแล้ว เพราะอัพลงเซิฟเวอร์แล้ว https://github.com/Jerry4709/server !!!ไฟล์เซิฟเวอร์!!!

### ติดตั้ง Dependencies



#### สำหรับ `NewCodeMba-main`

```sh
cd NewCodeMba-main
flutter pub get
```

## การพัฒนาและการมีส่วนร่วม

หากต้องการปรับปรุงโครงการนี้ สามารถ Fork และ Pull Request ได้ที่ GitHub repository

## ใบอนุญาต

โครงการนี้อยู่ภายใต้ MIT License สามารถใช้งานและพัฒนาเพิ่มเติมได้
