import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';

class Article {
  final String id;
  final String title;
  final String summary; // Added for search and details
  final String category;
  final String readTime;
  final String views;
  final bool isFeatured;
  final String imageUrl;

  Article({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.readTime,
    required this.views,
    required this.imageUrl,
    this.isFeatured = false,
  });

  factory Article.fromMap(Map<String, dynamic> map) {
    final cat = (map['category'] ?? '').toString();
    final title = (map['title'] ?? '').toString();
    
    // Determine category search tags for relevant dynamic images
    final catLower = cat.toLowerCase();
    String tags = 'business,office';
    if (catLower.contains('finance') || catLower.contains('money') || catLower.contains('market')) {
      tags = 'finance,stockmarket';
    } else if (catLower.contains('tech')) {
      tags = 'technology,software';
    } else if (catLower.contains('ai') || catLower.contains('robot') || catLower.contains('artificial')) {
      tags = 'artificialintelligence,robotics';
    } else if (catLower.contains('strategy') || catLower.contains('plan') || catLower.contains('leader')) {
      tags = 'strategy,management';
    } else if (catLower.contains('marketing') || catLower.contains('brand')) {
      tags = 'marketing,branding';
    }
    
    // Use title hash to lock the image to the article deterministically (so it doesn't change on rebuild)
    final titleHash = title.codeUnits.fold<int>(0, (sum, c) => sum + c);
    final lockId = (titleHash % 1000) + 1; // 1 to 1000
    
    // LoremFlickr serves extremely high quality relevant photos based on tags and a lock ID
    final generatedUrl = 'https://loremflickr.com/800/600/$tags?lock=$lockId';

    return Article(
      id: (map['id'] ?? '').toString(),
      title: title,
      summary: map['summary'] ?? '',
      category: cat,
      readTime: map['read_time'] ?? '',
      views: map['views'] ?? '',
      isFeatured: map['is_featured'] ?? false,
      imageUrl: generatedUrl,
    );
  }
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final FirebaseService _firebaseService = FirebaseService();

  Article? _featuredArticle;
  List<Article> _recentArticles = [];
  List<Article> _filteredArticles = [];
  bool _isLoading = true;
  bool _isRefreshingAI = false;
  DateTime? _lastUpdated;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  final List<String> _categories = ['All', 'Finance', 'Tech', 'AI', 'Strategy', 'Marketing'];

