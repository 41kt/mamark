import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class ProjectStagesScreen extends ConsumerWidget {
  final String projectId;
  const ProjectStagesScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // dummy data
    final stages = [
      {'title': 'التأسيس والحفر', 'status': 'completed', 'progress': 100, 'date': '2024-03-01'},
      {'title': 'صب القواعد والرقاب', 'status': 'completed', 'progress': 100, 'date': '2024-03-15'},
      {'title': 'صب الميد والملاحق', 'status': 'in_progress', 'progress': 60, 'date': '2024-04-01'},
      {'title': 'أعمدة الدور الأول', 'status': 'pending', 'progress': 0, 'date': 'لم يبدأ بعد'},
      {'title': 'سقف الدور الأول', 'status': 'delayed', 'progress': 0, 'date': 'متأخر 5 أيام'},
    ];

    bool isContractor = DateTime.now().year > 2000; // Note: get from role

    return Scaffold(
      appBar: AppBar(
        title: const Text("مراحل التنفيذ"),
        actions: [
          if (isContractor)
            IconButton(
              icon: const Icon(Icons.edit_document),
              onPressed: () => Get.toNamed('/project-execution/$projectId'),
            ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Total Progress Card
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("الإنجاز الكلي للمشروع", style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("45%", style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: 0.45,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 8),
                Text("اكتملت مرحلتين من أصل 5 مراحل", style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Timeline
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: stages.length,
              itemBuilder: (context, index) {
                final stage = stages[index];
                final isLast = index == stages.length - 1;
                
                Color statusColor;
                IconData statusIcon;
                switch (stage['status']) {
                  case 'completed': statusColor = AppColors.success; statusIcon = Icons.check_circle; break;
                  case 'in_progress': statusColor = Colors.blue; statusIcon = Icons.play_circle_filled; break;
                  case 'delayed': statusColor = AppColors.error; statusIcon = Icons.warning; break;
                  default: statusColor = Colors.grey; statusIcon = Icons.radio_button_unchecked; break;
                }

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Timeline indicator
                      SizedBox(
                        width: 40,
                        child: Column(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 28),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 3,
                                  color: statusColor.withValues(alpha: 0.3),
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Stage Card
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                              boxShadow: [
                                BoxShadow(color: statusColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(stage['title'] as String, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                      child: Text(
                                        "${stage['progress']}%",
                                        style: GoogleFonts.cairo(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(stage['date'] as String, style: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: (stage['progress'] as int) / 100,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: !isContractor
          ? FloatingActionButton.extended(
              onPressed: () {}, // Add Stage
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text("إضافة مرحلة", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}

