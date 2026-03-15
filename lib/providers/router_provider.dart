import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pages/matrix_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MatrixPage(),
        routes: [
          GoRoute(
            path: 'technique/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              return MatrixPage(initialTechniqueId: id);
            },
          ),
        ],
      ),
    ],
  );
});
