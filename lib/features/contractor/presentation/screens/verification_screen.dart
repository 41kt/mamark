import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/storage_provider.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  Uint8List? _crBytes; // Commercial Register bytes
  Uint8List? _idBytes; // ID Card bytes
  bool _isLoading = false;

  Future<void> _pickImage(bool isCR) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200, 
        maxHeight: 1200,
        imageQuality: 75, 
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          if (isCR) {
            _crBytes = bytes;
          } else {
            _idBytes = bytes;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("خطأ في اختيار الصورة: $e");
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo(color: Colors.white, fontSize: 13)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      )
    );
  }

  Future<void> _submitVerification() async {
    if (_crBytes == null || _idBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى إرفاق كافة الوثائق المطلوبة 📄", style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.orange,
        )
      );
      return;
    }
    
    setState(() => _isLoading = true);
    final supabase = ref.read(supabaseProvider);
    final user = ref.read(currentUserProvider);
    final storage = ref.read(storageProvider);
    
    if (user != null) {
      try {
        final contractorResponse = await supabase
            .from('contractors')
            .select('id, metadata')
            .eq('user_id', user.id)
            .maybeSingle();
            
        if (contractorResponse == null) {
          throw "لم يتم العثور على ملف مقاول لهذا المستخدم.";
        }
        
        final contractorId = contractorResponse['id'];
        final existingMetadata = contractorResponse['metadata'] as Map<String, dynamic>? ?? {};

        // 1. Upload Documents SEQUENTIALLY
        final crPath = 'contractors/$contractorId/cr_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final crResult = await storage.uploadBytes(
          bytes: _crBytes!,
          bucket: 'verification',
          path: crPath,
          mimeType: 'image/jpeg',
        );

        if (crResult['success'] == false) {
          throw "فشل رفع السجل: ${crResult['error']}";
        }
        final String crUrl = crResult['url'];

        final idPath = 'contractors/$contractorId/id_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final idResult = await storage.uploadBytes(
          bytes: _idBytes!,
          bucket: 'verification',
          path: idPath,
          mimeType: 'image/jpeg',
        );

        if (idResult['success'] == false) {
          throw "فشل رفع الهوية: ${idResult['error']}";
        }
        final String idUrl = idResult['url'];

        // 2. Update status in Database
        // Note: Using 'waiting' or similar might be the allowed constraint, but we safest is updating metadata only 
        // to avoid 'account_status' constraint violation if we don't know the exact allowed values.
        final updatedMetadata = {
          ...existingMetadata,
          'cr_url': crUrl,
          'id_url': idUrl,
          'verification_status': 'submitted',
          'verification_submitted_at': DateTime.now().toIso8601String(),
        };

        // We update ONLY the columns we are sure about or just metadata
        await supabase.from('contractors').update({
          'metadata': updatedMetadata,
          // 'account_status': 'verified', // Removed to avoid violation unless we know correct value
        }).eq('user_id', user.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("تم إرسال طلب التوثيق بنجاح! سيتم المراجعة خلال 24 ساعة ✅", style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar("حدث خطأ أثناء الاتصال: $e");
        }
      }
    } else {
      _showErrorSnackBar("يرجى تسجيل الدخول أولاً");
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("التوثيق والشهادات", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 32),
                _buildUploadBox("صورة السجل التجاري", _crBytes, () => _pickImage(true)),
                const SizedBox(height: 20),
                _buildUploadBox("صورة الهوية الوطنية", _idBytes, () => _pickImage(false)),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("إرسال طلب التوثيق", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "يتطلب التوثيق رفع نسخة واضحة من السجل التجاري ونسخة من الهوية للتأكد من هويتك المهنية وحماية المستخدمين.",
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.normal, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBox(String title, Uint8List? bytes, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: bytes != null ? AppColors.primary.withValues(alpha: 0.5) : Colors.grey.shade200, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: bytes != null 
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16), 
                      child: Image.memory(bytes, fit: BoxFit.cover)
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ),
                    ),
                  ],
                ) 
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
                      child: const Icon(Icons.add_a_photo_outlined, size: 30, color: AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                    Text("انقر لاختيار صورة الوثيقة", style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
          ),
        ),
      ],
    );
  }
}

