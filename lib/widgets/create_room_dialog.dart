// lib/widgets/create_room_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:team_up/configserver/cf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'select_location_screen.dart';

class CreateRoomDialog extends StatefulWidget {
  const CreateRoomDialog({Key? key}) : super(key: key);

  @override
  _CreateRoomDialogState createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  final TextEditingController _sportNameController = TextEditingController();
  final TextEditingController _fieldNameController = TextEditingController();
  final TextEditingController _totalPriceController = TextEditingController();

  int _maxParticipants = 2;
  LatLng? _selectedLocation;
  String? _locationText;
  File? _selectedImage;
  String? _selectedProvince;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime? _selectedDate;

  bool _isLoading = false;

  final List<String> provinces = [
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
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'สร้างห้องใหม่',
        style: TextStyle(color: Colors.orange),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _sportNameController,
              labelText: 'ชื่อกีฬา',
              icon: Icons.sports,
            ),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _fieldNameController,
              labelText: 'ชื่อสนาม',
              icon: Icons.sports_soccer,
            ),
            const SizedBox(height: 10),
            _buildDateTimePicker(),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _totalPriceController,
              labelText: 'ราคารวมทั้งหมด (บาท)',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _buildDropdownButtonFormField(),
            const SizedBox(height: 10),
            _buildMaxParticipantsPicker(),
            const SizedBox(height: 10),
            _buildLocationPicker(),
            const SizedBox(height: 10),
            _buildImagePicker(),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _selectedImage!,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createRoom,
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
              : const Text('สร้าง'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
          : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.orange),
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'วันที่และเวลาเล่น',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 5),
        ElevatedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_today, color: Colors.white),
          label: Text(
            _selectedDate != null
                ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                : 'เลือกวันที่',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectedDate != null ? _pickStartTime : null,
                icon: const Icon(Icons.access_time, color: Colors.white),
                label: Text(
                  _startTime != null
                      ? _formatTime(_startTime!)
                      : 'เลือกเวลาเริ่มต้น',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedDate != null ? Colors.orange : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectedDate != null ? _pickEndTime : null,
                icon: const Icon(Icons.access_time, color: Colors.white),
                label: Text(
                  _endTime != null
                      ? _formatTime(_endTime!)
                      : 'เลือกเวลาสิ้นสุด',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedDate != null ? Colors.orange : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_selectedDate != null && _startTime != null && _endTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _formatDateTimeRange(),
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownButtonFormField() {
    return DropdownButtonFormField<String>(
      value: _selectedProvince,
      hint: const Text('เลือกจังหวัด'),
      items: provinces.map((province) {
        return DropdownMenuItem(
          value: province,
          child: Text(province),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedProvince = value;
        });
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.location_city, color: Colors.orange),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildMaxParticipantsPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'จำนวนผู้เข้าร่วมสูงสุด',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        DropdownButton<int>(
          value: _maxParticipants,
          items: List.generate(
            39,
                (index) => DropdownMenuItem(
              value: index + 2,
              child: Text('${index + 2}'),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _maxParticipants = value!;
            });
          },
          underline: Container(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
        ),
      ],
    );
  }

  Widget _buildLocationPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Location',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        TextButton.icon(
          onPressed: _pickLocation,
          icon: const Icon(Icons.location_on, color: Colors.orange),
          label: Text(
            _locationText ?? 'ปักหมุด',
            style: const TextStyle(color: Colors.orange),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.orange.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'แนบรูปภาพ',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        TextButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image, color: Colors.orange),
          label: const Text(
            'เลือกรูปภาพ',
            style: TextStyle(color: Colors.orange),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.orange.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _startTime = null;
        _endTime = null;
      });
    }
  }

  Future<void> _pickStartTime() async {
    if (_selectedDate == null) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.orange,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
        if (_endTime != null && _isEndTimeBeforeStartTime()) {
          _endTime = null;
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    if (_selectedDate == null || _startTime == null) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? _startTime!,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.orange,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      if (_isEndTimeBeforeStartTime(picked)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เวลาสิ้นสุดต้องหลังจากเวลาเริ่มต้น')),
        );
        return;
      }
      setState(() => _endTime = picked);
    }
  }

  bool _isEndTimeBeforeStartTime([TimeOfDay? endTime]) {
    final checkTime = endTime ?? _endTime;
    if (_startTime == null || checkTime == null) return false;

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = checkTime.hour * 60 + checkTime.minute;

    return endMinutes <= startMinutes;
  }

  String _formatDateTimeRange() {
    if (_selectedDate == null || _startTime == null || _endTime == null) return '';
    final start = DateFormat('dd/MM/yyyy HH:mm').format(
      DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      ),
    );
    final end = DateFormat('HH:mm').format(
      DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      ),
    );
    return '$start - $end';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectLocationScreen(),
      ),
    );

    if (result != null && result is LatLng) {
      setState(() {
        _selectedLocation = result;
        _locationText =
        'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}';
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody)['url'];
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
    return null;
  }

  Future<void> _createRoom() async {
    final String sportName = _sportNameController.text.trim();
    final String fieldName = _fieldNameController.text.trim();
    final String totalPriceText = _totalPriceController.text.trim();

    if (sportName.isEmpty ||
        fieldName.isEmpty ||
        _selectedDate == null ||
        _startTime == null ||
        _endTime == null ||
        totalPriceText.isEmpty ||
        _selectedProvince == null ||
        _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    final double totalPrice = double.tryParse(totalPriceText) ?? 0.0;
    if (totalPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกราคาให้ถูกต้อง')),
      );
      return;
    }

    final double pricePerPerson = totalPrice / _maxParticipants;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
        if (imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถอัปโหลดรูปภาพได้')),
          );
          return;
        }
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      final String? userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้')),
        );
        return;
      }

      final roomData = {
        'sportName': sportName,
        'fieldName': fieldName,
        'time': _formatDateTimeRange(),
        'totalPrice': totalPrice,
        'pricePerPerson': pricePerPerson,
        'maxParticipants': _maxParticipants,
        'province': _selectedProvince,
        'location': {
          'lat': _selectedLocation!.latitude,
          'lng': _selectedLocation!.longitude,
        },
        'imagePath': imageUrl ?? 'default_image_url',
        'ownerId': userId.toString(),

      };

      final response = await http.post(
        Uri.parse('$baseUrl/rooms'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(roomData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สร้างห้องสำเร็จ!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${response.body}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $error')),
      );
    } finally {
      setState(() => _isLoading = false);
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
}