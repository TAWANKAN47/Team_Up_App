import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RoomCard extends StatelessWidget {
  final Map<String, dynamic> room;
  final bool isOwner;

  /// Callback ต่าง ๆ
  final VoidCallback onJoin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

  /// Callback สำหรับแจ้ง WebSocket ตอนดูสมาชิก (ถ้าต้องการใช้)
  final void Function(String roomId)? onViewMembersWebSocket;

  const RoomCard({
    Key? key,
    required this.room,
    required this.isOwner,
    required this.onJoin,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
    this.onViewMembersWebSocket,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1) เช็คว่ามีรูปไหม
    final String? imagePath = room['imagePath'];
    final bool hasImage = imagePath != null &&
        imagePath.isNotEmpty &&
        imagePath != 'default_image_url';

    // 2) เช็ค location ว่าเป็น object { lat, lng } หรือไม่
    double? lat;
    double? lng;

    // สมมติ Backend ส่งโครงสร้าง:
    // "location": { "lat": 13.7552, "lng": 100.4963 }
    final dynamic locationData = room['location'];
    if (locationData != null && locationData is Map<String, dynamic>) {
      lat = locationData['lat']?.toDouble();
      lng = locationData['lng']?.toDouble();
    }

    final bool hasValidLocation = (lat != null && lng != null);


    Widget headerWidget;
    if (hasImage) {
      headerWidget = CachedNetworkImage(
        imageUrl: imagePath!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
        const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(
          Icons.broken_image,
          size: 100,
          color: Colors.grey,
        ),
      );
    } else if (hasValidLocation) {
      headerWidget = SizedBox(
        height: 200,
        width: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            center: LatLng(lat!, lng!),
            zoom: 15.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(lat, lng),
                  builder: (ctx) => const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // ไม่มีรูป + ไม่มี location
      headerWidget = Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            color: Colors.grey,
            size: 100,
          ),
        ),
      );
    }

    final bool isFull = room['isFull'] ?? false;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            headerWidget, // แสดงรูปหรือแผนที่ตามเงื่อนไขด้านบน

            // ส่วนรายละเอียดห้องและปุ่มต่าง ๆ
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room['sportName'] ?? 'ไม่ระบุชื่อกีฬา',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'สนาม: ${room['fieldName'] ?? "ไม่ระบุ"}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'เวลา: ${room['time'] ?? "ไม่ระบุ"}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ราคา: ${room['pricePerPerson'] ?? 0} บาท/คน',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'จังหวัด: ${room['province'] ?? "ไม่ระบุ"}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'หัวหน้าห้อง: ${room['ownerName'] ?? "ไม่ระบุ"}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey[400]),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // แสดงจำนวนผู้เข้าร่วม
                      Row(
                        children: [
                          const Icon(Icons.people, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            '${room['currentParticipants'] ?? 0} / ${room['maxParticipants'] ?? 0}',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                      // ปุ่มแอ็กชัน
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.info, color: Colors.blue),
                            onPressed: () {
                              // เมื่อกดดูรายละเอียด (members)
                              if (onViewMembersWebSocket != null) {
                                onViewMembersWebSocket!(room['_id']);
                              }
                              onViewDetails();
                            },
                          ),
                          if (isOwner)
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.green),
                              onPressed: onEdit,
                            ),
                          if (isOwner)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: onDelete,
                            ),
                          if (!isOwner)
                            ElevatedButton(
                              onPressed: isFull ? null : onJoin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                isFull ? Colors.grey : Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(isFull ? 'เต็ม' : 'Join'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}