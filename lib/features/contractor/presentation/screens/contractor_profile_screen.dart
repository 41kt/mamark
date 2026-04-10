import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/supabase_provider.dart';

final contractorProfileProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, contractorId) async {
  final supabase = ref.read(supabaseProvider);
  
  // 1. Fetch Basic Profile
  final profileRes = await supabase
      .from('contractors')
      .select('*, cities!contractors_city_id_fkey(name_ar)')
      .eq('id', contractorId)
      .single();
  
  final userId = profileRes['user_id'];

  // 2. Fetch Average Rating
  final ratingsRes = await supabase
      .from('ratings')
      .select('rating')
      .eq('rated_id', userId)
      .eq('type', 'contractor');
  
  double avgRating = 0;
  if (ratingsRes.isNotEmpty) {
    double total = 0;
    for (var r in ratingsRes) {
      total += (r['rating'] as num).toDouble();
    }
    avgRating = total / ratingsRes.length;
  }

  // 3. Fetch Completed Projects Count
  final projectsRes = await supabase
      .from('projects')
      .select('id')
      .eq('assigned_contractor_id', contractorId)
      .eq('status', 'completed');
  
  final completedCount = (projectsRes as List).length;

  // 4. Fetch Recent Reviews Safely (Split query to avoid Join issues if schema doesn't support it)
  final rawReviews = await supabase
      .from('ratings')
      .select('*')
      .eq('rated_id', userId)
      .eq('type', 'contractor')
      .order('created_at', ascending: false)
      .limit(5);

  List<Map<String, dynamic>> reviewsWithProfiles = [];
  
  for (var review in rawReviews) {
    Map<String, dynamic> reviewData = Map<String, dynamic>.from(review);
    try {
      // Fetch rater profile info separately
      final raterId = review['rater_id'];
      if (raterId != null) {
        final profile = await supabase
            .from('profiles')
            .select('display_name, avatar_url')
            .eq('user_id', raterId) // Using user_id mapping
            .maybeSingle();
        
        reviewData['profiles'] = profile;
      }
    } catch (_) {
      reviewData['profiles'] = null;
    }
    reviewsWithProfiles.add(reviewData);
  }

  // 5. Fetch Portfolio
  final portfolioRes = await supabase
      .from('contractor_portfolio')
      .select('*')
      .eq('contractor_id', contractorId)
      .order('created_at', ascending: false)
      .limit(6);

  return {
    'profile': profileRes,
    'avgRating': avgRating,
    'completedCount': completedCount,
    'reviews': reviewsWithProfiles,
    'portfolio': List<Map<String, dynamic>>.from(portfolioRes),
  };
});

class ContractorProfileScreen extends ConsumerStatefulWidget {
  final String contractorId;
  const ContractorProfileScreen({super.key, required this.contractorId});

  @override
  ConsumerState<ContractorProfileScreen> createState() => _ContractorProfileScreenState();
}

