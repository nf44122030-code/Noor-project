class Message {
  final String id;
  final String type; // 'ai' or 'user'
  final String text;
  final String time;
  final bool hasAttachments;

  Message({
    required this.id,
    required this.type,
    required this.text,
    required this.time,
    this.hasAttachments = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: (json['id'] ?? '').toString(),
      type: (json['role'] ?? json['type'] ?? 'ai').toString(),
      text: (json['content'] ?? json['text'] ?? '').toString(),
      time: json['created_at']?.toString() ?? json['time']?.toString() ?? '',
      hasAttachments: json['has_attachments'] == true,
    );
  }

  /// Returns true when this message's text contains at least one pipe-table row.
  bool get containsTable {
    final lines = text.split('\n');
    // A table needs at least a header row and a separator row
    int pipeLines = 0;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('|') && trimmed.endsWith('|')) {
        pipeLines++;
        if (pipeLines >= 2) return true;
      }
    }
    return false;
  }
}
