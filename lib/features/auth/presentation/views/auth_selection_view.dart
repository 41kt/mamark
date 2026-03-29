import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthSelectionView extends StatelessWidget {
  const AuthSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // App Branding
              Hero(
                tag: 'app-logo',
                child: Icon(Icons.construction_rounded, size: 80, color: Colors.blue[900]),
              ),
              const SizedBox(height: 16),
              Text(
                'Mamark',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'اختر نوع حسابك للبدء',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 60),

              // Role Cards
              Expanded(
                child: Row(
                  children: [
                    _buildRoleCard(
                      title: 'أنا مشتري',
                      subtitle: 'تصفح واطلب مواد البناء',
                      icon: Icons.shopping_bag_outlined,
                      color: Colors.blue,
                      onTap: () => Get.toNamed('/login', arguments: {'role': 'customer'}),
                    ),
                    const SizedBox(width: 20),
                    _buildRoleCard(
                      title: 'أنا مورد',
                      subtitle: 'إدارة المنتجات والطلبات',
                      icon: Icons.storefront_outlined,
                      color: Colors.orange,
                      onTap: () => Get.toNamed('/login', arguments: {'role': 'supplier'}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Bottom Help
              const Text(
                'بالاستمرار أنت توافق على شروط الاستخدام',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: color.withValues(alpha: 0.1), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900]),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
