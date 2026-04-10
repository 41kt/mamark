import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../contractor/presentation/providers/contractor_providers.dart';
import '../../../chat/presentation/providers/chat_providers.dart';

// ─────────────────────────────────────────────────────────────
// Lazy providers (keyed by projectId)
// ─────────────────────────────────────────────────────────────
final _projectStagesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      projectId,
    ) async {
      final supabase = ref.read(supabaseProvider);
      final res = await supabase
          .from('project_stages')
          .select('*')
          .eq('project_id', projectId)
          .order('stage_order', ascending: true);
      return List<Map<String, dynamic>>.from(res);
    });

final _projectFilesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      projectId,
    ) async {
      final supabase = ref.read(supabaseProvider);
      final res = await supabase
          .from('files')
          .select('*')
          .eq('related_table', 'project')
          .eq('related_id', projectId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    });

// ─────────────────────────────────────────────────────────────
// Status helpers
// ─────────────────────────────────────────────────────────────
Color _statusColor(String? s) => switch (s) {
  'open' => const Color(0xFF3B82F6),
  'in_progress' => const Color(0xFF10B981),
  'assigned' => const Color(0xFF8B5CF6),
  'completed' => const Color(0xFF6B7280),
  'cancelled' => const Color(0xFFEF4444),
  'pending' => const Color(0xFFF59E0B),
  _ => const Color(0xFF9CA3AF),
};

String _statusLabel(String? s) => switch (s) {
  'open' => 'مفتوح',
  'in_progress' => 'قيد التنفيذ',
  'assigned' => 'تم التكليف',
  'completed' => 'منتهي',
  'cancelled' => 'ملغي',
  'pending' => 'في الانتظار',
  'archived' => 'مؤرشف',
  _ => s ?? '—',
};

String _stageStatusLabel(String? s) => switch (s) {
  'pending' => 'لم تبدأ',
  'in_progress' => 'جارية',
  'completed' => 'مكتملة',
  'delayed' => 'متأخرة',
  _ => s ?? '—',
};

Color _stageStatusColor(String? s) => switch (s) {
  'pending' => Colors.grey,
  'in_progress' => Colors.blue,
  'completed' => Colors.green,
  'delayed' => Colors.red,
  _ => Colors.grey,
};

String _fmt(dynamic v) {
  if (v == null) return '—';
  final n = double.tryParse(v.toString()) ?? 0;
  if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}م ر.ي";
  if (n >= 1000) return "${(n / 1000).toStringAsFixed(0)}ألف ر.ي";
  return "${n.toStringAsFixed(0)} ر.ي";
}

