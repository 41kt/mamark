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

    // Using Obx around the entire body ensures that when themeService.themeMode
    // or localizationService.currentLanguage changes, the UI updates instantly.
    return Obx(() {
      final theme = Theme.of(context);
      final isDark = themeService.themeMode == ThemeMode.dark;
      
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('settings'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildUserSection(authController, theme),
              const SizedBox(height: 20),
              _buildSettingsGroup('app_section'.tr, [
                _buildSettingItem(
                  title: 'language'.tr,
                  subtitle: localizationService.currentLanguage.languageCode == 'ar' ? 'العربية' : 'English',
                  icon: Icons.language_outlined,
                  iconColor: Colors.blue,
                  theme: theme,
                  onTap: () => _showLanguageDialog(context, localizationService, theme),
                ),
                _buildSettingItem(
                  title: 'dark_mode'.tr,
                  subtitle: isDark ? 'enabled'.tr : 'disabled'.tr,
                  icon: Icons.dark_mode_outlined,
                  iconColor: Colors.deepPurple,
                  theme: theme,
                  trailing: Switch(
                    value: isDark,
                    activeColor: Colors.deepPurple,
                    onChanged: (value) => themeService.switchTheme(),
                  ),
                ),
              ], theme),
              _buildSettingsGroup('account'.tr, [
                _buildSettingItem(
                  title: 'store_profile'.tr, // or 'edit_profile', using 'store_profile' if supplier based on auth logic usually
                  icon: Icons.person_outline,
                  iconColor: Colors.green,
                  theme: theme,
                  onTap: () => Get.toNamed('/edit-profile'),
                ),
                _buildSettingItem(
                  title: 'my_orders'.tr,
                  icon: Icons.receipt_long_outlined,
                  iconColor: Colors.orange,
                  theme: theme,
                  onTap: () => Get.toNamed('/orders'),
                ),
              ], theme),
              _buildSettingsGroup('support_legal'.tr, [
                _buildSettingItem(
                  title: 'about_app'.tr,
                  icon: Icons.info_outline,
                  iconColor: Colors.grey,
                  theme: theme,
                  onTap: () {},
                ),
                _buildSettingItem(
                  title: 'privacy_policy'.tr,
                  icon: Icons.privacy_tip_outlined,
                  iconColor: Colors.grey,
                  theme: theme,
                  onTap: () {},
                ),
              ], theme),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton.icon(
                  onPressed: () {
                    authController.logout();
                    Get.offAllNamed('/login');
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: Text('logout'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    });
  }

  Widget _buildUserSection(AuthController controller, ThemeData theme) {
    final user = controller.currentUser.value;
    return Container(
      padding: const EdgeInsets.all(24.0),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
            child: user?.avatarUrl == null ? Icon(Icons.person, size: 40, color: theme.colorScheme.primary) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'guest'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.email ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user?.role == 'supplier' ? 'supplier'.tr : 'customer'.tr,
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> items, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 28, left: 28, top: 24, bottom: 8),
          child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 0.5)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: theme.cardColor,
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
    required ThemeData theme,
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
      title: Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500])) : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showLanguageDialog(BuildContext context, LocalizationService service, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('language'.tr, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              title: Text('العربية', style: theme.textTheme.bodyLarge),
              trailing: service.currentLanguage.languageCode == 'ar' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () { service.changeLocale('ar'); Navigator.pop(context); },
            ),
            ListTile(
              title: Text('English', style: theme.textTheme.bodyLarge),
              trailing: service.currentLanguage.languageCode == 'en' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () { service.changeLocale('en'); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }
}
