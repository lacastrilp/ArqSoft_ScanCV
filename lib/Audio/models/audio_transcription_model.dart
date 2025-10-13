class AudioTranscription {
  final String id;
  final String cvId;
  final String audioUrl;
  final String? transcriptionText;
  final Map<String, dynamic>? aiAnalysis;
  final DateTime createdAt;

  AudioTranscription({
    required this.id,
    required this.cvId,
    required this.audioUrl,
    this.transcriptionText,
    this.aiAnalysis,
    required this.createdAt,
  });

  factory AudioTranscription.fromJson(Map<String, dynamic> json) =>
      AudioTranscription(
        id: json['id'].toString(),
        cvId: json['cvId'],
        audioUrl: json['audioUrl'],
        transcriptionText: json['transcriptionText'],
        aiAnalysis: json['aiAnalysis'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'cvId': cvId,
    'audioUrl': audioUrl,
    'transcriptionText': transcriptionText,
    'aiAnalysis': aiAnalysis,
    'createdAt': createdAt.toIso8601String(),
  };
}
