import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/email_service.dart';
import '../../../../features/auth/presentation/providers/auth_controller.dart';
import '../../data/models/expert.dart';

class ExpertSessionPage extends StatefulWidget {
  const ExpertSessionPage({super.key});

  @override
  State<ExpertSessionPage> createState() => _ExpertSessionPageState();
}

class _ExpertSessionPageState extends State<ExpertSessionPage> {
  final _firebaseService = FirebaseService();
  final _themeController = Get.find<ThemeController>();
  final _authController  = Get.find<AuthController>();

  List<Expert> _experts = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Selection state
  Expert?  _selectedExpert;
  bool     _showDetail  = false;
  bool     _showBooking = false;
  bool     _showSuccess = false;
  bool     _isSending   = false;

  // Booking form
  String?   _selectedDay;
  DateTime? _selectedDate;
  String?   _selectedSlot;
  String    _duration = '60';
  final  _notesController = TextEditingController();

  // Helpers – colour per expert (cycles through palette)
  static const List<List<Color>> _palette = [
    [Color(0xFF1E40AF), Color(0xFF3B82F6)],
    [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    [Color(0xFF065F46), Color(0xFF10B981)],
    [Color(0xFF92400E), Color(0xFFF59E0B)],
    [Color(0xFF831843), Color(0xFFF472B6)],
    [Color(0xFF1E3A5F), Color(0xFF0EA5E9)],
    [Color(0xFF3D1A00), Color(0xFFF97316)],
    [Color(0xFF164E63), Color(0xFF06B6D4)],
  ];

  List<Color> _gradientFor(int index) => _palette[index % _palette.length];

  @override
  void initState() {
    super.initState();
    _loadExperts();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExperts() async {
    try {
      final experts = await _firebaseService.getExperts();
      if (mounted) {
        setState(() { 
          _experts = experts; 
          _isLoading = false; 
          _errorMessage = experts.isEmpty ? "Found 0 experts in collection 'experts'." : null;
        });
      }
    } catch (e) {
      debugPrint('Error loading experts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error: $e";
        });
      }
    }
  }

  // ── Date helpers ─────────────────────────────────────────────────────────────
  int _dayToWeekday(String day) => const {
    'Monday': 1, 'Tuesday': 2, 'Wednesday': 3, 'Thursday': 4,
    'Friday': 5, 'Saturday': 6, 'Sunday': 7,
  }[day] ?? 1;

