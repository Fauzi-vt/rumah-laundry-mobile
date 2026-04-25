class UserModel {
  final int     id;
  final String  name;
  final String  email;
  final String? phone;
  final String? address;
  final String? role;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id:      j['id']      as int,
        name:    j['name']    as String,
        email:   j['email']   as String,
        phone:   j['phone']   as String?,
        address: j['address'] as String?,
        role:    j['role']    as String?,
      );

  Map<String, dynamic> toJson() => {
        'id':      id,
        'name':    name,
        'email':   email,
        'phone':   phone,
        'address': address,
        'role':    role,
      };
}