// ─────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────
class ProjectDetailsScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailsScreen> createState() =>
      _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends ConsumerState<ProjectDetailsScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  bool _descExpanded = false;

  bool _isLoading = false;

  // Track which tabs have been activated for lazy loading
  final Set<int> _loadedTabs = {0, 1}; // details + bids always loaded

  Future<void> _updateBidStatus(
    Map<String, dynamic> bidMap,
    String action,
  ) async {
    setState(() => _isLoading = true);
    try {
      final supabase = ref.read(supabaseProvider);
      final bidId = bidMap['id'].toString();
      final contractorId = bidMap['contractor_id'].toString();

      if (action == 'accept') {
        // 1. Update the selected bid to 'accepted'
        await supabase
            .from('bids')
            .update({'status': 'accepted'})
            .eq('id', bidId);

        // 2. Update the project status to 'assigned' and set the contractor
        await supabase
            .from('projects')
            .update({
              'status': 'assigned',
              'assigned_contractor_id': contractorId,
            })
            .eq('id', widget.projectId);

        // 3. Reject other pending bids for this project
        await supabase
            .from('bids')
            .update({'status': 'rejected'})
            .eq('project_id', widget.projectId)
            .neq('id', bidId)
            .eq('status', 'pending');

        // 4. Generate project stages from payment schedule
        final schedule = bidMap['payment_schedule'];
        if (schedule != null && schedule is List && schedule.isNotEmpty) {
          for (int i = 0; i < schedule.length; i++) {
            final step = schedule[i];
            await supabase.from('project_stages').insert({
              'project_id': widget.projectId,
              'stage_name': step['name'] ?? 'مرحلة ${i + 1}',
              'stage_description': 'دفعة مقترحة بنسبة: ${step['percentage']}%',
              'completion_percentage': 0,
              'status': 'pending',
              'stage_order': i + 1,
            });
          }
        } else {
          await supabase.from('project_stages').insert({
            'project_id': widget.projectId,
            'stage_name': 'تنفيذ إجمالي المشروع',
            'completion_percentage': 0,
            'status': 'pending',
            'stage_order': 1,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "تم قبول العرض والتعميد بنجاح!",
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Reject this specific bid
        await supabase
            .from('bids')
            .update({'status': 'rejected'})
            .eq('id', bidId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("تم رفض العرض", style: GoogleFonts.cairo()),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Refresh providers
      ref.invalidate(projectDetailsProvider(widget.projectId));
      ref.invalidate(projectBidsProvider(widget.projectId));
      ref.invalidate(_projectStagesProvider(widget.projectId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطأ: $e", style: GoogleFonts.cairo()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmBidAction(
    Map<String, dynamic> bid,
    String contractorName,
    String action,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          action == 'accept' ? "قبول عرض المقاول" : "رفض العرض",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          action == 'accept'
              ? "هل أنت متأكد من قبول عرض $contractorName؟ سيتم إغلاق المنافسة وتعميد المقاول للبدء في التنفيذ."
              : "هل أنت متأكد من رفض هذا العرض؟",
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("إلغاء", style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateBidStatus(bid, action);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'accept'
                  ? AppColors.success
                  : Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "تأكيد",
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() => _loadedTabs.add(_tabController.index));
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectDetailsProvider(widget.projectId));
    final bidsAsync = ref.watch(projectBidsProvider(widget.projectId));
    final currentUser = ref.watch(currentUserProvider);
    final contractorProfile = ref.watch(contractorProfileProvider).value;

    return projectAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.primary),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('خطأ')),
        body: Center(child: Text('$e', style: GoogleFonts.cairo())),
      ),
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                'المشروع غير موجود',
                style: GoogleFonts.cairo(fontSize: 18),
              ),
            ),
          );
        }

        final status = project['status'] as String? ?? 'open';
        final statusColor = _statusColor(status);
        final progress = ((project['progress_percentage'] ?? 0) as num)
            .toDouble();
        final bidsCount = bidsAsync.value?.length ?? project['bids_count'] ?? 0;
        // Owner check: compare current user with customer's user_id
        final customersDataRaw = project['customers'];
        String? customerUserId;
        if (customersDataRaw is List && customersDataRaw.isNotEmpty) {
          customerUserId = customersDataRaw[0]['user_id']?.toString();
        } else if (customersDataRaw is Map) {
          customerUserId = customersDataRaw['user_id']?.toString();
        }

        final isOwner =
            customerUserId != null &&
            currentUser?.id != null &&
            customerUserId == currentUser!.id;

        // Contractor assigned?
        final assignedContractorId = project['assigned_contractor_id'];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (ctx, innerScrolled) => [
              _buildSliverAppBar(
                project: project,
                status: status,
                statusColor: statusColor,
                progress: progress,
                isOwner: isOwner,
                contractorProfile: contractorProfile,
                bidsAsync: bidsAsync,
                bidsCount: bidsCount,
                assignedContractorId: assignedContractorId?.toString(),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0 — Details (always loaded)
                _DetailsTab(
                  project: project,
                  progress: progress,
                  descExpanded: _descExpanded,
                  onToggleDesc: () =>
                      setState(() => _descExpanded = !_descExpanded),
                  assignedContractorId: assignedContractorId?.toString(),
                  bidsCount: bidsCount,
                ),

                // Tab 1 — Bids (always loaded)
                _BidsTab(
                  projectId: widget.projectId,
                  bidsAsync: bidsAsync,
                  isOwner: isOwner,
                  projectStatus: status,
                  onAction: _confirmBidAction,
                  isLoading: _isLoading,
                ),

                // Tab 2 — Stages (lazy)
                _loadedTabs.contains(2)
                    ? _StagesTab(projectId: widget.projectId, status: status)
                    : const _TabPlaceholder(),

                // Tab 3 — Files (lazy)
                _loadedTabs.contains(3)
                    ? _FilesTab(projectId: widget.projectId)
                    : const _TabPlaceholder(),
              ],
            ),
          ),

          bottomNavigationBar: () {
            // 1. Open projects -> Submit Bid for Contractors
            if (isOwner == false &&
                contractorProfile != null &&
                status == 'open') {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Get.toNamed('/create-bid/${widget.projectId}'),
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: Text(
                      "تقديم عرض أسعار",
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              );
            }

            // 2. Assigned / In Progress -> Execution Screen for Owner and Assigned Contractor
            if (status == 'assigned' || status == 'in_progress') {
              bool isAssignedContractor =
                  contractorProfile != null &&
                  contractorProfile['id'].toString() ==
                      assignedContractorId?.toString();

              if (isOwner || isAssignedContractor) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: ElevatedButton.icon(
                      onPressed: () => Get.toNamed(
                        'projectExecution',
                        parameters: {'projectId': widget.projectId},
                      ),
                      icon: const Icon(
                        Icons.rocket_launch,
                        color: Colors.white,
                      ),
                      label: Text(
                        isOwner
                            ? "متابعة التنفيذ والمدفوعات"
                            : "لوحة التنفيذ وإدارة المراحل",
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOwner
                            ? AppColors.primary
                            : AppColors.success,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                );
              }
            }

            // 3. Completed -> Rate Contractor Button for Owner
            if (status == 'completed' && isOwner) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed(
                      'rateContractor',
                      parameters: {'projectId': widget.projectId},
                    ),
                    icon: const Icon(Icons.star_rate, color: Colors.white),
                    label: Text(
                      "تقييم أداء المقاول",
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              );
            }
            return null;
          }(),
        );
      },
    );
  }

  // ── SliverAppBar ──────────────────────────────────────────────
  Widget _buildSliverAppBar({
    required Map<String, dynamic> project,
    required String status,
    required Color statusColor,
    required double progress,
    required bool isOwner,
    required Map<String, dynamic>? contractorProfile,
    required AsyncValue<List<Map<String, dynamic>>> bidsAsync,
    required int bidsCount,
    String? assignedContractorId,
  }) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      actions: [
        if (assignedContractorId != null &&
            (isOwner ||
                (contractorProfile != null &&
                    contractorProfile['id'].toString() ==
                        assignedContractorId.toString())))
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chat_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            onPressed: () async {
              try {
                // 1. Try existing provider
                String? chatId = await ref.read(
                  projectChatProvider(project['id'].toString()).future,
                );

                // 2. If null, create it on-demand via Repository
                if (chatId == null) {
                  final repo = ref.read(chatRepositoryProvider);
                  final customerUserId = project['customers']?['user_id']
                      ?.toString();
                  final contractorUserId = project['contractors']?['user_id']
                      ?.toString();

                  if (customerUserId != null && contractorUserId != null) {
                    chatId = await repo.getOrCreateProjectChat(
                      projectId: project['id'].toString(),
                      customerId: customerUserId,
                      contractorId: contractorUserId,
                    );
                  }
                }

                if (!mounted) return;

                if (chatId != null) {
                  final otherName = isOwner
                      ? _getNestedValue(project, 'contractors', 'user_name')
                      : _getNestedValue(project, 'customers', 'user_name');

                  Get.toNamed(
                    '/chat-details/$chatId', arguments: {
                      'name': otherName,
                      'projectTitle': project['title'],
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "لم يتم العثور على المحادثة أو تهيئتها بعد.",
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("خطأ في تهيئة الدردشة: $e")),
                  );
                }
              }
            },
          ),
        if (isOwner)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            onPressed: () => Get.toNamed('/edit-project/${project['id']}'),
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF1E3A5F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              40,
              16,
              56,
            ), // 40 for top status bar manually
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Title
                Text(
                  project['title'] ?? '',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // Progress mini bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${progress.toStringAsFixed(0)}%",
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppColors.primary,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.cairo(fontSize: 13),
            tabs: [
              const Tab(text: "التفاصيل"),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("العروض  "),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: bidsAsync.when(
                        data: (b) => Text(
                          "${b.length}",
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => Text(
                          "...",
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                        error: (_, __) => Text(
                          "0",
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Tab(text: "مراحل التنفيذ"),
              const Tab(text: "الملفات"),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// Tab 0 — Details
// ═════════════════════════════════════════════════════════════
class _DetailsTab extends StatelessWidget {
  final Map<String, dynamic> project;
  final double progress;
  final bool descExpanded;
  final VoidCallback onToggleDesc;
  final String? assignedContractorId;
  final int bidsCount;

  const _DetailsTab({
    required this.project,
    required this.progress,
    required this.descExpanded,
    required this.onToggleDesc,
    this.assignedContractorId,
    required this.bidsCount,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = progress >= 80
        ? Colors.green
        : progress >= 40
        ? Colors.orange
        : AppColors.primary;
    final description = project['description'] as String? ?? '';
    final requirements = project['special_requirements'] as String?;
    final startDate = project['start_date']?.toString().split('T')[0];
    final deadline = project['deadline']?.toString().split('T')[0];
    final createdAt = project['created_at']?.toString().split('T')[0] ?? '—';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Big Progress Card ──────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                progressColor.withValues(alpha: 0.08),
                progressColor.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: progressColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "نسبة الإنجاز",
                    style: GoogleFonts.cairo(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "${progress.toStringAsFixed(0)}%",
                    style: GoogleFonts.cairo(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 14,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                progress == 0
                    ? "المشروع لم يبدأ بعد"
                    : progress == 100
                    ? "🎉 اكتمل المشروع بنجاح"
                    : "المشروع قيد التنفيذ — ${(100 - progress).toStringAsFixed(0)}% متبقية",
                style: GoogleFonts.cairo(fontSize: 12, color: progressColor),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Info Grid 2×3 ─────────────────────────────────────
        Text(
          "معلومات المشروع",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            _infoCell(
              "التصنيف",
              _getNestedValue(project, 'project_categories', 'name_ar') != 'غير محدد'
                  ? _getNestedValue(project, 'project_categories', 'name_ar')
                  : (project['project_type'] ?? 'عام'),
              Icons.category_outlined,
              AppColors.primary,
            ),
            _infoCell(
              "المدينة",
              _getNestedValue(project, 'cities', 'name_ar'),
              Icons.location_on_outlined,
              Colors.red,
            ),
            _infoCell(
              "تاريخ البدء",
              startDate ?? 'غير محدد',
              Icons.play_circle_outline,
              Colors.green,
            ),
            _infoCell(
              "الموعد النهائي",
              deadline ?? 'غير محدد',
              Icons.flag_outlined,
              Colors.orange,
            ),
            _infoCell(
              "عدد العروض",
              bidsCount.toString(),
              Icons.people_outline,
              AppColors.accent,
            ),
            _infoCell(
              "صاحب المشروع",
              _getNestedValue(project, 'customers', 'user_name'),
              Icons.person_outline,
              Colors.purple,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Budget Card ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "نطاق الميزانية المحددة",
                    style: GoogleFonts.cairo(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${_fmt(project['budget_min'])} — ${_fmt(project['budget_max'])}",
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        // ── Location Details ──────────────────────────────────
        if (project['location_details'] != null &&
            (project['location_details'] as String).isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "الموقع وتفاصيل العمل",
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  project['location_details'],
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Quick Documents Access Section ────────────────────
        Consumer(
          builder: (context, ref, child) {
            final filesAsync = ref.watch(_projectFilesProvider(project['id']));
            return filesAsync.maybeWhen(
              data: (files) {
                if (files.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attachment, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "مستندات المشروع (${files.length} ملفاً)",
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              "يمكنك الاطلاع عليها في تبويب الملفات",
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to Files tab if possible or just inform
                          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('انقر على تبويب "الملفات" في الأعلى')));
                        },
                        child: Text(
                          "مشاهدة",
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            );
          },
        ),

        // ── Description (expandable) ──────────────────────────
        _ExpandableSection(
          title: "وصف المشروع",
          content: description,
          expanded: descExpanded,
          onToggle: onToggleDesc,
        ),

        // ── Requirements ──────────────────────────────────────
        if (requirements != null && requirements.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "متطلبات خاصة",
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  requirements,
                  style: GoogleFonts.cairo(
                    color: Colors.amber.shade900,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Assigned Contractor Card ──────────────────────────
        if (assignedContractorId != null) ...[
          const SizedBox(height: 20),
          _AssignedContractorCard(contractorId: assignedContractorId!),
        ],

        const SizedBox(height: 12),
        Text(
          "تاريخ النشر: $createdAt",
          style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _infoCell(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 9,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Expandable description ───────────────────────────────────
class _ExpandableSection extends StatelessWidget {
  final String title;
  final String content;
  final bool expanded;
  final VoidCallback onToggle;

  const _ExpandableSection({
    required this.title,
    required this.content,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                content,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  height: 1.7,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          if (!expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Assigned Contractor Card ─────────────────────────────────
class _AssignedContractorCard extends ConsumerWidget {
  final String contractorId;
  const _AssignedContractorCard({required this.contractorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabase = ref.read(supabaseProvider);

    return FutureBuilder<Map<String, dynamic>?>(
      future: supabase
          .from('contractors')
          .select('*, cities!contractors_city_id_fkey(name_ar)')
          .eq('id', contractorId)
          .maybeSingle(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final c = snap.data;
        if (c == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.06),
                AppColors.primary.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.verified_user,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "المقاول المعيّن",
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: c['profile_image_url'] != null
                        ? NetworkImage(c['profile_image_url'])
                        : null,
                    child: c['profile_image_url'] == null
                        ? const Icon(Icons.person, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['user_name'] ?? '—',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          c['specialty'] ?? 'مقاول عام',
                          style: GoogleFonts.cairo(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 13,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "${c['avg_rating'] ?? '0.0'}",
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _getNestedValue(c, 'cities', 'name_ar') ==
                                      'غير محدد'
                                  ? '—'
                                  : _getNestedValue(c, 'cities', 'name_ar'),
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.primary,
                    ),
                    onPressed: () => Get.toNamed('/chats'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════
class _BidsTab extends ConsumerWidget {
  final String projectId;
  final AsyncValue<List<Map<String, dynamic>>> bidsAsync;
  final bool isOwner;
  final String projectStatus;
  final void Function(
    Map<String, dynamic> bidMap,
    String contractorName,
    String action,
  )
  onAction;
  final bool isLoading;

  const _BidsTab({
    required this.projectId,
    required this.bidsAsync,
    required this.isOwner,
    required this.projectStatus,
    required this.onAction,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return bidsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('خطأ: $e', style: GoogleFonts.cairo())),
      data: (bids) {
        if (bids.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 72,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  "لا توجد عروض مقدمة بعد",
                  style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
                ),
                if (projectStatus == 'open') ...[
                  const SizedBox(height: 8),
                  Text(
                    "انتظر حتى يقدم المقاولون عروضهم",
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: bids.length,
          itemBuilder: (ctx, i) => _BidCard(
            bid: bids[i],
            isOwner: isOwner,
            projectStatus: projectStatus,
            onAction: onAction,
            isLoading: isLoading,
          ),
        );
      },
    );
  }
}

// ─── Bid Card ─────────────────────────────────────────────────
class _BidCard extends StatelessWidget {
  final Map<String, dynamic> bid;
  final bool isOwner;
  final String projectStatus;
  final void Function(
    Map<String, dynamic> bidMap,
    String contractorName,
    String action,
  )
  onAction;
  final bool isLoading;

  const _BidCard({
    required this.bid,
    required this.isOwner,
    required this.projectStatus,
    required this.onAction,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final status = bid['status'] as String? ?? 'pending';
    final Color statusColor = switch (status) {
      'accepted' => Colors.green,
      'rejected' => Colors.red,
      'withdrawn' => Colors.grey,
      _ => Colors.orange,
    };
    final String statusLabel = switch (status) {
      'accepted' => 'مقبول ✓',
      'rejected' => 'مرفوض',
      'withdrawn' => 'مسحوب',
      _ => 'قيد الانتظار',
    };
    final contractorsRaw = bid['contractors'];
    Map<String, dynamic>? contractor;
    if (contractorsRaw is List && contractorsRaw.isNotEmpty) {
      contractor = contractorsRaw[0] as Map<String, dynamic>?;
    } else if (contractorsRaw is Map) {
      contractor = contractorsRaw as Map<String, dynamic>?;
    }

    final isVerified =
        contractor?['is_verified'] == true || contractor?['is_verified'] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: contractor?['profile_image_url'] != null
                      ? NetworkImage(contractor!['profile_image_url'])
                      : null,
                  child: contractor?['profile_image_url'] == null
                      ? const Icon(Icons.person, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            contractor?['user_name'] ?? 'مقاول',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 14,
                              color: Colors.blue,
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            "${contractor?['avg_rating'] ?? '0.0'}",
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Price + duration
            Row(
              children: [
                _bidStat(
                  Icons.payments_outlined,
                  _fmt(bid['bid_price']),
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _bidStat(
                  Icons.timer_outlined,
                  "${bid['duration_days'] ?? '—'} يوم",
                  Colors.blue,
                ),
              ],
            ),

            // Description snippet
            if (bid['description'] != null &&
                (bid['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                bid['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],

            // Owner actions
            if (isOwner && status == 'pending' && projectStatus == 'open') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => onAction(
                              bid,
                              contractor?['user_name'] ?? 'المقاول',
                              'reject',
                            ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "رفض العرض",
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => onAction(
                              bid,
                              contractor?['user_name'] ?? 'المقاول',
                              'accept',
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "قبول وإسناد المشروع",
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bidStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// Tab 2 — Stages (vertical timeline)
// ═════════════════════════════════════════════════════════════
class _StagesTab extends ConsumerStatefulWidget {
  final String projectId;
  final String status;
  const _StagesTab({required this.projectId, required this.status});

  @override
  ConsumerState<_StagesTab> createState() => _StagesTabState();
}

class _StagesTabState extends ConsumerState<_StagesTab> {
  bool _isGenerating = false;

  Future<void> _generateManualStages() async {
    setState(() => _isGenerating = true);
    try {
      final supabase = ref.read(supabaseProvider);

      // Get the accepted bid to see if there's a payment schedule
      final bidRes = await supabase
          .from('bids')
          .select('*')
          .eq('project_id', widget.projectId)
          .eq('status', 'accepted')
          .maybeSingle();

      bool generated = false;

      if (bidRes != null) {
        final schedule = bidRes['payment_schedule'];
        if (schedule != null && schedule is List && schedule.isNotEmpty) {
          for (int i = 0; i < schedule.length; i++) {
            final step = schedule[i];
            await supabase.from('project_stages').insert({
              'project_id': widget.projectId,
              'stage_name': step['name'] ?? 'مرحلة ${i + 1}',
              'stage_description': 'دفع مقترحة بنسبة: ${step['percentage']}%',
              'completion_percentage': 0,
              'status': 'pending',
              'stage_order': i + 1,
            });
          }
          generated = true;
        }
      }

      // If no schedule found, or no bid found, create a generic stage
      if (!generated) {
        await supabase.from('project_stages').insert({
          'project_id': widget.projectId,
          'stage_name': 'تنفيذ إجمالي المشروع',
          'stage_description':
              'لم يتم تحديد دفعات مسبقة، يتم التنفيذ على مرحلة واحدة.',
          'completion_percentage': 0,
          'status': 'pending',
          'stage_order': 1,
        });
        generated = true;
      }

      ref.invalidate(_projectStagesProvider(widget.projectId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "تم توليد مراحل المشروع بنجاح",
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطأ أثناء التوليد: $e", style: GoogleFonts.cairo()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stagesAsync = ref.watch(_projectStagesProvider(widget.projectId));

    return stagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('خطأ: $e', style: GoogleFonts.cairo())),
      data: (stages) {
        if (stages.isEmpty) {
          final isAssigned = widget.status != 'open';
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  size: 72,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  "لا توجد مراحل محددة بعد",
                  style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  isAssigned
                      ? "لم يتم بناء جدول المراحل لهذا المشروع"
                      : "تظهر المراحل بعد اختيار المقاول",
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
                if (isAssigned) ...[
                  const SizedBox(height: 24),
                  _isGenerating
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: Text(
                            "توليد المراحل الآن",
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          onPressed: _generateManualStages,
                        ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          itemCount: stages.length,
          itemBuilder: (ctx, i) {
            final stage = stages[i];
            final isLast = i == stages.length - 1;
            final stStatus = stage['status'] as String? ?? 'pending';
            final stColor = _stageStatusColor(stStatus);

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline column
                  SizedBox(
                    width: 36,
                    child: Column(
                      children: [
                        // Circle
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: stStatus == 'completed'
                                ? stColor
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: stColor, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: stColor.withValues(alpha: 0.2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            stStatus == 'completed'
                                ? Icons.check
                                : stStatus == 'in_progress'
                                ? Icons.construction
                                : stStatus == 'delayed'
                                ? Icons.warning_amber
                                : Icons.radio_button_unchecked,
                            color: stStatus == 'completed'
                                ? Colors.white
                                : stColor,
                            size: 18,
                          ),
                        ),
                        // Connector line
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2.5,
                              color: stColor.withValues(alpha: 0.3),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Content Card
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: stColor.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  stage['stage_name'] ?? 'مرحلة ${i + 1}',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: stColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _stageStatusLabel(stStatus),
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    color: stColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (stage['stage_description'] != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              stage['stage_description'],
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          // Progress bar for stage
                          if (stage['completion_percentage'] != null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value:
                                          ((stage['completion_percentage']
                                                  as num?) ??
                                              0) /
                                          100,
                                      minHeight: 6,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        stColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${stage['completion_percentage'] ?? 0}%",
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: stColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          // Dates
                          Row(
                            children: [
                              if (stage['start_date'] != null) ...[
                                Icon(
                                  Icons.play_arrow,
                                  size: 12,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  stage['start_date'].toString().split('T')[0],
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              if (stage['end_date'] != null) ...[
                                Icon(
                                  Icons.flag,
                                  size: 12,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  stage['end_date'].toString().split('T')[0],
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Tab 3 — Files
// ══════════════════════════════════════════════════════════════
class _FilesTab extends ConsumerWidget {
  final String projectId;
  const _FilesTab({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(_projectFilesProvider(projectId));

    return filesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('خطأ: $e', style: GoogleFonts.cairo())),
      data: (files) {
        if (files.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open_outlined,
                  size: 72,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  "لا توجد ملفات مرفقة",
                  style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: files.length,
          itemBuilder: (ctx, i) => _FileCell(file: files[i]),
        );
      },
    );
  }
}

// ─── File Cell ────────────────────────────────────────────────
class _FileCell extends StatelessWidget {
  final Map<String, dynamic> file;
  const _FileCell({required this.file});

  @override
  Widget build(BuildContext context) {
    final type = file['file_type'] as String? ?? 'other';
    final isImage = type == 'image';
    final url = file['file_url'] as String? ?? '';

    final IconData icon = switch (type) {
      'pdf' => Icons.picture_as_pdf,
      'image' => Icons.image_outlined,
      'video' => Icons.videocam_outlined,
      'document' => Icons.description_outlined,
      _ => Icons.attach_file,
    };
    final Color color = switch (type) {
      'pdf' => Colors.red,
      'image' => Colors.blue,
      'video' => Colors.purple,
      'document' => Colors.green,
      _ => Colors.grey,
    };

    return InkWell(
      onTap: () {
        // Logic to open URL would go here (e.g. url_launcher)
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: isImage && url.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) =>
                            Icon(icon, size: 36, color: color),
                      ),
                    )
                  : Icon(icon, size: 36, color: color),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Text(
                file['file_name'] ?? 'ملف',
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Placeholder for unloaded lazy tabs ────────────────────────
class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

