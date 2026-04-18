import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_controller.dart';

class DataAnalyticsPage extends StatefulWidget {
  const DataAnalyticsPage({super.key});

  @override
  State<DataAnalyticsPage> createState() => _DataAnalyticsPageState();
}

class _DataAnalyticsPageState extends State<DataAnalyticsPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final themeController = Get.find<ThemeController>();

  @override
  bool get wantKeepAlive => true;

  bool _isLoading = false;
  bool _isPicking = false;
  String? _fileName;
  int _rowCount = 0;
  List<String> _headers = [];
  List<List<dynamic>> _rows = [];
  List<_ChartConfig> _charts = [];

  final FirebaseService _firebaseService = FirebaseService();
  
  bool _historyOpen = false;
  bool _historyEverOpened = false;
  List<Map<String, dynamic>> _historyItems = [];
  bool _isLoadingHistory = false;

  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _loadHistoryList();
    _loadSavedData();
  }

  // ── Persistence & Local History ─────────────────────────────
  Future<void> _loadHistoryList() async {
    setState(() => _isLoadingHistory = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStr = prefs.getString('analytics_local_history') ?? '[]';
      List<Map<String, dynamic>> items = [];
      try {
        final List<dynamic> jsonList = jsonDecode(historyStr);
        items = jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        debugPrint('Corrupted history string: $e, wiping clean.');
        await prefs.setString('analytics_local_history', '[]');
      }
      
      if (mounted) {
        setState(() {
          _historyItems = items;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading local history: $e');
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _loadDataset(Map<String, dynamic> item) async {
    setState(() {
      _historyOpen = false;
      _isLoading = true;
      _charts.clear();
      _fileName = item['name'];
    });

    final id = item['fileId'];
    final ext = item['ext'];
    if (id == null || id.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/analytics_$id.$ext');
      
      if (!await file.exists()) {
        throw Exception('File no longer exists on device.');
      }
      
      final bytes = await file.readAsBytes();
      
      // Mark as current active screen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('analytics_active_id', id);

      if (ext == 'csv') {
        _parseCsv(bytes);
      } else {
        _parseExcel(bytes);
      }
    } catch (e) {
      debugPrint('Error loading dataset: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load dataset.'), backgroundColor: Colors.redAccent),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeId = prefs.getString('analytics_active_id');
      if (activeId == null) {
        setState(() => _isLoading = false);
        return;
      }

      await _loadHistoryList();
      final item = _historyItems.firstWhereOrNull((i) => i['fileId'] == activeId);
      if (item != null) {
        await _loadDataset(item);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading saved data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDataLocally(Uint8List bytes, String ext, String name) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/analytics_$id.$ext');
      await file.writeAsBytes(bytes);

      final prefs = await SharedPreferences.getInstance();
      
      List<Map<String, dynamic>> historyList = [];
      try {
        final historyStr = prefs.getString('analytics_local_history') ?? '[]';
        historyList = List<Map<String,dynamic>>.from(jsonDecode(historyStr));
      } catch (e) {
        historyList = [];
      }
      
      historyList.insert(0, {
        'fileId': id,
        'name': name,
        'ext': ext,
        'rowCount': _rowCount,
      });
      
      await prefs.setString('analytics_local_history', jsonEncode(historyList));
      await prefs.setString('analytics_active_id', id);
      
      await _loadHistoryList();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved successfully to local history!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          )
        );
      }
    } catch (e) {
      debugPrint('Error saving data locally: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('FATAL SAVE ERROR: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          )
        );
      }
    }
  }

  Future<void> _deleteDataset(String fileId, String ext) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove from history tracking
    List<Map<String, dynamic>> historyList = [];
    try {
      final historyStr = prefs.getString('analytics_local_history') ?? '[]';
      historyList = List<Map<String,dynamic>>.from(jsonDecode(historyStr));
    } catch(e) { /* ignore */ }
    
    historyList.removeWhere((item) => item['fileId'] == fileId);
    await prefs.setString('analytics_local_history', jsonEncode(historyList));
    
    // Delete actual file
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/analytics_$fileId.$ext');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting physical file: $e');
    }

    await _loadHistoryList();
    
    // If we're deleting what's currently on the screen, clear the screen
    final activeId = prefs.getString('analytics_active_id');
    if (activeId == fileId) {
       _clearActiveData();
    }
  }

  Future<void> _clearActiveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('analytics_active_id');

    setState(() {
      _charts.clear();
      _rows.clear();
      _headers.clear();
      _fileName = null;
      _rowCount = 0;
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── File Picker ─────────────────────────────────────────────
  Future<void> _pickFile() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _isPicking = false);
        return;
      }

      final file = result.files.first;
      final ext = file.name.split('.').last.toLowerCase();

      if (!['xlsx', 'csv'].contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please upload a modern Excel (.xlsx) or CSV file. Older .xls files are not supported.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        setState(() => _isPicking = false);
        return;
      }

      Uint8List? bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to read file data. The file might be corrupted or inaccessible.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        setState(() => _isPicking = false);
        return;
      }

      setState(() {
        _isLoading = true;
        _isPicking = false;
        _fileName = file.name;
      });

      await _saveDataLocally(bytes, ext, file.name);

      // Parse file
      if (ext == 'csv') {
        // Use Future.delayed to allow showing the loading state before parsing blocks the main thread
        await Future.delayed(const Duration(milliseconds: 100));
        _parseCsv(bytes);
      } else {
        await Future.delayed(const Duration(milliseconds: 100));
        _parseExcel(bytes);
      }
    } catch (e) {
      debugPrint('File pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() {
        _isPicking = false;
        _isLoading = false;
      });
    }
  }

  void _parseCsv(Uint8List bytes) {
    try {
      final csvString = String.fromCharCodes(bytes);
      final rows =
          const CsvToListConverter(eol: '\n').convert(csvString);
      if (rows.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      _headers = rows.first.map((e) => e.toString().trim()).toList();
      _rows = rows.skip(1).toList();
      _rowCount = _rows.length;
      _updateLocalRowCount();
      _generateCharts();
    } catch (e) {
      debugPrint('CSV parse error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing CSV: $e'), backgroundColor: Colors.redAccent),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _parseExcel(Uint8List bytes) {
    try {
      final decoder = SpreadsheetDecoder.decodeBytes(bytes);
      if (decoder.tables.isEmpty) {
         throw Exception('The Excel file contains no data sheets.');
      }
      
      final sheet = decoder.tables[decoder.tables.keys.first];
      if (sheet == null) {
         throw Exception('Could not read the first sheet.');
      }
      
      final allRows = sheet.rows;
      if (allRows.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      _headers =
          allRows.first.map((c) => c?.toString().trim() ?? '').toList();
      _rows = allRows
          .skip(1)
          .map((r) => r.map((c) => c ?? '').toList())
          .toList();
      _rowCount = _rows.length;
      _updateLocalRowCount();
      _generateCharts();
    } catch (e, stack) {
      debugPrint('Excel parse error: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error parsing Excel: $e (See console for details, ensure the file is a valid .xlsx)'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _updateLocalRowCount() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> historyList = [];
    try {
      final historyStr = prefs.getString('analytics_local_history') ?? '[]';
      historyList = List<Map<String,dynamic>>.from(jsonDecode(historyStr));
    } catch(e) { return; }
    
    if (historyList.isNotEmpty && historyList.first['rowCount'] != _rowCount) {
      historyList.first['rowCount'] = _rowCount;
      await prefs.setString('analytics_local_history', jsonEncode(historyList));
      _loadHistoryList();
    }
  }

  // ── Chart Generation ────────────────────────────────────────
  void _generateCharts() {
    final charts = <_ChartConfig>[];
    final hLower = _headers.map((h) => h.toLowerCase()).toList();

    // Detect numeric columns
    final Map<int, String> numericCols = {};
    final Map<int, String> stringCols = {};

    for (int i = 0; i < _headers.length; i++) {
      int numericCount = 0;
      for (final row in _rows.take(50)) {
        if (i < row.length) {
          final val = row[i];
          if (val is num || double.tryParse(val.toString()) != null) {
            numericCount++;
          }
        }
      }
      if (numericCount > _rows.take(50).length * 0.5) {
        numericCols[i] = _headers[i];
      } else {
        stringCols[i] = _headers[i];
      }
    }

    // Helper to detect column index by keywords
    int? findCol(List<String> keywords) {
      for (final kw in keywords) {
        final idx = hLower.indexWhere((h) => h.contains(kw));
        if (idx != -1) return idx;
      }
      return null;
    }

    // 1. Revenue / Sales Trend (Line Chart)
    final revCol = findCol(['revenue', 'sales', 'income', 'total', 'amount']);
    final dateCol = findCol(['date', 'month', 'year', 'period', 'time', 'day']);
    if (revCol != null) {
      charts.add(_ChartConfig(
        title: '📈 ${_headers[revCol]} Trend',
        type: _ChartType.line,
        xCol: dateCol,
        yCols: [revCol],
      ));
    }

    // 2. Profit by Category (Bar Chart)
    final profitCol = findCol(['profit', 'net', 'margin', 'earning']);
    final catCol = findCol(['city', 'branch', 'category', 'region', 'department', 'store', 'location', 'area']);
    if (profitCol != null && catCol != null) {
      charts.add(_ChartConfig(
        title: '📊 ${_headers[profitCol]} by ${_headers[catCol]}',
        type: _ChartType.bar,
        xCol: catCol,
        yCols: [profitCol],
      ));
    }

    // 3. Cost Breakdown (Pie Chart)
    final costCols = <int>[];
    for (final kw in ['cost', 'expense', 'salary', 'rent', 'marketing', 'inventory', 'overhead']) {
      final idx = findCol([kw]);
      if (idx != null && !costCols.contains(idx)) costCols.add(idx);
    }
    if (costCols.length >= 2) {
      charts.add(_ChartConfig(
        title: '🧩 Cost Breakdown',
        type: _ChartType.pie,
        xCol: null,
        yCols: costCols,
      ));
    }

    // 4. Scatter: Marketing vs Revenue
    final mktCol = findCol(['marketing', 'ad', 'advertising', 'promotion']);
    if (mktCol != null && revCol != null && mktCol != revCol) {
      charts.add(_ChartConfig(
        title: '🔥 ${_headers[mktCol]} vs ${_headers[revCol]}',
        type: _ChartType.scatter,
        xCol: mktCol,
        yCols: [revCol],
      ));
    }

    // 5. Top categories bar (if categorical + numeric exist)
    if (catCol != null && revCol != null && charts.length < 8) {
      charts.add(_ChartConfig(
        title: '🏆 ${_headers[catCol]} Ranking by ${_headers[revCol]}',
        type: _ChartType.horizontalBar,
        xCol: catCol,
        yCols: [revCol],
      ));
    }

    // 6. Multiple numeric columns comparison
    if (numericCols.length >= 2 && catCol != null && charts.length < 8) {
      final firstTwoNumeric = numericCols.keys.take(2).toList();
      charts.add(_ChartConfig(
        title: '📉 ${numericCols[firstTwoNumeric[0]]} vs ${numericCols[firstTwoNumeric[1]]}',
        type: _ChartType.line,
        xCol: dateCol ?? catCol,
        yCols: firstTwoNumeric,
      ));
    }

    // 7. If we have satisfaction / rating column
    final satCol = findCol(['satisfaction', 'rating', 'score', 'review', 'nps']);
    final custCol = findCol(['customer', 'client', 'visitor', 'user']);
    if (satCol != null && custCol != null && charts.length < 10) {
      charts.add(_ChartConfig(
        title: '👥 ${_headers[custCol]} vs ${_headers[satCol]}',
        type: _ChartType.scatter,
        xCol: custCol,
        yCols: [satCol],
      ));
    }

    // Fallback: if very few charts, create a line chart for every numeric col
    if (charts.isEmpty) {
      for (final entry in numericCols.entries.take(3)) {
        charts.add(_ChartConfig(
          title: '📈 ${entry.value} Overview',
          type: _ChartType.line,
          xCol: dateCol ?? stringCols.keys.firstOrNull,
          yCols: [entry.key],
        ));
      }
    }

    // Fallback 2: if still empty, just show a basic pie of first numeric col
    if (charts.isEmpty && numericCols.isNotEmpty) {
      charts.add(_ChartConfig(
        title: '📊 Data Distribution',
        type: _ChartType.pie,
        xCol: null,
        yCols: [numericCols.keys.first],
      ));
    }

    setState(() {
      _charts = charts.take(10).toList();
      _isLoading = false;
    });
    _fadeCtrl.forward(from: 0);
  }

  // ── Data Extraction Helpers ─────────────────────────────────
  double _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString().replaceAll(',', '')) ?? 0;
  }

  Map<String, double> _aggregateByCategory(int catCol, int valCol) {
    final Map<String, double> agg = {};
    for (final row in _rows) {
      if (catCol >= row.length || valCol >= row.length) continue;
      final cat = row[catCol].toString().trim();
      if (cat.isEmpty) continue;
      final val = _toDouble(row[valCol]);
      agg[cat] = (agg[cat] ?? 0) + val;
    }
    return agg;
  }

  List<double> _numericColumn(int col) {
    return _rows
        .where((r) => col < r.length)
        .map((r) => _toDouble(r[col]))
        .toList();
  }

  // ── Chart Colors ────────────────────────────────────────────
  static const _chartColors = [
    Color(0xFF2563EB),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFFf97316),
    Color(0xFF14B8A6),
    Color(0xFF6366F1),
  ];

  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      final isDark = themeController.isDarkMode;
      final bg = isDark ? AppColors.bgDark : AppColors.bgLight;

      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.menu_open_rounded, color: isDark ? Colors.white : Colors.black),
            onPressed: () {
              setState(() {
                _historyOpen = !_historyOpen;
                if (_historyOpen) _historyEverOpened = true;
              });
            },
          ),
          title: Text(
            'Data Analytics',
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_charts.isNotEmpty)
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                      title: Text('Start New?', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                      content: Text('This will clear the current screen. Your data is still safely saved in History.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Clear', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _clearActiveData();
                  }
                },
                icon: Icon(Icons.add_rounded, size: 20, color: isDark ? Colors.white70 : Colors.black87),
                label: Text(
                  'New',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            // Main Content
            Container(
              color: bg,
              child: _charts.isEmpty
                  ? _buildUploadState(isDark)
                  : _buildChartsView(isDark),
            ),
            
            // History Overlay Background Dimmer
            if (_historyOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _historyOpen = false),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),

            // History Drawer
            if (_historyEverOpened)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                top: 0,
                bottom: 0,
                left: _historyOpen ? 0 : -320,
                child: _buildHistorySidebar(isDark),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildHistorySidebar(bool isDark) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        boxShadow: [
          if (_historyOpen)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(4, 0),
            ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded,
                      color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Analytics History',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: isDark ? Colors.white54 : Colors.black45),
                    onPressed: () {
                      setState(() => _historyOpen = false);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : _historyItems.isEmpty
                      ? Center(
                          child: Text(
                            'No past data analyses found in local history.',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _historyItems.length,
                          itemBuilder: (context, index) {
                            final item = _historyItems[index];
                            final name = item['name'] ?? 'Data';
                            final ext = item['ext'] ?? 'csv';
                            final fileId = item['fileId'];
                            final rowCount = item['rowCount'] ?? 0;
                            // Add a visual indicator
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  ext == 'csv' ? Icons.table_chart_rounded : Icons.grid_on_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '$rowCount rows • Local',
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: AppColors.error, size: 20),
                                onPressed: () {
                                  if (fileId != null) {
                                    _deleteDataset(fileId, ext);
                                  }
                                },
                              ),
                              onTap: () {
                                _loadDataset(item);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Upload State ────────────────────────────────────────────
  Widget _buildUploadState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E3A5F), const Color(0xFF0D2137)]
                      : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.analytics_rounded,
                  color: AppColors.primary, size: 48),
            ),
            const SizedBox(height: 28),
            Text(
              'data_analytics'.tr.isEmpty ? 'Data Analytics' : 'Data Analytics',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Upload your business data and instantly see\npowerful visual insights and trends.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),

            // Upload Button
            GestureDetector(
              onTap: _isLoading ? null : _pickFile,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isLoading
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: AppColors.primary),
                      )
                    else
                      Icon(
                        Icons.cloud_upload_rounded,
                        size: 44,
                        color: isDark
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.8),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _isLoading ? 'Analyzing data...' : 'Upload Excel or CSV',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLoading
                          ? 'Generating charts automatically'
                          : 'Supports .xlsx, .xls, .csv files',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textDimDark
                            : AppColors.textHintLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Feature chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildChip('Auto Charts', Icons.auto_graph_rounded, isDark),
                _buildChip('Trend Analysis', Icons.trending_up_rounded, isDark),
                _buildChip('Cost Breakdown', Icons.pie_chart_rounded, isDark),
                _buildChip('Rankings', Icons.leaderboard_rounded, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : AppColors.primary)),
        ],
      ),
    );
  }

  // ── Charts View ─────────────────────────────────────────────
  Widget _buildChartsView(bool isDark) {
    return FadeTransition(
      opacity: _fadeCtrl,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fileName ?? 'Data Analysis',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_rowCount rows  •  ${_headers.length} columns  •  ${_charts.length} charts',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textDimDark
                                : AppColors.textHintLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Start New Analysis is now in the AppBar!
                  const SizedBox(),
                ],
              ),
            ),
          ),

          // Charts
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildChartCard(_charts[index], index, isDark),
                childCount: _charts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(_ChartConfig config, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            config.title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: _buildChart(config, index, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(_ChartConfig config, int index, bool isDark) {
    try {
      switch (config.type) {
        case _ChartType.line:
          return _buildLineChart(config, index, isDark);
        case _ChartType.bar:
          return _buildBarChart(config, index, isDark);
        case _ChartType.horizontalBar:
          return _buildHorizontalBarChart(config, index, isDark);
        case _ChartType.pie:
          return _buildPieChart(config, index, isDark);
        case _ChartType.scatter:
          return _buildScatterChart(config, index, isDark);
      }
    } catch (e) {
      return Center(
          child: Text('Chart error: $e',
              style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: 12)));
    }
  }

  // ── Line Chart ──────────────────────────────────────────────
  Widget _buildLineChart(_ChartConfig config, int index, bool isDark) {

    // Build spots for each Y column
    final List<LineChartBarData> lines = [];
    for (int ci = 0; ci < config.yCols.length; ci++) {
      final col = config.yCols[ci];
      final values = _numericColumn(col);
      if (values.isEmpty) continue;

      // Take max 50 points for readability
      final step = max(1, values.length ~/ 50);
      final spots = <FlSpot>[];
      for (int i = 0; i < values.length; i += step) {
        spots.add(FlSpot(spots.length.toDouble(), values[i]));
      }

      final c = _chartColors[(index + ci) % _chartColors.length];
      lines.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        color: c,
        barWidth: 2.5,
        dotData: FlDotData(show: spots.length < 20),
        belowBarData: BarAreaData(
          show: true,
          color: c.withValues(alpha: 0.08),
        ),
      ));
    }

    if (lines.isEmpty) {
      return const Center(child: Text('No numeric data to chart'));
    }

    return LineChart(
      LineChartData(
        lineBarsData: lines,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(
                _formatNum(v),
                style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.white38 : Colors.grey),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(
          touchTooltipData: LineTouchTooltipData(),
        ),
      ),
    );
  }

  // ── Bar Chart ───────────────────────────────────────────────
  Widget _buildBarChart(_ChartConfig config, int index, bool isDark) {
    if (config.xCol == null || config.yCols.isEmpty) {
      return const Center(child: Text('Insufficient data'));
    }
    final agg = _aggregateByCategory(config.xCol!, config.yCols.first);
    if (agg.isEmpty) return const Center(child: Text('No data'));

    final entries = agg.entries.take(12).toList();
    final color = _chartColors[index % _chartColors.length];

    return BarChart(
      BarChartData(
        barGroups: entries.asMap().entries.map((e) {
          return BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(
              toY: e.value.value,
              color: color,
              width: max(6, 24.0 - entries.length),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ]);
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= entries.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    entries[i].key.length > 8
                        ? '${entries[i].key.substring(0, 8)}…'
                        : entries[i].key,
                    style: TextStyle(
                        fontSize: 9,
                        color: isDark ? Colors.white54 : Colors.grey),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(_formatNum(v),
                  style: TextStyle(
                      fontSize: 9,
                      color: isDark ? Colors.white38 : Colors.grey)),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  // ── Horizontal Bar (Ranking) ────────────────────────────────
  Widget _buildHorizontalBarChart(
      _ChartConfig config, int index, bool isDark) {
    if (config.xCol == null || config.yCols.isEmpty) {
      return const Center(child: Text('Insufficient data'));
    }
    final agg = _aggregateByCategory(config.xCol!, config.yCols.first);
    if (agg.isEmpty) return const Center(child: Text('No data'));

    final sorted = agg.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(10).toList();
    final maxVal = top.first.value;

    return Column(
      children: top.asMap().entries.map((e) {
        final pct = maxVal > 0 ? e.value.value / maxVal : 0.0;
        final color = _chartColors[e.key % _chartColors.length];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  e.value.key.length > 10
                      ? '${e.value.key.substring(0, 10)}…'
                      : e.value.key,
                  style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white70 : Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: pct.clamp(0, 1).toDouble(),
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(_formatNum(e.value.value),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Pie Chart ───────────────────────────────────────────────
  Widget _buildPieChart(_ChartConfig config, int index, bool isDark) {
    final Map<String, double> slices = {};

    if (config.xCol != null && config.yCols.isNotEmpty) {
      slices.addAll(_aggregateByCategory(config.xCol!, config.yCols.first));
    } else {
      // Sum each cost column across all rows
      for (final col in config.yCols) {
        final sum = _numericColumn(col)
            .fold<double>(0, (a, b) => a + b);
        if (sum > 0) slices[_headers[col]] = sum;
      }
    }

    if (slices.isEmpty) return const Center(child: Text('No data'));
    final total = slices.values.fold<double>(0, (a, b) => a + b);

    final entries = slices.entries.take(8).toList();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: entries.asMap().entries.map((e) {
                final pct = total > 0 ? (e.value.value / total * 100) : 0.0;
                return PieChartSectionData(
                  value: e.value.value,
                  color: _chartColors[e.key % _chartColors.length],
                  radius: 60,
                  title: '${pct.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                );
              }).toList(),
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _chartColors[e.key % _chartColors.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        e.value.key,
                        style: TextStyle(
                            fontSize: 10,
                            color:
                                isDark ? Colors.white70 : Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Scatter Chart ───────────────────────────────────────────
  Widget _buildScatterChart(_ChartConfig config, int index, bool isDark) {
    if (config.xCol == null || config.yCols.isEmpty) {
      return const Center(child: Text('Insufficient data'));
    }

    final xVals = _numericColumn(config.xCol!);
    final yVals = _numericColumn(config.yCols.first);
    final count = min(xVals.length, yVals.length);
    if (count == 0) return const Center(child: Text('No data'));

    final color = _chartColors[index % _chartColors.length];
    final step = max(1, count ~/ 100);
    final spots = <ScatterSpot>[];
    for (int i = 0; i < count; i += step) {
      spots.add(ScatterSpot(xVals[i], yVals[i],
          dotPainter: FlDotCirclePainter(
            radius: 4,
            color: color.withValues(alpha: 0.6),
            strokeWidth: 0,
          )));
    }

    return ScatterChart(
      ScatterChartData(
        scatterSpots: spots,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(_formatNum(v),
                  style: TextStyle(
                      fontSize: 9,
                      color: isDark ? Colors.white38 : Colors.grey)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(_formatNum(v),
                  style: TextStyle(
                      fontSize: 9,
                      color: isDark ? Colors.white38 : Colors.grey)),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  String _formatNum(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
  }
}

// ── Models ──────────────────────────────────────────────────
enum _ChartType { line, bar, horizontalBar, pie, scatter }

class _ChartConfig {
  final String title;
  final _ChartType type;
  final int? xCol;
  final List<int> yCols;

  _ChartConfig({
    required this.title,
    required this.type,
    required this.xCol,
    required this.yCols,
  });
}
