import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/master_data_providers.dart';
import '../../../contractor/presentation/providers/contractor_providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class BrowseProjectsScreen extends ConsumerStatefulWidget {
  const BrowseProjectsScreen({super.key});

  @override
  ConsumerState<BrowseProjectsScreen> createState() => _BrowseProjectsScreenState();
}

class _BrowseProjectsScreenState extends ConsumerState<BrowseProjectsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Filter state (using names/labels for UI, but will map to IDs for query)
  RangeValues _budgetRange = const RangeValues(0, 50000000);
  final Set<String> _selectedCityIds = {};
  final Set<String> _selectedCategoryIds = {};
  String _selectedDateFilter = 'الكل';

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
    });
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_budgetRange.start > 0 || _budgetRange.end < 50000000) count++;
    if (_selectedCityIds.isNotEmpty) count++;
    if (_selectedCategoryIds.isNotEmpty) count++;
    if (_selectedDateFilter != 'الكل') count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final isCustomer = authController.currentUser.value?.role == 'customer';

    if (isCustomer) {
      return Scaffold(
        appBar: AppBar(
          title: Text("استكشاف المشاريع", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 80, color: AppColors.primary),
                const SizedBox(height: 24),
                Text(
                  "هذه الشاشة مخصصة للمقاولين فقط للبحث عن عروض المشاريع المتاحة.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  "كعميل، يمكنك إضافة مشروع جديد من صفحتك الرئيسية.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("العودة للرئيسية", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Current filters map
    final filters = {
      'searchQuery': _searchQuery,
      'selectedCities': _selectedCityIds.isEmpty ? null : _selectedCityIds.toList(),
      'selectedCategories': _selectedCategoryIds.isEmpty ? null : _selectedCategoryIds.toList(),
      'minBudget': _budgetRange.start > 0 ? _budgetRange.start : null,
      'maxBudget': _budgetRange.end < 50000000 ? _budgetRange.end : null,
    };

    final projectsAsync = ref.watch(filteredProjectsProvider(filters));
    final profileAsync = ref.watch(contractorProfileProvider);
    final myBidsAsync = ref.watch(contractorBidsProvider);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("المشاريع المتاحة", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Get.toNamed('/projects-map'),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _activeFiltersCount > 0,
              label: Text(_activeFiltersCount.toString()),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: _buildFilterDrawer(),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: "ابحث عن مشروع بالاسم...",
                hintStyle: GoogleFonts.cairo(fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Project List
          Expanded(
            child: projectsAsync.when(
              data: (projects) {
                if (projects.isEmpty) {
                  return _buildEmptyState();
                }

                final myBidProjectIds = myBidsAsync.when(
                  data: (bids) => bids.map((b) => b['project_id'].toString()).toSet(),
                  loading: () => <String>{},
                  error: (_, __) => <String>{},
                );

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(filteredProjectsProvider(filters).future),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      final projectId = project['id'].toString();
                      final hasBid = myBidProjectIds.contains(projectId);
                      final isVerified = profileAsync.value?['is_verified'] as bool? ?? false;

                      return _buildProjectCard(project, hasBid, isVerified);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("خطأ في تحميل البيانات: $e", style: GoogleFonts.cairo())),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildProjectCard(Map<String, dynamic> project, bool hasBid, bool isVerified) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: hasBid ? AppColors.primary.withValues(alpha: 0.3) : Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: () => Get.toNamed('/project-details/${project['id']}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project['title'] ?? 'بدون عنوان',
                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  if (hasBid)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.primary, size: 14),
                          const SizedBox(width: 4),
                          Text("قدّمت عرضاً", style: GoogleFonts.cairo(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text("مفتوح", style: GoogleFonts.cairo(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(project['cities']?['name_ar'] ?? 'غير محدد', style: GoogleFonts.cairo(color: Colors.grey.shade700, fontSize: 12)),
                  const SizedBox(width: 16),
                  const Icon(Icons.category_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project['project_categories']?['name_ar'] ?? 'عام',
                      style: GoogleFonts.cairo(color: Colors.grey.shade700, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.monetization_on_outlined, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    "${_formatBudget(project['budget_min'])} - ${_formatBudget(project['budget_max'])} ريال",
                    style: GoogleFonts.cairo(color: Colors.green.shade800, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text("${project['bids_count'] ?? 0} عروض", style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600)),
                  const Spacer(),
                  Text(
                    "نشر قبل: ${_timeSince(project['created_at'])}",
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!hasBid)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isVerified ? () => Get.toNamed('/create-bid/${project['id']}') : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      isVerified ? "تقديم عرض الآن" : "حسابك غير موثق للتقديم",
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("لا توجد مشاريع تطابق بحثك", style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("حاول تغيير فلاتر البحث أو الكلمات المفتاحية", style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedCityIds.clear();
                  _selectedCategoryIds.clear();
                  _budgetRange = const RangeValues(0, 50000000);
                  _selectedDateFilter = 'الكل';
                });
              },
              child: Text("مسح جميع الفلاتر", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.primary)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDrawer() {
    final citiesAsync = ref.watch(citiesProvider);
    final categoriesAsync = ref.watch(projectCategoriesProvider);

    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("فلاتر البحث", style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterSectionTitle("المدن"),
                    citiesAsync.when(
                      data: (cities) => Wrap(
                        spacing: 8,
                        children: cities.map((city) {
                          final id = city['id'].toString();
                          final isSelected = _selectedCityIds.contains(id);
                          return FilterChip(
                            label: Text(city['name_ar'], style: GoogleFonts.cairo(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (val) => setState(() => val ? _selectedCityIds.add(id) : _selectedCityIds.remove(id)),
                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            checkmarkColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          );
                        }).toList(),
                      ),
                      loading: () => const Center(child: LinearProgressIndicator()),
                      error: (_, __) => const Text("حدث خطأ في تحميل المدن"),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildFilterSectionTitle("التصنيفات"),
                    categoriesAsync.when(
                      data: (cats) => Wrap(
                        spacing: 8,
                        children: cats.map((cat) {
                          final id = cat['id'].toString();
                          final isSelected = _selectedCategoryIds.contains(id);
                          return FilterChip(
                            label: Text(cat['name_ar'], style: GoogleFonts.cairo(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (val) => setState(() => val ? _selectedCategoryIds.add(id) : _selectedCategoryIds.remove(id)),
                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            checkmarkColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          );
                        }).toList(),
                      ),
                      loading: () => const Center(child: LinearProgressIndicator()),
                      error: (_, __) => const Text("حدث خطأ في تحميل التصنيفات"),
                    ),
                    const SizedBox(height: 24),

                    _buildFilterSectionTitle("نطاق الميزانية (ريال)"),
                    RangeSlider(
                      values: _budgetRange,
                      min: 0,
                      max: 100000000,
                      divisions: 50,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _budgetRange = val),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatFullBudget(_budgetRange.start), style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                        Text(_formatFullBudget(_budgetRange.end), style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildFilterSectionTitle("تاريخ النشر"),
                    Wrap(
                      spacing: 8,
                      children: ['الكل', 'آخر 24 ساعة', 'آخر أسبوع', 'آخر شهر'].map((date) {
                        final isSelected = _selectedDateFilter == date;
                        return ChoiceChip(
                          label: Text(date, style: GoogleFonts.cairo(fontSize: 12)),
                          selected: isSelected,
                          onSelected: (val) => setState(() => _selectedDateFilter = date),
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCityIds.clear();
                          _selectedCategoryIds.clear();
                          _budgetRange = const RangeValues(0, 50000000);
                          _selectedDateFilter = 'الكل';
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text("إعادة ضبط", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text("تطبيق", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
    );
  }

  String _formatBudget(dynamic value) {
    if (value == null) return '0';
    final num = double.tryParse(value.toString()) ?? 0;
    if (num >= 1000000) return "${(num / 1000000).toStringAsFixed(1)}م";
    if (num >= 1000) return "${(num / 1000).toStringAsFixed(0)}ألف";
    return num.toStringAsFixed(0);
  }

  String _formatFullBudget(double value) {
    final fmt = value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return fmt;
  }

  String _timeSince(dynamic date) {
    if (date == null) return "غير معروف";
    final dt = DateTime.tryParse(date.toString());
    if (dt == null) return date.toString();
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return "${diff.inDays} يوم";
    if (diff.inHours > 0) return "${diff.inHours} ساعة";
    if (diff.inMinutes > 0) return "${diff.inMinutes} دقيقة";
    return "الآن";
  }
}

