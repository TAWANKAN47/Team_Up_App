import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// Flutter Map
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// นำเข้าฟังก์ชัน openMap() สำหรับกดนำทาง
import 'package:team_up/widgets/open_map.dart';
// นำเข้า Dialog สำหรับแสดงรายชื่อสมาชิก
import 'package:team_up/widgets/room_details_dialog.dart';
// baseUrl หรือ config อื่น ๆ
import 'package:team_up/configserver/cf.dart';

class RoomListScreen extends StatefulWidget {
  final String token;
  final Function() onRoomUpdated;

  const RoomListScreen({
    Key? key,
    required this.token,
    required this.onRoomUpdated,
  }) : super(key: key);

  @override
  _RoomListScreenState createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  List<Map<String, dynamic>> _joinedRooms = [];
  List<Map<String, dynamic>> _filteredRooms = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late WebSocketChannel _channel;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _fetchJoinedRoomsFromDatabase();

    // เชื่อมต่อ WebSocket
    _channel = WebSocketChannel.connect(Uri.parse('wss://team-up.up.railway.app'));

    _listenForRealtimeUpdates();
  }
  Future<void> _fetchRoomsFromDatabase() async {
    // ตัวอย่างโค้ดสำหรับดึงข้อมูลห้องจากเซิร์ฟเวอร์
    final url = Uri.parse('$baseUrl/rooms');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedRooms = jsonDecode(response.body);
        setState(() {
          // อัปเดต _joinedRooms หรือ _filteredRooms ตามการใช้งาน
          _filteredRooms = List<Map<String, dynamic>>.from(fetchedRooms);
        });
      } else {
        print('Failed to fetch rooms: ${response.body}');
      }
    } catch (error) {
      print('Error fetching rooms: $error');
    }
  }

  void _listenForRealtimeUpdates() {
    _channel.stream.listen(
          (message) {
        final decodedMessage = jsonDecode(message);
        final action = decodedMessage['action'];

        if (action == 'update' || action == 'join' || action == 'leave') {
          // ดึงข้อมูลใหม่จากเซิร์ฟเวอร์เมื่อมีการอัปเดต
          _fetchRoomsFromDatabase();
          _fetchJoinedRoomsFromDatabase();
        }
      },
      onError: (error) {
        print('WebSocket Error: $error');
      },
      onDone: () {
        print('WebSocket connection closed');
      },
    );
  }



  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  /// ดึงข้อมูลห้องที่ผู้ใช้ Join จาก Backend
  Future<void> _fetchJoinedRoomsFromDatabase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      final String? userId = prefs.getString('user_id');

      if (token == null || userId == null) {
        setState(() {
          _errorMessage = 'Token or User ID is missing.';
          _isLoading = false;
        });
        return;
      }

      _userId = userId;

      final url = Uri.parse('$baseUrl/rooms/joined/$_userId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Fetched rooms: $data'); // Debug data
        setState(() {
          _joinedRooms = List<Map<String, dynamic>>.from(data);
          _filterJoinedRooms();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load rooms: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching rooms: $e';
        _isLoading = false;
      });
    }
  }


  /// กรอง/จัดเรียงห้อง (ถ้าต้องการ)
  void _filterJoinedRooms() {
    _filteredRooms = List.from(_joinedRooms);
  }


  Future<void> _cancelRoom(Map<String, dynamic> room) async {
    final url = Uri.parse('$baseUrl/rooms/leave/${room["_id"]}?userId=$_userId');

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) {
        setState(() {
          _errorMessage = 'Token is missing.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // สำเร็จ: รีเฟรชข้อมูล
        await Future.wait([
          _fetchRoomsFromDatabase(),
          _fetchJoinedRoomsFromDatabase(),
        ]);
        widget.onRoomUpdated();

        // แสดง SnackBar สีส้ม
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ออกจากห้อง ${room["sportName"]} เรียบร้อย! 🧡'),
            backgroundColor: Colors.orange,
          ),
        );

        // ส่ง WebSocket Event
        _channel.sink.add(jsonEncode({
          'event': 'room_left',
          'roomId': room['_id'],
          'userId': _userId,
        }));
      } else {
        _showErrorPopup(
          'เกิดข้อผิดพลาด',
          'ไม่สามารถออกจากห้องได้: ${response.body}',
        );
      }
    } catch (error) {
      _showErrorPopup(
        '⚠️ เกิดข้อผิดพลาด',
        'ไม่สามารถออกจากห้องได้: ${error.toString()}',
      );
    }
  }




  /// ฟังก์ชัน Edit ห้อง (Owner เท่านั้น)
  void _editRoom(Map<String, dynamic> room) async {
    final sportNameController = TextEditingController(text: room['sportName']);
    final fieldNameController = TextEditingController(text: room['fieldName']);
    final priceController = TextEditingController(
      text: room['pricePerPerson'].toString(),
    );
    int? maxParticipants = room['maxParticipants'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขห้อง', style: TextStyle(color: Colors.orange)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: sportNameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อกีฬา',
                  prefixIcon: Icon(Icons.sports, color: Colors.orange),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: fieldNameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อสนาม',
                  prefixIcon: Icon(Icons.stadium, color: Colors.orange),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'ราคาต่อคน (บาท)',
                  prefixIcon: Icon(Icons.attach_money, color: Colors.orange),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: maxParticipants,
                decoration: const InputDecoration(
                  labelText: 'จำนวนคนสูงสุด',
                  prefixIcon: Icon(Icons.people, color: Colors.orange),
                ),
                items: List.generate(38, (i) => i + 2)
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text('$e คน'),
                ))
                    .toList(),
                onChanged: (value) => maxParticipants = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (sportNameController.text.isEmpty ||
                  fieldNameController.text.isEmpty ||
                  priceController.text.isEmpty ||
                  maxParticipants == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')),
                );
                return;
              }
              Navigator.pop(context);
              _updateRoom(
                room['_id'],
                sportNameController.text,
                fieldNameController.text,
                double.parse(priceController.text),
                maxParticipants!,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  /// อัปเดตห้อง (PUT) ไปยัง Backend
  Future<void> _updateRoom(
      String roomId,
      String sportName,
      String fieldName,
      double pricePerPerson,
      int maxParticipants,
      ) async {
    final url = Uri.parse('$baseUrl/rooms/$roomId/update');
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) {
        print('Error: Token is missing.');
        return;
      }

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sportName': sportName,
          'fieldName': fieldName,
          'pricePerPerson': pricePerPerson,
          'maxParticipants': maxParticipants,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = _joinedRooms.indexWhere((r) => r['_id'] == roomId);
          if (index != -1) {
            _joinedRooms[index] = {
              ..._joinedRooms[index],
              'sportName': sportName,
              'fieldName': fieldName,
              'pricePerPerson': pricePerPerson,
              'maxParticipants': maxParticipants,
            };
            _filterJoinedRooms();
          }
        });

        _showSuccessPopup('สำเร็จ', 'อัปเดตห้องเรียบร้อย');
      } else {
        _showSuccessPopup(
            'ผิดพลาด', 'ไม่สามารถอัปเดตห้องได้: ${response.body}');
      }
    } catch (e) {
      print('Error updating room: $e');
      _showSuccessPopup('ผิดพลาด', 'เกิดข้อผิดพลาดในการอัปเดตห้อง');
    }
  }

  Future<void> _deleteRoom(Map<String, dynamic> room) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => Theme(
        data: ThemeData(
          primaryColor: Colors.orange,
          colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.orange),
        ),
        child: AlertDialog(
          title: const Text('ยืนยันการลบห้อง', style: TextStyle(color: Colors.orange)),
          content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบห้องนี้? การลบห้องไม่สามารถกู้คืนได้'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('ลบห้อง'),
            ),
          ],
        ),
      ),
    );

    if (!confirmDelete) return;

    final url = Uri.parse('$baseUrl/rooms/${room["_id"]}?userId=$_userId');

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // กรณีสำเร็จ: รีเฟรชข้อมูลและแสดง SnackBar สีส้ม
        await _fetchJoinedRoomsFromDatabase();
        widget.onRoomUpdated();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบห้อง ${room["sportName"]} เรียบร้อย! 🧡'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // กรณี Error 500: แสดง Popup สีส้มและรีเฟรชข้อมูล
        _showErrorPopup(
          'ลบห้องแล้ว',
          'ระบบลบห้องสำเร็จ \n'
              'หน้าจอจะรีเฟรชใหม่โดยอัตโนมัติ',
        );
      }
    } catch (error) {
      // กรณี Exception: แสดง Popup สีส้ม
      _showErrorPopup(
        '⚠️ เกิดข้อผิดพลาด',
        'ไม่สามารถลบห้องได้: ${error.toString()}',
      );
    }
  }

