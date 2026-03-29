import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mamark/features/products/presentation/controllers/product_controller.dart';
import 'package:mamark/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mamark/features/products/domain/entities/product_entity.dart';

class AddProductView extends StatefulWidget {
  const AddProductView({super.key});

  @override
  State<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'أسمنت';

  final categories = ['أسمنت', 'حديد تسليح', 'طوب وبلك', 'رمال وخرسانة', 'أدوات بناء', 'دهانات', 'سباكة', 'كهرباء', 'أخرى'];
  final units = ['برطل', 'كيلو', 'طن', 'قطعة', 'متر مكعب', 'متر طولي'];
  String _selectedUnit = 'قطعة';
  ProductEntity? _editingProduct;

  @override
  void initState() {
    super.initState();
    Get.find<ProductController>().clearPickedImage();
    _editingProduct = Get.arguments as ProductEntity?;
    if (_editingProduct != null) {
      _nameController.text = _editingProduct!.name;
      _priceController.text = _editingProduct!.price.toString();
      _quantityController.text = _editingProduct!.quantity.toString();
      _descriptionController.text = _editingProduct!.description ?? '';
      _selectedCategory = categories.contains(_editingProduct!.category) ? _editingProduct!.category : categories.first;
      _selectedUnit = units.contains(_editingProduct!.unit) ? _editingProduct!.unit : units.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();
    final authController = Get.find<AuthController>();

    // Use categories from controller
    final categories = productController.categories;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_editingProduct == null ? 'إضافة صنف جديد' : 'تعديل الصنف', 
          style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker Section
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(context, productController),
                child: Obx(() {
                  final pickedImage = productController.pickedImage.value;
                  final hasImage = pickedImage != null || _editingProduct?.imageUrl != null;
                  
                  return Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[100]!, width: 2),
                      image: pickedImage != null
                          ? DecorationImage(image: FileImage(pickedImage), fit: BoxFit.cover)
                          : (_editingProduct?.imageUrl != null
                              ? DecorationImage(image: NetworkImage(_editingProduct!.imageUrl!), fit: BoxFit.cover)
                              : null),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: !hasImage
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 60, color: Colors.blue[800]),
                              const SizedBox(height: 12),
                              Text('أضف صورة احترافية للمنتج', 
                                style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                              const Text('(معرض الصور أو الكاميرا)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          )
                        : Stack(
                            children: [
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              
              _buildFieldLabel('اسم المنتج / المادة'),
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration('مثلاً: أسمنت بورتلاندي عالي الجودة'),
                validator: (value) => (value == null || value.isEmpty) ? 'يرجى إدخال اسم المنتج بدقة' : null,
              ),
              const SizedBox(height: 20),
              
              _buildFieldLabel('الصنف / الفئة'),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _buildInputDecoration(''),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
                validator: (value) => value == null ? 'يرجى اختيار الصنف' : null,
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('السعر (\$)'),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          decoration: _buildInputDecoration('0.00'),
                          validator: (value) => (value == null || value.isEmpty) ? 'سعر المادة مطلوب' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('وحدة القياس'),
                        DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: _buildInputDecoration(''),
                          items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (value) => setState(() => _selectedUnit = value!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              _buildFieldLabel('الكمية المتوفرة'),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _buildInputDecoration('0'),
                validator: (value) => (value == null || value.isEmpty) ? 'الرجاء تحديد الكمية المتاحة' : null,
              ),
              const SizedBox(height: 20),
              
              _buildFieldLabel('وصف المنتج (اختياري)'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _buildInputDecoration('اكتب هنا تفاصيل إضافية عن جودة المنتج أو طريقة التوصيل...'),
              ),
              const SizedBox(height: 40),
              
              Obx(() => ElevatedButton(
                onPressed: productController.isLoading.value 
                  ? null 
                  : () {
                    if (_formKey.currentState!.validate()) {
                      final supplier = authController.currentUser.value;
                      if (supplier == null) {
                        Get.snackbar('خطأ', 'يجب تسجيل الدخول كمورد أولاً');
                        return;
                      }

                      final quantity = int.tryParse(_quantityController.text) ?? 0;
                      final price = double.tryParse(_priceController.text) ?? 0.0;

                      final productData = ProductEntity(
                        id: _editingProduct?.id ?? '', 
                        supplierId: supplier.id,
                        name: _nameController.text,
                        category: _selectedCategory,
                        unit: _selectedUnit,
                        quantity: quantity,
                        price: price,
                        description: _descriptionController.text,
                        imageUrl: _editingProduct?.imageUrl,
                        createdAt: _editingProduct?.createdAt,
                      );

                      if (_editingProduct == null) {
                        productController.addProduct(productData);
                      } else {
                        productController.updateProduct(productData);
                      }
                    }
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: productController.isLoading.value 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_editingProduct == null ? 'نشر المنتج الآن' : 'حفظ التعديلات', 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              )),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 4),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue[800]!, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
    );
  }

  void _showImageSourceActionSheet(BuildContext context, ProductController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          children: [
            const Center(child: Text('اختيار صورة المنتج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            const SizedBox(height: 40, width: double.infinity),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle), child: const Icon(Icons.photo_library, color: Colors.blue)),
              title: const Text('المعرض (Gallery)'),
              onTap: () {
                controller.pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle), child: const Icon(Icons.photo_camera, color: Colors.green)),
              title: const Text('الكاميرا (Camera)'),
              onTap: () {
                controller.pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
