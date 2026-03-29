import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/services/theme_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationService = Get.find<LocalizationService>();
    final themeService = Get.find<ThemeService>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUserSection(authController),
            const SizedBox(height: 20),
            _buildSettingsGroup('التطبيق', [
              _buildSettingItem(
                title: 'اللغة',
                subtitle: localizationService.currentLanguage.languageCode == 'ar' ? 'العربية' : 'English',
                icon: Icons.language_outlined,
                iconColor: Colors.blue,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () => _showLanguageDialog(context, localizationService),
              ),
              _buildSettingItem(
                title: 'المظهر الداكن',
                subtitle: themeService.themeMode == ThemeMode.dark ? 'مفعل' : 'معطل',
                icon: Icons.dark_mode_outlined,
                iconColor: Colors.deepPurple,
                trailing: Switch(
                  value: themeService.themeMode == ThemeMode.dark,
                  activeColor: Colors.deepPurple,
                  onChanged: (value) => themeService.switchTheme(),
                ),
              ),
            ]),
            _buildSettingsGroup('الحساب', [
              _buildSettingItem(
                title: 'تعديل الملف الشخصي',
                icon: Icons.person_outline,
                iconColor: Colors.green,
                onTap: () => Get.toNamed('/edit-profile'),
              ),
              _buildSettingItem(
                title: 'طلباتي',
                icon: Icons.receipt_long_outlined,
                iconColor: Colors.orange,
                onTap: () => Get.toNamed('/orders'),
              ),
            ]),
            _buildSettingsGroup('الدعم والقانونية', [
              _buildSettingItem(
                title: 'عن مامارك',
                icon: Icons.info_outline,
                iconColor: Colors.grey,
                onTap: () {},
              ),
              _buildSettingItem(
                title: 'سياسة الخصوصية',
                icon: Icons.privacy_tip_outlined,
                iconColor: Colors.grey,
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: () {
                  authController.logout();
                  Get.offAllNamed('/login');
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size.fromHeight(55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection(AuthController controller) {
    final user = controller.currentUser.value;
    return Container(
      padding: const EdgeInsets.all(24.0),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.blue[50],
            backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
            child: user?.avatarUrl == null ? Icon(Icons.person, size: 40, color: Colors.blue[800]) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'زائر',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.email ?? '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user?.role == 'supplier' ? 'مورد' : 'مشتري',
                    style: TextStyle(fontSize: 11, color: Colors.blue[900], fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 28, top: 24, bottom: 8),
          child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 0.5)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showLanguageDialog(BuildContext context, LocalizationService service) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('اختر اللغة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('العربية'),
              trailing: service.currentLanguage.languageCode == 'ar' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () { service.changeLocale('ar'); Navigator.pop(context); },
            ),
            ListTile(
              title: const Text('English'),
              trailing: service.currentLanguage.languageCode == 'en' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () { service.changeLocale('en'); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }
}
