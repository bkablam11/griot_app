import 'package:hive/hive.dart';

part 'story_model.g.dart'; // On générera ce fichier plus tard pour Hive

@HiveType(typeId: 0)
class StoryModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String elderName;
  @HiveField(3)
  final String language;
  @HiveField(4)
  final String audioUrl; // URL Supabase
  @HiveField(5)
  final String summary;
  @HiveField(6)
  final DateTime createdAt;

  StoryModel({
    required this.id,
    required this.title,
    required this.elderName,
    required this.language,
    required this.audioUrl,
    required this.summary,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'elderName': elderName,
      'language': language,
      'audioUrl': audioUrl,
      'summary': summary,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
