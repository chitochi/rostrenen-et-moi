import 'dart:typed_data';

class Draft {
  const Draft({
    required this.id,
    required this.address,
    required this.description,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.photos,
  });

  final int id;
  final String address;
  final String description;
  final String fullName;
  final String email;
  final String phoneNumber;
  final List<Uint8List> photos;
}
