import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/providers/storage_provider.dart';
import '../providers/contractor_providers.dart';

class AddPortfolioItemScreen extends ConsumerStatefulWidget {
  const AddPortfolioItemScreen({super.key});

  @override
  ConsumerState<AddPortfolioItemScreen> createState() => _AddPortfolioItemScreenState();
}

class _AddPortfolioItemScreenState extends ConsumerState<AddPortfolioItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى اختيار صورة للعمل 🖼️", style: TextStyle(fontFamily: 'Cairo'))));
      }
      return;
    }
    
    setState(() => _isLoading = true);
    final supabase = ref.read(supabaseProvider);
    final user = ref.read(currentUserProvider);
    final storage = ref.read(storageProvider);
    
    if (user != null) {
      try {
        final contractorResponse = await supabase.from('contractors').select('id').eq('user_id', user.id).single();
        final contractorId = contractorResponse['id'];

        final uploadedUrl = await storage.uploadFile(
          file: _imageFile!,
          bucket: 'portfolio',
          path: 'contractors/$contractorId',
        );

        if (uploadedUrl != null) {
          await supabase.from('contractor_portfolio').insert({
            'contractor_id': contractorId,
            'project_title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'images': [uploadedUrl], // Store in jsonb array
          });
          
          // Invalidate the provider to refresh the gallery
          ref.invalidate(contractorPortfolioProvider);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("تم نشر العمل بنجاح! 🎉", style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.green,
            ));
            Navigator.pop(context, true); // Return true to indicate something was added
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("خطأ: $e", style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إضافة عمل جديد", style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
      backgroundColor: AppColors.background,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200, width: 1),
                      ),
                      child: _imageFile != null 
                        ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image(image: FileImage(_imageFile!), fit: BoxFit.cover)) 
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined, size: 50, color: AppColors.primary),
                              const SizedBox(height: 12),
                              Text("اضغط لاختيار صورة للعمل", style: GoogleFonts.cairo(color: Colors.grey)),
                            ],
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField("عنوان العمل", _titleController, Icons.title_outlined),
                  _buildTextField("وصف العمل", _descriptionController, Icons.description_outlined, isMultiLine: true),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _saveItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text("نشر العمل في المعرض", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isMultiLine = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            maxLines: isMultiLine ? 4 : 1,
            style: GoogleFonts.cairo(fontSize: 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1)),
              hintText: "أدخل $label...",
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (val) => (val == null || val.isEmpty) ? "هذا الحقل مطلوب" : null,
          ),
        ],
      ),
    );
  }
}

