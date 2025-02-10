class Note {
  String id;
  String title;
  String content;
  DateTime lastModified;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.lastModified,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      lastModified: DateTime.parse(json['lastModified']),
    );
  }
}
