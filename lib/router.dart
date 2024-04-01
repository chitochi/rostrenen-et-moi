import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:rostrenen_et_moi/app_scaffold.dart';
import 'package:rostrenen_et_moi/pages/create_anomaly_page.dart';
import 'package:rostrenen_et_moi/pages/drafts_page.dart';
import 'package:rostrenen_et_moi/pages/draft_page.dart';
import 'package:sqflite/sqflite.dart';

GoRouter createRouter({
  required Database database,
  required Dio dio,
}) {
  return GoRouter(
    initialLocation: '/create',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppScaffold(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/create',
            builder: (context, state) => CreateAnomalyPage(
              database: database,
              dio: dio,
            ),
          ),
          GoRoute(
            path: '/drafts',
            builder: (context, state) => DraftsPage(
              database: database,
            ),
          ),
          GoRoute(
            path: '/drafts/:draftId',
            builder: (context, state) => DraftPage(
              database: database,
              dio: dio,
              draftId: int.parse(state.pathParameters['draftId']!),
            ),
          ),
        ],
      )
    ],
  );
}
