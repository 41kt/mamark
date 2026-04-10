import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/contractor_card.dart';

class BrowseContractorsScreen extends ConsumerStatefulWidget {
  const BrowseContractorsScreen({super.key});

  @override
  ConsumerState<BrowseContractorsScreen> createState() =>
      _BrowseContractorsScreenState();
}

class _BrowseContractorsScreenState
    extends ConsumerState<BrowseContractorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCityId;

  List<Map<String, dynamic>> _allContractors = [];
  List<Map<String, dynamic>> _filteredContractors = [];
  List<Map<String, dynamic>> _cities = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      List<Map<String, dynamic>> contractorList = [];
      List<Map<String, dynamic>> cityList = [];

      // أولاً: جلب المدن
      try {
        final r = await supabase.from('cities').select('id, name_ar').order('name_ar');
        cityList = List<Map<String, dynamic>>.from(r);
        debugPrint('Cities loaded: ${cityList.length}');
        if (cityList.isNotEmpty) debugPrint('First city: ${cityList.first}');
      } catch (e) {
        debugPrint('Cities fetch error: $e');
      }

      // ثانياً: جلب المقاولين مع Join بتحديد اسم العلاقة لتفادي PGRST201
      try {
        final r = await supabase
            .from('contractors')
            .select('*, cities!contractors_city_id_fkey(name_ar)');
        contractorList = List<Map<String, dynamic>>.from(r);
        debugPrint('Contractors loaded: ${contractorList.length}');
        if (contractorList.isNotEmpty) {
          debugPrint('First contractor city_id: ${contractorList.first['city_id']}');
          debugPrint('First contractor cities: ${contractorList.first['cities']}');
        }
      } catch (e) {
        debugPrint('contractors fetch error: $e');
        if (!mounted) return;
        setState(() {
          _errorMessage = 'خطأ في جلب المقاولين:\n$e';
          _isLoading = false;
        });
        return;
      }

      // إذا فشل الـ Join التلقائي، نربط يدوياً
      for (var c in contractorList) {
        // إذا cities موجود ومفيد، نكمل
        if (c['cities'] != null && c['cities']['name_ar'] != null) continue;
        
        // ربط يدوي بناءً على city_id
        if (c['city_id'] != null) {
          for (var city in cityList) {
            if (city['id'].toString() == c['city_id'].toString()) {
              c['cities'] = {'name_ar': city['name_ar']};
              break;
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _allContractors = contractorList;
        _filteredContractors = contractorList;
        _cities = cityList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('=== BrowseContractors ERROR: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// فلترة محلية بدون استدعاء السيرفر (سريعة جداً ولا تسبب تعليق)
  void _applyFilters() {
    final searchText = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredContractors = _allContractors.where((c) {
        // فلتر الاسم
        final name = (c['user_name'] ?? '').toString().toLowerCase();
        final matchesSearch = searchText.isEmpty || name.contains(searchText);

        // فلتر المدينة
        final matchesCity = _selectedCityId == null ||
            c['city_id']?.toString() == _selectedCityId;

        return matchesSearch && matchesCity;
      }).toList();
    });
  }

  void _onSearchChanged(String _) {
    // تأخير البحث 300ms لتجنب الضغط على الواجهة
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "البحث عن مقاولين",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ─── شريط البحث والفلترة ───
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: "ابحث عن طريق الاسم...",
                    hintStyle: GoogleFonts.cairo(color: Colors.grey, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.grey, width: 0.5),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCityDropdown(),
              ],
            ),
          ),

          // ─── قائمة المقاولين ───
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildCityDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        hintText: "تصفية بالمدينة",
        prefixIcon: const Icon(Icons.location_city, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.grey, width: 0.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      value: _selectedCityId,
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text("كل المدن", style: GoogleFonts.cairo()),
        ),
        ..._cities.map(
          (c) => DropdownMenuItem<String>(
            value: c['id'].toString(),
            child: Text(c['name_ar'].toString(), style: GoogleFonts.cairo()),
          ),
        ),
      ],
      onChanged: (val) {
        _selectedCityId = val;
        _applyFilters();
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                "حدث خطأ أثناء جلب البيانات:\n$_errorMessage",
                style: GoogleFonts.cairo(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchAll,
                icon: const Icon(Icons.refresh),
                label: Text("إعادة المحاولة", style: GoogleFonts.cairo()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredContractors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "لم يتم العثور على مقاولين",
              style: GoogleFonts.cairo(color: Colors.grey, fontSize: 16),
            ),
            if (_allContractors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                "إجمالي المقاولين: ${_allContractors.length}",
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 40),
        itemCount: _filteredContractors.length,
        itemBuilder: (context, index) {
          final c = _filteredContractors[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: ContractorCard(
              contractor: c,
              onTap: () {
                Get.toNamed('/contractor-profile/${c['id']}');
              },
            ),
          );
        },
      ),
    );
  }
}

