import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/market_analysis_controller.dart';
import '../../data/models/market_insight.dart';

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
              _buildGeoRecommendation(insight),
              const SizedBox(height: 24),
              _buildFinancialMetrics(insight),
              const SizedBox(height: 24),
              _buildOperationsCard(insight),
              const SizedBox(height: 24),
              _buildTrendChart(insight),
            ] else
              _buildEmptyState(),
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
            'Geo-Marketing Analysis',
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
                  value: controller.selectedArea.value == '' ? null : controller.selectedArea.value,
                  items: controller.availableAreas,
                  onChanged: (v) => controller.selectArea(v!),
                  icon: Icons.map_rounded,
                  hint: 'Select Area',
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
              _buildMiniMetric('Success Rate', '\${insight.successProbability}%', Icons.trending_up, Colors.green),
              _buildMiniMetric('Competition', '\${insight.competitionLevel}/100', Icons.people_alt, Colors.orange),
              _buildMiniMetric('Risk', insight.riskLevel, Icons.warning_amber_rounded, Colors.redAccent),
            ],
          ),
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
                'Expert Intelligence',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Financial Overview', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildDetailedCard(
                'Avg Startup Cost',
                '\${_formatCurrency(insight.financials.avgStartupCost)} $currency',
                Icons.account_balance_wallet,
                isDark,
              ),
              const SizedBox(width: 16),
              _buildDetailedCard(
                'Monthly Op. Cost',
                '\${_formatCurrency(insight.financials.avgMonthlyOperationalCost)} $currency',
                Icons.receipt_long,
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Expected Profitability Margin', style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black87)),
                Text(
                  insight.financials.profitabilityMargin,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                ),
              ],
            ),
          )
        ],
      ),
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
                'Human Resources & Operations',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Recommended Minimum Team Size: \${insight.operations.recommendedEmployeesCount} employees',
            style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text('Salary Benchmarks (${insight.financials.currency} / mo):', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          ...insight.operations.roles.entries.map((role) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(role.key, style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black)),
                  Text(
                    _formatCurrency(role.value),
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            );
          }),
        ],
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
          Text('Local Demand Trend', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
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

  Widget _buildDetailedCard(String title, String value, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.accent, size: 24),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.map_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 16),
            Text(
              'Select an area to view deep market analytics',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: isDark ? Colors.white60 : Colors.black54, fontSize: 16),
            )
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
        result = ',\$result';
        count = 0;
      }
      result = '\${str[i]}\$result';
      count++;
    }
    return result;
  }
}
