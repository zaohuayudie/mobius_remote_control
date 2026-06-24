class User {
  final String? id;
  final String username;
  final int status;

  const User({
    this.id,
    required this.username,
    this.status = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id']?.toString(),
        username: json['username'] as String,
        status: json['status'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'username': username,
        'status': status,
      };
}