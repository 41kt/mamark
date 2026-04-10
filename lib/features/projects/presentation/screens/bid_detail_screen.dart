import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../contractor/presentation/providers/contractor_providers.dart';

class BidDetailScreen extends ConsumerStatefulWidget {
  final String bidId;
  const BidDetailScreen({super.key, required this.bidId});

  @override
  ConsumerState<BidDetailScreen> createState() => _BidDetailScreenState();
}

class _BidDetailScreenState extends ConsumerState<BidDetailScreen> {
  bool _isLoading = false;

  String _fmt(dynamic v) {
    if (v == null) return '—';
    final n = double.tryParse(v.toString()) ?? 0;
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)} مليون ر.ي";
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(0)} ألف ر.ي";
    return "${n.toStringAsFixed(0)} ر.ي";
  }

  Future<void> _updateBidStatus(String bidId, String projectId, String contractorId, String status) async {
    setState(() => _isLoading = true);
    try {
      final supabase = ref.read(supabaseProvider);

      if (status == 'accepted') {
        // 1. Update the selected bid
        await supabase.from('bids').update({'status': 'accepted'}).eq('id', bidId);

        // 2. Update the project status and assigned contractor
        await supabase.from('projects').update({
          'status': 'assigned',
          'assigned_contractor_id': contractorId,
        }).eq('id', projectId);

        // 3. Optionally reject other bids (managed by DB ideally, but can do here)
        await supabase
            .from('bids')
            .update({'status': 'rejected'})
            .eq('project_id', projectId)
            .neq('id', bidId)
            .eq('status', 'pending');
      } else {
        // Just reject this bid
        await supabase.from('bids').update({'status': 'rejected'}).eq('id', bidId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'accepted' ? "تم قبول العرض والتعاقد بنجاح" : "تم رفض العرض",
                style: GoogleFonts.cairo()),
            backgroundColor: status == 'accepted' ? AppColors.success : Colors.orange,
          ),
        );
        Get.back();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ: $e", style: GoogleFonts.cairo()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bidAsync = ref.watch(bidDetailsProvider(widget.bidId));

    return Scaffold(
      appBar: AppBar(
        title: const Text("تفاصيل العرض"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: bidAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("خطأ: $e", style: GoogleFonts.cairo())),
        data: (bid) {
          if (bid == null) return const Center(child: Text("العرض غير موجود"));

          final contractor = bid['contractors'] as Map<String, dynamic>?;
          final project = bid['projects'] as Map<String, dynamic>?;
          final bidStatus = bid['status'] as String? ?? 'pending';
          final projectStatus = project?['status'] as String? ?? 'open';
          final canAction = bidStatus == 'pending' && projectStatus == 'open';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bid Value Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                        ),
                        child: Column(
                          children: [
                            Text("القيمة المقدمة", style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13)),
                            Text(_fmt(bid['total_amount']),
                                style: GoogleFonts.cairo(
                                    fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildBidInfoItem(Icons.timer_outlined, "المدة", "${bid['duration_days']} يوم"),
                                _buildBidInfoItem(Icons.verified_user_outlined, "الضمان", bid['warranty_details'] ?? "غير محدد"),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      _buildSectionTitle("وصف العرض"),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          bid['description'] ?? 'لا يوجد وصف متاح.',
                          style: GoogleFonts.cairo(fontSize: 14, height: 1.7, color: Colors.grey.shade800),
                        ),
                      ),

                      const SizedBox(height: 24),
                      _buildSectionTitle("معلومات المقاول"),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.background,
                              backgroundImage: contractor?['profile_image_url'] != null
                                  ? NetworkImage(contractor!['profile_image_url'])
                                  : null,
                              child: contractor?['profile_image_url'] == null
                                  ? const Icon(Icons.person, size: 30, color: AppColors.primary)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(contractor?['user_name'] ?? '—',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text("${contractor?['avg_rating'] ?? '0.0'}", style: GoogleFonts.cairo(fontSize: 13)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
                                      const SizedBox(width: 4),
                                      Text(contractor?['cities']?['name_ar'] ?? '—',
                                          style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigate to contractor profile
                              },
                              child: Text("الملف الشخصي", style: GoogleFonts.cairo(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              if (canAction)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => _confirmAction(context, 'reject', bid, contractor),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("رفض العرض", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _confirmAction(context, 'accept', bid, contractor),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text("قبول وتعميد العرض", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                )
              else if (bidStatus == 'accepted')
                Container(
                  width: double.infinity,
                  color: Colors.green.shade50,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "✓ هذا العرض مقبول وتم التعاقد على تنفيذه.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                )
              else if (bidStatus == 'rejected')
                Container(
                  width: double.infinity,
                  color: Colors.red.shade50,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "✕ تم رفض هذا العرض.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBidInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 11)),
        Text(value, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
    );
  }

  void _confirmAction(BuildContext context, String type, Map<String, dynamic> bid, Map<String, dynamic>? contractor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'accept' ? "قبول العرض" : "رفض العرض", style: GoogleFonts.cairo()),
        content: Text(
          type == 'accept'
              ? "هل أنت متأكد من قبول عرض المقاول ${contractor?['user_name']}؟ سيتم التعاقد معه رسمياً وإغلاق المنافسة."
              : "هل أنت متأكد من رفض هذا العرض؟ لن يتمكن المقاول من التعديل عليه.",
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("إلغاء", style: GoogleFonts.cairo())),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateBidStatus(bid['id'], bid['project_id'], bid['contractor_id'], type == 'accept' ? 'accepted' : 'rejected');
            },
            style: ElevatedButton.styleFrom(backgroundColor: type == 'accept' ? AppColors.success : Colors.red),
            child: Text("تأكيد", style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

