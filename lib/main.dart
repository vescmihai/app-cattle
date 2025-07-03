import 'package:app_p3topicos/app.router.dart';
import 'package:app_p3topicos/bloc/asistente/asistente_bloc.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const colorPrimario = Color(0xFF2C473E);
const colorSecundario = Color(0xFF6A8E4E);
const colorTerciario = Color(0xFFB0D182);
const colorCuaternario = Color(0xFFF4F1EA);

List<CameraDescription> camarasDisponibles = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    camarasDisponibles = await availableCameras();
  } catch (e) {
    print('Error al obtener cámaras: $e');
  }

  runApp(
    MultiBlocProvider(
      providers: [BlocProvider(create: (context) => AsistenteBloc())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
