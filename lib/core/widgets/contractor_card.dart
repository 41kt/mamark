import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ContractorCard extends StatelessWidget {
  final Map<String, dynamic> contractor;
  final VoidCallback onTap;

  const ContractorCard({
    super.key,
    required this.contractor,
    required this.onTap,
  });

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
    String cityName = contractor['city']?.toString() ?? 
                      contractor['location']?.toString() ?? 
                      contractor['address']?.toString() ?? 
                      _getNestedValue(contractor, 'cities', 'name_ar');

    final avatar = contractor['profile_image_url'] as String?;
    final rating = contractor['avg_rating']?.toString() ?? '0.0';
    final reviews = contractor['reviews_count']?.toString() ?? '0';

    return Container(
      width: 260,
      margin: const EdgeInsets.only(left: 16),
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
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null ? const Icon(Icons.business, color: Colors.grey) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contractor['user_name'] ?? 'مقاول',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                cityName,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          " ($reviews)",
                          style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "التفاصيل",
                        style: GoogleFonts.cairo(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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
}

