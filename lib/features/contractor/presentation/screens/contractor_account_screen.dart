import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart' show Get, GetNavigation;
import '../providers/contractor_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/master_data_providers.dart';

class ContractorAccountScreen extends ConsumerStatefulWidget {
  const ContractorAccountScreen({super.key});

  @override
  ConsumerState<ContractorAccountScreen> createState() => _ContractorAccountScreenState();
}

class _ContractorAccountScreenState extends ConsumerState<ContractorAccountScreen> {
  bool _editMode = false;

  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _crCtrl = TextEditingController();
  final _expCtrl = TextEditingController();

  String? _selectedCityId;
  bool _saving = false;

  static const _specialtyOptions = [
    'بناء وإنشاء',
    'سباكة',
    'كهرباء',
    'تكييف وتبريد',
    'ديكور وتشطيبات',
    'أسطح ومحيط',
    'لحامات',
    'نجارة',
    'دهانات',
  ];
  List<String> _selectedSpecialties = [];

  void _loadProfile(Map<String, dynamic>? p) {
    if (p == null) return;
    _nameCtrl.text = p['user_name'] ?? '';
    _bioCtrl.text = p['bio'] ?? '';
    _phoneCtrl.text = p['phone_number'] ?? '';
    _whatsappCtrl.text = p['whatsapp'] ?? '';
    _crCtrl.text = p['cr_number'] ?? '';
    _expCtrl.text = p['years_experience']?.toString() ?? '';
    _selectedCityId = p['city_id'];
    final spec = p['specialty'];
    if (spec is List) {
      _selectedSpecialties = List<String>.from(spec);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(contractorProfileSaverProvider).save({
        'user_name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'phone_number': _phoneCtrl.text.trim(),
        'whatsapp': _whatsappCtrl.text.trim(),
        'cr_number': _crCtrl.text.trim(),
        'years_experience': int.tryParse(_expCtrl.text) ?? 0,
        'city_id': _selectedCityId,
        'specialty': _selectedSpecialties,
      });
      if (mounted) {
        setState(() => _editMode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الملف الشخصي'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(contractorProfileProvider);
    final statsAsync = ref.watch(contractorStatsProvider);
    final completionAsync = ref.watch(profileCompletionProvider);
    final citiesAsync = ref.watch(citiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        data: (p) {
          // Load controllers only once on first data
          if (!_editMode && _nameCtrl.text.isEmpty && p != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile(p));
          }
          return CustomScrollView(
            slivers: [
              // ─── Header ───
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white24,
                            backgroundImage: p?['profile_image_url'] != null
                                ? NetworkImage(p!['profile_image_url'])
                                : null,
                            child: p?['profile_image_url'] == null
                                ? const Icon(Icons.person, size: 50, color: Colors.white)
                                : null,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        p?['user_name'] ?? 'المقاول',
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            p?['is_verified'] == true
                                ? Icons.verified
                                : Icons.warning_amber_rounded,
                            color: p?['is_verified'] == true
                                ? Colors.lightBlueAccent
                                : Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p?['is_verified'] == true ? 'مقاول موثق' : 'حساب غير موثق',
                            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Profile Completion Bar
                      completionAsync.when(
                        data: (pct) => Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'اكتمال الملف الشخصي',
                                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11),
                                ),
                                Text(
                                  '$pct%',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: pct / 100,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                pct >= 80 ? Colors.greenAccent : Colors.amber,
                              ),
                            ),
                          ],
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Stats ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: statsAsync.when(
                    data: (stats) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statItem('العروض', '${stats['accepted']}'),
                          Container(height: 30, width: 1, color: Colors.grey.shade200),
                          _statItem('النشطة', '${stats['active']}'),
                          Container(height: 30, width: 1, color: Colors.grey.shade200),
                          _statItem('التقييم', '${stats['rating']} ⭐'),
                        ],
                      ),
                    ),
                    loading: () => const SizedBox(height: 80),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // ─── Edit Form / Menu ───
              if (_editMode)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildEditForm(citiesAsync),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _section('إدارة الأعمال'),
                      _menuItem(context, 'عروضي المقدمة', Icons.assignment_outlined,
                          onTap: () => Get.toNamed('/orders')),
                      _menuItem(context, 'معرض أعمالي', Icons.photo_library_outlined,
                          onTap: () => Get.toNamed('/portfolio')),
                      _menuItem(context, 'المتجر الإلكتروني', Icons.store_outlined,
                          onTap: () => Get.toNamed('/home')),
                      const SizedBox(height: 16),

                      _section('الحساب والتوثيق'),
                      _menuItem(context, 'توثيق الهوية', Icons.verified_user_outlined,
                          onTap: () {}),
                      _menuItem(context, 'تعديل الملف الشخصي', Icons.edit_outlined,
                          onTap: () {
                            _loadProfile(p);
                            setState(() => _editMode = true);
                          }),
                      const SizedBox(height: 16),

                      _section('عام'),
                      _menuItem(context, 'الإشعارات', Icons.notifications_outlined,
                          onTap: () => Get.toNamed('/notifications')),
                      _menuItem(context, 'الإعدادات', Icons.settings_outlined,
                          onTap: () => Get.toNamed('/settings')),
                      _menuItem(context, 'مركز المساعدة', Icons.help_outline,
                          onTap: () {}),
                      const SizedBox(height: 24),

                      _logoutButton(),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e', style: GoogleFonts.cairo())),
      ),
    );
  }

  Widget _buildEditForm(AsyncValue<List<Map<String, dynamic>>> citiesAsync) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _formLabel('الاسم الكامل'),
        TextField(
          controller: _nameCtrl,
          decoration: inputDecoration.copyWith(hintText: 'الاسم الكامل'),
        ),
        const SizedBox(height: 12),

        _formLabel('نبذة مهنية'),
        TextField(
          controller: _bioCtrl,
          maxLines: 3,
          decoration: inputDecoration.copyWith(hintText: 'اكتب نبذة مهنية عنك...'),
        ),
        const SizedBox(height: 12),

        _formLabel('رقم الجوال'),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: inputDecoration.copyWith(hintText: '+967 7X XXX XXXX'),
        ),
        const SizedBox(height: 12),

        _formLabel('واتساب (اختياري)'),
        TextField(
          controller: _whatsappCtrl,
          keyboardType: TextInputType.phone,
          decoration: inputDecoration.copyWith(hintText: 'رقم الواتساب'),
        ),
        const SizedBox(height: 12),

        _formLabel('رقم السجل التجاري (اختياري)'),
        TextField(
          controller: _crCtrl,
          decoration: inputDecoration.copyWith(hintText: 'رقم السجل التجاري'),
        ),
        const SizedBox(height: 12),

        _formLabel('سنوات الخبرة'),
        TextField(
          controller: _expCtrl,
          keyboardType: TextInputType.number,
          decoration: inputDecoration.copyWith(hintText: 'عدد سنوات الخبرة'),
        ),
        const SizedBox(height: 12),

        _formLabel('المدينة'),
        citiesAsync.when(
          data: (cities) => DropdownButtonFormField<String>(
            value: _selectedCityId,
            decoration: inputDecoration,
            hint: Text('اختر المدينة', style: GoogleFonts.cairo()),
            items: cities.map((c) => DropdownMenuItem<String>(
              value: c['id'] as String,
              child: Text(c['name_ar'] as String, style: GoogleFonts.cairo()),
            )).toList(),
            onChanged: (v) => setState(() => _selectedCityId = v),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),

        _formLabel('التخصصات'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _specialtyOptions.map((s) {
            final selected = _selectedSpecialties.contains(s);
            return FilterChip(
              label: Text(s, style: GoogleFonts.cairo(fontSize: 12)),
              selected: selected,
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _selectedSpecialties.add(s);
                  } else {
                    _selectedSpecialties.remove(s);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _editMode = false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('إلغاء', style: GoogleFonts.cairo()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('حفظ التغييرات', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _formLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        text,
        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        Text(label,
            style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500),
      ),
    );
  }

  Widget _menuItem(BuildContext context, String title, IconData icon,
      {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(title,
            style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _logoutButton() {
    return ElevatedButton.icon(
      onPressed: () => ref.read(supabaseProvider).auth.signOut().then((_) {
        Get.offAllNamed('/login');
      }),
      icon: const Icon(Icons.logout, size: 20),
      label: Text('تسجيل الخروج',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.shade100),
        ),
      ),
    );
  }
}
