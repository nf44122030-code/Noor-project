import 'package:get/get.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/models/market_insight.dart';

class MarketAnalysisController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();

  final RxList<MarketInsight> allInsights = <MarketInsight>[].obs;
  final RxBool isLoading = true.obs;

  // Selected State
  final RxString selectedCity = 'Erbil'.obs;
  final RxString selectedArea = ''.obs;
  
  // Specific Insight currently viewed
  final Rx<MarketInsight?> currentInsight = Rx<MarketInsight?>(null);

  @override
  void onInit() {
    super.onInit();
    _fetchInsights();
  }

  Future<void> _fetchInsights() async {
    isLoading.value = true;
    try {
      final rawData = await _firebaseService.getMarketInsights();
      allInsights.value = rawData.map((e) => MarketInsight.fromJson(e)).toList();
      
      // Auto-select first area if available
      if (allInsights.isNotEmpty) {
        _updateAvailableAreas();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _updateAvailableAreas() {
    final areas = availableAreas;
    if (areas.isNotEmpty && !areas.contains(selectedArea.value)) {
      selectArea(areas.first);
    } else if (areas.isEmpty) {
      currentInsight.value = null;
    }
  }

  List<String> get availableCities {
    return allInsights.map((i) => i.city).toSet().toList()..sort();
  }

  List<String> get availableAreas {
    return allInsights
        .where((i) => i.city == selectedCity.value)
        .map((i) => i.area)
        .toSet()
        .toList()
        ..sort();
  }

  void selectCity(String city) {
    selectedCity.value = city;
    _updateAvailableAreas();
  }

  void selectArea(String area) {
    selectedArea.value = area;
    final insight = allInsights.firstWhereOrNull(
      (i) => i.city == selectedCity.value && i.area == area,
    );
    currentInsight.value = insight;
  }
}
