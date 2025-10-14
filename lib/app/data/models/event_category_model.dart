class EventCategory {
  final String id;
  final String title;
  final String? iconUrl;
  final String? bannerUrl;

  EventCategory({
    required this.id,
    required this.title,
    this.iconUrl,
    this.bannerUrl,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      iconUrl: json['iconUrl'],
      bannerUrl: json['bannerUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'iconUrl': iconUrl,
      'bannerUrl': bannerUrl,
    };
  }
}
