import 'cv_section_model.dart';

class CV {
  final String id;
  final String title;
  final String ownerId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPublic;
  final List<CVSection> sections;

  CV({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.createdAt,
    this.updatedAt,
    this.isPublic = false,
    this.sections = const [],
  });

  factory CV.fromJson(Map<String, dynamic> json) => CV(
    id: json['id'].toString(),
    title: json['title'],
    ownerId: json['ownerId'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : null,
    isPublic: json['isPublic'] ?? false,
    sections: (json['sections'] as List<dynamic>?)
        ?.map((s) => CVSection.fromJson(s))
        .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'ownerId': ownerId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'isPublic': isPublic,
    'sections': sections.map((s) => s.toJson()).toList(),
  };
}
