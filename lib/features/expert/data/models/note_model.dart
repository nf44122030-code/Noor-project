
class SessionNote {
  final String id;
  final String expertName;
  final String expertTitle;
  final DateTime sessionDate;
  final int duration; // in seconds
  final List<NoteDetail> notes;
  final String summary;
  final String? aiContent;

  SessionNote({
    required this.id,
    required this.expertName,
    required this.expertTitle,
    required this.sessionDate,
    required this.duration,
    required this.notes,
    required this.summary,
    this.aiContent,
  });

  factory SessionNote.fromJson(Map<String, dynamic> json) => _$SessionNoteFromJson(json);
  Map<String, dynamic> toJson() => _$SessionNoteToJson(sessionNote: this);
}

class NoteDetail {
  final String id;
  final DateTime timestamp;
  final String speaker;
  final String content;
  final String type; // key-point, action-item, etc.
  final String aiInsight;

  NoteDetail({
    required this.id,
    required this.timestamp,
    required this.speaker,
    required this.content,
    required this.type,
    this.aiInsight = '',
  });

  factory NoteDetail.fromJson(Map<String, dynamic> json) => _$NoteDetailFromJson(json);
  Map<String, dynamic> toJson() => _$NoteDetailToJson(noteDetail: this);
}

// Manual JSON methods to avoid build_runner dependency for this quick migration
SessionNote _$SessionNoteFromJson(Map<String, dynamic> json) => SessionNote(
      id: json['id'] as String,
      expertName: json['expertName'] as String,
      expertTitle: json['expertTitle'] as String,
      sessionDate: DateTime.parse(json['sessionDate'] as String),
      duration: (json['duration'] as num).toInt(),
      notes: (json['notes'] as List<dynamic>)
          .map((e) => NoteDetail.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] as String,
      aiContent: json['aiContent'] as String?,
    );

Map<String, dynamic> _$SessionNoteToJson({required SessionNote sessionNote}) => <String, dynamic>{
      'id': sessionNote.id,
      'expertName': sessionNote.expertName,
      'expertTitle': sessionNote.expertTitle,
      'sessionDate': sessionNote.sessionDate.toIso8601String(),
      'duration': sessionNote.duration,
      'notes': sessionNote.notes.map((e) => e.toJson()).toList(),
      'summary': sessionNote.summary,
      'aiContent': sessionNote.aiContent,
    };

NoteDetail _$NoteDetailFromJson(Map<String, dynamic> json) => NoteDetail(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      speaker: json['speaker'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      aiInsight: json['aiInsight'] as String? ?? '',
    );

Map<String, dynamic> _$NoteDetailToJson({required NoteDetail noteDetail}) => <String, dynamic>{
      'id': noteDetail.id,
      'timestamp': noteDetail.timestamp.toIso8601String(),
      'speaker': noteDetail.speaker,
      'content': noteDetail.content,
      'type': noteDetail.type,
      'aiInsight': noteDetail.aiInsight,
    };
