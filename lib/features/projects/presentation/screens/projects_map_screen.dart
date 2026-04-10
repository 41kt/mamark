import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../contractor/presentation/providers/contractor_providers.dart';

class ProjectsMapScreen extends ConsumerStatefulWidget {
  const ProjectsMapScreen({super.key});

  @override
  ConsumerState<ProjectsMapScreen> createState() => _ProjectsMapScreenState();
}

class _ProjectsMapScreenState extends ConsumerState<ProjectsMapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    // using allOpenProjectsProvider to fetch all projects
    final allProjectsAsync = ref.watch(allOpenProjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("خريطة المشاريع", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: allProjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("خطأ في تحميل المشاريع: $e", style: GoogleFonts.cairo())),
        data: (projects) {
          // filter projects that have valid location_lat and location_lng
          final mappedProjects = projects.where((p) {
            final lat = p['location_lat'];
            final lng = p['location_lng'];
            return lat != null && lng != null;
          }).toList();

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(15.3694, 44.1910), // Default center (e.g. Sanaa, Yemen)
                  initialZoom: 6,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.mamark.mamark11', // Should match package name
                  ),
                  MarkerLayer(
                    markers: mappedProjects.map((project) {
                      final lat = (project['location_lat'] as num).toDouble();
                      final lng = (project['location_lng'] as num).toDouble();
                      
                      return Marker(
                        point: LatLng(lat, lng),
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () => _showProjectDetails(context, project),
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 40,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              if (mappedProjects.isEmpty)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "لا توجد مشاريع بإحداثيات جغرافية حالياً.",
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showProjectDetails(BuildContext context, Map<String, dynamic> project) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project['title'] ?? 'بدون عنوان',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    project['cities']?['name_ar'] ?? 'غير محدد',
                    style: GoogleFonts.cairo(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.monetization_on_outlined, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    "${project['budget_min']} - ${project['budget_max']} ريال",
                    style: GoogleFonts.cairo(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close bottom sheet
                    Get.toNamed('/project-details/${project['id']}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    "عرض التفاصيل",
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

