import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';

// ────────────────────────────────────────────────
// Customer Profile
// ────────────────────────────────────────────────
final customerProfileProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final supabase = ref.read(supabaseProvider);
  final user = ref.read(currentUserProvider);
  if (user == null) return null;

  var response = await supabase
      .from('customers')
      .select('*, cities!customers_city_id_fkey(name_ar)')
      .eq('user_id', user.id)
      .maybeSingle();

  if (response == null) {
    try {
      final name = user.userMetadata?['full_name'] ?? 'عميل جديد';
      final email = user.email;
      response = await supabase
          .from('customers')
          .insert({'user_id': user.id, 'user_name': name, 'email': email})
          .select('*, cities!customers_city_id_fkey(name_ar)')
          .maybeSingle();
    } catch (e) {
      // Ignored if RLS prevents inserts here
    }
  }

  return response;
});

// ────────────────────────────────────────────────
// Customer Stats
// ────────────────────────────────────────────────
final customerStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final supabase = ref.read(supabaseProvider);
  final user = ref.read(currentUserProvider);
  if (user == null) {
    return {'open_projects': 0, 'new_bids': 0, 'completed_projects': 0};
  }

  final customer = await supabase
      .from('customers')
      .select('id')
      .eq('user_id', user.id)
      .maybeSingle();

  if (customer == null) {
    return {'open_projects': 0, 'new_bids': 0, 'completed_projects': 0};
  }

  final customerId = customer['id'] as String;

  // ✅ Run all 3 queries IN PARALLEL
  final results = await Future.wait([
    supabase
        .from('projects')
        .select('id')
        .eq('customer_id', customerId)
        .eq('status', 'open'),
    supabase
        .from('projects')
        .select('id')
        .eq('customer_id', customerId)
        .eq('status', 'completed'),
    supabase
        .from('projects')
        .select('id')
        .eq('customer_id', customerId)
        .eq('status', 'in_progress'),
  ]);

  return {
    'open_projects': results[0].length,
    'in_progress': results[2].length,
    'completed_projects': results[1].length,
  };
});

// ────────────────────────────────────────────────
// My Projects — StreamProvider for real-time updates
// Fetches all customer projects with related data
// ────────────────────────────────────────────────
final myProjectsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) async* {
  final supabase = ref.read(supabaseProvider);
  final user = ref.read(currentUserProvider);
  if (user == null) {
    yield [];
    return;
  }

  // Get customer id
  final customer = await supabase
      .from('customers')
      .select('id')
      .eq('user_id', user.id)
      .maybeSingle();

  if (customer == null) {
    yield [];
    return;
  }

  final customerId = customer['id'] as String;

  // Initial load
  final initial = await supabase
      .from('projects')
      .select('''
        id, title, description, status, project_type,
        budget_min, budget_max, progress_percentage,
        bids_count, created_at, deadline,
        location_lat, location_lng,
        cities!fk_projects_city(name_ar),
        project_categories!fk_projects_category(name_ar)
      ''')
      .eq('customer_id', customerId)
      .order('created_at', ascending: false);

  yield List<Map<String, dynamic>>.from(initial);

  // Supabase realtime stream
  await for (final _
      in supabase
          .from('projects')
          .stream(primaryKey: ['id'])
          .eq('customer_id', customerId)) {
    // Re-fetch with full joins on each update
    final updated = await supabase
        .from('projects')
        .select('''
          id, title, description, status, project_type,
          budget_min, budget_max, progress_percentage,
          bids_count, created_at, deadline,
          location_lat, location_lng,
          cities!fk_projects_city(name_ar),
          project_categories!fk_projects_category(name_ar)
        ''')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    yield List<Map<String, dynamic>>.from(updated);
  }
});

// ────────────────────────────────────────────────
// Featured Products
// ────────────────────────────────────────────────
final featuredProductsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final supabase = ref.read(supabaseProvider);

  final response = await supabase
      .from('products')
      .select('*, product_images(image_url)')
      .eq('is_active', true)
      .order(
        'created_at',
        ascending: false,
      ) // Or any other criteria for "featured"
      .limit(5);

  return List<Map<String, dynamic>>.from(response);
});

