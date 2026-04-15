import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MarketDataSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedIraqiMarketData() async {
    debugPrint('🌱 Seeding Iraq Geo-Marketing Data...');

    final insights = [
      // ==================================
      // ERBIL DATA
      // ==================================
      {
        'city': 'Erbil',
        'area': 'Bakhtiari',
        'industry': 'Food & Beverage',
        'category': 'High-End Cafes',
        'competition_level': 90,
        'success_probability': 75,
        'risk_level': 'Medium-High',
        'financials': {
          'currency': 'IQD',
          'avg_startup_cost': 75000000,
          'avg_monthly_operational_cost': 15000000,
          'profitability_margin': '18-22%',
        },
        'operations': {
          'recommended_employees_count': 8,
          'roles': {
            'Branch Manager': 1500000,
            'Head Barista': 1000000,
            'Service Staff': 600000,
          }
        },
        'audience': {
          'target_demographics': ['High-Income Professionals', 'Business Executives'],
          'market_size_est': 'High',
        },
        'growth_opportunities': ['Corporate Catering', 'Specialty Coffee Retail'],
        'trends': [
          {'year': 2023, 'demand_index': 75},
          {'year': 2024, 'demand_index': 85},
          {'year': 2025, 'demand_index': 92},
        ],
        'geo_recommendation': 'Bakhtiari is the premium hub for upscale F&B. A highly aesthetic cafe focusing on specialty coffee will capture the executive audience, though initial real estate costs are steep.',
      },
      {
        'city': 'Erbil',
        'area': 'Empire World',
        'industry': 'Real Estate',
        'category': 'Commercial Offices',
        'competition_level': 85,
        'success_probability': 82,
        'risk_level': 'Medium',
        'financials': {
          'currency': 'IQD',
          'avg_startup_cost': 250000000,
          'avg_monthly_operational_cost': 2500000,
          'profitability_margin': '12-15%',
        },
        'operations': {
          'recommended_employees_count': 3,
          'roles': {
            'Property Manager': 2000000,
            'Sales Agent': 800000,
            'Admin': 600000,
          }
        },
        'audience': {
          'target_demographics': ['International NGOs', 'Foreign Corporations', 'Tech Startups'],
          'market_size_est': 'Growing',
        },
        'growth_opportunities': ['Co-working spaces', 'Serviced Virtual Offices'],
        'trends': [
          {'year': 2023, 'demand_index': 65},
          {'year': 2024, 'demand_index': 72},
          {'year': 2025, 'demand_index': 88},
        ],
        'geo_recommendation': 'Empire represents modern corporate Erbil. High demand for fully serviced commercial suites by foreign companies. ROI is steady but requires significant upfront capital.',
      },
      {
        'city': 'Erbil',
        'area': 'Ankawa',
        'industry': 'Food & Beverage',
        'category': 'Dine-in Restaurants & Entertainment',
        'competition_level': 95,
        'success_probability': 68,
        'risk_level': 'High',
        'financials': {
          'currency': 'IQD',
          'avg_startup_cost': 120000000,
          'avg_monthly_operational_cost': 22000000,
          'profitability_margin': '20-30%',
        },
        'operations': {
          'recommended_employees_count': 15,
          'roles': {
            'Restaurant Manager': 1800000,
            'Executive Chef': 2000000,
            'Waitstaff': 500000,
          }
        },
        'audience': {
          'target_demographics': ['Expats', 'Tourists', 'Local Families'],
          'market_size_est': 'Very High',
        },
        'growth_opportunities': ['Live Entertainment', 'Fusion Cuisine'],
        'trends': [
          {'year': 2023, 'demand_index': 80},
          {'year': 2024, 'demand_index': 88},
          {'year': 2025, 'demand_index': 85},
        ],
        'geo_recommendation': 'Ankawa is heavily saturated but extremely lucrative for nighttime dining. Success relies heavily on unique menus, marketing, and exceptional service to stand out.',
      },
      {
        'city': 'Erbil',
        'area': 'Iskan',
        'industry': 'Food & Beverage',
        'category': 'Street Food / Quick Service',
        'competition_level': 98,
        'success_probability': 85,
        'risk_level': 'Low-Medium',
        'financials': {
          'currency': 'IQD',
          'avg_startup_cost': 15000000,
          'avg_monthly_operational_cost': 4000000,
          'profitability_margin': '35-45%',
        },
        'operations': {
          'recommended_employees_count': 4,
          'roles': {
            'Shift Lead': 750000,
            'Cook': 800000,
            'Cashier': 500000,
          }
        },
        'audience': {
          'target_demographics': ['Youth', 'Students', 'Late-night crowd'],
          'market_size_est': 'Massive',
        },
        'growth_opportunities': ['Late night delivery', 'Viral social media marketing'],
        'trends': [
          {'year': 2023, 'demand_index': 90},
          {'year': 2024, 'demand_index': 92},
          {'year': 2025, 'demand_index': 95},
        ],
        'geo_recommendation': 'Iskan is the heart of night-time street food in Erbil. Very high volume, high turn-over environment. Best for fast food concepts prioritizing speed and competitive pricing.',
      },
      {
        'city': 'Erbil',
        'area': 'Dream City',
        'industry': 'Health & Beauty',
        'category': 'Luxury Clinics / Spas',
        'competition_level': 75,
        'success_probability': 80,
        'risk_level': 'Medium',
        'financials': {
          'currency': 'IQD',
          'avg_startup_cost': 150000000,
          'avg_monthly_operational_cost': 12000000,
          'profitability_margin': '40-50%',
        },
        'operations': {
          'recommended_employees_count': 6,
          'roles': {
            'Clinic Manager': 1500000,
            'Specialist/Dermatologist': 3500000,
            'Receptionist': 600000,
          }
        },
        'audience': {
          'target_demographics': ['High-Net-Worth Individuals', 'Elite Residents'],
          'market_size_est': 'Niche but Highly Profitable',
        },
        'growth_opportunities': ['VIP Membership Programs', 'Exclusive global product lines'],
        'trends': [
          {'year': 2023, 'demand_index': 60},
          {'year': 2024, 'demand_index': 75},
          {'year': 2025, 'demand_index': 85},
        ],
        'geo_recommendation': 'Dream City demands ultra-luxury. Aesthetic clinics and high-end wellness spas perform exceptionally well here, targeting residents with high disposable incomes.',
      },

      // ==================================
      // BAGHDAD DATA
      // ==================================
      {
        'city': 'Baghdad',
        'area': 'Mansour',
        'industry': 'Retail',
        'category': 'Fashion & Boutiques',
        'competition_level': 92,
        'success_probability': 70,
        'risk_level': 'Medium-High',
        'financials': {
          'currency': 'IQD',
          'avg_startup_cost': 90000000,
          'avg_monthly_operational_cost': 18000000,
          'profitability_margin': '25-35%',
        },
        'operations': {
          'recommended_employees_count': 5,
          'roles': {
            'Store Manager': 1200000,
            'Sales Associate': 650000,
            'Social Media Manager': 800000,
          }
        },
        'audience': {
          'target_demographics': ['Upper-Middle Class', 'Trend-conscious youth'],
          'market_size_est': 'Very High',
        },
        'growth_opportunities': ['Pop-up collaborations', 'E-commerce integration'],
        'trends': [
          {'year': 2023, 'demand_index': 80},
          {'year': 2024, 'demand_index': 85},
          {'year': 2025, 'demand_index': 90},
        ],
        'geo_recommendation': 'Mansour is the premier shopping district in Baghdad. Success requires high-visibility storefronts, aggressive Instagram marketing, and exclusive inventory.',
      },
      {
        'city': 'Baghdad',
        'area': 'Karrada',
        'industry': 'Tech/Electronics',
        'category': 'Consumer Electronics Retail',
        'competition_level': 95,
        'success_probability': 78,
        'risk_level': 'Medium',
        'financials': {
          'currency': 'IQD',
          'avg_startup_cost': 180000000,
          'avg_monthly_operational_cost': 8000000,
          'profitability_margin': '10-15%',
        },
        'operations': {
          'recommended_employees_count': 4,
          'roles': {
            'Tech Sales Specialist': 850000,
            'Repair Technician': 1000000,
            'Inventory Manager': 700000,
          }
        },
        'audience': {
          'target_demographics': ['General Public', 'Tech Enthusiasts'],
          'market_size_est': 'Massive',
        },
        'growth_opportunities': ['B2B Sales', 'Authorized Repair Center Certifications'],
        'trends': [
          {'year': 2023, 'demand_index': 95},
          {'year': 2024, 'demand_index': 96},
          {'year': 2025, 'demand_index': 98},
        ],
        'geo_recommendation': 'Karrada is Baghdad’s tech hub. Extremely competitive but guarantees foot traffic. Margin is low, so volume and exclusive distribution rights are key to profitability.',
      },
      {
        'city': 'Baghdad',
        'area': 'Zayouna',
        'industry': 'Entertainment',
        'category': 'Family Recreation & Malls',
        'competition_level': 80,
        'success_probability': 82,
        'risk_level': 'Medium-High',
        'financials': {
          'currency': 'IQD',
          'avg_startup_cost': 350000000,
          'avg_monthly_operational_cost': 45000000,
          'profitability_margin': '25-30%',
        },
        'operations': {
          'recommended_employees_count': 25,
          'roles': {
            'Operations Director': 2500000,
            'Facility Staff': 550000,
            'Event Coordinator': 1000000,
          }
        },
        'audience': {
          'target_demographics': ['Families', 'Teenagers'],
          'market_size_est': 'Very High',
        },
        'growth_opportunities': ['VR Arcades', 'Edutainment Centers'],
        'trends': [
          {'year': 2023, 'demand_index': 70},
          {'year': 2024, 'demand_index': 82},
          {'year': 2025, 'demand_index': 90},
        ],
        'geo_recommendation': 'Zayouna boasts high family footfall. Investing in innovative family entertainment options inside or near major malls yields reliable and steady returns.',
      },
      {
        'city': 'Baghdad',
        'area': 'Jadriya',
        'industry': 'Real Estate',
        'category': 'Luxury Residential & Office',
        'competition_level': 70,
        'success_probability': 88,
        'risk_level': 'Low',
        'financials': {
          'currency': 'IQD',
          'avg_startup_cost': 500000000,
          'avg_monthly_operational_cost': 5000000,
          'profitability_margin': '15-25%',
        },
        'operations': {
          'recommended_employees_count': 4,
          'roles': {
            'Real Estate Broker': 1500000,
            'Property Attorney': 2000000,
            'Admin': 700000,
          }
        },
        'audience': {
          'target_demographics': ['Politicians', 'Diplomats', 'Foreign Embassies', 'Elite Class'],
          'market_size_est': 'Exclusive/Niche',
        },
        'growth_opportunities': ['Smart Home Integrations', 'High-security gated communities'],
        'trends': [
          {'year': 2023, 'demand_index': 80},
          {'year': 2024, 'demand_index': 82},
          {'year': 2025, 'demand_index': 86},
        ],
        'geo_recommendation': 'Jadriya is Baghdad’s hyper-elite zone. Focus exclusively on premium construction quality, utmost security, and privacy. The barrier to entry is immense capital, but the failure rate is lowest.',
      },
      {
        'city': 'Baghdad',
        'area': 'Adhamiya',
        'industry': 'Healthcare',
        'category': 'Specialized Medical Clinics',
        'competition_level': 85,
        'success_probability': 90,
        'risk_level': 'Low',
        'financials': {
          'currency': 'IQD',
          'avg_startup_cost': 120000000,
          'avg_monthly_operational_cost': 10000000,
          'profitability_margin': '35-50%',
        },
        'operations': {
          'recommended_employees_count': 7,
          'roles': {
            'Specialist Doctor': 4000000,
            'Registered Nurse': 1000000,
            'Medical Admin': 600000,
          }
        },
        'audience': {
          'target_demographics': ['Elderly', 'Families', 'Local Residents'],
          'market_size_est': 'High and Stable',
        },
        'growth_opportunities': ['Telemedicine integration', 'In-house diagnostic labs'],
        'trends': [
          {'year': 2023, 'demand_index': 88},
          {'year': 2024, 'demand_index': 90},
          {'year': 2025, 'demand_index': 94},
        ],
        'geo_recommendation': 'Adhamiya has deep community roots. A well-equipped, specialized clinic will thrive due to immense local trust. Emphasis must be placed on highly reputable physicians.',
      },
    ];

    // Delete existing collection first to avoid duplicates
    final snapshot = await _firestore.collection('iraq_market_insights').get();
    for (DocumentSnapshot doc in snapshot.docs) {
      await doc.reference.delete();
    }

    // Insert new data
    for (var insight in insights) {
      // Document ID: E.g., erbil_bakhtiari_food_beverage
      final docId = '${insight['city']}_${insight['area']}_${insight['industry']}'.toLowerCase().replaceAll(' & ', '_').replaceAll(' ', '_');
      await _firestore.collection('iraq_market_insights').doc(docId).set(insight);
    }

    debugPrint('✅ Iraq Geo-Marketing Data seeded successfully! (${insights.length} records)');
  }
}
