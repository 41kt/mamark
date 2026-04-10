import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_provider.dart';

final citiesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final response = await supabase.from('cities').select('*').order('name_ar');
  
  if (response.isEmpty) {
    // 🔥 Fallback: Return default cities if the table is empty in Supabase
    return [
      {'id': '11111111-1111-1111-1111-111111111111', 'name_ar': 'صنعاء'},
      {'id': '22222222-2222-2222-2222-222222222222', 'name_ar': 'عدن'},
      {'id': '33333333-3333-3333-3333-333333333333', 'name_ar': 'تعز'},
      {'id': '44444444-4444-4444-4444-444444444444', 'name_ar': 'إب'},
      {'id': '55555555-5555-5555-5555-555555555555', 'name_ar': 'حضرموت'},
      {'id': '66666666-6666-6666-6666-666666666666', 'name_ar': 'الحديدة'},
      {'id': '77777777-7777-7777-7777-777777777777', 'name_ar': 'مأرب'},
    ];
  }
  
  return List<Map<String, dynamic>>.from(response);
});

final projectCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final response = await supabase.from('project_categories').select('*').order('name_ar');
  
  if (response.isEmpty) {
    // 🔥 Fallback: Return default categories if the table is empty in Supabase
    return [
      {'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'name_ar': 'بناء أساسات وخرسانة'},
      {'id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'name_ar': 'لياسة ودهانات'},
      {'id': 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'name_ar': 'سباكة وأعمال صحية'},
      {'id': 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'name_ar': 'أعمال كهربائية وانارة'},
      {'id': 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'name_ar': 'ديكور وجبس'},
      {'id': 'f0f0f0f0-f0f0-f0f0-f0f0-f0f0f0f0f0f0', 'name_ar': 'تركيب سيراميك ورخام'},
      {'id': 'f1f1f1f1-f1f1-f1f1-f1f1-f1f1f1f1f1f1', 'name_ar': 'نجارة وكهرباء'},
      {'id': 'f2f2f2f2-f2f2-f2f2-f2f2-f2f2f2f2f2f2', 'name_ar': 'حدادة وألومنيوم'},
    ];
  }
  
  return List<Map<String, dynamic>>.from(response);
});

