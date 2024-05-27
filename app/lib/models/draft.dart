import 'dart:typed_data';

class Draft {
  const Draft({
    required this.id,
    required this.address,
    required this.description,
    required this.photos,
  });

  final int id;
  final String address;
  final String description;
  final List<Uint8List> photos;
}
