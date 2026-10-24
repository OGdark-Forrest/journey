class UserInfo {
  final int? id;
  final String name;
  final int age;
  final String gender;
  final String employmentStatus;

  const UserInfo({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.employmentStatus,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'age': age,
        'gender': gender,
        'employmentStatus': employmentStatus,
      };

  factory UserInfo.fromMap(Map<String, dynamic> map) => UserInfo(
        id: map['id'] as int?,
        name: map['name'] as String,
        age: map['age'] as int,
        gender: map['gender'] as String,
        employmentStatus: map['employmentStatus'] as String,
      );
}
