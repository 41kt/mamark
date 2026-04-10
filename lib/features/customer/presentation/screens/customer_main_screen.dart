import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/contractor_card.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../../core/widgets/stats_card.dart';
import '../../../../core/widgets/project_card.dart';
import '../../../../core/widgets/shimmer_loader.dart';

import '../providers/customer_providers.dart';

// تبويبات (Tabs)
import '../../../projects/presentation/screens/my_projects_list_screen.dart';
import '../../../products/presentation/views/home_view.dart';
import '../../../chat/presentation/screens/chats_list_screen.dart';

import '../../../../core/providers/supabase_provider.dart';

// ============================================================
// شاشة العميل الرئيسية
// ============================================================
class CustomerMainScreen extends ConsumerStatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  ConsumerState<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends ConsumerState<CustomerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CustomerHomeScreenTab(),
    const MyProjectsListScreen(),
    const HomeView(),
    const ChatsListScreen(),
    const CustomerProfileTab(),
  ];

  void changeTab(int index) {
    if (mounted) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: FloatingActionButton.extended(
                onPressed: () => Get.toNamed('/create-project'),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  "مشروع جديد",
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// ============================================================
// التبويب الأول: الصفحة الرئيسية (العميل)
// ============================================================
class CustomerHomeScreenTab extends ConsumerWidget {
  const CustomerHomeScreenTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(customerProfileProvider);
    final statsAsync = ref.watch(customerStatsProvider);
    final myProjectsAsync = ref.watch(myProjectsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: profileAsync.when(
          data: (p) => "مرحباً بك 👋 ${p?['user_name'] ?? ''}",
          loading: () => "مرحباً بك 👋",
          error: (_, __) => "مرحباً",
        ),
        subtitle: "جاهز لبناء مشروعك القادم؟",
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Get.toNamed('/browse-contractors'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => Get.toNamed('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerProfileProvider);
          ref.invalidate(customerStatsProvider);
          ref.invalidate(myProjectsStreamProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقتا الإجراء الرئيستان
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: "المتجر 🛒",
                      subtitle: "تصفح المنتجات",
                      icon: Icons.storefront_outlined,
                      color: Colors.orange,
                      onTap: () {
                        final nav = context
                            .findAncestorStateOfType<_CustomerMainScreenState>();
                        if (nav != null) {
                          nav.changeTab(2);
                        } else {
                          Get.toNamed('/marketplace');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      title: "نشر مشروع 🏗️",
                      subtitle: "أطرح مناقصة",
                      icon: Icons.post_add_rounded,
                      color: AppColors.primary,
                      onTap: () => Get.toNamed('/create-project'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // إحصائيات المشاريع
              Text(
                "إحصائيات مشاريعك",
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
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
                    StatsCard(
                      label: "مشاريع مفتوحة",
                      value: "${stats['open_projects'] ?? 0}",
                      icon: Icons.folder_open,
                      color: Colors.blue,
                    ),
                    StatsCard(
                      label: "قيد التنفيذ",
                      value: "${stats['in_progress'] ?? 0}",
                      icon: Icons.sync,
                      color: Colors.orange,
                    ),
                    StatsCard(
                      label: "مشاريع مكتملة",
                      value: "${stats['completed_projects'] ?? 0}",
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    StatsCard(
                      label: "عروض جديدة",
                      value: "${stats['new_bids'] ?? 0}",
                      icon: Icons.local_offer_outlined,
                      color: AppColors.accent,
                    ),
                  ],
                ),
                loading: () =>
                    const ShimmerLoader(width: double.infinity, height: 200),
                error: (err, __) => Center(
                  child: Text(
                    "خطأ في تحميل الإحصائيات: $err",
                    style: GoogleFonts.cairo(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // شريط البحث عن مقاولين
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  readOnly: true,
                  onTap: () => Get.toNamed('/browse-contractors'),
                  decoration: InputDecoration(
                    hintText: "ابحث عن أفضل المقاولين لمشروعك...",
                    hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune, color: AppColors.primary, size: 20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // مقاولون مقترحون
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "مقاولون مقترحون لك",
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed('/browse-contractors'),
                    child: Text(
                      "عرض الكل",
                      style: GoogleFonts.cairo(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 180,
                child: Consumer(
                  builder: (context, ref, child) {
                    final recommendedAsync = ref.watch(recommendedContractorsProvider);
                    return recommendedAsync.when(
                      data: (contractors) {
                        if (contractors.isEmpty) {
                          return Center(
                            child: Text(
                              "لا يوجد مقاولين حالياً متاحين في مدينتك.",
                              style: GoogleFonts.cairo(color: Colors.grey),
                            ),
                          );
                        }
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: contractors.length,
                          itemBuilder: (context, index) {
                            final c = contractors[index];
                            return ContractorCard(
                              contractor: c,
                              onTap: () {
                                Get.toNamed('/contractor-profile/${c['id']}');
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, __) => Center(
                        child: Text("خطأ: $e", style: GoogleFonts.cairo(color: Colors.red)),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // أحدث المشاريع النشطة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "مشاريعي النشطة",
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final nav = context
                          .findAncestorStateOfType<_CustomerMainScreenState>();
                      if (nav != null) {
                        nav.changeTab(1);
                      } else {
                        Get.toNamed('/my-projects');
                      }
                    },
                    child: Text(
                      "عرض الكل",
                      style: GoogleFonts.cairo(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              myProjectsAsync.when(
                data: (projects) {
                  final activeProjects = projects
                      .where((p) => p['status'] != 'completed')
                      .take(3)
                      .toList();
                  if (activeProjects.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.folder_open_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            "ليس لديك مشاريع نشطة حالياً.",
                            style: GoogleFonts.cairo(color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => Get.toNamed('/create-project'),
                            icon: const Icon(Icons.add, size: 16),
                            label: Text("أنشئ مشروعك الأول", style: GoogleFonts.cairo()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: activeProjects
                        .map(
                          (p) => ProjectCard(
                            project: p,
                            onTap: () =>
                                Get.toNamed('/project-details/${p['id']}'),
                            actionLabel: "التفاصيل",
                            hasAction: true,
                            onActionTap: () =>
                                Get.toNamed('/project-details/${p['id']}'),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => Column(
                  children: List.generate(2, (index) => const ShimmerCard()),
                ),
                error: (err, __) => Text(
                  "فشل في جلب المشاريع: $err",
                  style: GoogleFonts.cairo(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// التبويب الخامس: حسابي (الملف الشخصي للعميل)
// ============================================================
class CustomerProfileTab extends ConsumerWidget {
  const CustomerProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(customerProfileProvider);
    final statsAsync = ref.watch(customerStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text("لم يتم العثور على بروفايل"));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white24,
                          backgroundImage: profile['profile_image_url'] != null
                              ? NetworkImage(profile['profile_image_url'])
                              : null,
                          child: profile['profile_image_url'] == null
                              ? const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          profile['user_name'] ?? 'الاسم غير متوفر',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          profile['user_email'] ?? profile['email'] ?? '',
                          style: GoogleFonts.cairo(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: statsAsync.when(
                    data: (stats) => Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniStat(
                            "مشاريعك",
                            "${(stats['open_projects'] ?? 0) + (stats['in_progress'] ?? 0)}",
                            Icons.folder_outlined,
                          ),
                          _buildMiniStat(
                            "طلباتك",
                            "0",
                            Icons.shopping_bag_outlined,
                          ),
                          _buildMiniStat(
                            "مفضلاتك",
                            "0",
                            Icons.favorite_border,
                          ),
                        ],
                      ),
                    ),
                    loading: () => const ShimmerCard(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionTitle("إدارة الحساب"),
                  _buildMenuTile(
                    icon: Icons.person_outline,
                    title: "تعديل الملف الشخصي",
                    onTap: () => Get.toNamed('/edit-profile'),
                    color: Colors.purple,
                  ),
                  _buildMenuTile(
                    icon: Icons.lock_outline,
                    title: "تغيير كلمة المرور",
                    onTap: () => Get.toNamed('/change-password'),
                    color: Colors.orange,
                  ),

                  _buildSectionTitle("نشاطاتي"),
                  _buildMenuTile(
                    icon: Icons.folder_outlined,
                    title: "مشاريعي",
                    onTap: () => Get.toNamed('/my-projects'),
                    color: Colors.blue,
                  ),
                  _buildMenuTile(
                    icon: Icons.history,
                    title: "تاريخ الطلبات",
                    onTap: () => Get.toNamed('/orders'),
                    color: Colors.green,
                  ),
                  _buildMenuTile(
                    icon: Icons.favorite_border,
                    title: "المفضلة",
                    onTap: () => Get.toNamed('/favorites'),
                    color: Colors.red,
                  ),

                  _buildSectionTitle("الدعم والخصوصية"),
                  _buildMenuTile(
                    icon: Icons.settings_outlined,
                    title: "الإعدادات",
                    onTap: () => Get.toNamed('/settings'),
                    color: Colors.grey,
                  ),
                  _buildMenuTile(
                    icon: Icons.help_outline,
                    title: "مركز المساعدة",
                    onTap: () {},
                    color: Colors.teal,
                  ),
                  _buildMenuTile(
                    icon: Icons.privacy_tip_outlined,
                    title: "سياسة الخصوصية",
                    onTap: () {},
                    color: Colors.indigo,
                  ),

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ref.read(supabaseProvider).auth.signOut();
                        Get.offAllNamed('/login');
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: Text(
                        "تسجيل الخروج",
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text("خطأ في تحميل البيانات: $e", style: GoogleFonts.cairo()),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: GoogleFonts.cairo(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
            )
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}

// ============================================================
// ShimmerCard
// ============================================================
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const ShimmerLoader(width: double.infinity, height: 100),
    );
  }
}
