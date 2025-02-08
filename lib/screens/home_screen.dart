// lib/screens/home_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../configserver/cf.dart';
import '../widgets/create_room_dialog.dart';
import '../widgets/room_card.dart';
import '../widgets/room_details_dialog.dart';
import '../widgets/custom_popup.dart';
import '../widgets/room_dialog.dart'; // นำเข้า RoomDialog
import 'profile_page.dart';
import 'room_list_screen.dart'; // นำเข้า RoomListScreen

class HomeScreen extends StatefulWidget {
  final String token;

  const HomeScreen({Key? key, required this.token}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _filteredRooms = [];
  List<Map<String, dynamic>> _joinedRooms = [];
  bool _isLoading = true;
  String _searchQuery = "";
  late WebSocketChannel _channel;
  bool _showPopUp = false;
  bool _isRoomCreated = false; // Flag to differentiate between create and join
  String _lastOwnerName = 'Unknown'; // Variable to store the last owner name

  // เพิ่มตัวแปรนี้
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _fetchUserId(); // ดึง userId ก่อนดึงข้อมูลห้อง
    _fetchRoomsFromDatabase();
    _fetchJoinedRoomsFromDatabase();
    _channel = WebSocketChannel.connect(Uri.parse('wss://team-up.up.railway.app'));
    _listenForRealtimeUpdates();
  }

