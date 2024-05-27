import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_image_picker/form_builder_image_picker.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:rostrenen_et_moi/models/anomaly.dart';
import 'package:rostrenen_et_moi/models/draft.dart';
import 'package:sqflite/sqflite.dart';

Future<Directory> getPhotosDirectory(int draftId) async {
  final appDirectory = await getApplicationDocumentsDirectory();
  final directory = Directory(path.join(appDirectory.path, '$draftId'));

  return directory;
}

Future<void> storePhotos(int draftId, List<Uint8List> photos) async {
  final directory = await getPhotosDirectory(draftId);
  if (await directory.exists()) {
    await directory.delete(recursive: true);
  }
  await directory.create();

  for (var i = 0; i < photos.length; i++) {
    final file = File(path.join(directory.path, '$i'));

    await file.writeAsBytes(photos[i]);
  }
}

class CreateAnomalyPage extends StatelessWidget {
  const CreateAnomalyPage({
    super.key,
    required this.database,
    required this.dio,
  });

  final Database database;
  final Dio dio;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AnomalyForm(
          onSubmit: ({
            required Anomaly anomaly,
            required GlobalKey<FormBuilderState> formKey,
          }) async {
            await submitAnomaly(
              anomaly: anomaly,
              dio: dio,
            );

            formKey.currentState?.reset();
          },
          onDraft: ({
            required Anomaly draft,
            required GlobalKey<FormBuilderState> formKey,
          }) async {
            await database.transaction((transaction) async {
              final draftId = await transaction.insert('drafts', {
                'address': draft.address,
                'description': draft.description,
              });

              await storePhotos(draftId, draft.photos);
            });

            if (context.mounted) {
              context.go('/drafts');
            }
          },
        ),
      ),
    );
  }
}

Future<void> submitAnomaly({
  required Anomaly anomaly,
  required Dio dio,
}) async {
  final Map<String, dynamic> data = {
    'address': anomaly.address,
    'description': anomaly.description,
  };

  final List<MultipartFile> photos = [];
  if (anomaly.photos.isNotEmpty) {
    for (var i = 0; i < anomaly.photos.length; i++) {
      photos.add(MultipartFile.fromBytes(
        anomaly.photos[i],
        filename: 'photo_$i.jpg',
      ));
    }
  }
  data['photos'] = photos;

  final formData = FormData.fromMap(data);

  await dio.post(
    'https://rostrenen-et-moi.rostrenen.bzh/anomalies/api/anomalies',
    data: formData,
  );
}

class AnomalyForm extends StatefulWidget {
  const AnomalyForm({
    super.key,
    this.initialDraft,
    required this.onSubmit,
    required this.onDraft,
  });

  final Draft? initialDraft;
  final FutureOr<void> Function({
    required Anomaly anomaly,
    required GlobalKey<FormBuilderState> formKey,
  }) onSubmit;
  final FutureOr<void> Function({
    required Anomaly draft,
    required GlobalKey<FormBuilderState> formKey,
  }) onDraft;

  @override
  State<AnomalyForm> createState() => _AnomalyFormState();
}

class _AnomalyFormState extends State<AnomalyForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  var submitting = false;

  Future<List<Uint8List>> getPhotos(dynamic formValue) async {
    Future<Uint8List> processPhoto(XFile photo) async {
      final bytes = await photo.readAsBytes();

      return await FlutterImageCompress.compressWithList(
        bytes,
        format: CompressFormat.jpeg,
        quality: 70,
      );
    }

    final files = (formValue as List<dynamic>?)
            ?.map((photo) => photo as XFile)
            .toList() ??
        [];

    final photos = await Future.wait(files.map(processPhoto));

    return photos;
  }

  Future<Anomaly?> validateForm() async {
    final currentState = _formKey.currentState;
    if (currentState == null) {
      return null;
    }

    final valid = currentState.saveAndValidate();
    if (!valid) {
      return null;
    }

    final value = currentState.value;

    return Anomaly(
      address: value['address'],
      description: value['description'],
      photos: await getPhotos(value['photos']),
    );
  }

  Future<Anomaly?> getDraft() async {
    final currentState = _formKey.currentState;
    if (currentState == null) {
      return null;
    }

    currentState.save();

    final value = currentState.value;

    return Anomaly(
      address: value['address'] ?? '',
      description: value['description'] ?? '',
      photos: await getPhotos(value['photos']),
    );
  }

  Future<void> submit() async {}

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      initialValue: {
        'address': widget.initialDraft?.address,
        'description': widget.initialDraft?.description,
        'photos': widget.initialDraft?.photos
            .map((photo) => XFile.fromData(photo))
            .toList(),
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AddressField(formKey: _formKey),
          const SizedBox(height: 12),
          FormBuilderImagePicker(
            name: 'photos',
            decoration: const InputDecoration(
              border: InputBorder.none,
              labelText: 'Photos',
            ),
          ),
          const SizedBox(height: 12),
          FormBuilderTextField(
            name: 'description',
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: null,
            validator: FormBuilderValidators.required(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: submitting
                    ? null
                    : () async {
                        final anomaly = await validateForm();
                        if (anomaly == null) {
                          return;
                        }

                        setState(() => submitting = true);
                        try {
                          await widget.onSubmit(
                            anomaly: anomaly,
                            formKey: _formKey,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('L\'anomalie a bien été signalée.'),
                            ));
                          }
                        } finally {
                          setState(() => submitting = false);
                        }
                      },
                child: ProgressSuffix(
                  loading: submitting,
                  child: const Text('Signaler'),
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  final draft = await getDraft();
                  if (draft == null) {
                    return;
                  }

                  await widget.onDraft(
                    draft: draft,
                    formKey: _formKey,
                  );
                },
                child: const Text('Enregistrer comme brouillon'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddressField extends StatefulWidget {
  const AddressField({
    super.key,
    required this.formKey,
  });

  final GlobalKey<FormBuilderState> formKey;

  @override
  State<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> {
  Future<void>? fillAddressFuture;

  Future<void> fillAddress() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location services are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    final position = await Geolocator.getCurrentPosition();

    await setLocaleIdentifier('fr_FR');

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isEmpty) {
      throw Exception('No placemark found.');
    }

    final placemark = placemarks[0];

    final formState = widget.formKey.currentState;
    if (formState == null) {
      throw Exception('No form state.');
    }

    final address =
        '${placemark.street}, ${placemark.postalCode} ${placemark.locality}';
    formState.fields['address']?.didChange(address);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fillAddressFuture,
      builder: (_, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormBuilderTextField(
              readOnly: loading,
              name: 'address',
              decoration: const InputDecoration(
                labelText: 'Adresse',
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.required(),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: loading
                  ? null
                  : () {
                      setState(() {
                        fillAddressFuture = fillAddress();
                      });
                    },
              child: ProgressSuffix(
                loading: loading,
                child: const Text('Remplir avec ma position'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ProgressSuffix extends StatelessWidget {
  const ProgressSuffix({
    super.key,
    required this.child,
    required this.loading,
  });

  final Widget child;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        if (loading) ...[
          const SizedBox(width: 12),
          const SizedBox(
            height: 12,
            width: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ],
      ],
    );
  }
}
