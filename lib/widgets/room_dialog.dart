// lib/widgets/room_dialog.dart
import 'package:flutter/material.dart';

class RoomDialog extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? roomData;
  final VoidCallback? onRoomUpdated;

  const RoomDialog({
    Key? key,
    this.isEdit = false,
    this.roomData,
    this.onRoomUpdated,
  }) : super(key: key);

  @override
  _RoomDialogState createState() => _RoomDialogState();
}

class _RoomDialogState extends State<RoomDialog> {
  final _formKey = GlobalKey<FormState>();
  late String sportName;
  late String fieldName;
  late String time;
  late double pricePerPerson;
  late int maxParticipants;
  String? province;
  String? imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.roomData != null) {
      sportName = widget.roomData!['sportName'] ?? '';
      fieldName = widget.roomData!['fieldName'] ?? '';
      time = widget.roomData!['time'] ?? '';
      pricePerPerson = (widget.roomData!['pricePerPerson'] ?? 0).toDouble();
      maxParticipants = widget.roomData!['maxParticipants'] ?? 0;
      province = widget.roomData!['province'];
      imagePath = widget.roomData!['imagePath'];
    } else {
      sportName = '';
      fieldName = '';
      time = '';
      pricePerPerson = 0.0;
      maxParticipants = 0;
      province = null;
      imagePath = null;
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      // ส่งข้อมูลไปยังเซิร์ฟเวอร์ตามวิธีที่คุณต้องการ
      // ตัวอย่าง:
      /*
      final response = await http.post(
        Uri.parse('$baseUrl/rooms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'sportName': sportName,
          'fieldName': fieldName,
          'time': time,
          'pricePerPerson': pricePerPerson,
          'maxParticipants': maxParticipants,
          'province': province,
          'imagePath': imagePath,
        }),
      );

      if (response.statusCode == 200) {
        // แจ้งเตือนความสำเร็จ
        widget.onRoomUpdated?.call();
        Navigator.of(context).pop(true);
      } else {
        // แจ้งเตือนความล้มเหลว
      }
      */

      // สำหรับตอนนี้ สมมติว่าการส่งสำเร็จ
      widget.onRoomUpdated?.call();
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'แก้ไขห้อง' : 'สร้างห้อง'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: sportName,
                decoration: const InputDecoration(labelText: 'กีฬา'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกกีฬา';
                  }
                  return null;
                },
                onSaved: (value) => sportName = value!,
              ),
              TextFormField(
                initialValue: fieldName,
                decoration: const InputDecoration(labelText: 'สนาม'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกสนาม';
                  }
                  return null;
                },
                onSaved: (value) => fieldName = value!,
              ),
              TextFormField(
                initialValue: time,
                decoration: const InputDecoration(labelText: 'เวลา'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกเวลา';
                  }
                  return null;
                },
                onSaved: (value) => time = value!,
              ),
              TextFormField(
                initialValue: pricePerPerson != 0.0 ? pricePerPerson.toString() : '',
                decoration: const InputDecoration(labelText: 'ราคา/คน (บาท)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกราคา';
                  }
                  if (double.tryParse(value) == null) {
                    return 'กรุณากรอกราคาให้ถูกต้อง';
                  }
                  return null;
                },
                onSaved: (value) => pricePerPerson = double.parse(value!),
              ),
              TextFormField(
                initialValue: maxParticipants != 0 ? maxParticipants.toString() : '',
                decoration: const InputDecoration(labelText: 'จำนวนผู้เข้าร่วมสูงสุด'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกจำนวนผู้เข้าร่วม';
                  }
                  if (int.tryParse(value) == null) {
                    return 'กรุณากรอกจำนวนผู้เข้าร่วมให้ถูกต้อง';
                  }
                  return null;
                },
                onSaved: (value) => maxParticipants = int.parse(value!),
              ),
              DropdownButtonFormField<String>(
                value: province,
                hint: const Text('เลือกจังหวัด'),
                items: _provinces.map((province) {
                  return DropdownMenuItem(
                    value: province,
                    child: Text(province),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    province = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณาเลือกจังหวัด';
                  }
                  return null;
                },
                onSaved: (value) => province = value,
              ),
              TextFormField(
                initialValue: imagePath,
                decoration: const InputDecoration(labelText: 'URL รูปภาพ'),
                onSaved: (value) => imagePath = value,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.isEdit ? 'บันทึก' : 'สร้าง'),
        ),
      ],
    );
  }

  final List<String> _provinces = [
    // รายชื่อจังหวัดทั้งหมด
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
}
