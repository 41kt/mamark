import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../../contractor/presentation/providers/contractor_providers.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../../core/theme/app_colors.dart';

class CreateBidScreen extends ConsumerStatefulWidget {
  final String projectId;
  const CreateBidScreen({super.key, required this.projectId});

  @override
  ConsumerState<CreateBidScreen> createState() => _CreateBidScreenState();
}

class _CreateBidScreenState extends ConsumerState<CreateBidScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _priceController = TextEditingController();
  final _daysController = TextEditingController();
  final _descController = TextEditingController();
  final _warrantyController = TextEditingController();
  
  bool _enablePaymentSchedule = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _paymentSteps = [
    {"name": "", "percentage": 0.0},
  ];

  double get _totalPercentage {
    return _paymentSteps.fold(0.0, (sum, item) => sum + (item['percentage'] as double));
  }

  double get _totalPrice {
    return double.tryParse(_priceController.text) ?? 0.0;
  }

  void _addStep() {
    setState(() => _paymentSteps.add({"name": "", "percentage": 0.0}));
  }

  void _removeStep(int index) {
    if (_paymentSteps.length > 1) {
      setState(() => _paymentSteps.removeAt(index));
    }
  }

  Future<void> _submitBid() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_enablePaymentSchedule) {
      if ((_totalPercentage - 100.0).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("مجموع النسب في جدول الدفع يجب أن يساوي 100%", style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.error),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    
    try {
      final supabase = ref.read(supabaseProvider);
      final user = ref.read(currentUserProvider);
      
      if (user == null) {
        throw Exception("يجب تسجيل الدخول أولاً");
      }

      // 1. Get contractor ID
      final contractorResponse = await supabase
          .from('contractors')
          .select('id')
          .eq('user_id', user.id)
          .single();
      
      final contractorId = contractorResponse['id'];

      // 2. Insert bid
      await supabase.from('bids').insert({
        'project_id': widget.projectId,
        'contractor_id': contractorId,
        'bid_price': _totalPrice,
        'duration_days': int.tryParse(_daysController.text) ?? 0,
        'description': _descController.text.trim(),
        'warranty': _warrantyController.text.trim(),
        'payment_schedule': _enablePaymentSchedule ? _paymentSteps : null,
        'status': 'pending',
      });

      if (mounted) {
        ref.invalidate(contractorBidsProvider);
        ref.invalidate(projectBidsProvider(widget.projectId));
        ref.invalidate(contractorStatsProvider);
        
        Get.back();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم إرسال عرضك بنجاح", style: TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("حدث خطأ أثناء الإرسال: $e", style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _daysController.dispose();
    _descController.dispose();
    _warrantyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectDetailsProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(title: const Text("تقديم عرض", style: TextStyle(fontFamily: 'Cairo'))),
      backgroundColor: AppColors.background,
      body: projectAsync.when(
        data: (project) {
          if (project == null) {
            return const Center(child: Text("المشروع غير موجود", style: TextStyle(fontFamily: 'Cairo')));
          }
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Project summary
                          Card(
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(project['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.monetization_on, size: 16, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${project['budget_min']} - ${project['budget_max']} ريال",
                                        style: const TextStyle(color: Colors.green, fontSize: 14, fontFamily: 'Cairo'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text("التفاصيل الفنية والمالية", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo')),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: "السعر الإجمالي (ريال يمني)", prefixIcon: Icon(Icons.attach_money)),
                            onChanged: (val) => setState(() {}),
                            validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _daysController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: "مدة التنفيذ بالأيام", prefixIcon: Icon(Icons.timer)),
                            validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descController,
                            maxLines: 5,
                            decoration: const InputDecoration(hintText: "وصف العرض التفصيلي (خطوات العمل، المواد..)"),
                            validator: (val) => val == null || val.length < 50 ? 'يجب كتابة تفاصيل 50 حرفاً على الأقل' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _warrantyController,
                            decoration: const InputDecoration(hintText: "الضمان المقدم (اختياري)"),
                          ),
                          const SizedBox(height: 24),
                          
                          // Payment Schedule
                          Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  title: const Text("إضافة جدول سداد (دفعات)", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                  activeColor: AppColors.primary,
                                  value: _enablePaymentSchedule,
                                  onChanged: (val) => setState(() => _enablePaymentSchedule = val),
                                ),
                                if (_enablePaymentSchedule)
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        ..._paymentSteps.asMap().entries.map((entry) {
                                          int idx = entry.key;
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 12.0),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: TextFormField(
                                                    initialValue: entry.value['name'],
                                                    decoration: const InputDecoration(hintText: "اسم الدفعة"),
                                                    onChanged: (val) => _paymentSteps[idx]['name'] = val,
                                                    validator: (val) => val == null || val.isEmpty ? '*' : null,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  flex: 1,
                                                  child: TextFormField(
                                                    keyboardType: TextInputType.number,
                                                    decoration: const InputDecoration(hintText: "%"),
                                                    onChanged: (val) {
                                                      setState(() {
                                                        _paymentSteps[idx]['percentage'] = double.tryParse(val) ?? 0.0;
                                                      });
                                                    },
                                                    validator: (val) => val == null || val.isEmpty ? '*' : null,
                                                  ),
                                                ),
                                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeStep(idx)),
                                              ],
                                            ),
                                          );
                                        }),
                                        TextButton.icon(
                                          icon: const Icon(Icons.add),
                                          label: const Text("إضافة دفعة", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                          onPressed: _addStep,
                                        ),
                                      ],
                                    ),
                                  )
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitBid,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("إرسال العرض"),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text("خطأ في تحميل بيانات المشروع: $e", style: const TextStyle(fontFamily: 'Cairo'))),
      ),
    );
  }
}

