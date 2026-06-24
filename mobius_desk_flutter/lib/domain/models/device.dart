class Device {
  final String? id;
  final String uuid;
  final String? password;
  final String? userId;
  final int status;
  final bool online;

  const Device({
    this.id,
    required this.uuid,
    this.password,
    this.userId,
    this.status = 0,
    this.online = false,
  });

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        id: json['id']?.toString(),
        uuid: (json['uuid'] ?? '').toString(),
        password: json['password']?.toString(),
        userId: json['user_id']?.toString(),
        status: json['status'] is int ? json['status'] as int : (json['status'] == true || json['status'] == '1' ? 1 : 0),
        online: json['online'] is bool ? json['online'] as bool : (json['online'] == 1 || json['online'] == 'true'),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'uuid': uuid,
        if (password != null) 'password': password,
        if (userId != null) 'user_id': userId,
        'status': status,
        'online': online,
      };
}