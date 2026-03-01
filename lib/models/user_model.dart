class UserModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Convert from Google Sheets row (List of values)
  factory UserModel.fromSheetRow(List<dynamic> row) {
    return UserModel(
      id: row.isNotEmpty ? row[0].toString() : '',
      name: row.length > 1 ? row[1].toString() : '',
      address: row.length > 2 ? row[2].toString() : '',
      phone: row.length > 3 ? row[3].toString() : '',
      createdAt: row.length > 4 && row[4].toString().isNotEmpty
          ? DateTime.tryParse(row[4].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: row.length > 5 && row[5].toString().isNotEmpty
          ? DateTime.tryParse(row[5].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // Convert to Google Sheets row
  List<dynamic> toSheetRow() {
    return [
      id,
      name,
      address,
      phone,
      createdAt.toIso8601String(),
      updatedAt.toIso8601String(),
    ];
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, address: $address, phone: $phone)';
  }
}