// ────────────────────────────────────────────────
// Recommended Contractors
// ────────────────────────────────────────────────
final recommendedContractorsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final supabase = ref.read(supabaseProvider);
    final user = ref.read(currentUserProvider);

    if (user == null) return [];

    // جلب بيانات المدينة مباشرة دون الاعتماد على بروفايدر آخر لتجنب مسارات معلقة (Deadlocks)
    final profileData = await supabase
        .from('customers')
        .select('city_id')
        .eq('user_id', user.id)
        .maybeSingle();
    final cityId = profileData?['city_id'];

    var query = supabase
        .from('contractors')
        .select('*, cities!contractors_city_id_fkey(name_ar)');

    if (cityId != null) {
      query = query.eq('city_id', cityId);
    }

    // تأكد من فرز المقاولين إذا كان لديك حقل تقييم في الداتا بيس، وإذا لم يكن موجوداً أزله.
    // لتجنب أي أخطاء في قاعدة البيانات، نزيل الفرز مؤقتاً
    final response = await query.limit(3);
    final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
      response,
    );

    // Fallback manual join: if the database doesn't have a formal Foreign Key for 'cities',
    // the 'cities(name_ar)' join might fail silently and return null.
    try {
      final cities = await supabase.from('cities').select('id, name_ar');
      for (var c in list) {
        if (c['cities'] == null && c['city_id'] != null) {
          final match = cities.cast<Map<String, dynamic>>().firstWhere(
            (x) => x['id'].toString() == c['city_id'].toString(),
            orElse: () => <String, dynamic>{},
          );
          if (match.isNotEmpty) {
            c['cities'] = {'name_ar': match['name_ar']};
          }
        }
      }
    } catch (_) {}

    return list;
  } catch (e) {
    // إرجاع مصفوفة فارغة مؤقتاً إذا فشل الجلب (مثلاً الحقل غير موجود)
    debugPrint("Error in recommendedContractors: $e");
    return [];
  }
});

// Lookups (Cities, Categories) moved to master_data_providers.dart

// ────────────────────────────────────────────────
// Browse Contractors (With Filters)
// ────────────────────────────────────────────────
final browseContractorsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, encodedFilters) async {
      final supabase = ref.watch(supabaseProvider);

      final parts = encodedFilters.split('||');
      final searchQuery = parts[0];
      final cityId = parts[1] == 'null' ? null : parts[1];

      var query = supabase
          .from('contractors')
          .select('*, cities!contractors_city_id_fkey(name_ar)');

      if (searchQuery.isNotEmpty) {
        query = query.like('user_name', '%$searchQuery%');
      }

      if (cityId != null && cityId.isNotEmpty) {
        query = query.eq('city_id', cityId);
      }

      try {
        final response = await query.order('created_at', ascending: false);
        final List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(
          response,
        );

        try {
          final citiesResponse = await supabase
              .from('cities')
              .select('id, name_ar');
          final List<Map<String, dynamic>> citiesList =
              List<Map<String, dynamic>>.from(citiesResponse);

          for (var c in list) {
            if (c['cities'] == null && c['city_id'] != null) {
              // البحث في مصفوفة المدن باستخدام for loop بسيط وسريع جداً لتفادي أي تعطل
              for (var city in citiesList) {
                if (city['id'].toString() == c['city_id'].toString()) {
                  c['cities'] = {'name_ar': city['name_ar']};
                  break;
                }
              }
            }
          }
        } catch (_) {}

        return list;
      } catch (e, stacktrace) {
        debugPrint("Error in browseContractors: $e\n$stacktrace");
        return [
          {
            'id': 'error-id',
            'user_name': 'خطأ مع السيرفر: $e',
            'avg_rating': 0,
            'reviews_count': 0,
            'city_id': 'error',
          },
        ];
      }
    });

