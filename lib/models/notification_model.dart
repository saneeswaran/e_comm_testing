class NotificationModel {
  final String? id;
  final String? title;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;

  const NotificationModel(
      {required this.id,
      required this.title,
      required this.description,
      required this.imageUrl,
      required this.createdAt});

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
        id: json['_id'],
        title: json['title'],
        description: json['description'],
        imageUrl: json['imageUrl'],
        createdAt: DateTime.parse(json['createdAt']));
  }
}
