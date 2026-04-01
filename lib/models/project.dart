import 'ai_provider.dart';

class RoadmapItem {
  String title;
  String phase; // "MVP", "v1.0", "v2.0"
  int priority; // 1-3

  RoadmapItem({
    required this.title,
    required this.phase,
    required this.priority,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'phase': phase,
        'priority': priority,
      };

  factory RoadmapItem.fromJson(Map<String, dynamic> json) => RoadmapItem(
        title: json['title'] as String,
        phase: json['phase'] as String,
        priority: json['priority'] as int,
      );
}

class AppProject {
  String id;
  String name;
  String description;
  List<String> features;
  List<String> userStories;
  List<RoadmapItem> roadmap;
  DateTime createdAt;
  AIProviderType? providerUsed;

  AppProject({
    required this.id,
    required this.name,
    required this.description,
    List<String>? features,
    List<String>? userStories,
    List<RoadmapItem>? roadmap,
    required this.createdAt,
    this.providerUsed,
  })  : features = features ?? [],
        userStories = userStories ?? [],
        roadmap = roadmap ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'features': features,
        'userStories': userStories,
        'roadmap': roadmap.map((r) => r.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'providerUsed': providerUsed?.name,
      };

  factory AppProject.fromJson(Map<String, dynamic> json) => AppProject(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        features: List<String>.from(json['features'] as List),
        userStories: List<String>.from(json['userStories'] as List),
        roadmap: (json['roadmap'] as List)
            .map((r) => RoadmapItem.fromJson(r as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        providerUsed: json['providerUsed'] != null
            ? AIProviderType.values.firstWhere(
                (e) => e.name == json['providerUsed'],
                orElse: () => AIProviderType.openai,
              )
            : null,
      );
}
