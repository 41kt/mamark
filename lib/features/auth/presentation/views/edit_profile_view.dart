import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _storeNameController;
  
  final AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    final user = authController.currentUser.value;
    _nameController = TextEditingController(text: user?.name);
    _usernameController = TextEditingController(text: user?.username);
    _storeNameController = TextEditingController(text: user?.storeName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('المعرض'),
              onTap: () {
                authController.pickAvatar(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('الكاميرا'),
              onTap: () {
                authController.pickAvatar(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = authController.currentUser.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar Section
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(context),
                child: Obx(() => CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: authController.pickedAvatar.value != null
                      ? FileImage(authController.pickedAvatar.value!)
                      : (user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null) as ImageProvider?,
                  child: (authController.pickedAvatar.value == null && user?.avatarUrl == null)
                      ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                      : null,
                )),
              ),
              const SizedBox(height: 8),
              const Text('تغيير الشعار / الصورة الشخصية', style: TextStyle(color: Colors.blue)),
              const SizedBox(height: 32),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'يرجى إدخال الاسم' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'اسم المستخدم', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'يرجى إدخال اسم المستخدم' : null,
              ),
              const SizedBox(height: 16),

              if (user?.role == 'supplier') ...[
                TextFormField(
                  controller: _storeNameController,
                  decoration: const InputDecoration(labelText: 'اسم المتجر', border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? 'يرجى إدخال اسم المتجر' : null,
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),
              Obx(() => ElevatedButton(
                onPressed: authController.isLoading.value 
                  ? null 
                  : () async {
                    if (_formKey.currentState!.validate()) {
                      await authController.updateProfile(
                        name: _nameController.text,
                        username: _usernameController.text,
                        storeName: user?.role == 'supplier' ? _storeNameController.text : null,
                      );
                      Get.back();
                    }
                  },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                  backgroundColor: Colors.blue[800],
                ),
                child: authController.isLoading.value 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('حفظ التغييرات', style: TextStyle(fontSize: 18, color: Colors.white)),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
