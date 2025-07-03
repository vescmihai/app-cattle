import 'package:app_p3topicos/screens/bienvenida.screen.dart';
import 'package:app_p3topicos/screens/capturaFrames.screen.dart';
import 'package:app_p3topicos/screens/resultadoBusqueda.screen.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/capturaFrames',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const BienvenidaScreen()),
    GoRoute(
      path: '/capturaFrames',
      builder: (context, state) => const CapturaFrameScreen(),
    ),
    GoRoute(
      path: '/resultado',
      builder: (context, state) => const ResultadoBusquedaScreen(),
    ),
  ],
);
