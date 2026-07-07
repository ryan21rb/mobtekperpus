class Materi {
  final int id;
  final String title;
  final String description;
  final String image;

  Materi({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
  });

  factory Materi.fromJson(Map<String, dynamic> json) {
    return Materi(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      // Menjaga jika field image di database bernilai null
      image: json['image'] ?? '',
    );
  }
}
