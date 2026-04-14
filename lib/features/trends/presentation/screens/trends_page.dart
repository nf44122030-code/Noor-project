import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/services/firebase_service.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  final FirebaseService _firebaseService = FirebaseService();
  String selectedTimeframe = 'month';
  Map<String, dynamic>? _trendsData;
  bool _isLoading = true;

  final themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  Future<void> _loadTrends() async {
    try {
      final data = await _firebaseService.getTrends();
      setState(() {
        _trendsData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading trends: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDarkMode = themeController.isDarkMode;

      if (_isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final metrics = _trendsData?['metrics'] as Map<String, dynamic>?;
      final revenueData = (_trendsData?['revenue_data'] as List?) ?? [];

      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? const LinearGradient(colors: [Color(0xFF0A1929), Color(0xFF0A1929)])
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                  ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: isDarkMode
                          ? const LinearGradient(colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)])
                          : const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0EA5E9), Color(0xFF06B6D4)]),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                    ),
                    padding: const EdgeInsets.only(top: 40, bottom: 96, left: 24, right: 24),
                    child: Row(
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24), onPressed: () => Navigator.pop(context)),
                        const Expanded(child: Center(child: Text('TRENDS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 4.8)))),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (metrics != null)
                          Row(
                            children: [
                              Expanded(child: _buildMetricCard(icon: Icons.attach_money, color: Colors.green, label: 'Revenue', value: metrics['revenue'] ?? '', change: 12.5, isDarkMode: isDarkMode)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildMetricCard(icon: Icons.people, color: Colors.blue, label: 'Users', value: metrics['users'] ?? '', change: 8.3, isDarkMode: isDarkMode)),
                            ],
                          ),
                          const SizedBox(height: 24),

                          _buildChartCard(
                            title: 'Revenue Trend',
                            isDarkMode: isDarkMode,
                            child: SizedBox(
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: revenueData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['value'] as num).toDouble())).toList(),
                                      isCurved: true,
                                      color: Colors.blue,
                                      barWidth: 3,
                                      dotData: const FlDotData(show: false),
                                    ),
                                  ],
                                  titlesData: const FlTitlesData(show: false),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              Positioned(
                top: 120, left: 0, right: 0,
                child: Center(
                  child: Container(
                    width: 128, height: 128,
                    decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))]),
                    child: const Icon(Icons.trending_up, size: 64, color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMetricCard({required IconData icon, required Color color, required String label, required String value, required double change, required bool isDarkMode}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildChartCard({required String title, required bool isDarkMode, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
