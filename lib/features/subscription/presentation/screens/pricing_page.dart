import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../features/auth/presentation/providers/auth_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class PricingPlan {
  final String id; // Stripe Price ID
  final String productId; // Stripe Product ID
  final String name;
  final IconData icon;
  final int price;
  final String period;
  final String description;
  final List<String> features;
  final bool popular;
  final Color gradientFrom;
  final Color gradientTo;
  final bool isYearly;

  PricingPlan({
    required this.id,
    required this.productId,
    required this.name,
    required this.icon,
    required this.price,
    required this.period,
    required this.description,
    required this.features,
    this.popular = false,
    required this.gradientFrom,
    required this.gradientTo,
    required this.isYearly,
  });

  factory PricingPlan.fromMap(Map<String, dynamic> map) {
    Color parseColor(String? hex) {
      if (hex == null || hex.isEmpty) return const Color(0xFF0284C7);
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    }

    return PricingPlan(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      icon: _getIcon(map['icon_name']),
      price: (map['price'] ?? 0) as int,
      period: map['period'] ?? 'per month',
      description: map['description'] ?? '',
      features: List<String>.from(map['features'] ?? []),
      popular: (map['popular'] ?? false) as bool,
      gradientFrom: parseColor(map['gradientFrom'] as String?),
      gradientTo: parseColor(map['gradientTo'] as String?),
      isYearly: (map['isYearly'] ?? false) as bool,
    );
  }

  static IconData _getIcon(String? name) {
    switch (name) {
      case 'auto_awesome': return Icons.auto_awesome;
      case 'flash_on': return Icons.flash_on;
      case 'workspace_premium': return Icons.workspace_premium;
      default: return Icons.check_circle_outline;
    }
  }
}

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  final FirebaseService _firebaseService = FirebaseService();
  bool isYearly = true; // default to yearly for the discount view
  String? selectedProductId; // Changed from selectedPlanId
  List<PricingPlan> _plans = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  final themeController = Get.find<ThemeController>();
  final authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await _firebaseService.getPricingPlans();
      if (!mounted) return;
      setState(() {
        _plans = plans.map((m) => PricingPlan.fromMap(m)).toList();
        if (_plans.isNotEmpty && selectedProductId == null) {
          final premiumPlans = _plans.where((p) => p.price > 0).toList();
          if (premiumPlans.isNotEmpty) {
             final popular = premiumPlans.firstWhere((p) => p.popular, orElse: () => premiumPlans.last);
             selectedProductId = popular.productId;
          } else {
             selectedProductId = _plans.first.productId;
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading plans: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _purchasePlan(PricingPlan plan) async {
    setState(() => _isProcessing = true);
    try {
      final result = await _firebaseService.purchaseSubscription(
        plan.id,
        plan.name,
        isYearly,
      );

      if (result['success'] == true && result['checkoutUrl'] != null) {
        final url = Uri.parse(result['checkoutUrl']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not open payment portal.');
        }
      } else {
        throw Exception(result['error'] ?? 'Failed to initialize checkout.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to subscribe: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDarkMode = themeController.isDarkMode;

      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F172A), Color(0xFF020617)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                  ),
          ),
          child: Column(
            children: [
              _buildAppBar(isDarkMode),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _plans.isEmpty 
                      ? const Center(child: Text('No plans available at the moment'))
                      : Stack(
                          children: [
                            _buildContent(isDarkMode),
                            if (_isProcessing)
                              Container(
                                color: isDarkMode ? Colors.black54 : Colors.white54,
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                          ],
                        ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAppBar(bool isDarkMode) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: AppColors.gradientAppBar),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(color: Color(0x220EA5E9), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.only(top: 60, bottom: 24, left: 8, right: 24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                'PRICING',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDarkMode) {
    // Get unique products for the selection header
    final uniqueProductsMap = <String, PricingPlan>{};
    for (var plan in _plans) {
      if (!uniqueProductsMap.containsKey(plan.productId)) {
        uniqueProductsMap[plan.productId] = plan;
      }
    }
    final products = uniqueProductsMap.values.toList();
    products.sort((a, b) => a.price.compareTo(b.price));

    // Find current selection
    final selectedProduct = products.firstWhere(
      (p) => p.productId == selectedProductId, 
      orElse: () => products.isNotEmpty ? products.first : _plans.first
    );

    // Get the specific Price ID for the selected Product + isYearly toggle
    final currentPricePlan = _plans.firstWhere(
      (p) => p.productId == selectedProductId && p.isYearly == isYearly,
      orElse: () => _plans.firstWhere(
        (p) => p.productId == selectedProductId,
        orElse: () => selectedProduct
      )
    );
    
    // Extract unique features
    final uniqueFeatures = <String>{};
    for (final p in _plans) {
      uniqueFeatures.addAll(p.features);
    }
    final featureList = uniqueFeatures.take(7).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header special offer
          Center(
            child: Text(
              'SPECIAL OFFER',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Go ${selectedProduct.name != 'Starter' ? selectedProduct.name : 'Unlimited'}',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Supercharge your productivity from the get go!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Features Table Header
          Row(
            children: [
              Expanded(
                flex: 2, // Slightly smaller header to make room for 3 columns if needed
                child: Text(
                  'Comparison',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              ...products.map((p) => _buildColumnHeader(p, isDarkMode)),
            ],
          ),
          const SizedBox(height: 16),

          // Features Table Body
          ...featureList.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    f,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                ...products.map((p) => Expanded(
                  flex: 1,
                  child: Center(
                    child: p.features.contains(f)
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                        : Icon(
                            Icons.close_rounded,
                            color: Colors.red.withValues(alpha: 0.5),
                            size: 18,
                          ),
                  ),
                )),
              ],
            ),
          )),
          
          const SizedBox(height: 24),

          // Plan Cards (Glowy side-by-side versions)
          _buildPlanCardsSection(products, isDarkMode),

          const SizedBox(height: 32),

          // Footer Action buttons
          _buildActionButtons(currentPricePlan, isDarkMode),
          
          const SizedBox(height: 24),
          Text(
            'Recurring billing, cancel anytime. Save with Yearly plan compared to Monthly.\nTerms & Conditions & Privacy Policy apply.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
          )
        ],
      ),
    );
  }

  Widget _buildPlanCardsSection(List<PricingPlan> products, bool isDarkMode) {
    // Only show paid products in the bottom cards
    final paidProducts = products.where((p) => p.productId != 'starter_product' && p.price > 0).toList();
    
    if (paidProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Center(
          child: Text(
            'Select your plan',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (int i = 0; i < paidProducts.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              Expanded(
                child: _buildProductCard(paidProducts[i], isDarkMode),
              ),
            ]
          ],
        ),
      ],
    );
  }

  Widget _buildColumnHeader(PricingPlan plan, bool isDarkMode) {
    final isSelected = plan.productId == selectedProductId;
    return Expanded(
      flex: 1,
      child: GestureDetector(
        onTap: () => setState(() => selectedProductId = plan.productId),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected 
              ? (isDarkMode ? const Color(0xFF0EA5E9).withValues(alpha: 0.2) : const Color(0xFF0EA5E9).withValues(alpha: 0.15)) 
              : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                plan.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(PricingPlan plan, bool isDarkMode) {
    final isSelected = plan.productId == selectedProductId;
    
    // Check if this plan has a yearly version to calculate savings
    int savings = 0;
    final yearlyVersion = _plans.firstWhereOrNull((p) => p.productId == plan.productId && p.isYearly);
    final monthlyVersion = _plans.firstWhereOrNull((p) => p.productId == plan.productId && !p.isYearly);
    
    if (yearlyVersion != null && monthlyVersion != null && monthlyVersion.price > 0) {
      final monthlyTotal = monthlyVersion.price * 12;
      savings = ((monthlyTotal - yearlyVersion.price) / monthlyTotal * 100).round();
    }

    // Helper for the savings badge
    Widget buildSavingsBadge() {
      if (plan.isYearly) {
        final isPremium = plan.name.toLowerCase().contains('premium');
        if (isPremium) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF0EA5E9), borderRadius: BorderRadius.circular(12)),
            child: const Text('Save >15%', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          );
        } else if (savings > 0 && savings < 90) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF0EA5E9), borderRadius: BorderRadius.circular(12)),
            child: Text('Save $savings%', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
          );
        }
      }
      return const SizedBox(height: 20);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedProductId = plan.productId;
          // When picking a product, ensure isYearly matches the plan we just tapped
          isYearly = plan.isYearly;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
             ? (isDarkMode ? const Color(0xFF0C4A6E).withValues(alpha: 0.8) : Colors.white)
             : (isDarkMode ? const Color(0xFF1F2937).withValues(alpha: 0.5) : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
              ? const Color(0xFF0EA5E9) 
              : (isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ] : null,
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isSelected ? 1.0 : 0.6,
          child: Column(
            children: [
              buildSavingsBadge(),
              const SizedBox(height: 12),
              Text(
                plan.isYearly ? '1 year' : '1 month',
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)
                )
              ),
              const SizedBox(height: 8),
              Text(
                '\$${plan.price.toStringAsFixed(2)}', 
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: isDarkMode ? Colors.white : const Color(0xFF1F2937)
                )
              ),
              const SizedBox(height: 16),
              Text(
                plan.isYearly 
                  ? '\$${(plan.price / 12).toStringAsFixed(2)} /mon'
                  : '\$${plan.price.toStringAsFixed(2)} /mon',
                style: TextStyle(
                  fontSize: 12, 
                  color: isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0284C7), 
                  fontWeight: FontWeight.w500
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(PricingPlan selectedPlan, bool isDarkMode) {
    // Correctly check if this is the active plan (Free or Stripe)
    final bool isUserFree = authController.currentPlanId == 'free' || authController.currentPlanId.isEmpty;
    final bool isSelectionFree = selectedPlan.id == 'free' || selectedPlan.price == 0;
    
    final bool isActivePlan = isSelectionFree 
        ? isUserFree 
        : (authController.currentPlanId == selectedPlan.id && authController.isPremium);

    if (isActivePlan) {
      return SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: null,
          style: TextButton.styleFrom(
            backgroundColor: isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
          ),
          child: Text('Current Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white54 : Colors.black54)),
        ),
      );
    }

    if (selectedPlan.price == 0) {
      return SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () => _purchasePlan(selectedPlan),
          style: TextButton.styleFrom(
            backgroundColor: isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
          ),
          child: Text('Downgrade to ${selectedPlan.name} Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : const Color(0xFF1F2937))),
        ),
      );
    }

    int savings = 0;
    if (isYearly) {
      final monthlyPlan = _plans.firstWhereOrNull((p) => p.productId == selectedPlan.productId && !p.isYearly);
      if (monthlyPlan != null && monthlyPlan.price > 0) {
        final monthlyTotal = monthlyPlan.price * 12;
        savings = ((monthlyTotal - selectedPlan.price) / monthlyTotal * 100).round();
      }
    }

    // Determine the label for Premium vs other plans
    String? discountLabel;
    if (isYearly) {
      final isPremium = selectedPlan.name.toLowerCase().contains('premium');
      if (isPremium) {
        discountLabel = 'Save more than 15%';
      } else if (savings > 0 && savings < 90) {
        discountLabel = 'Save $savings%';
      }
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _purchasePlan(selectedPlan),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9), // Solid primary button
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Go ${selectedPlan.name} now', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (discountLabel != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                    child: Text(discountLabel, style: const TextStyle(fontSize: 10)),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (authController.currentPlanId != 'free')
          TextButton(
            onPressed: () {
              final freePlan = _plans.firstWhere((p) => p.price == 0, orElse: () => _plans.first);
              _purchasePlan(freePlan);
            },
            child: Text('Downgrade to Starter Plan', style: TextStyle(color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))),
          )
      ],
    );
  }
}
