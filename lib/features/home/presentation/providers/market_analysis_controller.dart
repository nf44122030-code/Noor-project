import 'package:get/get.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/models/market_insight.dart';

class MarketAnalysisController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();

  final RxList<MarketInsight> allInsights = <MarketInsight>[].obs;
  final RxBool isLoading = true.obs;

  // Selected State
  final RxString selectedCity = 'Erbil'.obs;
  final RxString selectedCategory = ''.obs;
  final RxString selectedArea = ''.obs;
  
  // Specific Insight currently viewed
  final Rx<MarketInsight?> currentInsight = Rx<MarketInsight?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchInsights();
  }

  Future<void> fetchInsights() async {
    isLoading.value = true;
    try {
      final rawData = await _firebaseService.getMarketInsights();
      allInsights.value = rawData.map((e) => MarketInsight.fromJson(e)).toList();
      
      if (allInsights.isNotEmpty) {
        if (!availableCities.contains(selectedCity.value)) {
           selectedCity.value = availableCities.first;
        }
        _updateAvailableCategories();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _updateAvailableCategories() {
    final cats = availableCategories;
    if (cats.isNotEmpty && !cats.contains(selectedCategory.value)) {
      selectCategory(cats.first);
    } else if (cats.isEmpty) {
      selectedCategory.value = '';
      _updateAvailableAreas();
    } else {
      _updateAvailableAreas();
    }
  }

  void _updateAvailableAreas() {
    final areas = availableAreas;
    if (areas.isNotEmpty && !areas.contains(selectedArea.value)) {
      selectArea(areas.first);
    } else if (areas.isEmpty) {
      selectedArea.value = '';
      currentInsight.value = null;
    } else {
      selectArea(selectedArea.value);
    }
  }

  List<String> get availableCities {
    return allInsights.map((i) => i.city).toSet().toList()..sort();
  }

  List<String> get availableCategories {
    return allInsights
        .where((i) => i.city == selectedCity.value)
        .map((i) => i.category)
        .toSet()
        .toList()
        ..sort();
  }

  List<String> get availableAreas {
    return allInsights
        .where((i) => i.city == selectedCity.value && i.category == selectedCategory.value)
        .map((i) => i.area)
        .toSet()
        .toList()
        ..sort();
  }

  void selectCity(String city) {
    selectedCity.value = city;
    _updateAvailableCategories();
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
    _updateAvailableAreas();
  }

  void selectArea(String area) {
    selectedArea.value = area;
    final insight = allInsights.firstWhereOrNull(
      (i) => i.city == selectedCity.value && i.category == selectedCategory.value && i.area == area,
    );
    currentInsight.value = insight;
  }
}
