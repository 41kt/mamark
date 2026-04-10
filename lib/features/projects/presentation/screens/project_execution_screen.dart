import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/supabase_provider.dart';

final executionDataProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, projectId) async {
      final supabase = ref.read(supabaseProvider);

      final projectRes = await supabase
          .from('projects')
          .select('*, customers(user_id)')
          .eq('id', projectId)
          .maybeSingle();

      final stagesRes = await supabase
          .from('project_stages')
          .select('*')
          .eq('project_id', projectId)
          .order('stage_order', ascending: true);

      return {
        'project': projectRes,
        'stages': List<Map<String, dynamic>>.from(stagesRes),
      };
    });

class ProjectExecutionScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectExecutionScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectExecutionScreen> createState() =>
      _ProjectExecutionScreenState();
}

class _ProjectExecutionScreenState
    extends ConsumerState<ProjectExecutionScreen> {
  bool _isSaving = false;
  List<Map<String, dynamic>>? _mutatedStages;

  Future<void> _saveUpdates() async {
    if (_mutatedStages == null) return;

    setState(() => _isSaving = true);
    final supabase = ref.read(supabaseProvider);
    try {
      double totalProgress = 0;
      for (var stage in _mutatedStages!) {
        totalProgress += (stage['completion_percentage'] ?? 0);
        await supabase
            .from('project_stages')
            .update({
              'status': stage['status'],
              'completion_percentage': stage['completion_percentage'],
              'stage_description': stage['stage_description'],
            })
            .eq('id', stage['id']);
      }

      final overall = _mutatedStages!.isEmpty
          ? 0
          : (totalProgress / _mutatedStages!.length).round();
      
      await supabase
          .from('projects')
          .update({
            'progress_percentage': overall,
            'status': overall == 100 ? 'completed' : 'in_progress',
          })
          .eq('id', widget.projectId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم حفظ التحديثات بنجاح", style: GoogleFonts.cairo()),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(executionDataProvider(widget.projectId));
        Get.back();
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطأ أثناء الحفظ: $e", style: GoogleFonts.cairo()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showUploadProofDialog(Map<String, dynamic> stage) {
    Uint8List? imageBytes;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              "رفع إثبات الدفع",
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "الرجاء إرفاق صورة إيصال التحويل للمرحلة: ${stage['stage_name']}",
                  style: GoogleFonts.cairo(fontSize: 13),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: isUploading
                      ? null
                      : () async {
                          final picker = ImagePicker();
                          try {
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 70,
                            );
                            if (pickedFile != null) {
                              final bytes = await pickedFile.readAsBytes();
                              if (bytes.isNotEmpty) {
                                setDialogState(() {
                                  imageBytes = bytes;
                                });
                              } else {
                                throw Exception("الصورة المختارة فارغة");
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("خطأ في اختيار الصورة: $e"), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        },
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.memory(imageBytes!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.primary),
                              const SizedBox(height: 8),
                              Text("اختيار صورة", style: GoogleFonts.cairo(color: AppColors.primary)),
                            ],
                          ),
                  ),
                ),
                if (isUploading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(ctx),
                child: Text("إلغاء", style: GoogleFonts.cairo(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: (imageBytes == null || isUploading)
                    ? null
                    : () async {
                        setDialogState(() => isUploading = true);
                        try {
                          final supabase = ref.read(supabaseProvider);
                          final fileName = 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
                          final path = '${widget.projectId}/receipts/$fileName';

                          await supabase.storage.from('project_files').uploadBinary(path, imageBytes!);
                          final publicUrl = supabase.storage.from('project_files').getPublicUrl(path);

                          final currentDesc = stage['stage_description'] ?? '';
                          final updatedDesc = "$currentDesc\n\n✅ [مرفق إثبات الدفع]: $publicUrl".trim();

                          await supabase
                              .from('project_stages')
                              .update({'stage_description': updatedDesc})
                              .eq('id', stage['id']);

                          ref.invalidate(executionDataProvider(widget.projectId));

                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("تم الرفع بنجاح"), backgroundColor: AppColors.success),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isUploading = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("فشل الرفع: $e"), backgroundColor: AppColors.error),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: Text("تأكيد الرفع", style: GoogleFonts.cairo(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(executionDataProvider(widget.projectId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: asyncData.when(
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("لوحة التنفيذ", style: GoogleFonts.cairo(fontSize: 16)),
              if (data['project'] != null)
                Text(
                  data['project']['title'] ?? '',
                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.white70),
                ),
            ],
          ),
          loading: () => Text("جاري التحميل...", style: GoogleFonts.cairo()),
          error: (_, __) => Text("خطأ في جلب البيانات", style: GoogleFonts.cairo()),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(executionDataProvider(widget.projectId)),
          ),
        ],
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text("حدث خطأ: $e")),
        data: (data) {
          final project = data['project'] as Map<String, dynamic>?;
          final List stagesList = data['stages'] as List? ?? [];
          final originalStages = stagesList.cast<Map<String, dynamic>>();

          if (project == null) {
            return Center(child: Text("المشروع غير موجود", style: GoogleFonts.cairo()));
          }

          _mutatedStages ??= List<Map<String, dynamic>>.from(
            originalStages.map((e) => Map<String, dynamic>.from(e)),
          );

          if (_mutatedStages!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_tree_outlined, size: 70, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text("لا توجد مراحل مسجلة لهذا المشروع", style: GoogleFonts.cairo()),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => Get.back(), child: Text("عودة")),
                ],
              ),
            );
          }

          final customersData = project['customers'];
          final isOwner = customersData is Map && customersData['user_id'] == currentUser?.id;
          final isContractor = !isOwner;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _mutatedStages!.length,
                    itemBuilder: (context, index) {
                      final stage = _mutatedStages![index];
                      final progress = (stage['completion_percentage'] ?? 0) as num;
                      final status = stage['status'] ?? 'pending';
                      final description = stage['stage_description']?.toString() ?? '';

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    radius: 18,
                                    child: Text("${index + 1}", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      stage['stage_name'] ?? 'مرحلة',
                                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  _StatusBadge(status: status),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Text("الإنجاز: ${progress.toInt()}%", style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: progress / 100,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        progress >= 100 ? Colors.green : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (isContractor) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: ['pending', 'in_progress', 'completed', 'delayed', 'cancelled'].contains(status) ? status : 'pending',
                                        decoration: InputDecoration(
                                          labelText: "تغيير الحالة",
                                          labelStyle: GoogleFonts.cairo(fontSize: 12),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: 'pending', child: Text("معلقة")),
                                          DropdownMenuItem(value: 'in_progress', child: Text("قيد العمل")),
                                          DropdownMenuItem(value: 'completed', child: Text("مكتملة")),
                                          DropdownMenuItem(value: 'delayed', child: Text("متأخرة")),
                                          DropdownMenuItem(value: 'cancelled', child: Text("ملغاة")),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              stage['status'] = val;
                                              if (val == 'completed') stage['completion_percentage'] = 100;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Slider(
                                        value: progress.toDouble(),
                                        min: 0, max: 100, divisions: 10,
                                        onChanged: status == 'completed' ? null : (val) {
                                          setState(() => stage['completion_percentage'] = val.toInt());
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  initialValue: description,
                                  decoration: InputDecoration(
                                    hintText: "أضف ملاحظات أو تحديثات...",
                                    hintStyle: GoogleFonts.cairo(fontSize: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  maxLines: 2,
                                  onChanged: (val) => stage['stage_description'] = val,
                                ),
                              ] else ...[
                                if (description.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    width: double.infinity,
                                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                                    child: Text(
                                      description,
                                      style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ),
                              ],
                              if (description.contains('[مرفق إثبات الدفع]:'))
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: _ImagePreview(description: description),
                                ),
                              if (isOwner)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        if (status == 'completed' || progress >= 80) {
                                          _showUploadProofDialog(stage);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(Icons.info_outline, color: Colors.white),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      "نعتذر، يجب وصول نسبة الإنجاز لـ 80% على الأقل لبدء عملية الدفع لهذه المرحلة.",
                                                      style: GoogleFonts.cairo(fontSize: 12),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: Colors.orange.shade700,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          );
                                        }
                                      },
                                      icon: Icon(
                                        (status == 'completed' || progress >= 80) ? Icons.upload : Icons.lock_outline,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        "إرفاق إثبات دفع للمرحلة",
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: (status == 'completed' || progress >= 80) 
                                            ? Colors.green 
                                            : Colors.grey.shade400,
                                        elevation: (status == 'completed' || progress >= 80) ? 2 : 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                ),
                if (isContractor)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveUpdates,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text("حفظ التحديثات وإرسالها", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String description;
  const _ImagePreview({required this.description});

  @override
  Widget build(BuildContext context) {
    try {
      final url = description.split('[مرفق إثبات الدفع]:').last.trim();
      if (!url.startsWith('http')) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Text("إثبات الدفع المرفق:", style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppBar(
                        title: Text("إثبات الدفع", style: GoogleFonts.cairo()),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        automaticallyImplyLeading: false,
                        actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))],
                      ),
                      ClipRRect(
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                        child: Image.network(url, fit: BoxFit.contain),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Container(
              height: 120,
              width: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
                image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                  ),
                ),
                child: const Center(child: Icon(Icons.zoom_in, color: Colors.white, size: 30)),
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    switch (status) {
      case 'completed':
        color = Colors.green;
        text = "مكتملة";
        break;
      case 'in_progress':
        color = Colors.blue;
        text = "قيد العمل";
        break;
      case 'delayed':
        color = Colors.red;
        text = "متأخرة";
        break;
      case 'cancelled':
        color = Colors.grey;
        text = "ملغاة";
        break;
      default:
        color = Colors.orange;
        text = "معلقة";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: GoogleFonts.cairo(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

