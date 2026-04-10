import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/master_data_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../contractor/presentation/providers/contractor_providers.dart';

class EditProjectScreen extends ConsumerStatefulWidget {
  final String projectId;
  const EditProjectScreen({super.key, required this.projectId});

  @override
  ConsumerState<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends ConsumerState<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  String? _selectedCategoryId;
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();

  String? _selectedCityId;
  final _locationDetailsController = TextEditingController();
  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = false;
  bool _isDataLoaded = false;
  bool _canEdit = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _locationDetailsController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    super.dispose();
  }

  void _loadProjectData(Map<String, dynamic> project) {
    if (_isDataLoaded) return;
    final status = project['status'] as String? ?? 'open';
    if (status != 'open' && status != 'pending') {
      _canEdit = false;
    }

    _titleController.text = project['title'] ?? '';
    _selectedCategoryId = project['category_id']?.toString();
    _descriptionController.text = project['description'] ?? '';
    _requirementsController.text = project['special_requirements'] ?? '';

    _selectedCityId = project['city_id']?.toString();
    _locationDetailsController.text = project['location_details'] ?? '';
    _minBudgetController.text = project['budget_min']?.toString() ?? '';
    _maxBudgetController.text = project['budget_max']?.toString() ?? '';

    if (project['expected_start_date'] != null) {
      _startDate = DateTime.tryParse(project['expected_start_date'].toString());
    }
    if (project['expected_deadline'] != null) {
      _endDate = DateTime.tryParse(project['expected_deadline'].toString());
    }

    _isDataLoaded = true;
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "الرجاء تحديد تواريخ المشروع",
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = ref.read(supabaseProvider);
      final updateData = {
        'title': _titleController.text.trim(),
        'category_id': _selectedCategoryId,
        'description': _descriptionController.text.trim(),
        'special_requirements': _requirementsController.text.trim(),
        'city_id': _selectedCityId,
        'location_details': _locationDetailsController.text.trim(),
        'budget_min': double.tryParse(_minBudgetController.text),
        'budget_max': double.tryParse(_maxBudgetController.text),
        'start_date': _startDate!.toIso8601String(),
        'deadline': _endDate!.toIso8601String(),
      };

      await supabase
          .from('projects')
          .update(updateData)
          .eq('id', widget.projectId);

      if (mounted) {
        Get.back();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم حفظ التعديلات بنجاح", style: GoogleFonts.cairo()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "حدث خطأ أثناء الحفظ: $e",
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectDetailsProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text("تعديل المشروع"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: projectAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text("خطأ في التحميل: $e", style: GoogleFonts.cairo()),
        ),
        data: (project) {
          if (project == null) {
            return Center(
              child: Text("المشروع غير موجود", style: GoogleFonts.cairo()),
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _loadProjectData(project);
            });
          });

          if (!_isDataLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!_canEdit) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "لا يمكن تعديل المشروع بعد قبول عرض أو تغيّر حالته.",
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(
                        "العودة",
                        style: GoogleFonts.cairo(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("المعلومات الأساسية"),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              hintText: "عنوان المشروع (مطلوب)",
                            ),
                            validator: (val) => val == null || val.length < 10
                                ? 'العنوان قصير جداً (حد أدنى 10 أحرف)'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          ref
                              .watch(projectCategoriesProvider)
                              .when(
                                data: (categories) =>
                                    DropdownButtonFormField<String>(
                                      value: _selectedCategoryId,
                                      decoration: const InputDecoration(
                                        hintText: "التصنيف (مطلوب)",
                                      ),
                                      items: categories
                                          .map(
                                            (c) => DropdownMenuItem<String>(
                                              value: c['id'] as String,
                                              child: Text(
                                                c['name_ar'] as String,
                                                style: GoogleFonts.cairo(),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) => setState(
                                        () => _selectedCategoryId = val,
                                      ),
                                      validator: (val) =>
                                          val == null ? 'مطلوب' : null,
                                    ),
                                loading: () =>
                                    const CircularProgressIndicator(),
                                error: (_, __) => const Text("خطأ"),
                              ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText: "وصف المشروع التفصيلي (مطلوب)",
                            ),
                            validator: (val) => val == null || val.length < 30
                                ? 'الوصف قصير جداً (حد أدنى 30 حرف)'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _requirementsController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: "متطلبات خاصة (اختياري)",
                            ),
                          ),

                          const SizedBox(height: 32),
                          _buildSectionTitle("الموقع والميزانية"),
                          ref
                              .watch(citiesProvider)
                              .when(
                                data: (citiesList) =>
                                    DropdownButtonFormField<String>(
                                      value: _selectedCityId,
                                      decoration: const InputDecoration(
                                        hintText: "المدينة (مطلوب)",
                                      ),
                                      items: citiesList
                                          .map(
                                            (c) => DropdownMenuItem<String>(
                                              value: c['id'] as String,
                                              child: Text(
                                                c['name_ar'] as String,
                                                style: GoogleFonts.cairo(),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) =>
                                          setState(() => _selectedCityId = val),
                                      validator: (val) =>
                                          val == null ? 'مطلوب' : null,
                                    ),
                                loading: () =>
                                    const CircularProgressIndicator(),
                                error: (_, __) => const Text("خطأ"),
                              ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _locationDetailsController,
                            decoration: const InputDecoration(
                              hintText: "تفاصيل الموقع أو الحي (مطلوب)",
                            ),
                            validator: (val) =>
                                val == null || val.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _minBudgetController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: "الحد الأدنى للميزانية",
                                  ),
                                  validator: (val) => val == null || val.isEmpty
                                      ? 'مطلوب'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _maxBudgetController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: "الحد الأقصى للميزانية",
                                  ),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'مطلوب';
                                    }
                                    final min =
                                        double.tryParse(
                                          _minBudgetController.text,
                                        ) ??
                                        0;
                                    final max = double.tryParse(val) ?? 0;
                                    if (max <= min) {
                                      return 'يجب أن يكون الأقصى أكبر';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),
                          _buildSectionTitle("التواريخ والمواعيد"),
                          ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            tileColor: Colors.white,
                            leading: const Icon(
                              Icons.calendar_today,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              "تاريخ البدء المتوقع",
                              style: GoogleFonts.cairo(),
                            ),
                            subtitle: Text(
                              _startDate != null
                                  ? DateFormat('yyyy-MM-dd').format(_startDate!)
                                  : "اختر التاريخ",
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                color: _startDate != null
                                    ? AppColors.primary
                                    : Colors.grey,
                              ),
                            ),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setState(() {
                                  _startDate = date;
                                  if (_endDate != null &&
                                      _endDate!.isBefore(date)) {
                                    _endDate = null;
                                  }
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            tileColor: Colors.white,
                            leading: const Icon(
                              Icons.event,
                              color: AppColors.accent,
                            ),
                            title: Text(
                              "الموعد النهائي المتوقع",
                              style: GoogleFonts.cairo(),
                            ),
                            subtitle: Text(
                              _endDate != null
                                  ? DateFormat('yyyy-MM-dd').format(_endDate!)
                                  : "اختر التاريخ",
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                color: _endDate != null
                                    ? AppColors.accent
                                    : Colors.grey,
                              ),
                            ),
                            onTap: () async {
                              if (_startDate == null) return;
                              final date = await showDatePicker(
                                context: context,
                                initialDate:
                                    _endDate ??
                                    _startDate!.add(const Duration(days: 1)),
                                firstDate: _startDate!.add(
                                  const Duration(days: 1),
                                ),
                                lastDate: _startDate!.add(
                                  const Duration(days: 1000),
                                ),
                              );
                              if (date != null) setState(() => _endDate = date);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "حفظ التعديلات",
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

