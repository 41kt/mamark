import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../contractor/presentation/providers/contractor_providers.dart';
import 'package:get/get.dart';

class BidsListScreen extends ConsumerStatefulWidget {
  final String projectId;
  const BidsListScreen({super.key, required this.projectId});

  @override
  ConsumerState<BidsListScreen> createState() => _BidsListScreenState();
}

class _BidsListScreenState extends ConsumerState<BidsListScreen> {
  final Set<String> _selectedForComparison = {};

  String _fmt(dynamic v) {
    if (v == null) return '—';
    final n = double.tryParse(v.toString()) ?? 0;
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}م ر.ي";
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(0)}ألف ر.ي";
    return "${n.toStringAsFixed(0)} ر.ي";
  }

  @override
  Widget build(BuildContext context) {
    final bidsAsync = ref.watch(projectBidsProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: bidsAsync.when(
          data: (bids) => Text("عروض المشروع (${bids.length})", style: GoogleFonts.cairo(fontSize: 18)),
          loading: () => Text("عروض المشروع...", style: GoogleFonts.cairo(fontSize: 18)),
          error: (_, __) => Text("عروض المشروع", style: GoogleFonts.cairo(fontSize: 18)),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedForComparison.length == 2)
            TextButton.icon(
              icon: const Icon(Icons.compare_arrows, color: Colors.white),
              label: Text("مقارنة", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                // Future implementation: Navigate to comparison screen
              },
            ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: bidsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("خطأ في التحميل: $e", style: GoogleFonts.cairo())),
        data: (bids) {
          if (bids.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_late_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("لا توجد عروض مقدمة بعد", style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "اضغط مطولاً على أي عرضين لمقارنتهما جنباً إلى جنب",
                        style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: bids.length,
                  itemBuilder: (context, index) {
                    final bid = bids[index];
                    final bidId = bid['id'] as String;
                    final isSelected = _selectedForComparison.contains(bidId);
                    final contractor = bid['contractors'] as Map<String, dynamic>?;
                    final isVerified = contractor?['is_verified'] as bool? ?? false;
                    final totalAmount = bid['total_amount'] ?? 0;
                    final duration = bid['duration_days'] ?? 0;

                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          if (isSelected) {
                            _selectedForComparison.remove(bidId);
                          } else {
                            if (_selectedForComparison.length < 2) {
                              _selectedForComparison.add(bidId);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("يمكنك مقارنة عرضين كحد أقصى", style: GoogleFonts.cairo())),
                              );
                            }
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.accent : Colors.grey.shade100,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.background,
                                    backgroundImage: contractor?['profile_image_url'] != null 
                                        ? NetworkImage(contractor!['profile_image_url']) 
                                        : null,
                                    child: contractor?['profile_image_url'] == null 
                                        ? const Icon(Icons.person, color: AppColors.primary) 
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text("مقاول:", style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12)),
                                            const SizedBox(width: 4),
                                            Text(contractor?['user_name'] ?? '—', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            if (isVerified)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                                                child: Text("موثق ✓", style: GoogleFonts.cairo(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.star, color: Colors.amber, size: 14),
                                            Text(" ${contractor?['avg_rating'] ?? '0.0'}", style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("السعر الإجمالي", style: GoogleFonts.cairo(color: Colors.grey, fontSize: 11)),
                                      Text(_fmt(totalAmount), style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.timer_outlined, color: AppColors.primary, size: 16),
                                        const SizedBox(width: 6),
                                        Text("$duration يوم", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                bid['description'] ?? 'لا يوجد وصف متاح لهذا العرض.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(color: Colors.grey.shade700, fontSize: 13, height: 1.6),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Get.toNamed('/bid-details/$bidId'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        side: const BorderSide(color: AppColors.primary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Text("تفاصيل العرض", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => Get.toNamed('/bid-details/$bidId'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        elevation: 0,
                                      ),
                                      child: Text("مراجعة وقبول", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

