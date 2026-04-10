import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../customer/presentation/providers/customer_providers.dart';

// ─── Status config ─────────────────────────────────────────────
typedef _StatusCfg = ({String label, Color color, IconData icon});

const _statusMap = <String, _StatusCfg>{
  'pending':     (label: 'في الانتظار',  color: Color(0xFFF59E0B), icon: Icons.hourglass_empty),
  'open':        (label: 'مفتوح',         color: Color(0xFF3B82F6), icon: Icons.lock_open),
  'assigned':    (label: 'تم التكليف',   color: Color(0xFF8B5CF6), icon: Icons.person_pin),
  'in_progress': (label: 'قيد التنفيذ',  color: Color(0xFF10B981), icon: Icons.construction),
  'completed':   (label: 'منتهي',        color: Color(0xFF6B7280), icon: Icons.check_circle),
  'cancelled':   (label: 'ملغي',         color: Color(0xFFEF4444), icon: Icons.cancel),
  'archived':    (label: 'مؤرشف',        color: Color(0xFFD1D5DB), icon: Icons.archive),
};

// ─── Filter chip data ─────────────────────────────────────────
class _FilterOption {
  final String label;
  final String? statusKey; // null = "all"
  const _FilterOption(this.label, this.statusKey);
}

const _filterOptions = [
  _FilterOption('الكل',           null),
  _FilterOption('مفتوح',          'open'),
  _FilterOption('قيد التنفيذ',    'in_progress'),
  _FilterOption('منتهي',          'completed'),
  _FilterOption('ملغي',           'cancelled'),
];

// ═══════════════════════════════════════════════════════════════
// Screen
// ═══════════════════════════════════════════════════════════════
class MyProjectsListScreen extends ConsumerStatefulWidget {
  const MyProjectsListScreen({super.key});

  @override
  ConsumerState<MyProjectsListScreen> createState() => _MyProjectsListScreenState();
}

class _MyProjectsListScreenState extends ConsumerState<MyProjectsListScreen>
    with SingleTickerProviderStateMixin {
  String? _activeFilter; // null = all
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> all) {
    if (_activeFilter == null) return all;
    return all.where((p) => p['status'] == _activeFilter).toList();
  }

  Future<void> _refresh() async {
    ref.invalidate(myProjectsStreamProvider);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(myProjectsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      floatingActionButton: _buildFab(context),
      body: Column(
        children: [
          _buildFilterBar(),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: projectsAsync.when(
              data: (projects) {
                final filtered = _applyFilter(projects);
                if (filtered.isEmpty) return _buildEmptyState(context);
                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppColors.primary,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _ProjectCard(
                      project: filtered[i],
                      onTap: () => Get.toNamed('/project-details/${filtered[i]['id']}'),
                    ),
                  ),
                );
              },
              loading: () => _buildShimmer(),
              error: (e, _) => _buildError(e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      title: Text("مشاريعي", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          tooltip: "مشروع جديد",
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
          onPressed: () => Get.toNamed('/create-project'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Filter chips ─────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _filterOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final opt = _filterOptions[i];
          final selected = _activeFilter == opt.statusKey;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade300),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _activeFilter = opt.statusKey),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  opt.label,
                  style: GoogleFonts.cairo(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── FAB ─────────────────────────────────────────────────────
  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Get.toNamed('/create-project'),
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text("مشروع جديد", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  // ── Empty state ─────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    final isFiltered = _activeFilter != null;
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFiltered ? Icons.filter_alt_off : Icons.folder_open_outlined,
                    size: 72,
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isFiltered ? "لا توجد مشاريع في هذه الفئة" : "لا توجد مشاريع بعد",
                  style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  isFiltered
                      ? "جرّب فلتراً مختلفاً أو أضف مشروعاً جديداً"
                      : "ابدأ بنشر مشروعك الأول وسيتواصل معك المقاولون",
                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (!isFiltered)
                  ElevatedButton.icon(
                    onPressed: () => Get.toNamed('/create-project'),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text("أنشئ مشروعك الأول", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shimmer skeleton ─────────────────────────────────────────
  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => _ShimmerCard(),
    );
  }

  // ── Error ────────────────────────────────────────────────────
  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text("تعذّر تحميل المشاريع", style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(msg, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: Text("إعادة المحاولة", style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Project Card
// ═══════════════════════════════════════════════════════════════
class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final VoidCallback onTap;

  const _ProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = project['status'] as String? ?? 'open';
    final cfg = _statusMap[status] ?? (label: status, color: Colors.grey, icon: Icons.circle);
    final progress = ((project['progress_percentage'] ?? 0) as num).toDouble();
    final progressColor = progress >= 80
        ? Colors.green
        : progress >= 40
            ? AppColors.accent
            : AppColors.primary;

    final budgetMin = project['budget_min'];
    final budgetMax = project['budget_max'];
    final bidsCount = project['bids_count'] ?? 0;
    final createdAt = project['created_at']?.toString().split('T')[0] ?? '—';
    final city = project['cities']?['name_ar'] ?? 'غير محدد';
    final category = project['project_categories']?['name_ar'] ?? 'عام';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
        border: Border(left: BorderSide(color: cfg.color, width: 4)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: Title + Status badge ──────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        project['title'] ?? 'مشروع',
                        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(cfg: cfg),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Row 2: City + Category ───────────────────
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(city, style: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(width: 16),
                    const Icon(Icons.category_outlined, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(category, style: GoogleFonts.cairo(color: Colors.grey.shade600, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Row 3: Budget ────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      budgetMin != null && budgetMax != null
                          ? "${_fmt(budgetMin)} — ${_fmt(budgetMax)} ر.ي"
                          : "الميزانية غير محددة",
                      style: GoogleFonts.cairo(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Progress bar ─────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("نسبة الإنجاز", style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600)),
                        Text(
                          "${progress.toStringAsFixed(0)}%",
                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: progressColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 12),

                // ── Row 4: Bids count + Date + Details button ──
                Row(
                  children: [
                    // Bids
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline, size: 14, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            "$bidsCount عرض",
                            style: GoogleFonts.cairo(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Date
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(createdAt, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),

                    const Spacer(),

                    // Details button
                    ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      child: const Text("التفاصيل"),
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

  String _fmt(dynamic value) {
    if (value == null) return '—';
    final n = double.tryParse(value.toString()) ?? 0;
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}م";
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(0)}ألف";
    return n.toStringAsFixed(0);
  }
}

// ═══════════════════════════════════════════════════════════════
// Status Badge
// ═══════════════════════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final _StatusCfg cfg;
  const _StatusBadge({required this.cfg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, size: 11, color: cfg.color),
          const SizedBox(width: 4),
          Text(
            cfg.label,
            style: GoogleFonts.cairo(color: cfg.color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Shimmer skeleton card
// ═══════════════════════════════════════════════════════════════
class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skel(width: 200, height: 18),
            const SizedBox(height: 10),
            _skel(width: 140, height: 12),
            const SizedBox(height: 8),
            _skel(width: 180, height: 12),
            const SizedBox(height: 16),
            _skel(width: double.infinity, height: 8),
            const SizedBox(height: 16),
            Row(children: [_skel(width: 80, height: 28), const Spacer(), _skel(width: 80, height: 36)]),
          ],
        ),
      ),
    );
  }

  Widget _skel({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment(_anim.value - 1, 0),
          end: Alignment(_anim.value + 1, 0),
          colors: [Colors.grey.shade200, Colors.grey.shade100, Colors.grey.shade200],
        ),
      ),
    );
  }
}

