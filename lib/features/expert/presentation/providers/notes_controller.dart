import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/note_model.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class NotesController extends GetxController {
  final RxList<SessionNote> _sessionNotes = <SessionNote>[].obs;
  final RxList<NoteDetail> _currentSessionNotes = <NoteDetail>[].obs;
  final RxBool isRecording = false.obs;
  
  static const String _notesKey = 'saved_session_notes';

  List<SessionNote> get sessionNotes => _sessionNotes;
  List<NoteDetail> get currentSessionNotes => _currentSessionNotes;

  @override
  void onInit() {
    super.onInit();
    _loadNotes();
  }

  SessionNote? getSessionById(String id) {
    try {
      return _sessionNotes.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notesJson = prefs.getString(_notesKey);
    if (notesJson != null) {
      final List<dynamic> decoded = jsonDecode(notesJson);
      _sessionNotes.assignAll(decoded.map((item) => SessionNote.fromJson(item)).toList());
    }
  }

  void startRecording() {
    _currentSessionNotes.clear();
    isRecording.value = true;
  }

  void stopRecording() {
    isRecording.value = false;
  }

  void addGeneratedNote(String content) {
    if (!isRecording.value) return;

    final newNote = NoteDetail(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      speaker: "AI Assistant generated this note insight",
      content: content.replaceAll('*', '').trim(),
      type: 'key-point',
    );
    // Add to top of current notes
    _currentSessionNotes.insert(0, newNote);
  }

  Future<SessionNote> saveSession({
    String? id,
    required String expertName,
    required String expertTitle,
    required int duration,
    String? aiContent,
  }) async {
    final cleanedAiContent = aiContent?.replaceAll('*', '').trim();
    
    final session = SessionNote(
      id: id ?? const Uuid().v4(),
      expertName: expertName,
      expertTitle: expertTitle,
      sessionDate: DateTime.now(),
      duration: duration,
      notes: List<NoteDetail>.from(_currentSessionNotes),
      summary: _generateSummary(),
      aiContent: cleanedAiContent,
    );

    _sessionNotes.add(session);
    await _saveNotes();
    _currentSessionNotes.clear();
    isRecording.value = false;
    
    return session;
  }

  String _generateSummary() {
    if (_currentSessionNotes.isEmpty) return 'No notes captured during this session.';
    
    final topics = _currentSessionNotes.take(3).map((n) => n.content).join(' ');
    return 'Detailed discussion covering: ${topics.length > 100 ? '${topics.substring(0, 100)}...' : topics}';
  }

  Future<void> deleteSession(String id) async {
    _sessionNotes.removeWhere((s) => s.id == id);
    await _saveNotes();
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_sessionNotes.map((s) => s.toJson()).toList());
    await prefs.setString(_notesKey, encoded);
  }
}