class _ContractorProfileScreenState extends ConsumerState<ContractorProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(contractorProfileProvider(widget.contractorId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, __) => Scaffold(
          appBar: AppBar(title: Text("خطأ", style: GoogleFonts.cairo())),
          body: Center(child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text("حدث خطأ أثناء تحميل البيانات: $e", style: GoogleFonts.cairo(), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(contractorProfileProvider(widget.contractorId)),
                  child: Text("إعادة المحاولة", style: GoogleFonts.cairo()),
                ),
              ],
            ),
          )),
        ),
        data: (data) {
          final profile = data['profile'] as Map<String, dynamic>;
          final avgRating = data['avgRating'] as double;
          final completedCount = data['completedCount'] as int;
          final reviews = data['reviews'] as List<Map<String, dynamic>>;

          final portfolio = data['portfolio'] as List<Map<String, dynamic>>;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(profile['user_name'] ?? "المقاول"),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildProfileHeader(profile),
                    _buildStatsGrid(avgRating, completedCount),
                    _buildSpecialties(profile['specialty']),
                    _buildBio(profile['bio']),
                    _buildPortfolioPreview(portfolio),
                    _buildReviewsPreview(reviews),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: profileAsync.hasValue ? _buildBottomActionBar(profileAsync.value!['profile']) : null,
    );
  }

  Widget _buildSliverAppBar(String name) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(name, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, Color(0xFF1E3A59)],
            ),
          ),
          child: const Center(child: Icon(Icons.person, size: 60, color: Colors.white24)),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> profile) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(profile['user_name'] ?? "بدون اسم", style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              if (profile['is_verified'] == true)
                const Icon(Icons.verified, color: Colors.blue, size: 20),
            ],
          ),
          Text(profile['title'] ?? profile['specialty'] ?? "مقاول عام", style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(double rating, int completed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("مشاريع مكتملة", completed.toString()),
          _buildStatItem("سنوات الخبرة", "+10"), 
          _buildStatItem("التقييم الكلي", rating == 0 ? "جديد" : rating.toStringAsFixed(1)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(label, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSpecialties(dynamic specialtiesData) {
    List<String> specialties = [];
    if (specialtiesData is List) {
       specialties = specialtiesData.map((e) => e.toString()).toList();
    } else if (specialtiesData is String) {
       specialties = specialtiesData.split(',');
    }

    if (specialties.isEmpty) specialties = ["بناء عام"];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("التخصصات", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: specialties.map((s) => Chip(
              label: Text(s.trim(), style: GoogleFonts.cairo(fontSize: 12)),
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade200),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBio(String? bio) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("عن المقاول", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            bio ?? "خبرة واسعة في تنفيذ المشاريع السكنية والتجارية. نلتزم بأعلى معايير الجودة والجداول الزمنية المحدد",
            style: GoogleFonts.cairo(color: Colors.grey.shade800, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioPreview(List<Map<String, dynamic>> portfolio) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("معرض الأعمال", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              if (portfolio.isNotEmpty)
                TextButton(
                  onPressed: () {}, // Get.toNamed('/contractor-portfolio/${widget.contractorId}'),
                  child: Text("عرض الكل", style: GoogleFonts.cairo(color: AppColors.primary)),
                ),
            ],
          ),
          if (portfolio.isEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: Text("لا توجد أعمال لعرضها حالياً", style: GoogleFonts.cairo(color: Colors.grey, fontSize: 13)),
            ),
          ] else ...[
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: portfolio.length,
                itemBuilder: (context, index) {
                  final item = portfolio[index];
                  final images = item['images'] as List?;
                  final coverUrl = (images != null && images.isNotEmpty) ? images[0] : null;

                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100, 
                      borderRadius: BorderRadius.circular(12),
                      image: coverUrl != null ? DecorationImage(image: NetworkImage(coverUrl), fit: BoxFit.cover) : null,
                    ),
                    child: coverUrl == null ? const Center(child: Icon(Icons.photo_library, color: Colors.grey)) : null,
                  );
                },
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildReviewsPreview(List<Map<String, dynamic>> reviews) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("آراء العملاء (${reviews.length})", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (reviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Text("لا تتوفر تقييمات حالياً.", style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
            )
          else
            ...reviews.map((r) => _buildReviewCard(r)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final comment = review['comment'] ?? "بدون تعليق";
    final rating = (review['rating'] as num).toInt();
    final rater = review['profiles'] as Map<String, dynamic>?;
    final raterName = rater?['display_name'] ?? "عميل معمارك";
    final avatarUrl = rater?['avatar_url'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person, size: 18, color: AppColors.primary) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(raterName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
                    Row(
                      children: List.generate(5, (index) => Icon(
                        Icons.star, 
                        size: 14, 
                        color: index < rating ? Colors.amber : Colors.grey.shade200
                      )),
                    ),
                  ],
                ),
              ),
              if (review['created_at'] != null)
                Text(
                  review['created_at'].toString().split('T')[0],
                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(comment, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade800, height: 1.6)),
        ],
      ),
    );
  }

  bool _isChatting = false;

  Widget _buildBottomActionBar(Map<String, dynamic> profile) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))]
        ),
        child: ElevatedButton.icon(
          onPressed: _isChatting ? null : () => _startChat(profile['user_name'], profile['user_id']), 
          icon: _isChatting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.chat_outlined),
          label: Text("تواصل مع المقاول الآن", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, 
            foregroundColor: Colors.white, 
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Future<void> _startChat(String? contractorName, String? contractorUserId) async {
    if (contractorUserId == null) return;
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("يرجى تسجيل الدخول أولاً", style: GoogleFonts.cairo()),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (currentUser.id == contractorUserId) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("لا يمكنك مراسلة نفسك", style: GoogleFonts.cairo()),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isChatting = true);
    try {
      final supabase = ref.read(supabaseProvider);
      final currentId = currentUser.id;

      // أبحث عن محادثة سابقة بينهما
      var chatResList = await supabase.from('chats')
          .select('id')
          .or('and(user1_id.eq.$currentId,user2_id.eq.$contractorUserId),and(user1_id.eq.$contractorUserId,user2_id.eq.$currentId)')
          .limit(1);

      String chatId;
      if (chatResList.isNotEmpty) {
          chatId = chatResList.first['id'].toString();
      } else {
          // أنشئ محادثة جديدة
          final newChatRes = await supabase.from('chats').insert({
              'chat_type': 'direct',
              'user1_id': currentId,
              'user2_id': contractorUserId,
              'updated_at': DateTime.now().toIso8601String(),
          }).select('id').single();
          chatId = newChatRes['id'].toString();
      }

      if (!mounted) return;
      Get.toNamed('/chat-details/$chatId', arguments: {'user_name': contractorName ?? 'مقاول'});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("حدث خطأ في إنشاء المحادثة: $e", style: GoogleFonts.cairo()),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => _isChatting = false);
    }
  }
}