// ฟังก์ชันแสดง Popup ข้อผิดพลาดแบบธีมสีส้ม
  void _showErrorPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Theme(
        data: ThemeData(
          primaryColor: Colors.orange,
          colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.orange),
        ),
        child: AlertDialog(
          title: Text(title, style: const TextStyle(color: Colors.orange)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // รีเฟรชข้อมูลหลังปิด Popup
                _fetchJoinedRoomsFromDatabase();
                widget.onRoomUpdated();
              },
              child: const Text('ตกลง', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      ),
    );
  }


  /// แสดง Dialog รายชื่อสมาชิก
  void _showMembersDialog(Map<String, dynamic> room) {
    // ตัวอย่าง: Backend เก็บสมาชิกใน field 'participants'
    final members = room['participants'] ?? [];
    print('Members data: $members');

    // Map ให้ตรงกับ RoomDetailsDialog
    final participants = (members as List<dynamic>).map<Map<String, dynamic>>((m) {
      return {
        'name': m['name'] ?? 'ไม่ทราบชื่อ',
        'age': m['age']?.toString() ?? 'ไม่ระบุ',
      };
    }).toList();

    showDialog(
      context: context,
      builder: (context) => RoomDetailsDialog(
        roomName: room['sportName'] ?? 'ไม่ระบุชื่อกีฬา',
        participants: participants,
      ),
    );
  }

  /// แสดง Dialog Map (location = { lat: number, lng: number })
  void _showMapDialog(Map<String, dynamic> room) {
    final locationData = room['location'];
    double lat = 0.0;
    double lng = 0.0;

    if (locationData != null && locationData is Map<String, dynamic>) {
      lat = (locationData['lat'] as num?)?.toDouble() ?? 0.0;
      lng = (locationData['lng'] as num?)?.toDouble() ?? 0.0;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('ตำแหน่งสนาม ${room['fieldName']}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(lat, lng),
                zoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: LatLng(lat, lng),
                      builder: (ctx) =>
                      const Icon(Icons.location_on, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            // ปุ่ม “นำทาง” โดยเรียก openMap
            TextButton.icon(
              icon: const Icon(Icons.navigation, color: Colors.blue),
              label: const Text('นำทาง'),
              onPressed: () {
                Navigator.pop(context);
                openMap(lat, lng);
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  /// Popup แสดงผลลัพธ์สำเร็จ/ผิดพลาด
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
              onPressed: () {
                Navigator.of(context).pop();
                widget.onRoomUpdated();
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

  /// สร้าง UI List ของห้องที่เรา Join แล้ว
  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
        ? Center(child: Text(_errorMessage))
        : ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredRooms.length,
      itemBuilder: (context, index) {
        final room = _filteredRooms[index];
        final isOwner = room['ownerId']?['_id'] == _userId;

        return Card(
          elevation: 4.0,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ส่วนหัวข้อ / ข้อมูลห้อง
                Text(
                  room['sportName'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text('สนาม: ${room['fieldName']}'),
                Text('เวลา: ${room['time']}'),
                Text('ราคา: ${room['pricePerPerson']} บาท/คน'),
                Text(
                  'จำนวน: ${room['currentParticipants']}/${room['maxParticipants']} คน',
                ),
                const SizedBox(height: 8),
                // แถวไอคอนด้านล่าง
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ซ้าย
                    Row(
                      children: [
                        // ดูสมาชิก
                        IconButton(
                          icon: const Icon(Icons.people,
                              color: Colors.green),
                          onPressed: () => _showMembersDialog(room),
                        ),
                        // ดูแผนที่
                        IconButton(
                          icon: const Icon(Icons.map,
                              color: Colors.orange),
                          onPressed: () => _showMapDialog(room),
                        ),
                        // นำทาง (Blue)
                        IconButton(
                          icon: const Icon(Icons.navigation,
                              color: Colors.blue),
                          onPressed: () {
                            // อ่าน lat,lng จาก room['location'] (object)
                            final locationData = room['location'];
                            if (locationData != null &&
                                locationData
                                is Map<String, dynamic>) {
                              final double lat =
                                  (locationData['lat'] as num?)
                                      ?.toDouble() ??
                                      0.0;
                              final double lng =
                                  (locationData['lng'] as num?)
                                      ?.toDouble() ??
                                      0.0;
                              openMap(lat, lng);
                            } else {
                              print('No valid location for navigation.');
                            }
                          },
                        ),
                      ],
                    ),
                    // ขวา
                    Row(
                      children: [
                        // แสดงผล Owner => Edit, Delete
                        if (isOwner) ...[
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blue),
                            onPressed: () => _editRoom(room),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () => _deleteRoom(room),
                          ),
                        ],
                        // ผู้ร่วม => Cancel (leave)
                        if (!isOwner)
                          IconButton(
                            icon: const Icon(Icons.exit_to_app,
                                color: Colors.red),
                            onPressed: () => _cancelRoom(room),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}