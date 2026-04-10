import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'gradient_button.dart';

class ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final VoidCallback onTap;
  final VoidCallback? onActionTap;
  final String actionLabel;
  final bool hasAction;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onActionTap,
    this.actionLabel = "التفاصيل",
    this.hasAction = true,
  });

  String _formatBudget(dynamic value) {
    if (value == null) return '0';
    final num = double.tryParse(value.toString()) ?? 0;
    if (num >= 1000000) return "${(num / 1000000).toStringAsFixed(1)}م";
    if (num >= 1000) return "${(num / 1000).toStringAsFixed(0)}أ";
    return num.toStringAsFixed(0);
  }

  String _getNestedValue(Map<String, dynamic>? data, String key, String subKey) {
    if (data == null) return 'غير محدد';
    final value = data[key];
    if (value == null) return 'غير محدد';
    if (value is List && value.isNotEmpty) {
      return value[0][subKey]?.toString() ?? 'غير محدد';
    } else if (value is Map) {
      return value[subKey]?.toString() ?? 'غير محدد';
    }
    return 'غير محدد';
  }

  @override
  Widget build(BuildContext context) {
    final cityName = _getNestedValue(project, 'cities', 'name_ar');
    final categoryTemp = _getNestedValue(project, 'project_categories', 'name_ar');
    final categoryName = categoryTemp != 'غير محدد' ? categoryTemp : (project['project_type'] ?? 'عام');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.architecture, color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        project['title'] ?? 'بدون عنوان',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusBadge(project['status']),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(Icons.location_on_outlined, cityName),
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.category_outlined, categoryName),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.monetization_on_outlined, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          "${_formatBudget(project['budget_min'])} - ${_formatBudget(project['budget_max'])} ريال",
                          style: GoogleFonts.cairo(
                            color: Colors.green.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (hasAction && onActionTap != null)
                      SizedBox(
                        height: 36,
                        child: GradientButton(
                          text: actionLabel,
                          onPressed: onActionTap!,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade700;
    String text = "مجهول";

    if (status == 'open') {
      bg = Colors.blue.withValues(alpha: 0.1);
      fg = Colors.blue;
      text = "مفتوح";
    } else if (status == 'in_progress') {
      bg = Colors.orange.withValues(alpha: 0.1);
      fg = Colors.orange;
      text = "قيد التنفيذ";
    } else if (status == 'completed') {
      bg = Colors.green.withValues(alpha: 0.1);
      fg = Colors.green;
      text = "مكتمل";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

