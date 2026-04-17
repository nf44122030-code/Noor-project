class MarketInsight {
  final String id;
  final String city;
  final String area;
  final String industry;
  final String category;
  final int competitionLevel;
  final int successProbability;
  final String riskLevel;
  final Financials financials;
  final Operations operations;
  final Audience audience;
  final List<String> growthOpportunities;
  final List<Trend> trends;
  final String geoRecommendation;

  MarketInsight({
    required this.id,
    required this.city,
    required this.area,
    required this.industry,
    required this.category,
    required this.competitionLevel,
    required this.successProbability,
    required this.riskLevel,
    required this.financials,
    required this.operations,
    required this.audience,
    required this.growthOpportunities,
    required this.trends,
    required this.geoRecommendation,
  });

  factory MarketInsight.fromJson(Map<String, dynamic> json) {
    return MarketInsight(
      id: json['id'] ?? '',
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      industry: json['industry'] ?? '',
      category: json['category'] ?? '',
      competitionLevel: json['competition_level'] ?? 0,
      successProbability: json['success_probability'] ?? 0,
      riskLevel: json['risk_level'] ?? '',
      financials: Financials.fromJson(json['financials'] ?? {}),
      operations: Operations.fromJson(json['operations'] ?? {}),
      audience: Audience.fromJson(json['audience'] ?? {}),
      growthOpportunities: List<String>.from(json['growth_opportunities'] ?? []),
      trends: (json['trends'] as List? ?? []).map((t) => Trend.fromJson(t)).toList(),
      geoRecommendation: json['geo_recommendation'] ?? '',
    );
  }
}

class Financials {
  final String currency;
  final int avgStartupCost;
  final int avgMonthlyOperationalCost;
  final String profitabilityMargin;
  final Map<String, int> revenueProjections;

  Financials({
    required this.currency,
    required this.avgStartupCost,
    required this.avgMonthlyOperationalCost,
    required this.profitabilityMargin,
    required this.revenueProjections,
  });

  factory Financials.fromJson(Map<String, dynamic> json) {
    return Financials(
      currency: json['currency'] ?? 'IQD',
      avgStartupCost: json['avg_startup_cost'] ?? 0,
      avgMonthlyOperationalCost: json['avg_monthly_operational_cost'] ?? 0,
      profitabilityMargin: json['profitability_margin'] ?? '',
      revenueProjections: Map<String, int>.from(json['revenue_projections'] ?? {}),
    );
  }
}

class Operations {
  final int recommendedEmployeesCount;
  final Map<String, int> roles;

  Operations({
    required this.recommendedEmployeesCount,
    required this.roles,
  });

  factory Operations.fromJson(Map<String, dynamic> json) {
    return Operations(
      recommendedEmployeesCount: json['recommended_employees_count'] ?? 0,
      roles: Map<String, int>.from(json['roles'] ?? {}),
    );
  }
}

class Audience {
  final List<String> targetDemographics;
  final String marketSizeEst;
  final Map<String, int> ageBreakdown;

  Audience({
    required this.targetDemographics,
    required this.marketSizeEst,
    required this.ageBreakdown,
  });

  factory Audience.fromJson(Map<String, dynamic> json) {
    return Audience(
      targetDemographics: List<String>.from(json['target_demographics'] ?? []),
      marketSizeEst: json['market_size_est'] ?? '',
      ageBreakdown: Map<String, int>.from(json['age_breakdown'] ?? {}),
    );
  }
}

class Trend {
  final int year;
  final int demandIndex;

  Trend({
    required this.year,
    required this.demandIndex,
  });

  factory Trend.fromJson(Map<String, dynamic> json) {
    return Trend(
      year: json['year'] ?? 0,
      demandIndex: json['demand_index'] ?? 0,
    );
  }
}
