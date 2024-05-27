import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite/sqflite.dart';
import 'package:rostrenen_et_moi/models/draft.dart';
import 'package:rostrenen_et_moi/pages/create_anomaly_page.dart';

Future<List<Draft>> _fetchDraftsWithoutPhotos(Database database) async {
  final draftsMaps = await database.query(
    'drafts',
    columns: ['id', 'address', 'description'],
    orderBy: 'id DESC',
  );

  return draftsMaps
      .map((draftMap) => Draft(
            id: draftMap['id'] as int,
            address: draftMap['address'] as String,
            description: draftMap['description'] as String,
            photos: [],
          ))
      .toList();
}

class DraftsPage extends StatefulWidget {
  const DraftsPage({
    super.key,
    required this.database,
  });

  final Database database;

  @override
  State<DraftsPage> createState() => _DraftsPageState();
}

class _DraftsPageState extends State<DraftsPage> {
  late Future<List<Draft>> queryFuture;

  @override
  void initState() {
    super.initState();

    queryFuture = _fetchDraftsWithoutPhotos(widget.database);
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

            return buildDrafts(snapshot.data ?? []);
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

  Widget buildEmpty() {
    return const Center(
      child: Text('Pas de brouillons.'),
    );
  }

  Widget buildDrafts(List<Draft> drafts) {
    if (drafts.isEmpty) {
      return const Center(
        child: Text('Pas de brouillon enregistré.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < drafts.length; i++) ...[
          if (i != 0) const SizedBox(height: 10),
          DraftCard(
            draft: drafts[i],
            onDelete: () async {
              final draft = drafts[i];

              await deleteDraft(widget.database, draft.id);

              setState(() {
                queryFuture = _fetchDraftsWithoutPhotos(widget.database);
              });
            },
          ),
        ],
      ],
    );
  }
}

Future<void> deleteDraft(Database database, int draftId) async {
  await database.transaction((tx) async {
    await tx.delete(
      'drafts',
      where: 'id = ?',
      whereArgs: [draftId],
    );

    final directory = await getPhotosDirectory(draftId);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });
}

class DraftCard extends StatelessWidget {
  const DraftCard({
    super.key,
    required this.draft,
    required this.onDelete,
  });

  final Draft draft;
  final FutureOr<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/drafts/${draft.id}'),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Brouillon ${draft.id}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              Text(
                draft.address.isNotEmpty
                    ? draft.address
                    : 'Pas d\'adresse dans ce brouillon.',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                draft.description.isNotEmpty
                    ? draft.description
                    : 'Pas de description dans ce brouillon.',
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onDelete,
                    child: const Text('Supprimer'),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go('/drafts/${draft.id}');
                    },
                    child: const Text('Reprendre'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
