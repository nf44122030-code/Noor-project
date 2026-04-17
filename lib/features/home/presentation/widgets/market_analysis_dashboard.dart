import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/market_analysis_controller.dart';
import '../../data/models/market_insight.dart';
import '../../../../core/utils/market_data_seeder.dart';

class MarketAnalysisDashboard extends StatelessWidget {
  final bool isDark;

  const MarketAnalysisDashboard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Initialize Controller if not already
    final controller = Get.put(MarketAnalysisController());

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final insight = controller.currentInsight.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationHeader(controller),
            const SizedBox(height: 24),
            
            if (insight != null) ...[
              _buildIndustryContext(insight),
              const SizedBox(height: 24),
              _buildMarketRadarChart(insight),
              const SizedBox(height: 24),
              _buildGeoRecommendation(insight),
              const SizedBox(height: 24),
              _buildDemographicsCard(insight),
              const SizedBox(height: 24),
              _buildFinancialMetrics(insight),
              const SizedBox(height: 24),
              _buildRevenueChart(insight),
              const SizedBox(height: 24),
              _buildOperationsCard(insight),
              const SizedBox(height: 24),
              _buildTrendChart(insight),
            ] else
              _buildEmptyState(controller),
          ],
        ),
      );
    });
  }

  Widget _buildLocationHeader(MarketAnalysisController controller) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'geo_marketing_analysis'.tr,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: controller.selectedCity.value,
                  items: controller.availableCities,
                  onChanged: (v) => controller.selectCity(v!),
                  icon: Icons.location_city,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  value: controller.selectedCategory.value == '' ? null : controller.selectedCategory.value,
                  items: controller.availableCategories,
                  onChanged: (v) => controller.selectCategory(v!),
                  icon: Icons.storefront,
                  hint: 'select_business'.tr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: controller.selectedArea.value == '' ? null : controller.selectedArea.value,
                  items: controller.availableAreas,
                  onChanged: (v) => controller.selectArea(v!),
                  icon: Icons.map_rounded,
                  hint: 'select_area'.tr,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          hint: hint != null ? Text(hint, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)) : null,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.black54),
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, overflow: TextOverflow.ellipsis)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildIndustryContext(MarketInsight insight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  insight.industry,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  insight.category,
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildCircularMetric('success_prob'.tr, insight.successProbability, Colors.green),
              _buildCircularMetric('competition'.tr, insight.competitionLevel, Colors.orange),
              _buildMiniMetric('risk'.tr, insight.riskLevel, Icons.warning_amber_rounded, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketRadarChart(MarketInsight insight) {
    final latestDemand = insight.trends.isNotEmpty ? insight.trends.last.demandIndex.toDouble() : 50.0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.radar, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'market_environment'.tr,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: AppColors.primary.withValues(alpha: 0.2),
                    borderColor: AppColors.primary,
                    entryRadius: 3,
                    dataEntries: [
                      RadarEntry(value: insight.successProbability.toDouble()),
                      RadarEntry(value: insight.competitionLevel.toDouble()),
                      RadarEntry(value: latestDemand),
                    ],
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: const BorderSide(color: Colors.transparent),
                getTitle: (index, angle) {
                  switch (index) {
                    case 0:
                      return const RadarChartTitle(text: 'Success Prob.');
                    case 1:
                      return const RadarChartTitle(text: 'Competition');
                    case 2:
                      return const RadarChartTitle(text: 'Demand Index');
                    default:
                      return const RadarChartTitle(text: '');
                  }
                },
                tickCount: 5,
                ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
                tickBorderData: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                gridBorderData: BorderSide(color: isDark ? Colors.white24 : Colors.black26, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularMetric(String label, int percentage, Color color) {
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 60,
            width: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 24,
                    sections: [
                      PieChartSectionData(value: percentage.toDouble(), color: color, radius: 6, showTitle: false),
                      PieChartSectionData(value: (100 - percentage).toDouble(), color: color.withValues(alpha: 0.15), radius: 6, showTitle: false),
                    ],
                  ),
                ),
                Text('$percentage%', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : Colors.black)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildGeoRecommendation(MarketInsight insight) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.gradientPrimary),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'expert_intelligence'.tr,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.geoRecommendation,
            style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), height: 1.6, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetrics(MarketInsight insight) {
    final currency = insight.financials.currency;
    final totalCost = insight.financials.avgStartupCost + insight.financials.avgMonthlyOperationalCost;
    final startupPct = totalCost > 0 ? (insight.financials.avgStartupCost / totalCost) * 100 : 0.0;
    final operationalPct = totalCost > 0 ? (insight.financials.avgMonthlyOperationalCost / totalCost) * 100 : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('financial_allocation'.tr, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(color: AppColors.primary, value: startupPct, radius: 12, showTitle: false),
                      PieChartSectionData(color: Colors.orangeAccent, value: operationalPct, radius: 12, showTitle: false),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem('Startup', '${_formatCurrency(insight.financials.avgStartupCost)} $currency', AppColors.primary),
                    const SizedBox(height: 16),
                    _buildLegendItem('1st Mo Op.', '${_formatCurrency(insight.financials.avgMonthlyOperationalCost)} $currency', Colors.orangeAccent),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                Text('expected_profitability'.tr, style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black87)),
                Text(insight.financials.profitabilityMargin, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
             ]
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
     return Row(
        children: [
           Container(width: 12, height: 12, color: color, margin: const EdgeInsets.only(right: 8)),
           Expanded(
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(label, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                   if (value.isNotEmpty) Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black)),
                ],
             ),
           )
        ]
     );
  }

  Widget _buildDemographicsCard(MarketInsight insight) {
    if (insight.audience.ageBreakdown.isEmpty) return const SizedBox.shrink();
    
    final breakdown = insight.audience.ageBreakdown.entries.toList();
    final colors = [AppColors.primary, Colors.orangeAccent, Colors.green, Colors.purpleAccent, Colors.blueAccent];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'target_demographics'.tr,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: List.generate(breakdown.length, (i) {
                         return PieChartSectionData(
                            color: colors[i % colors.length],
                            value: breakdown[i].value.toDouble(),
                            title: '${breakdown[i].value}%',
                            radius: 30,
                            titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                         );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(breakdown.length, (i) => Padding(
                       padding: const EdgeInsets.only(bottom: 12),
                       child: _buildLegendItem(breakdown[i].key, '', colors[i % colors.length]),
                    )),
                  ),
                )
              ]
            ),
          )
        ],
      )
    );
  }

  Widget _buildRevenueChart(MarketInsight insight) {
     if (insight.financials.revenueProjections.isEmpty) return const SizedBox.shrink();
     
     final data = insight.financials.revenueProjections.entries.toList();
     final maxValue = data.fold(0, (max, e) => e.value > max ? e.value : max).toDouble();

     return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'revenue_projections'.tr,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                       return BarTooltipItem(
                          '${data[group.x].key}\n',
                          GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text: '${_formatCurrency(rod.toY)} ${insight.financials.currency}',
                              style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.normal),
                            )
                          ]
                       );
                    }
                  )
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                         if (value.toInt() < 0 || value.toInt() >= data.length) return const SizedBox.shrink();
                         return Padding(
                           padding: const EdgeInsets.only(top: 8.0),
                           child: Text(data[value.toInt()].key, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                         );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(data.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[i].value.toDouble(),
                        color: Colors.green,
                        width: 24,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          )
        ]
      )
    );
  }

  Widget _buildOperationsCard(MarketInsight insight) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'operations_team'.tr,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${'recommended_team_size'.tr}: ${insight.operations.recommendedEmployeesCount}',
            style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text('${'salary_benchmarks'.tr} (${insight.financials.currency} / mo):', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 24),
          _buildSalariesBarChart(insight.operations.roles),
        ],
      ),
    );
  }

  Widget _buildSalariesBarChart(Map<String, int> roles) {
    if (roles.isEmpty) return const SizedBox.shrink();
    
    final maxSalary = roles.values.reduce(math.max).toDouble();
    final roleEntries = roles.entries.toList();

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxSalary * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                 return BarTooltipItem(
                    '${roleEntries[group.x].key}\n',
                    GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: _formatCurrency(rod.toY),
                        style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.normal),
                      )
                    ]
                 );
              }
            )
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                   if (value.toInt() < 0 || value.toInt() >= roleEntries.length) return const SizedBox.shrink();
                   String roleName = roleEntries[value.toInt()].key;
                   String shortened = roleName.length > 8 ? '${roleName.substring(0, 8)}...' : roleName;
                   return Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text(shortened, style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87)),
                   );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(roleEntries.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: roleEntries[i].value.toDouble(),
                  color: AppColors.primary,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTrendChart(MarketInsight insight) {
    if (insight.trends.isEmpty) return const SizedBox.shrink();

    final spots = insight.trends.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.demandIndex.toDouble());
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('demand_trend'.tr, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < insight.trends.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              insight.trends[value.toInt()].year.toString(),
                              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildEmptyState(MarketAnalysisController controller) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.map_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 16),
            if (controller.allInsights.isEmpty) ...[
              Text(
                'market_db_empty'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'seed_db_desc'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: isDark ? Colors.white60 : Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_download),
                label: Text('seed_db_now'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () async {
                  controller.isLoading.value = true;
                  await MarketDataSeeder.seedIraqiMarketData();
                  await controller.fetchInsights();
                },
              ),
            ] else ...[
              Text(
                'no_data_combo'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: isDark ? Colors.white60 : Colors.black54, fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCurrency(num value) {
    String str = value.toStringAsFixed(0);
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = ',$result';
        count = 0;
      }
      result = '${str[i]}$result';
      count++;
    }
    return result;
  }
}