  Future<void> _fetchUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('user_id');
    if (userId != null && userId.isNotEmpty) {
      setState(() {
        _userId = userId;
      });
    }
  }

  void _listenForRealtimeUpdates() {
    _channel.stream.listen(
          (message) {
        final updatedRoom = jsonDecode(message);
        setState(() {
          _rooms.add(updatedRoom);
          _filterJoinedRooms();
        });
      },
      onError: (error) {
        print('WebSocket Error: $error');
        // คุณสามารถเพิ่มการจัดการข้อผิดพลาดที่นี่ เช่น การเชื่อมต่อใหม่
      },
      onDone: () {
        print('WebSocket connection closed');
        // คุณสามารถเพิ่มการเชื่อมต่อใหม่ที่นี่หากต้องการ
      },
    );
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  Future<void> _fetchRoomsFromDatabase() async {
    final url = Uri.parse('$baseUrl/rooms');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> fetchedRooms = jsonDecode(response.body);

        // Directly assign rooms with ownerName from populated ownerId
        List<Map<String, dynamic>> roomsWithOwner = [];
        for (var room in fetchedRooms) {
          String ownerName = room['ownerId']?['name'] ?? 'Unknown';
          room['ownerName'] = ownerName;
          roomsWithOwner.add(room);
        }

        setState(() {
          _rooms = roomsWithOwner.cast<Map<String, dynamic>>();
          _filteredRooms = _rooms;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print('Failed to fetch rooms: ${response.body}');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching rooms: $error');
    }
  }

  Future<void> _fetchJoinedRoomsFromDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('user_id');
    final String? token = prefs.getString('jwt_token');

    if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
      print('Error: User ID or Token is missing.');
      return;
    }

    setState(() {
      _userId = userId; // เก็บ userId
    });

    try {
      final url = Uri.parse('$baseUrl/rooms/joined/$userId');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedRooms = jsonDecode(response.body);
        setState(() {
          _joinedRooms = fetchedRooms.cast<Map<String, dynamic>>();
          _filterJoinedRooms();
        });
      } else {
        print('Failed to fetch joined rooms: ${response.body}');
      }
    } catch (error) {
      print('Error fetching joined rooms: $error');
    }
  }

  void _filterJoinedRooms() {
    setState(() {
      _filteredRooms = _rooms.where((room) => !_joinedRooms.any((joined) => joined['_id'] == room['_id'])).toList();
    });
  }

  void _filterRoomsBySearch(String query) {
    setState(() {
      _searchQuery = query;
      _filteredRooms = _rooms.where((room) {
        final sportName = room['sportName']?.toLowerCase() ?? '';
        final fieldName = room['fieldName']?.toLowerCase() ?? '';
        final province = room['province']?.toLowerCase() ?? '';
        return sportName.contains(query.toLowerCase()) ||
            fieldName.contains(query.toLowerCase()) ||
            province.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> joinRoom(String roomId) async {
    if (_joinedRooms.any((room) => room['_id'] == roomId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คุณได้เข้าร่วมห้องนี้แล้ว')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');
      final String? token = prefs.getString('jwt_token');

      if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID หรือ Token หาย')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/rooms/join/$roomId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เข้าร่วมห้องสำเร็จ!')),
        );

        // ดึงข้อมูลใหม่จากเซิร์ฟเวอร์
        await _fetchRoomsFromDatabase();
        await _fetchJoinedRoomsFromDatabase();

        // อัปเดตการแสดงผล
        setState(() {
          _filterJoinedRooms();
        });

        _channel.sink.add(jsonEncode({'action': 'join', 'roomId': roomId}));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเข้าร่วมห้องได้: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการเข้าร่วมห้อง')),
      );
    }
  }
  void _onTabChanged(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    // รีเฟรชข้อมูลเมื่อเลือกหน้า Home
    if (index == 0) {
      setState(() {
        _isLoading = true;
      });
      await _fetchRoomsFromDatabase();
      await _fetchJoinedRoomsFromDatabase();
      setState(() {
        _isLoading = false;
      });
    }
  }


  void _onPopUpClose() {
    setState(() {
      _showPopUp = false;
      _isRoomCreated = false;
    });

    if (_isRoomCreated) {
      _channel.sink.add(jsonEncode({'action': 'create', 'status': 'created'}));
    } else {
      _channel.sink.add(jsonEncode({'action': 'confirm', 'status': 'joined'}));
    }
  }

  Widget _buildHomePage() {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: _filterRoomsBySearch,
                decoration: InputDecoration(
                  hintText: 'จังหวัด...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredRooms.isEmpty
                  ? const Center(
                child: Text(
                  'ไม่พบห้องที่ตรงกับการค้นหา',
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : RefreshIndicator(
                onRefresh: () async {
                  await _fetchRoomsFromDatabase();
                  await _fetchJoinedRoomsFromDatabase();
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _filteredRooms.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final room = _filteredRooms[index];
                    final isOwner = room['ownerId']?['id'] == _userId || room['ownerId'] == _userId;

                    return RoomCard(
                      room: room,
                      isOwner: isOwner,
                      onJoin: () => joinRoom(room['_id']),
                      onEdit: () => _editRoom(room),
                      onDelete: () => _deleteRoom(room),
                      onViewDetails: () => _viewRoomDetails(room),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        // Popup
        if (_showPopUp)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {}, // Prevents tap from dismissing the popup
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: CustomPopup(
                    title: _isRoomCreated ? "ห้องถูกสร้างแล้ว!" : "คุณได้เข้าร่วมห้องแล้ว!",
                    message: _isRoomCreated
                        ? "ห้องใหม่ของคุณได้รับการสร้างเรียบร้อยแล้ว"
                        : "ห้องที่คุณเข้าร่วมจะได้รับการอัปเดต\nเจ้าของห้อง: $_lastOwnerName",
                    onClose: _onPopUpClose,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showCreateRoomDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return const CreateRoomDialog();
      },
    );

    if (result == true) {
      await _fetchRoomsFromDatabase();

      setState(() {
        _isRoomCreated = true;
        _showPopUp = true;
        _lastOwnerName = 'คุณ'; // ตั้งค่าเป็น 'คุณ' เมื่อสร้างห้อง
      });

      _channel.sink.add(jsonEncode({'action': 'create', 'status': 'created'}));
    }
  }

  void _editRoom(Map<String, dynamic> room) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return RoomDialog(
          isEdit: true,
          roomData: room,
          onRoomUpdated: () {
            _fetchRoomsFromDatabase();
          },
        );
      },
    );

    if (result == true) {
      // ส่งการอัปเดตห้องไปยัง WebSocket
      _channel.sink.add(jsonEncode({'action': 'update', 'roomId': room['_id']}));
    }
  }

  Future<void> _deleteRoom(Map<String, dynamic> room) async {
    final url = Uri.parse('$baseUrl/rooms/${room["_id"]}'); // Assuming DELETE /rooms/:roomId deletes the room
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');
      final String? token = prefs.getString('jwt_token');

      if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID หรือ Token หาย')),
        );
        return;
      }

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId}), // Assuming server requires userId in body
      );

      if (response.statusCode == 200) {
        setState(() {
          _rooms.removeWhere((r) => r['_id'] == room['_id']); // ลบห้องออกจากการแสดง
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบห้อง ${room["sportName"]} เรียบร้อย!')),
        );

        // แสดง Popup
        _showActionPopup(
          'ลบห้องเรียบร้อย!',
          'คุณได้ลบห้อง ${room["sportName"]} เรียบร้อยแล้ว',
        );

        // ส่งการอัปเดตห้องไปยัง WebSocket
        _channel.sink.add(jsonEncode({'action': 'delete', 'roomId': room['_id']}));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถลบห้องได้: ${response.body}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการลบห้อง')),
      );
    }
  }

  void _viewRoomDetails(Map<String, dynamic> room) {
    showDialog(
      context: context,
      builder: (context) {
        return RoomDetailsDialog(
          roomName: room['sportName'] ?? 'Unknown',
          participants: room['participants'] != null
              ? List<Map<String, dynamic>>.from(room['participants'])
              : [],
        );
      },
    );
  }

  // ฟังก์ชันแสดง AlertDialog หลังการกระทำ
  void _showActionPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return CustomPopup(
          title: title,
          message: message,
          onClose: () {
            Navigator.of(context).pop();
            // อาจเรียก refresh data ถ้าต้องการ
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      RoomListScreen(
        token: widget.token,
        onRoomUpdated: _fetchRoomsFromDatabase,
      ),
      ProfilePage(token: widget.token),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Home'
              : _selectedIndex == 1
              ? 'Schedule'
              : 'Profile',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        automaticallyImplyLeading: false,
      ),
      body: pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        onPressed: () {
          _showCreateRoomDialog(context);
        },
        label: const Text('สร้างเลย'),
        backgroundColor: Colors.orange,
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabChanged, // เรียกฟังก์ชันที่เพิ่มเข้ามา
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}