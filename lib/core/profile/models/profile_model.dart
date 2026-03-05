import '../../utils/data_utils.dart';

class ProfileModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String displayName;
  final String email;
  final String position;
  final String phone;
  final String phoneCode;
  final String photoUrl;
  final int updatedAtMs;

  ProfileModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.email,
    required this.position,
    required this.phone,
    required this.phoneCode,
    this.photoUrl = '',
    required this.updatedAtMs,
  });

  factory ProfileModel.fromMap(
    Map<String, dynamic> data,
    String uid, {
    String? authEmail,
    String? authDisplayName,
  }) {
    return ProfileModel(
      uid: uid,
      firstName: DataUtils.asString(data['firstName']),
      lastName: DataUtils.asString(data['lastName']),
      displayName: DataUtils.asString(
        data['displayName'],
        authDisplayName ?? 'User',
      ),
      email: DataUtils.asString(data['email'], authEmail ?? ''),
      position: DataUtils.asString(data['position']),
      phone: DataUtils.asString(data['phone']),
      phoneCode: DataUtils.asString(data['phoneCode']),
      photoUrl: DataUtils.asString(data['photoUrl']),
      updatedAtMs: DataUtils.asInt(data['updatedAtMs']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'displayName': displayName,
      'position': position,
      'phone': phone,
      'phoneCode': phoneCode,
      'photoUrl': photoUrl,
      'updatedAtMs': updatedAtMs,
    };
  }

  String get fullName {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    return firstName.isNotEmpty ? firstName : displayName;
  }
}
