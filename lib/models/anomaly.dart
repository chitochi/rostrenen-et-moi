import 'dart:typed_data';

class Anomaly {
  const Anomaly({
    required this.address,
    required this.description,
    required this.photos,
  });

  final String address;
  final String description;
  final List<Uint8List> photos;
}
