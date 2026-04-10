import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../providers/contractor_providers.dart';
import '../../../../core/theme/app_colors.dart';

class ContractorHomeScreen extends ConsumerWidget {
  const ContractorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(contractorProfileProvider);
    final statsAsync = ref.watch(contractorStatsProvider);
    final suggestedAsync = ref.watch(openProjectsProvider);
    final bidsAsync = ref.watch(contractorBidsProvider);
    final completionAsync = ref.watch(profileCompletionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(contractorProfileProvider);
          ref.invalidate(contractorStatsProvider);
          ref.invalidate(openProjectsProvider);
          ref.invalidate(contractorBidsProvider);
          ref.invalidate(profileCompletionProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.primary,
              title: profileAsync.when(
                data: (p) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("مرحباً 👋", style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70)),
                    Text(
                      p?['user_name'] ?? 'المقاول',
                      style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                loading: () => Text("لوحة المقاول", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                error: (_, __) => Text("لوحة المقاول", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              actions: [
                IconButton(
                  icon: const Badge(
                    label: Text("3"),
                    child: Icon(Icons.notifications_outlined, color: Colors.white),
                  ),
                  onPressed: () => Get.toNamed('/notifications'),
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verification Warning
                    profileAsync.when(
                      data: (p) {
                        final isVerified = p?['is_verified'] as bool? ?? false;
                        if (!isVerified) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.orange.shade50, Colors.orange.shade100]),
                              border: Border.all(color: Colors.orange.shade300),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("حسابك قيد المراجعة", style: GoogleFonts.cairo(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Text(
                                        "لا يمكنك تقديم عروض حتى نوافق على حسابك وتوثيق بياناتك.",
                                        style: GoogleFonts.cairo(color: Colors.orange.shade800, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Stats Grid 2x2
                    statsAsync.when(
                      data: (stats) => GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.55,
                        children: [
                          _buildStatCard("عروضي المعلقة", "${stats['pending']}", Colors.orange, Icons.timer_outlined),
                          _buildStatCard("مشاريعي النشطة", "${stats['active']}", Colors.green, Icons.construction_outlined),
                          _buildStatCard("العروض المقبولة", "${stats['accepted']}", Colors.blue, Icons.check_circle_outline),
                          _buildStatCard("متوسط تقييمي", "${stats['rating']} ⭐", Colors.amber, Icons.star_outline),
                        ],
                      ),
                      loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
                      error: (e, _) => _buildErrorCard("تعذّر تحميل الإحصائيات"),
                    ),

                    const SizedBox(height: 28),

                    // Suggested Projects
                    _buildSectionHeader(context, "مشاريع جديدة تناسبك", onSeeAll: () => Get.offAllNamed('/contractor/browse-projects')),
                    const SizedBox(height: 12),
                    suggestedAsync.when(
                      data: (projects) {
                        if (projects.isEmpty) {
                          return _buildEmptyState("لا توجد مشاريع مفتوحة في مدينتك حالياً", Icons.search_off);
                        }
                        final preview = projects.take(3).toList();
                        return Column(
                          children: preview.map((p) => _buildProjectTile(context, p)).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => _buildErrorCard("تعذّر تحميل المشاريع"),
                    ),

                    const SizedBox(height: 28),

                    // Last Bids
                    _buildSectionHeader(context, "آخر عروضي", onSeeAll: () => Get.offAllNamed('/contractor/my-bids')),
                    const SizedBox(height: 12),
                    bidsAsync.when(
                      data: (bids) {
                        if (bids.isEmpty) {
                          return _buildEmptyState("لم تقدّم أي عروض حتى الآن", Icons.assignment_outlined);
                        }
                        final preview = bids.take(3).toList();
                        return Column(
                          children: preview.map((b) => _buildBidTile(context, b)).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => _buildErrorCard("تعذّر تحميل العروض"),
                    ),

                    const SizedBox(height: 28),

                    // Profile Completion
                    completionAsync.when(
                      data: (pct) => _buildProfileCompletionCard(context, pct),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text("عرض الكل", style: GoogleFonts.cairo(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildProjectTile(BuildContext context, Map<String, dynamic> project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.architecture, color: AppColors.primary, size: 22),
        ),
        title: Text(
          project['title'] ?? 'مشروع',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 12, color: AppColors.primary),
            const SizedBox(width: 2),
            Text(
              "${project['cities']?['name_ar'] ?? 'غير محدد'} · ${project['project_categories']?['name_ar'] ?? 'عام'}",
              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${_formatBudget(project['budget_min'])} - ${_formatBudget(project['budget_max'])}",
              style: GoogleFonts.cairo(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
        onTap: () => Get.toNamed('/project-details/${project['id']}'),
      ),
    );
  }

  Widget _buildBidTile(BuildContext context, Map<String, dynamic> bid) {
    final status = bid['status'] as String? ?? 'pending';
    final statusMap = {
      'pending': ('قيد الانتظار', Colors.orange),
      'accepted': ('مقبول ✓', Colors.green),
      'rejected': ('مرفوض', Colors.red),
      'withdrawn': ('تم السحب', Colors.grey),
    };
    final (statusText, statusColor) = statusMap[status] ?? ('غير معروف', Colors.grey);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text(
          bid['projects']?['title'] ?? 'مشروع غير معروف',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          "تقديم: ${bid['created_at'].toString().split('T')[0]}",
          style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${_formatBudget(bid['bid_price'])} ر.ي",
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(statusText, style: GoogleFonts.cairo(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        onTap: () => Get.toNamed('/project-details/${bid['project_id']}'),
      ),
    );
  }

  Widget _buildProfileCompletionCard(BuildContext context, int pct) {
    final color = pct >= 80 ? Colors.green : pct >= 50 ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.primary.withValues(alpha: 0.02)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("اكتمال ملفك الشخصي", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
              Text("$pct%", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 12),
          if (pct < 100)
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pct < 50
                        ? "أكمل ملفك لتحسين ظهورك للعملاء وزيادة فرص قبول عروضك"
                        : "أنت قريب من الاكتمال — أضف بقية بياناتك للحصول على شارة 'موثق'",
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Get.toNamed('/profile'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("اكتمل ملفك الآن", style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(message, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Text(message, style: GoogleFonts.cairo(color: Colors.red.shade700)),
        ],
      ),
    );
  }

  String _formatBudget(dynamic value) {
    if (value == null) return '—';
    final num = double.tryParse(value.toString()) ?? 0;
    if (num >= 1000000) return "${(num / 1000000).toStringAsFixed(1)}م";
    if (num >= 1000) return "${(num / 1000).toStringAsFixed(0)}ألف";
    return value.toString();
  }
}

