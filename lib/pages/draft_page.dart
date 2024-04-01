import 'dart:typed_data';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite/sqflite.dart';
import 'package:rostrenen_et_moi/models/anomaly.dart';
import 'package:rostrenen_et_moi/models/draft.dart';
import 'package:rostrenen_et_moi/pages/create_anomaly_page.dart';
import 'package:rostrenen_et_moi/pages/drafts_page.dart';

Future<Draft> _fetchDraft(Database database, int draftId) async {
  final draftsMaps = await database.query(
    'drafts',
    columns: ['id', 'address', 'description'],
    where: 'id = ?',
    whereArgs: [draftId],
  );
  final draftMap = draftsMaps[0];

  final directory = await getPhotosDirectory(draftId);
  final List<Uint8List> photos = [];
  if (await directory.exists()) {
    await for (var entity in directory.list(followLinks: false)) {
      if (entity is File) {
        final photo = await entity.readAsBytes();
        photos.add(photo);
      }
    }
  }

  return Draft(
    id: draftMap['id'] as int,
    address: draftMap['address'] as String,
    description: draftMap['description'] as String,
    photos: photos,
  );
}

class DraftPage extends StatefulWidget {
  const DraftPage({
    super.key,
    required this.database,
    required this.dio,
    required this.draftId,
  });

  final Database database;
  final Dio dio;
  final int draftId;

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  late Future<Draft> queryFuture;

  @override
  void initState() {
    super.initState();

    queryFuture = _fetchDraft(widget.database, widget.draftId);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder(
          future: queryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return buildLoading();
            }

            final error = snapshot.error;
            if (error != null) {
              throw error;
            }

            return buildForm(context, snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget buildForm(BuildContext context, Draft draft) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnomalyForm(
          initialDraft: draft,
          onSubmit: ({
            required Anomaly anomaly,
            required GlobalKey<FormBuilderState> formKey,
          }) async {
            await submitAnomaly(
              anomaly: anomaly,
              dio: widget.dio,
            );

            await deleteDraft(widget.database, widget.draftId);

            if (context.mounted) {
              context.go('/create');
            }
          },
          onDraft: ({
            required Anomaly draft,
            required GlobalKey<FormBuilderState> formKey,
          }) async {
            await widget.database.transaction((transaction) async {
              await transaction.update(
                'drafts',
                {
                  'address': draft.address,
                  'description': draft.description,
                },
                where: 'id = ?',
                whereArgs: [widget.draftId],
              );

              await storePhotos(widget.draftId, draft.photos);
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