  final themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }



  void _onSearchChanged() {
    _filterArticles();
  }

  void _filterArticles() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      
      // Combine all articles for filtering
      final List<Article> allArticles = [];
      if (_featuredArticle != null) allArticles.add(_featuredArticle!);
      allArticles.addAll(_recentArticles);

      _filteredArticles = allArticles.where((article) {
        final matchesSearch = article.title.toLowerCase().contains(_searchQuery) ||
                             article.category.toLowerCase().contains(_searchQuery) ||
                             article.summary.toLowerCase().contains(_searchQuery);
                             
        final matchesCategory = _selectedCategory == 'All' || 
                               article.category.toLowerCase().contains(_selectedCategory.toLowerCase());
                               
        return matchesSearch && matchesCategory;
      }).toList();
      
      // If we are filtering, we don't want the featured card to repeat
      if (_selectedCategory != 'All' || _searchQuery.isNotEmpty) {
        // No special action needed, _filteredArticles already contains everything
      } else {
        // If no filter, don't show the featured one in the "recent" list
        _filteredArticles = List.from(_recentArticles);
      }
    });
  }

  Future<void> _loadData({bool force = false}) async {
    setState(() {
      if (force) {
        _isRefreshingAI = true;
      } else {
        _isLoading = true;
      }
    });

    try {
      final articlesData = await _firebaseService.getDynamicArticles(forceRefresh: force);

      setState(() {
        if (articlesData['featured'] != null) {
          _featuredArticle = Article.fromMap(articlesData['featured']);
        }
        _recentArticles = (articlesData['recent'] as List).map((m) => Article.fromMap(m)).toList();
        _filteredArticles = List.from(_recentArticles);
        _lastUpdated = DateTime.now();
        _isLoading = false;
        _isRefreshingAI = false;
      });

      if (force) {
        Get.snackbar(
          'Intelligence Synchronized',
          'AI has synthesized brand-new business insights for you.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.primary.withValues(alpha: 0.9),
          colorText: Colors.white,
          borderRadius: 16,
          margin: const EdgeInsets.all(16),
          icon: const Icon(Icons.auto_awesome, color: Colors.white),
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint('Error loading explore data: $e');
      setState(() {
        _isLoading = false;
        _isRefreshingAI = false;
      });
      
      if (force) {
        Get.snackbar(
          'Synchronization Note',
          'Serving verified business insights from cache.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.withValues(alpha: 0.9),
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDarkMode = themeController.isDarkMode;

      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      return RefreshIndicator(
        onRefresh: () => _loadData(force: true),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(isDarkMode),
              const SizedBox(height: 16),

              _buildCategoryFilters(isDarkMode),
              const SizedBox(height: 16),
              
              // Live update indicator
              if (_searchQuery.isEmpty && _selectedCategory == 'All')
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      _isRefreshingAI 
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                          ),
                        )
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981), // Live Green
                            shape: BoxShape.circle,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _isRefreshingAI 
                          ? 'synthesizing'.tr 
                          : (_lastUpdated != null 
                              ? '${'live_content'.tr} · ${_lastUpdated!.hour.toString().padLeft(2, '0')}:${_lastUpdated!.minute.toString().padLeft(2, '0')}'
                              : 'live_content'.tr),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isRefreshingAI 
                            ? const Color(0xFF10B981)
                            : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_featuredArticle != null && _searchQuery.isEmpty && _selectedCategory == 'All') ...[
                _buildSectionTitleWithIcon('daily_insights'.tr, Icons.auto_awesome_rounded, const Color(0xFFF59E0B), isDarkMode),
                const SizedBox(height: 12),
                _buildFeaturedArticleCard(_featuredArticle!, isDarkMode),
                const SizedBox(height: 24),
              ],

              _buildSectionTitleWithIcon(
                (_searchQuery.isEmpty && _selectedCategory == 'All') ? 'trending_articles'.tr : 'discovered_insights'.tr, 
                (_searchQuery.isEmpty && _selectedCategory == 'All') ? Icons.trending_up_rounded : Icons.explore_rounded, 
                const Color(0xFF0EA5E9), 
                isDarkMode, 
                hasViewAll: _searchQuery.isEmpty && _selectedCategory == 'All'
              ),
              const SizedBox(height: 12),
              if (_filteredArticles.isEmpty && _searchQuery.isNotEmpty)
                _buildNoResults(isDarkMode)
              else
                ..._filteredArticles.map((article) => _buildRecentArticleCard(article, isDarkMode)),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCategoryFilters(bool isDarkMode) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                  _filterArticles();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AppColors.primary 
                    : (isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isSelected 
                      ? AppColors.primary 
                      : (isDarkMode ? AppColors.borderDark : AppColors.borderLight),
                  ),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                      ? Colors.white 
                      : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.borderLight,
          width: 1.5,
        ),
        boxShadow: isDarkMode ? [] : AppColors.cardShadow(),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _onSearchChanged(),
        style: GoogleFonts.inter(
          fontSize: 14,
          color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        decoration: InputDecoration(
          hintText: 'search_topics'.tr,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: isDarkMode ? AppColors.textHintDark : AppColors.textHintLight,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDarkMode ? AppColors.textDimDark : AppColors.textHintLight,
          ),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged();
                },
              ) 
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }


  Widget _buildSectionTitleWithIcon(String title, IconData icon, Color color, bool isDarkMode, {bool hasViewAll = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        if (hasViewAll)
          TextButton(
            onPressed: () {},
            child: Text(
              'view_all'.tr,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }


  Widget _buildFeaturedArticleCard(Article article, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _showArticleDetail(article, isDarkMode),
      child: Container(
        decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: isDarkMode ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: isDarkMode ? AppColors.glowShadow(intensity: 0.06) : AppColors.cardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
            child: Image.network(
              article.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: AppColors.surfaceDim,
                child: const Icon(Icons.image_not_supported_rounded, color: AppColors.borderDark, size: 48),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    article.category,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  article.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 13, color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    const SizedBox(width: 4),
                    Text(article.readTime, style: GoogleFonts.inter(fontSize: 12, color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    const SizedBox(width: 14),
                    Icon(Icons.visibility_rounded, size: 13, color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    const SizedBox(width: 4),
                    Text(article.views, style: GoogleFonts.inter(fontSize: 12, color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildRecentArticleCard(Article article, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _showArticleDetail(article, isDarkMode),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: isDarkMode ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: isDarkMode ? [] : AppColors.cardShadow(),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.network(
              article.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: AppColors.surfaceDim,
                child: const Icon(Icons.image_not_supported_rounded, color: AppColors.borderDark),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    article.category,
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  article.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${article.readTime} · ${article.views}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildNoResults(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48,
                color: isDarkMode ? AppColors.textDimDark : AppColors.textSecondaryLight),
            const SizedBox(height: 16),
            Text(
              'No articles found for "$_searchQuery"',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showArticleDetail(Article article, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        article.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        article.category,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      article.title,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textDimDark),
                        const SizedBox(width: 4),
                        Text(article.readTime, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDimDark)),
                        const SizedBox(width: 16),
                        const Icon(Icons.visibility_rounded, size: 14, color: AppColors.textDimDark),
                        const SizedBox(width: 4),
                        Text(article.views, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDimDark)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'insight_summary'.tr,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.summary,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.6,
                        color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text('back_to_insights'.tr),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
