import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';

// ────────────────────────────────────────────────
// Contractor Profile (auto-creates on first load)
// ────────────────────────────────────────────────
final contractorProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = ref.read(supabaseProvider);
  final user = ref.read(currentUserProvider);
  if (user == null) return null;

  var response = await supabase
      .from('contractors')
      .select('*, cities!contractors_city_id_fkey(name_ar)')
      .eq('user_id', user.id)
      .maybeSingle();

  if (response == null) {
    try {
      final name = user.userMetadata?['full_name'] ??
                   user.userMetadata?['name'] ?? 'مقاول جديد';
      final email = user.email ?? '';
      response = await supabase.from('contractors').insert({
        'user_id': user.id,
        'user_name': name,
        'email': email,
        'is_verified': false,
        'verification_status': 'not_submitted',
      }).select('*, cities!contractors_city_id_fkey(name_ar)').maybeSingle();
    } catch (_) {
      // Ignored — may fail if RLS prevents it
    }
  }

  return response;
});

// ────────────────────────────────────────────────
// Edit / Save Contractor Profile
// ────────────────────────────────────────────────
final contractorProfileSaverProvider = Provider((ref) {
  return _ContractorProfileSaver(ref);
});

class _ContractorProfileSaver {
  final Ref ref;
  _ContractorProfileSaver(this.ref);

  Future<void> save(Map<String, dynamic> data) async {
    final supabase = ref.read(supabaseProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await supabase
        .from('contractors')
        .update(data)
        .eq('user_id', user.id);
    ref.invalidate(contractorProfileProvider);
  }
}

// ────────────────────────────────────────────────
// Open projects in contractor's city (for dashboard)
// ────────────────────────────────────────────────
final openProjectsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.read(supabaseProvider);
  final profile = await ref.read(contractorProfileProvider.future);

  var query = supabase
      .from('projects')
      .select('*, users!projects_owner_id_fkey(name, username), cities!fk_projects_city(name_ar), project_categories!fk_projects_category(name_ar)')
      .eq('status', 'open')
      .order('created_at', ascending: false)
      .limit(20);

  if (profile != null && profile['city_id'] != null) {
    query = supabase
        .from('projects')
        .select('*, users!projects_owner_id_fkey(name, username), cities!fk_projects_city(name_ar), project_categories!fk_projects_category(name_ar)')
        .eq('status', 'open')
        .eq('city_id', profile['city_id'])
        .order('created_at', ascending: false)
        .limit(20);
  }

  final response = await query;
  return List<Map<String, dynamic>>.from(response);
});

// ────────────────────────────────────────────────
// All open projects (browse tab — no location filter)
// ────────────────────────────────────────────────
final allOpenProjectsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final response = await supabase
      .from('projects')
      .select('*, users!projects_owner_id_fkey(name, username), cities!fk_projects_city(name_ar), project_categories!fk_projects_category(name_ar)')
      .eq('status', 'open')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

// ────────────────────────────────────────────────
// Dynamic Filtered Projects
// ────────────────────────────────────────────────
final filteredProjectsProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, filters) async {
  final supabase = ref.watch(supabaseProvider);

  var query = supabase
      .from('projects')
      .select('*, users!projects_owner_id_fkey(name, username), cities!fk_projects_city(name_ar), project_categories!fk_projects_category(name_ar)')
      .eq('status', 'open');

  if (filters['searchQuery'] != null && (filters['searchQuery'] as String).isNotEmpty) {
    query = query.ilike('title', '%${filters['searchQuery']}%');
  }
  if (filters['selectedCities'] != null && (filters['selectedCities'] as List).isNotEmpty) {
    query = query.inFilter('city_id', filters['selectedCities']);
  }
  if (filters['selectedCategories'] != null && (filters['selectedCategories'] as List).isNotEmpty) {
    query = query.inFilter('category_id', filters['selectedCategories']);
  }
  if (filters['minBudget'] != null) {
    query = query.gte('budget_max', filters['minBudget']);
  }
  if (filters['maxBudget'] != null) {
    query = query.lte('budget_min', filters['maxBudget']);
  }

  final response = await query.order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

// ────────────────────────────────────────────────
// Project Details
// ────────────────────────────────────────────────
final projectDetailsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, id) async {
  final supabase = ref.watch(supabaseProvider);
  final response = await supabase
      .from('projects')
      .select('*, users!projects_owner_id_fkey(name, username), cities!fk_projects_city(name_ar), project_categories!fk_projects_category(name_ar)')
      .eq('id', id)
      .maybeSingle();
  return response;
});

