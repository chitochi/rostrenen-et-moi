import 'dart:typed_data';

class Anomaly {
  const Anomaly({
    required this.address,
    required this.description,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.photos,
  });

  final String address;
  final String description;
  final String fullName;
  final String email;
  final String phoneNumber;
  final List<Uint8List> photos;
}
