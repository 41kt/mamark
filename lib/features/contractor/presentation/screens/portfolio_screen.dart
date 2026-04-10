import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/contractor_providers.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  // The provider is now global in contractor_providers.dart

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("معرض أعمالي", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(contractorPortfolioProvider.future),
        child: ref.watch(contractorPortfolioProvider).when(
          data: (projects) {
            if (projects.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                   SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                   Center(
                     child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_outlined, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text("لا توجد أعمال مضافة حالياً في معرضك", style: GoogleFonts.cairo(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => Get.toNamed('/add-portfolio')?.then((_) => ref.invalidate(contractorPortfolioProvider)),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text("إضافة أول عمل", style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                   ),
                ],
              );
            }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: (project['images'] != null && (project['images'] as List).isNotEmpty)
                          ? Image.network((project['images'] as List).first, width: double.infinity, fit: BoxFit.cover) 
                          : const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project['project_title'] ?? 'عمل غير مسمى', 
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            project['description'] ?? '', 
                            style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              Center(child: Text("خطأ: $e", style: const TextStyle(fontFamily: 'Cairo'), textAlign: TextAlign.center)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/add-portfolio')?.then((_) => ref.invalidate(contractorPortfolioProvider)),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

