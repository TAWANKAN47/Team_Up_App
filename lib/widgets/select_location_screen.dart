import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({Key? key}) : super(key: key);

  @override
  _SelectLocationScreenState createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  LatLng? _pickedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกตำแหน่งบนแผนที่'),
        backgroundColor: Colors.orange,
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(13.7563, 100.5018), // Bangkok, Thailand
          zoom: 13.0,
          onTap: (tapPosition, latLng) {
            setState(() {
              _pickedLocation = latLng;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          if (_pickedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _pickedLocation!,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_pickedLocation != null) {
            Navigator.of(context).pop(_pickedLocation);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('กรุณาเลือกตำแหน่ง')),
            );
          }
        },
        label: const Text('เลือกตำแหน่งนี้'),
        icon: const Icon(Icons.check),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