// ────────────────────────────────────────────────
// My Bids (logged-in contractor)
// ────────────────────────────────────────────────
final contractorBidsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.read(supabaseProvider);
  final user = ref.read(currentUserProvider);
  if (user == null) return [];

  final contractor = await supabase
      .from('contractors')
      .select('id')
      .eq('user_id', user.id)
      .maybeSingle();

  if (contractor == null) return [];

  final response = await supabase
      .from('bids')
      .select('*, projects(id, title, status, assigned_contractor_id, cities!fk_projects_city(name_ar))')
      .eq('contractor_id', contractor['id'])
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});

// ────────────────────────────────────────────────
// Bids for a specific project (customer view)
// ────────────────────────────────────────────────
final projectBidsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, projectId) async {
  final supabase = ref.watch(supabaseProvider);
  final response = await supabase
      .from('bids')
      .select('*, contractors(user_name, avg_rating, is_verified, profile_image_url)')
      .eq('project_id', projectId)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

final bidDetailsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, bidId) async {
  final supabase = ref.watch(supabaseProvider);
  final response = await supabase
      .from('bids')
      .select('*, contractors(*, cities!contractors_city_id_fkey(name_ar)), projects(title, status)')
      .eq('id', bidId)
      .maybeSingle();
  return response;
});

// ────────────────────────────────────────────────
// Contractor Stats
// ────────────────────────────────────────────────
final contractorStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final supabase = ref.read(supabaseProvider);
  final user = ref.read(currentUserProvider);

  if (user == null) {
    return {'pending': 0, 'active': 0, 'accepted': 0, 'rating': '0.0'};
  }

  final contractor = await supabase
      .from('contractors')
      .select('id, avg_rating')
      .eq('user_id', user.id)
      .maybeSingle();

  if (contractor == null) {
    return {'pending': 0, 'active': 0, 'accepted': 0, 'rating': '0.0'};
  }

  final contractorId = contractor['id'] as String;

  final results = await Future.wait([
    supabase.from('bids').select('id').eq('contractor_id', contractorId).eq('status', 'pending'),
    supabase.from('bids').select('id').eq('contractor_id', contractorId).eq('status', 'accepted'),
    supabase.from('projects').select('id').eq('assigned_contractor_id', contractorId).eq('status', 'in_progress'),
  ]);

  final rating = contractor['avg_rating'];
  final ratingStr = rating != null ? (rating as num).toStringAsFixed(1) : '0.0';

  return {
    'pending': results[0].length,
    'active': results[2].length,
    'accepted': results[1].length,
    'rating': ratingStr,
  };
});

// ────────────────────────────────────────────────
// Profile completion %
// ────────────────────────────────────────────────
final profileCompletionProvider = FutureProvider<int>((ref) async {
  final profile = await ref.read(contractorProfileProvider.future);
  if (profile == null) return 0;

  final fields = [
    profile['user_name'],
    profile['phone_number'],
    profile['city_id'],
    profile['specialty'],
    profile['bio'],
    profile['profile_image_url'],
    profile['years_experience'],
    profile['cr_number'],
  ];
  final filled = fields.where((f) => f != null && f.toString().isNotEmpty).length;
  return ((filled / fields.length) * 100).round();
});

// ────────────────────────────────────────────────
// Portfolio
// ────────────────────────────────────────────────
final contractorPortfolioProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final contractor = await supabase
      .from('contractors')
      .select('id')
      .eq('user_id', user.id)
      .maybeSingle();

  if (contractor == null) return [];

  final response = await supabase
      .from('contractor_portfolio')
      .select('*')
      .eq('contractor_id', contractor['id'])
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(response);
});
