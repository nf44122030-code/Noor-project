import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class AreaProfile {
  final String city;
  final String area;
  final double costMultiplier;
  final double trafficMultiplier;
  final int competitivenessBase;
  final String areaInsight;

  const AreaProfile(this.city, this.area, this.costMultiplier, this.trafficMultiplier, this.competitivenessBase, this.areaInsight);
}

class CategoryProfile {
  final String industry;
  final String category;
  final int baseStartupCost;
  final int baseOperationalCost;
  final int baseSuccessProb;
  final Map<String, int> roles;
  final Map<String, int> demographics;
  final String geoRecTemplate;

  const CategoryProfile(
      this.industry,
      this.category,
      this.baseStartupCost,
      this.baseOperationalCost,
      this.baseSuccessProb,
      this.roles,
      this.demographics,
      this.geoRecTemplate);
}

class MarketDataSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<AreaProfile> areas = [
    // Erbil
    AreaProfile('Erbil', 'Bakhtiari', 1.5, 1.2, 80, 'Bakhtiari attracts a highly affluent executive crowd.'),
    AreaProfile('Erbil', 'Empire World', 2.5, 1.0, 70, 'Empire World is a premium corporate hub with steep lease rates.'),
    AreaProfile('Erbil', 'Ankawa', 1.2, 1.8, 90, 'Ankawa boasts a massive late-night and expatriate footfall.'),
    AreaProfile('Erbil', 'Iskan', 0.8, 2.5, 95, 'Iskan offers unparalleled dense foot traffic but cutthroat competition.'),
    AreaProfile('Erbil', 'Dream City', 3.0, 0.8, 60, 'Dream City commands elite exclusivity but has limited general walkthrough traffic.'),
    // Baghdad
    AreaProfile('Baghdad', 'Mansour', 1.8, 2.0, 92, 'Mansour is Baghdad\'s premier commercial and shopping district.'),
    AreaProfile('Baghdad', 'Karrada', 1.5, 2.5, 95, 'Karrada provides immense consumer density and historical market loyalty.'),
    AreaProfile('Baghdad', 'Zayouna', 1.4, 1.8, 80, 'Zayouna is a rapidly expanding hub for family-oriented commerce.'),
    AreaProfile('Baghdad', 'Jadriya', 3.5, 0.7, 50, 'Jadriya caters to high-net-worth individuals and diplomatic entities.'),
    AreaProfile('Baghdad', 'Adhamiya', 1.0, 1.5, 75, 'Adhamiya benefits from strong community-based local commerce.'),
  ];

  static const List<CategoryProfile> categories = [
    CategoryProfile(
        'Food & Beverage',
        'High-End Cafes',
        75000000,
        15000000,
        75,
        {'Branch Manager': 1500000, 'Head Barista': 1000000, 'Service Staff': 600000},
        {'18-24': 20, '25-34': 50, '35-44': 20, '45+': 10},
        'A high-end cafe in [AREA] requires heavy aesthetic investment. Success highly depends on the local executive presence.'),
    CategoryProfile(
        'Real Estate',
        'Commercial Offices',
        250000000,
        2500000,
        82,
        {'Property Manager': 2000000, 'Sales Agent': 800000, 'Admin': 600000},
        {'Corporate': 60, 'Startups': 30, 'NGOs': 10},
        '[AREA] has specific real estate dynamics. Serviced virtual offices cater to commercial entities over foot traffic.'),
    CategoryProfile(
        'Food & Beverage',
        'Dine-in Restaurants & Entertainment',
        120000000,
        22000000,
        68,
        {'Restaurant Manager': 1800000, 'Executive Chef': 2000000, 'Waitstaff': 500000},
        {'Families': 50, 'Couples': 30, 'Tourists': 20},
        'Dine-in restaurants in [AREA] face stiff competition. Ambiance, live entertainment, and exceptional service are vital.'),
    CategoryProfile(
        'Food & Beverage',
        'Street Food / Quick Service',
        15000000,
        4000000,
        85,
        {'Shift Lead': 750000, 'Cook': 800000, 'Cashier': 500000},
        {'Youth': 45, 'Students': 35, 'Late-night': 20},
        'Street food and QSRs in [AREA] rely entirely on volume. Ensure pricing aligns exactly with passing traffic demographics.'),
    CategoryProfile(
        'Health & Beauty',
        'Luxury Clinics / Spas',
        150000000,
        12000000,
        80,
        {'Clinic Manager': 1500000, 'Specialist': 3500000, 'Receptionist': 600000},
        {'Elite Residents': 60, 'VIPs': 40},
        'Luxury clinics in [AREA] demand ultimate privacy and premium global brands to attract high-net-worth clients.'),
    CategoryProfile(
        'Retail',
        'Fashion & Boutiques',
        90000000,
        18000000,
        70,
        {'Store Manager': 1200000, 'Sales Associate': 650000, 'Marketing': 800000},
        {'Upper-Middle Class': 50, 'Youth': 50},
        'High-visibility storefronts in [AREA] are critical. Aggressive social media marketing pairs well with this retail sector.'),
    CategoryProfile(
        'Tech & Electronics',
        'Consumer Electronics Retail',
        180000000,
        8000000,
        78,
        {'Tech Sales': 850000, 'Repair Tech': 1000000, 'Inventory': 700000},
        {'General Public': 70, 'Tech Enthusiasts': 30},
        'Tech retail in [AREA] operates on low margins but high volume. Official distributorships provide a massive edge.'),
    CategoryProfile(
        'Entertainment',
        'Family Recreation & Malls',
        350000000,
        45000000,
        82,
        {'Operations Director': 2500000, 'Facility Staff': 550000, 'Event Manager': 1000000},
        {'Families': 60, 'Teenagers': 40},
        'Family recreation centers in [AREA] guarantee steady weekend traffic. Integrating edutainment yields reliable returns.'),
    CategoryProfile(
        'Real Estate',
        'Luxury Residential & Office',
        500000000,
        5000000,
        88,
        {'Broker': 1500000, 'Attorney': 2000000, 'Admin': 700000},
        {'Diplomats': 40, 'Foreign Embassies': 30, 'Elite Class': 30},
        '[AREA] demands hyper-premium development. Security, privacy, and smart home integrations justify the massive capital required.'),
    CategoryProfile(
        'Healthcare',
        'Specialized Medical Clinics',
        120000000,
        10000000,
        90,
        {'Specialist Doctor': 4000000, 'Nurse': 1000000, 'Admin': 600000},
        {'Elderly': 40, 'Families': 40, 'Local Residents': 20},
        'Specialized care in [AREA] thrives on community trust. Establishing relationships with reputable physicians is key.'),
  ];

  static List<Map<String, dynamic>> generateInsights() {
    List<Map<String, dynamic>> generated = [];
    final random = Random(42); // Seed for consistency across generations

    for (var area in areas) {
      for (var category in categories) {
        // Calculate realistic metrics dynamically based on area multipliers
        double startupCost = category.baseStartupCost * area.costMultiplier;
        double opCost = category.baseOperationalCost * area.costMultiplier;
        
        // Success is influenced positively by traffic and negatively by prohibitive costs
        int successRaw = (category.baseSuccessProb * area.trafficMultiplier / (area.costMultiplier * 0.8)).round();
        int finalSuccess = min(98, max(30, successRaw)); // clamp between 30 and 98

        // Competition is inherently based on the area's base competitiveness with slight randomization
        int compRaw = (area.competitivenessBase * (random.nextDouble() * 0.2 + 0.9)).round();
        int finalComp = min(100, max(20, compRaw));

        String riskLevel = finalSuccess > 80 ? 'Low' : (finalSuccess > 60 ? 'Medium' : 'High');
        if (startupCost > 200000000 && finalSuccess < 70) riskLevel = 'Very High';

        // Revenue scaling logic based on OP costs and traffic multipliers
        double baseRev = opCost * 1.5 * area.trafficMultiplier;
        Map<String, int> revenueProjections = {
           'Year 1': (baseRev * 12).round(),
           'Year 2': (baseRev * 14).round(),
           'Year 3': (baseRev * 18).round(),
        };

        // Synthesize the final data payload
        generated.add({
          'city': area.city,
          'area': area.area,
          'industry': category.industry,
          'category': category.category,
          'competition_level': finalComp,
          'success_probability': finalSuccess,
          'risk_level': riskLevel,
          'financials': {
            'currency': 'IQD',
            'avg_startup_cost': startupCost.round(),
            'avg_monthly_operational_cost': opCost.round(),
            'profitability_margin': '${(finalSuccess / 3).round()}-${(finalSuccess / 2.5).round()}%',
            'revenue_projections': revenueProjections,
          },
          'operations': {
            'recommended_employees_count': category.roles.length + random.nextInt(5) + 1,
            'roles': category.roles.map((k, v) => MapEntry(k, (v * area.costMultiplier * 0.8).round())),
          },
          'audience': {
            'target_demographics': category.demographics.keys.toList(),
            'market_size_est': area.trafficMultiplier > 1.5 ? 'Very High' : 'Moderate',
            'age_breakdown': category.demographics,
          },
          'growth_opportunities': ['Digital Expansion', 'Loyalty Programs', 'B2B Partnerships'],
          'trends': [
            {'year': 2023, 'demand_index': min(100, max(10, finalSuccess - 15 + random.nextInt(10)))},
            {'year': 2024, 'demand_index': min(100, max(10, finalSuccess - 5 + random.nextInt(10)))},
            {'year': 2025, 'demand_index': min(100, max(10, finalSuccess + random.nextInt(10)))},
          ],
          'geo_recommendation': '${area.areaInsight} ${category.geoRecTemplate.replaceAll('[AREA]', area.area)}',
        });
      }
    }
    return generated;
  }

  static Future<void> seedIraqiMarketData() async {
    debugPrint('🌱 Sowing Dynamic Iraq Geo-Marketing Combinations...');

    try {
      final rawInsights = generateInsights();

      // Wipe previous instances
      final snapshot = await _firestore.collection('iraq_market_insights').get();
      for (DocumentSnapshot doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // Seed all new permutations
      for (var insight in rawInsights) {
        final docId = '${insight['city']}_${insight['area']}_${insight['industry']}_${insight['category']}'
           .toLowerCase().replaceAll(' & ', '_').replaceAll(' / ', '_').replaceAll(' ', '_');
        await _firestore.collection('iraq_market_insights').doc(docId).set(insight);
      }

      debugPrint('✅ Iraq Geo-Marketing Data seeded successfully! (${rawInsights.length} records)');
    } catch (e) {
      debugPrint('❌ Failed to seed Iraq Geo-Marketing Data globally due to permissions: $e');
    }
  }
}