  List<DateTime> _upcomingDates(String dayName, {int count = 5}) {
    final target = _dayToWeekday(dayName);
    final results = <DateTime>[];
    var cursor = DateTime.now().add(const Duration(days: 1));
    while (results.length < count) {
      if (cursor.weekday == target) results.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return results;
  }

  // ── Booking confirm ───────────────────────────────────────────────────────────
  Future<void> _confirmBooking() async {
    if (_selectedExpert == null || _selectedDate == null || _selectedSlot == null) return;

    setState(() => _isSending = true);

    final dateStr = DateFormat('EEEE, MMM d, yyyy').format(_selectedDate!);
    final user    = _authController.user;

    // 1 – Save to Firestore
    await _firebaseService.bookSession(
      expertId:    _selectedExpert!.id,
      expertName:  _selectedExpert!.name,
      expertEmail: _selectedExpert!.email,
      sessionDate: dateStr,
      sessionTime: _selectedSlot!,
      duration:    _duration,
      notes:       _notesController.text.trim(),
    );

    // 2 – Send email notification to expert
    await EmailService.sendBookingEmail(
      expertName:  _selectedExpert!.name,
      expertEmail: _selectedExpert!.email,
      userName:    user?.displayName ?? _authController.userName,
      userEmail:   user?.email ?? _authController.userEmail,
      sessionDate: dateStr,
      sessionTime: _selectedSlot!,
      duration:    _duration,
      notes:       _notesController.text.trim(),
    );

    // 3 – Send "booking received" email to the user (pending – no code yet)
    await EmailService.sendBookingReceivedEmail(
      userName:    user?.displayName ?? _authController.userName,
      userEmail:   user?.email ?? _authController.userEmail,
      expertName:  _selectedExpert!.name,
      sessionDate: dateStr,
      sessionTime: _selectedSlot!,
      duration:    _duration,
      notes:       _notesController.text.trim(),
    );

    setState(() {
      _isSending    = false;
      _showBooking  = false;
      _showSuccess  = true;
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showSuccess    = false;
          _selectedExpert = null;
          _showDetail     = false;
          _selectedDay    = null;
          _selectedDate   = null;
          _selectedSlot   = null;
          _duration       = '60';
          _notesController.clear();
        });
      }
    });
  }

  void _startInstantCall(Expert expert) {
    final randomCode = (Random().nextInt(90000) + 10000).toString();
    context.push('/video-session', extra: {
      'expertName': expert.name,
      'expertTitle': expert.title,
      'initialCode': randomCode,
    });
  }

  // ══════════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = _themeController.isDarkMode;
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(colors: [Color(0xFF0A1929), Color(0xFF0A1929)])
                : const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                  ),
          ),
          child: Stack(
            children: [
              _buildBase(isDark),
              if (_showDetail  && _selectedExpert != null) _buildDetailSheet(isDark),
              if (_showBooking && _selectedExpert != null) _buildBookingSheet(isDark),
              if (_showSuccess) _buildSuccessOverlay(isDark),
            ],
          ),
        ),
      );
    });
  }

  // ── Base list ─────────────────────────────────────────────────────────────────
  Widget _buildBase(bool isDark) {
    return Column(
      children: [
        // Header
        Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)])
                : const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0EA5E9), Color(0xFF06B6D4)]),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36),
            ),
          ),
          padding: const EdgeInsets.only(top: 48, bottom: 28, left: 16, right: 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Center(
                  child: Text('expert_sessions_title'.tr,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: Colors.white, letterSpacing: 2.5)),
                ),
              ),
              IconButton(
                tooltip: 'My Bookings',
                icon: const Icon(Icons.bookmark_rounded, color: Colors.white),
                onPressed: () => context.push('/my-bookings'),
              ),
            ],
          ),
        ),

        // Expert list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _experts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('no_experts'.tr,
                              style: TextStyle(color: isDark ? Colors.white54 : Colors.black38)),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(_errorMessage!,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                          ],
                        ],
                      ))
                  : RefreshIndicator(
                      onRefresh: _loadExperts,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        itemCount: _experts.length,
                        itemBuilder: (_, i) => _buildExpertCard(_experts[i], i, isDark),
                      ),
                    ),
        ),
      ],
    );
  }

  // ── Expert card ───────────────────────────────────────────────────────────────
  Widget _buildExpertCard(Expert expert, int index, bool isDark) {
    final grad = _gradientFor(index);
    return GestureDetector(
      onTap: () => setState(() { _selectedExpert = expert; _showDetail = true; }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF132F4C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF1E4976) : const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07),
              blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(expert, 56, grad, 22),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expert.name,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF111827)),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(expert.title,
                        style: TextStyle(fontSize: 12,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text('${expert.rating}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF374151))),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(expert.availability,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF10B981),
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Book button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: () => setState(() { _selectedExpert = expert; _showDetail = true; }),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                  child: const Text('Book', style: TextStyle(color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w600)),
                ),
              ),
              // Videocam button removed
            ],
          ),
        ),
      ),
    );
  }

  // ── Expert detail sheet ───────────────────────────────────────────────────────
  Widget _buildDetailSheet(bool isDark) {
    final expert = _selectedExpert!;
    final index  = _experts.indexOf(expert);
    final grad   = _gradientFor(index < 0 ? 0 : index);

    return _overlayWrap(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top gradient strip
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: grad, begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Row(
              children: [
                _buildAvatar(expert, 72, grad, 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expert.name,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(expert.title,
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text('${expert.rating}  ·  ${expert.reviews} reviews',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(children: [
                    _statChip(Icons.work_history_rounded, '${expert.yearsExperience} yrs', isDark),
                    const SizedBox(width: 10),
                    _statChip(Icons.check_circle_outline, '${expert.sessionsCompleted} sessions', isDark),
                    const SizedBox(width: 10),
                    _statChip(Icons.hub_rounded, expert.specialty.split(' ').first, isDark),
                  ]),
                  const SizedBox(height: 14),

                  // Bio
                  _sectionTitle('About', isDark),
                  const SizedBox(height: 6),
                  Text(expert.bio,
                      style: TextStyle(fontSize: 13, height: 1.6,
                          color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151))),
                  const SizedBox(height: 16),

                  // Schedule
                  _sectionTitle('Available Schedule', isDark),
                  const SizedBox(height: 10),
                  ...expert.schedule.map((day) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildScheduleRow(day, grad, isDark),
                  )),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() { _showDetail = false; _selectedExpert = null; }),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: isDark ? const Color(0xFF1E4976) : const Color(0xFFD1D5DB), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('close'.tr,
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: grad),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() { _showDetail = false; _showBooking = true; }),
                    icon: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 18),
                    label: Text('book_session'.tr,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Booking sheet ─────────────────────────────────────────────────────────────
  Widget _buildBookingSheet(bool isDark) {
    final expert = _selectedExpert!;
    final index  = _experts.indexOf(expert);
    final grad   = _gradientFor(index < 0 ? 0 : index);
    final canConfirm = _selectedDate != null && _selectedSlot != null;

    return _overlayWrap(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: grad, begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
                  onPressed: () => setState(() { _showBooking = false; _showDetail = true; }),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('book_session'.tr,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('${'with_expert'.tr} ${expert.name}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1 – Day selector
                  _sectionTitle('1. Choose a Day', isDark),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: expert.schedule.map((s) {
                      final isSelected = _selectedDay == s.day;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedDay  = s.day;
                          _selectedDate = null;
                          _selectedSlot = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: isSelected ? LinearGradient(colors: grad) : null,
                            color: isSelected ? null : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : (isDark ? const Color(0xFF2563EB).withValues(alpha: 0.3) : const Color(0xFFBFDBFE)),
                            ),
                          ),
                          child: Text(s.day,
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8)))),
                        ),
                      );
                    }).toList(),
                  ),

                  // 2 – Date selector
                  if (_selectedDay != null) ...[
                    const SizedBox(height: 18),
                    _sectionTitle('2. Pick a Date', isDark),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 70,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _upcomingDates(_selectedDay!).map((date) {
                          final isSelected = _selectedDate == date;
                          return GestureDetector(
                            onTap: () => setState(() { _selectedDate = date; _selectedSlot = null; }),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 60,
                              decoration: BoxDecoration(
                                gradient: isSelected ? LinearGradient(colors: grad) : null,
                                color: isSelected ? null : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? Colors.transparent : (isDark ? const Color(0xFF1E4976) : const Color(0xFFBFDBFE))),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(DateFormat('MMM').format(date),
                                      style: TextStyle(fontSize: 10,
                                          color: isSelected ? Colors.white70 : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)))),
                                  Text('${date.day}',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF1D4ED8)))),
                                  Text(DateFormat('EEE').format(date),
                                      style: TextStyle(fontSize: 10,
                                          color: isSelected ? Colors.white70 : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)))),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // 3 – Time slot
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 18),
                    _sectionTitle('3. Select a Time Slot', isDark),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: (expert.schedule
                              .firstWhere((s) => s.day == _selectedDay,
                                  orElse: () => ExpertScheduleDay(day: '', slots: []))
                              .slots)
                          .map((slot) {
                        final isSelected = _selectedSlot == slot;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedSlot = slot),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected ? LinearGradient(colors: grad) : null,
                              color: isSelected ? null : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : (isDark ? const Color(0xFF1E4976) : const Color(0xFFBFDBFE))),
                            ),
                            child: Row(children: [
                              Icon(Icons.access_time_rounded, size: 14,
                                  color: isSelected ? Colors.white : (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))),
                              const SizedBox(width: 6),
                              Text(slot,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8)))),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // 4 – Duration
                  if (_selectedSlot != null) ...[
                    const SizedBox(height: 18),
                    _sectionTitle('4. Duration', isDark),
                    const SizedBox(height: 10),
                    Row(
                      children: ['30', '60', '90', '120'].map((d) {
                        final isSelected = _duration == d;
                        return GestureDetector(
                          onTap: () => setState(() => _duration = d),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              gradient: isSelected ? LinearGradient(colors: grad) : null,
                              color: isSelected ? null : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : (isDark ? const Color(0xFF1E4976) : const Color(0xFFBFDBFE))),
                            ),
                            child: Text('$d min',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8)))),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 18),
                    _sectionTitle('5. Notes (optional)', isDark),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827)),
                      decoration: InputDecoration(
                        hintText: 'Topics you want to discuss, specific questions...',
                        hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Confirm button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: AnimatedOpacity(
                opacity: canConfirm ? 1.0 : 0.45,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: grad),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: canConfirm
                        ? [BoxShadow(color: grad.first.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))]
                        : [],
                  ),
                  child: ElevatedButton(
                    onPressed: (canConfirm && !_isSending) ? _confirmBooking : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSending
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('confirm_send_request'.tr,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Success overlay ───────────────────────────────────────────────────────────
  Widget _buildSuccessOverlay(bool isDark) {
    final expert   = _selectedExpert;
    final dateStr  = _selectedDate != null ? DateFormat('EEE, MMM d yyyy').format(_selectedDate!) : '';
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF132F4C) : Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 20),
                Text('session_requested'.tr,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  'Your request has been sent to ${expert?.name ?? 'the expert'}\non $dateStr at $_selectedSlot.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, height: 1.6,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.email_outlined, color: Color(0xFF059669), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A notification has been sent to the expert\'s university email.',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46)),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────────
  Widget _overlayWrap({required bool isDark, required Widget child}) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {}, // absorb taps
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D2137) : Colors.white,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 30)],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Expert expert, double size, List<Color> grad, double fontSize) {
    final assetPath = expert.image;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: grad.first.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipOval(
        child: assetPath.startsWith('assets/')
            ? Image.asset(assetPath, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsWidget(expert.initials, fontSize))
            : assetPath.startsWith('http')
                ? Image.network(assetPath, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initialsWidget(expert.initials, fontSize))
                : _initialsWidget(expert.initials, fontSize),
      ),
    );
  }

  Widget _initialsWidget(String initials, double fontSize) {
    return Center(
      child: Text(initials,
          style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildScheduleRow(ExpertScheduleDay day, List<Color> grad, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: grad),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(day.day,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: day.slots.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? const Color(0xFF1E4976) : const Color(0xFFBFDBFE)),
            ),
            child: Text(s,
                style: TextStyle(fontSize: 12,
                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w500)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _statChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF1E4976) : const Color(0xFFBFDBFE)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8)),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))),
      ]),
    );
  }

  Widget _sectionTitle(String text, bool isDark) {
    return Text(text,
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF111827)));
  }
}
