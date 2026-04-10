import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/master_data_providers.dart';
import '../../../../core/providers/storage_provider.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  int _currentStep = 1;
  final _formKey = GlobalKey<FormState>();

  // Step 1 Data
  final _titleController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();

  // Step 2 Data
  String? _selectedCityId;
  String? _selectedCityName;
  final _locationDetailsController = TextEditingController();
  final _locationUrlController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _minBudgetController = TextEditingController();
  final _maxBudgetController = TextEditingController();

  // Step 3 Data
  DateTime? _startDate;
  DateTime? _endDate;
  final List<PlatformFile> _selectedFiles = [];

  // Step 4 Data
  bool _agreeToPublish = false;
  bool _isLoading = false;

  int get _calculatedDays {
    if (_startDate != null && _endDate != null) {
      return _endDate!.difference(_startDate!).inDays;
    }
    return 0;
  }

  Future<void> _publishProject() async {
    if (!_agreeToPublish) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "الرجاء الموافقة على نشر المشروع",
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
      final user = ref.read(currentUserProvider);

      if (user == null) throw Exception("User not logged in");

      // In the new unified architecture, all users are in public.users,
      // and their ID equals auth.uid().
      final customerId = user.id;

      // Extract numeric budget intelligently
      final minB = double.tryParse(_minBudgetController.text) ?? 0;
      final maxB = double.tryParse(_maxBudgetController.text) ?? 0;
      final avgBudget = (minB + maxB) / 2;

      // Combine description with requirements
      final desc = _descriptionController.text.trim();
      final reqs = _requirementsController.text.trim();
      final fullDescription = reqs.isNotEmpty ? "$desc\nمتطلبات خاصة:\n$reqs" : desc;

      // Combine location details
      final loc = _locationDetailsController.text.trim();
      final locUrl = _locationUrlController.text.trim();
      final fullLocation = locUrl.isNotEmpty ? "$loc\nالرابط: $locUrl" : loc;

      final projectData = {
        'client_id': customerId,
        'title': _titleController.text.trim(),
        'description': fullDescription,
        'budget': avgBudget > 0 ? avgBudget : null,
        'location': fullLocation,
        'status': 'open',
      };

      final projectResponse = await supabase.from('projects').insert(projectData).select('id').single();
      final newProjectId = projectResponse['id'].toString();

      // Simple file attachment simulation or external link updating for photos
      List<String> fileUrls = [];
      if (_selectedFiles.isNotEmpty) {
        final storage = ref.read(storageProvider);
        for (final file in _selectedFiles) {
          if (file.bytes == null) continue;
          try {
            final ext = file.extension?.toLowerCase() ?? '';
            final mimeType = ext == 'pdf' ? 'application/pdf' : 'image/jpeg';

            // Ensure bucket exists in Supabase Dashboard (e.g., 'projects')
            final uploadResult = await storage.uploadProjectFile(
              bytes: file.bytes!,
              projectId: newProjectId,
              fileName: file.name,
              mimeType: mimeType,
            );

            if (uploadResult['success'] == true) {
              fileUrls.add(uploadResult['url'] as String);
            }
          } catch (e) {
            debugPrint("File upload error: $e");
          }
        }
        
        // Update the project with the uploaded images array
        if (fileUrls.isNotEmpty) {
           await supabase.from('projects').update({'images': fileUrls}).eq('id', newProjectId);
        }
      }


      if (mounted) {
        Get.back();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم نشر مشروعك ومعالجة الملفات بنجاح", style: GoogleFonts.cairo()),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "حدث خطأ أثناء النشر: $e",
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

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      withData: true, // ← مهم جداً: يحمّل بيانات الملف في الذاكرة
    );

    if (result != null) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _nextStep() {
    if (_currentStep == 1 || _currentStep == 2) {
      if (!_formKey.currentState!.validate()) return;
    }

    if (_currentStep == 3) {
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
    }

    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _publishProject();
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _locationDetailsController.dispose();
    _locationUrlController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مشروع جديد"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: _currentStep / 4,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getStepTitle(),
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      "الخطوة $_currentStep من 4",
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildCurrentStep(),
                ),
              ),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return "المعلومات الأساسية";
      case 2:
        return "الموقع والميزانية";
      case 3:
        return "التواريخ والمواعيد";
      case 4:
        return "المراجعة والنشر";
      default:
        return "";
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(hintText: "عنوان المشروع (مطلوب)"),
          validator: (val) => val == null || val.length < 10
              ? 'العنوان قصير جداً (حد أدنى 10 أحرف)'
              : null,
        ),
        const SizedBox(height: 16),
        ref
            .watch(projectCategoriesProvider)
            .when(
              data: (categories) => DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(hintText: "التصنيف (مطلوب)"),
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
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                    if (val != null) {
                      _selectedCategoryName = categories.firstWhere(
                        (cat) => cat['id'] == val,
                      )['name_ar'];
                    }
                  });
                },
                validator: (val) => val == null ? 'مطلوب' : null,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text("خطأ في تحميل التصنيفات"),
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
          decoration: const InputDecoration(hintText: "متطلبات خاصة (اختياري)"),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ref
            .watch(citiesProvider)
            .when(
              data: (citiesList) => DropdownButtonFormField<String>(
                value: _selectedCityId,
                decoration: const InputDecoration(hintText: "المدينة (مطلوب)"),
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
                onChanged: (val) {
                  setState(() {
                    _selectedCityId = val;
                    if (val != null) {
                      _selectedCityName = citiesList.firstWhere(
                        (city) => city['id'] == val,
                      )['name_ar'];
                    }
                  });
                },
                validator: (val) => val == null ? 'مطلوب' : null,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text("خطأ في تحميل المدن"),
            ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _locationDetailsController,
          decoration: const InputDecoration(
            hintText: "تفاصيل الموقع أو الحي (مطلوب)",
          ),
          validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _locationUrlController,
          decoration: const InputDecoration(
            hintText: "رابط خرائط جوجل (اختياري)",
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _latController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: "خط العرض (Lat)"),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _lngController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: "خط الطول (Lng)"),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        Text(
          "نطاق الميزانية (ريال يمني):",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _minBudgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "الحد الأدنى"),
                validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _maxBudgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "الحد الأقصى"),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'مطلوب';
                  final min = double.tryParse(_minBudgetController.text) ?? 0;
                  final max = double.tryParse(val) ?? 0;
                  if (max <= min) return 'يجب أن يكون الأقصى أكبر';
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          tileColor: Colors.white,
          leading: const Icon(Icons.calendar_today, color: AppColors.primary),
          title: Text("تاريخ البدء المتوقع", style: GoogleFonts.cairo()),
          subtitle: Text(
            _startDate != null
                ? DateFormat('yyyy-MM-dd').format(_startDate!)
                : "اختر التاريخ",
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: _startDate != null ? AppColors.primary : Colors.grey,
            ),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                _startDate = date;
                if (_endDate != null && _endDate!.isBefore(date)) {
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
          leading: const Icon(Icons.event, color: AppColors.accent),
          title: Text("الموعد النهائي المتوقع", style: GoogleFonts.cairo()),
          subtitle: Text(
            _endDate != null
                ? DateFormat('yyyy-MM-dd').format(_endDate!)
                : "اختر التاريخ",
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: _endDate != null ? AppColors.accent : Colors.grey,
            ),
          ),
          onTap: () async {
            if (_startDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "يرجى تحديد تاريخ البدء أولاً",
                    style: GoogleFonts.cairo(),
                  ),
                ),
              );
              return;
            }
            final date = await showDatePicker(
              context: context,
              initialDate: _startDate!.add(const Duration(days: 1)),
              firstDate: _startDate!.add(const Duration(days: 1)),
              lastDate: _startDate!.add(const Duration(days: 1000)),
            );
            if (date != null) {
              setState(() => _endDate = date);
            }
          },
        ),
        const SizedBox(height: 32),
        if (_startDate != null && _endDate != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  "مدة المشروع المتوقعة: $_calculatedDays أيام",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 32),
        Text(
          "المخططات والمستندات (اختياري)",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          "يمكنك رفع المخططات المعمارية أو أي ملفات توضح نطاق العمل",
          style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _pickFiles,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primary.withValues(alpha: 0.05),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.primary),
                const SizedBox(height: 8),
                Text("اضغط هنا لاختيار الملفات", style: GoogleFonts.cairo(color: AppColors.primary, fontWeight: FontWeight.bold)),
                Text("(PDF, PNG, JPG, DOC)", style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ),
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedFiles.length,
            itemBuilder: (context, index) {
              final file = _selectedFiles[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: Icon(
                    file.extension == 'pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file,
                    color: file.extension == 'pdf' ? Colors.red : AppColors.primary,
                  ),
                  title: Text(file.name, style: GoogleFonts.cairo(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text("${(file.size / 1024).toStringAsFixed(1)} KB", style: const TextStyle(fontSize: 10)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => _removeFile(index),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ملخص المشروع",
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Divider(),
                _buildSummaryRow("العنوان", _titleController.text),
                _buildSummaryRow("التصنيف", _selectedCategoryName ?? ''),
                _buildSummaryRow(
                  "الموقع",
                  "${_selectedCityName ?? ''} - ${_locationDetailsController.text}${_locationUrlController.text.isNotEmpty ? '\n(رابط الخريطة متوفر)' : ''}",
                ),
                _buildSummaryRow("الميزانية", "${_minBudgetController.text} إلى ${_maxBudgetController.text} ريال"),
                if (_startDate != null && _endDate != null)
                  _buildSummaryRow("التواريخ", "${DateFormat('yyyy-MM-dd').format(_startDate!)} إلى ${DateFormat('yyyy-MM-dd').format(_endDate!)} ($_calculatedDays أيام)"),
                _buildSummaryRow("الملفات المرفقة", "${_selectedFiles.length} ملف"),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: Text(
            "أوافق على نشر المشروع للسماح للمقاولين بتقديم عروضهم والالتزام بشروط المنصة.",
            style: GoogleFonts.cairo(fontSize: 14),
          ),
          value: _agreeToPublish,
          activeColor: AppColors.primary,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) => setState(() => _agreeToPublish = val ?? false),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.cairo(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
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
      child: Row(
        children: [
          if (_currentStep > 1)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _prevStep,
                child: const Text("السابق"),
              ),
            ),
          if (_currentStep > 1) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == 4
                    ? AppColors.success
                    : AppColors.primary,
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
                  : Text(_currentStep == 4 ? "نشر المشروع" : "التالي"),
            ),
          ),
        ],
      ),
    );
  }
}

