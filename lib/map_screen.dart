import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  final double teacherLat;
  final double teacherLng;
  final List<Map<String, double>> students;

  const MapScreen({
    super.key,
    required this.teacherLat,
    required this.teacherLng,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location Map")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(teacherLat, teacherLng),
          initialZoom: 16,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.attendance_app',
          ),

          MarkerLayer(
            markers: [
              // 🔴 TEACHER PIN
              Marker(
                point: LatLng(teacherLat, teacherLng),
                width: 50,
                height: 50,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),

              // 🟢 ALL STUDENTS
              ...students.map((student) {
                return Marker(
                  point: LatLng(student["lat"]!, student["lng"]!),
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.green,
                    size: 40,
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}
