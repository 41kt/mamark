import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../../core/widgets/project_card.dart';
import '../../../../core/widgets/shimmer_loader.dart';
import '../../../../core/widgets/stats_card.dart';
import '../providers/contractor_providers.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../chat/presentation/screens/chats_list_screen.dart';

// ═══════════════════════════════════════════════
// Main shell — BottomNav with 5 tabs
// ═══════════════════════════════════════════════
class ContractorMainScreen extends ConsumerStatefulWidget {
  const ContractorMainScreen({super.key});

  @override
  ConsumerState<ContractorMainScreen> createState() =>
      _ContractorMainScreenState();
}

class _ContractorMainScreenState extends ConsumerState<ContractorMainScreen> {
  int _currentIndex = 0;

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const ContractorHomeTab();
      case 1:
        return const AvailableProjectsTab();
      case 2:
        return const MyBidsTab();
      case 3:
        return const ChatsListScreen();
      case 4:
        return const ContractorProfileTab();
      default:
        return const ContractorHomeTab();
    }
  }

  void changeTab(int index) {
    if (mounted) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildScreen(_currentIndex),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
            ),
          ),
        ],
      ),
    );
  }
}

class ContractorHomeTab extends ConsumerWidget {
  const ContractorHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(contractorProfileProvider);
    final statsAsync = ref.watch(contractorStatsProvider);
    final suggestedAsync = ref.watch(openProjectsProvider);
    final bidsAsync = ref.watch(contractorBidsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Premium SliverAppBar — same as store ──
          SliverAppBar(
            expandedHeight: 130.0,
            floating: true,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
              title: profileAsync.when(
                data: (p) => Text(
                  "مرحباً 👷 ${p?['user_name'] ?? 'المقاول'}",
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                ),
                loading: () => Text("معمارك — المقاول", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                error: (_, __) => Text("معمارك", style: GoogleFonts.cairo(color: Colors.white, fontSize: 16)),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade900, Colors.blue.shade700],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () => Get.toNamed('/notifications'),
              ),
              IconButton(
                icon: const Icon(Icons.storefront_outlined, color: Colors.white),
                onPressed: () => Get.toNamed('/marketplace'),
                tooltip: "المتجر",
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Body Content ──
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(contractorProfileProvider);
                ref.invalidate(contractorStatsProvider);
                ref.invalidate(openProjectsProvider);
                ref.invalidate(contractorBidsProvider);
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
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
                                      Text("حسابك قيد المراجعة", style: GoogleFonts.cairo(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text("أكمل توثيق بياناتك للتمكن من تقديم عروضك.", style: GoogleFonts.cairo(color: Colors.orange.shade800, fontSize: 11)),
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

                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: Icons.folder_open_rounded,
                            label: "المشاريع",
                            subtitle: "تصفح المناقصات",
                            color: const Color(0xFF1E3A8A),
                            onTap: () {
                              final nav = context.findAncestorStateOfType<_ContractorMainScreenState>();
                              if (nav != null) nav.changeTab(1);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: Icons.handshake_rounded,
                            label: "عروضي",
                            subtitle: "متابعة عروضك",
                            color: Colors.green.shade700,
                            onTap: () {
                              final nav = context.findAncestorStateOfType<_ContractorMainScreenState>();
                              if (nav != null) nav.changeTab(2);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Stats
                    Text("إحصائيات الأداء", style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 12),
                    statsAsync.when(
                      data: (stats) => GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          StatsCard(label: "عروضي المعلقة", value: "${stats['pending']}", icon: Icons.timer_outlined, color: Colors.orange),
                          StatsCard(label: "مشاريعي النشطة", value: "${stats['active']}", icon: Icons.construction_outlined, color: Colors.green),
                          StatsCard(label: "العروض المقبولة", value: "${stats['accepted']}", icon: Icons.check_circle_outline, color: Colors.blue),
                          StatsCard(label: "التقييم", value: "${stats['rating']} ⭐", icon: Icons.star_outline, color: Colors.amber),
                        ],
                      ),
                      loading: () => const ShimmerLoader(width: double.infinity, height: 200),
                      error: (_, __) => const Text("فشل تحميل الإحصائيات"),
                    ),

                    const SizedBox(height: 20),

                    // Marketplace Banner — matching store design
                    GestureDetector(
                      onTap: () => Get.toNamed('/marketplace'),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade900, Colors.blue.shade700],
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade900.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                              child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("سوق معمارك للمواد 🏪", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text("اطلب المواد والأدوات لمشاريعك الآن", style: GoogleFonts.cairo(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Suggested Projects
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("مشاريع تناسبك", style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        TextButton(
                          onPressed: () {
                            final nav = context.findAncestorStateOfType<_ContractorMainScreenState>();
                            if (nav != null) nav.changeTab(1);
                          },
                          child: Text("الكل", style: GoogleFonts.cairo(color: AppColors.accent, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    suggestedAsync.when(
                      data: (projects) {
                        if (projects.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                            child: Text("لا توجد مشاريع متاحة.", style: GoogleFonts.cairo(color: Colors.grey)),
                          );
                        }
                        return Column(
                          children: projects.take(3).map((p) => ProjectCard(
                            project: p,
                            actionLabel: "تقديم عرض",
                            onTap: () => Get.toNamed('/project-details/${p['id']}'),
                            onActionTap: () => Get.toNamed('/create-bid/${p['id']}'),
                          )).toList(),
                        );
                      },
                      loading: () => Column(children: List.generate(2, (index) => const ShimmerCard())),
                      error: (_, __) => const Text("فشل في جلب المشاريع"),
                    ),

                    const SizedBox(height: 24),

                    // My Latest Bids
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("آخر عروضي", style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        TextButton(
                          onPressed: () {
                            final nav = context.findAncestorStateOfType<_ContractorMainScreenState>();
                            if (nav != null) nav.changeTab(2);
                          },
                          child: Text("الكل", style: GoogleFonts.cairo(color: AppColors.accent, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    bidsAsync.when(
                      data: (bids) {
                        if (bids.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                            child: Text("لم تقدّم أي عروض حتى الآن.", style: GoogleFonts.cairo(color: Colors.grey)),
                          );
                        }
                        return Column(
                          children: bids.take(3).map((b) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                                child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                              ),
                              title: Text(b['projects']?['title'] ?? 'مشروع غير معروف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text("مبلغ العرض: ${b['bid_price']} ريال", style: GoogleFonts.cairo(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: b['status'] == 'accepted' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  b['status'] == 'accepted' ? 'مقبول' : 'قيد الانتظار',
                                  style: GoogleFonts.cairo(color: b['status'] == 'accepted' ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              onTap: () => Get.toNamed('/project-details/${b['project_id']}'),
                            ),
                          )).toList(),
                        );
                      },
                      loading: () => Column(children: List.generate(2, (index) => const ShimmerCard())),
                      error: (_, __) => const Text("فشل في جلب العروض"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 10),
            Text(label, style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            Text(subtitle, style: GoogleFonts.cairo(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Tab 2 — Available Projects (browse all)
// ═══════════════════════════════════════════════
class AvailableProjectsTab extends ConsumerWidget {
  const AvailableProjectsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(allOpenProjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "المشاريع المتاحة",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      backgroundColor: AppColors.background,
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "لا توجد مشاريع مفتوحة حالياً",
                    style: GoogleFonts.cairo(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return GestureDetector(
                onTap: () => Get.toNamed('/project-details/${project['id']}'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                project['title'],
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                project['project_categories']?['name_ar'] ??
                                    'عام',
                                style: GoogleFonts.cairo(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          project['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              project['cities']?['name_ar'] ?? 'غير محدد',
                              style: GoogleFonts.cairo(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.payments_outlined,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${project['budget_min'] ?? '—'} - ${project['budget_max'] ?? '—'} ر.ي",
                              style: GoogleFonts.cairo(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                Get.toNamed('/create-bid/${project['id']}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "تقديم عرض",
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text("خطأ: $e", style: GoogleFonts.cairo())),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Tab 3 — My Bids / My Assigned Projects
// ═══════════════════════════════════════════════
class MyBidsTab extends ConsumerStatefulWidget {
  const MyBidsTab({super.key});

  @override
  ConsumerState<MyBidsTab> createState() => _MyBidsTabState();
}

class _MyBidsTabState extends ConsumerState<MyBidsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bidsAsync = ref.watch(contractorBidsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "عروضي ومشاريعي",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        bottom: bidsAsync.maybeWhen(
          data: (bids) {
            // Consistent filtering logic for counts
            final accepted = bids.where((b) {
              return b['status'] == 'accepted' ||
                  (b['projects']?['assigned_contractor_id'] != null &&
                      b['projects']?['assigned_contractor_id'].toString() ==
                          b['contractor_id'].toString());
            }).length;

            final pending = bids.where((b) {
              final isAccepted =
                  b['status'] == 'accepted' ||
                  (b['projects']?['assigned_contractor_id'] != null &&
                      b['projects']?['assigned_contractor_id'].toString() ==
                          b['contractor_id'].toString());
              return b['status'] == 'pending' && !isAccepted;
            }).length;

            final rejected = bids
                .where((b) => b['status'] == 'rejected')
                .length;

            return TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              labelStyle: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              tabs: [
                Tab(text: "المعلقة ($pending)"),
                Tab(text: "المقبولة ($accepted)"),
                Tab(text: "المرفوضة ($rejected)"),
              ],
            );
          },
          orElse: () => TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            tabs: const [
              Tab(text: "المعلقة"),
              Tab(text: "المقبولة"),
              Tab(text: "المرفوضة"),
            ],
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: bidsAsync.when(
        data: (bids) {
          final acceptedBids = bids.where((b) {
            return b['status'] == 'accepted' ||
                (b['projects']?['assigned_contractor_id'] != null &&
                    b['projects']?['assigned_contractor_id'].toString() ==
                        b['contractor_id'].toString());
          }).toList();

          final pendingBids = bids.where((b) {
            final isAccepted =
                b['status'] == 'accepted' ||
                (b['projects']?['assigned_contractor_id'] != null &&
                    b['projects']?['assigned_contractor_id'].toString() ==
                        b['contractor_id'].toString());
            return b['status'] == 'pending' && !isAccepted;
          }).toList();

          final rejectedBids = bids
              .where((b) => b['status'] == 'rejected')
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBidList(context, pendingBids, 'pending'),
              _buildBidList(context, acceptedBids, 'accepted'),
              _buildBidList(context, rejectedBids, 'rejected'),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text("خطأ: $e", style: GoogleFonts.cairo())),
      ),
    );
  }

  Widget _buildBidList(
    BuildContext context,
    List<Map<String, dynamic>> bids,
    String statusType,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(contractorBidsProvider);
        return await ref.read(contractorBidsProvider.future);
      },
      child: bids.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        statusType == 'accepted'
                            ? Icons.construction_outlined
                            : Icons.assignment_outlined,
                        size: 70,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        statusType == 'pending'
                            ? "لا توجد عروض قيد الانتظار حالياً"
                            : statusType == 'accepted'
                            ? "لم يتم قبول أي عرض حتى الآن"
                            : "لا توجد عروض مرفوضة",
                        style: GoogleFonts.cairo(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: bids.length,
              itemBuilder: (context, index) {
                final bid = bids[index];
                final status = bid['status'] as String? ?? 'pending';
                final project = bid['projects'] as Map<String, dynamic>?;
                final projectStatus = project?['status'] as String? ?? 'open';
                final assignedId = project?['assigned_contractor_id']
                    ?.toString();
                final isMeAssigned =
                    assignedId != null &&
                    assignedId == bid['contractor_id'].toString();

                final statusMap = {
                  'pending': ('قيد الانتظار', Colors.orange),
                  'accepted': ('مقبول ✓', Colors.green),
                  'rejected': ('مرفوض', Colors.red),
                  'withdrawn': ('تم السحب', Colors.grey),
                };

                var (statusText, statusColor) =
                    statusMap[status] ?? ('غير معروف', Colors.grey);

                // If it's assigned to me but status is still pending (fallback display)
                if (isMeAssigned && status == 'pending') {
                  statusText = 'تم التعميد ✓';
                  statusColor = Colors.green;
                }

                final isRunning =
                    (status == 'accepted' || isMeAssigned) &&
                    (projectStatus == 'assigned' ||
                        projectStatus == 'in_progress');

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isRunning
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (isRunning) {
                          Get.toNamed(
                            '/project-execution/${bid['project_id']}',
                          );
                        } else {
                          Get.toNamed('/project-details/${bid['project_id']}');
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isRunning
                                        ? Icons.play_circle_fill
                                        : Icons.assignment,
                                    color: statusColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project?['title'] ?? 'مشروع',
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        "${project?['cities']?['name_ar'] ?? '—'} · ${bid['created_at'].toString().split('T')[0]}",
                                        style: GoogleFonts.cairo(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${bid['bid_price']} ر.ي",
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: GoogleFonts.cairo(
                                          color: statusColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (isRunning) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.flash_on,
                                    size: 14,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "المشروع قيد التنفيذ - اضغط للمتابعة",
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ═══════════════════════════════════════════════
// Tab 5 — Contractor Profile
// ═══════════════════════════════════════════════
class ContractorProfileTab extends ConsumerWidget {
  const ContractorProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(contractorProfileProvider);
    final statsAsync = ref.watch(contractorStatsProvider);
    final completionAsync = ref.watch(profileCompletionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "لم يتم العثور على بروفايل مقاول",
                    style: GoogleFonts.cairo(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final isVerified = profile['is_verified'] as bool? ?? false;

          return CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, Color(0xFF1E3A8A)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  (profile['profile_image_url'] != null &&
                                      profile['profile_image_url'] != '')
                                  ? NetworkImage(profile['profile_image_url'])
                                  : null,
                              child:
                                  (profile['profile_image_url'] == null ||
                                      profile['profile_image_url'] == '')
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: AppColors.primary,
                                    )
                                  : null,
                            ),
                            if (isVerified)
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          profile['user_name'] ?? 'مقاول',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          profile['specialty'] ?? 'مقاول عام',
                          style: GoogleFonts.cairo(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: Column(
                    children: [
                      // Stats row
                      statsAsync.when(
                        data: (stats) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              SizedBox(
                                width: (MediaQuery.of(context).size.width - 60) / 3,
                                child: _buildQuickInfo(
                                  "التقييم",
                                  "${stats['rating']} ⭐",
                                  Colors.amber,
                                ),
                              ),
                              SizedBox(
                                width: (MediaQuery.of(context).size.width - 60) / 3,
                                child: _buildQuickInfo(
                                  "العروض المقبولة",
                                  "${stats['accepted']}",
                                  Colors.green,
                                ),
                              ),
                              SizedBox(
                                width: (MediaQuery.of(context).size.width - 60) / 3,
                                child: _buildQuickInfo(
                                  "النشطة",
                                  "${stats['active']}",
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      // Profile completion bar
                      completionAsync.when(
                        data: (pct) => Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "اكتمال الملف",
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    "$pct%",
                                    style: GoogleFonts.cairo(
                                      color: pct >= 80
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: pct / 100,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pct >= 80 ? Colors.green : Colors.orange,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                minHeight: 8,
                              ),
                            ],
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      _buildMenuGroup("الملف المهني", [
                        _buildMenuTile(
                          context,
                          Icons.assignment_ind_outlined,
                          "تعديل الملف الشخصي",
                          "الاسم، التخصص، النبذة",
                          () => Get.toNamed('/edit-profile'),
                        ),
                        _buildMenuTile(
                          context,
                          Icons.image_outlined,
                          "معرض الأعمال",
                          "مشاريعك المنفذة السابقة",
                          () => Get.toNamed('/portfolio'),
                        ),
                      ]),

                      const SizedBox(height: 16),

                      _buildMenuGroup("نشاطي", [
                        _buildMenuTile(
                          context,
                          Icons.work_outline,
                          "مشاريعي",
                          "المشاريع التي تعمل عليها",
                          () {
                            final nav = context.findAncestorStateOfType<_ContractorMainScreenState>();
                            if (nav != null) nav.changeTab(1);
                          },
                        ),
                        _buildMenuTile(
                          context,
                          Icons.handshake_outlined,
                          "عروضي",
                          "عروض المناقصة المقدمة",
                          () {
                            final nav = context.findAncestorStateOfType<_ContractorMainScreenState>();
                            if (nav != null) nav.changeTab(2);
                          },
                        ),
                        _buildMenuTile(
                          context,
                          Icons.storefront_outlined,
                          "المتجر",
                          "تصفح مواد البناء",
                          () => Get.toNamed('/marketplace'),
                        ),
                      ]),

                      const SizedBox(height: 16),

                      _buildMenuGroup("الإعدادات", [
                        _buildMenuTile(
                          context,
                          Icons.notifications_none,
                          "الإشعارات",
                          "تخصيص إشعاراتك",
                          () => Get.toNamed('/notifications'),
                        ),
                        _buildMenuTile(
                          context,
                          Icons.settings,
                          "الإعدادات",
                          "",
                          () => Get.toNamed('/settings'),
                        ),
                      ]),

                      const SizedBox(height: 24),

                      ElevatedButton.icon(
                        onPressed: () async {
                          final supabase = ref.read(supabaseProvider);
                          await supabase.auth.signOut();
                          if (context.mounted) Get.offAllNamed('/login');
                        },
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: Text(
                          "تسجيل الخروج",
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          elevation: 0,
                          side: const BorderSide(color: Colors.red, width: 0.5),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text("خطأ: $e", style: GoogleFonts.cairo())),
      ),
    );
  }

  Widget _buildQuickInfo(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
            )
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 13,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}

