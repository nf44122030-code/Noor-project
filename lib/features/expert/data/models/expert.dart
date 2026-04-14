class ExpertScheduleDay {
  final String day;
  final List<String> slots;

  ExpertScheduleDay({required this.day, required this.slots});

  factory ExpertScheduleDay.fromJson(Map<String, dynamic> json) {
    List<String> parsedSlots = [];
    if (json['slots'] is List) {
      parsedSlots = (json['slots'] as List).map((e) => e.toString()).toList();
    }
    return ExpertScheduleDay(
      day: json['day']?.toString() ?? '',
      slots: parsedSlots,
    );
  }
}

class Expert {
  final String id;
  final String name;
  final String email;
  final String title;
  final String specialty;
  final double rating;
  final int reviews;
  final int hourlyRate;
  final String image;
  final String availability;
  final int yearsExperience;
  final int sessionsCompleted;
  final String bio;
  final List<ExpertScheduleDay> schedule;

  Expert({
    required this.id,
    required this.name,
    required this.email,
    required this.title,
    required this.specialty,
    required this.rating,
    required this.reviews,
    required this.hourlyRate,
    required this.image,
    required this.availability,
    required this.yearsExperience,
    required this.sessionsCompleted,
    required this.bio,
    required this.schedule,
  });

  factory Expert.fromJson(Map<String, dynamic> json) {
    return Expert(
      id:                (json['id'] ?? '').toString(),
      name:              json['name']?.toString() ?? '',
      email:             json['email']?.toString() ?? '',
      title:             json['title']?.toString() ?? '',
      specialty:         json['specialty']?.toString() ?? '',
      rating:            double.tryParse((json['rating'] ?? 0).toString()) ?? 0.0,
      reviews:           int.tryParse((json['reviews'] ?? 0).toString()) ?? 0,
      hourlyRate:        int.tryParse((json['hourly_rate'] ?? json['hourlyRate'] ?? 0).toString()) ?? 0,
      image:             json['image']?.toString() ?? '',
      availability:      json['availability']?.toString() ?? 'Available',
      yearsExperience:   int.tryParse((json['years_experience'] ?? json['yearsExperience'] ?? 0).toString()) ?? 0,
      sessionsCompleted: int.tryParse((json['sessions_completed'] ?? json['sessionsCompleted'] ?? 0).toString()) ?? 0,
      bio:               json['bio']?.toString() ?? '',
      schedule: () {
        final schedRaw = json['schedule'];
        if (schedRaw is List) {
          try {
            return schedRaw
                .map((s) => ExpertScheduleDay.fromJson(Map<String, dynamic>.from(s as Map)))
                .toList();
          } catch (e) {
            return <ExpertScheduleDay>[];
          }
        }
        return <ExpertScheduleDay>[];
      }(),
    );
  }

  /// Returns the initials for use in the avatar placeholder.
  String get initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    if (parts.isNotEmpty) return parts.first[0].toUpperCase();
    return '?';
  }
}
