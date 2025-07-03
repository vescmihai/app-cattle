import 'dart:async';

import 'package:app_p3topicos/bloc/asistente/asistente_bloc.dart';
import 'package:app_p3topicos/main.dart';
import 'package:app_p3topicos/services/analisisImagen.service.dart';
import 'package:app_p3topicos/widgets/botonPersonalizado.widget.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class CapturaFrameScreen extends StatefulWidget {
  const CapturaFrameScreen({super.key});

  @override
  State<CapturaFrameScreen> createState() => _CapturaFrameScreenState();
}

class _CapturaFrameScreenState extends State<CapturaFrameScreen> {
  // Controladores de cámara y estado
  late AsistenteBloc asistenteBloc;
  CameraController? controladorCamara;
  bool camaraLista = false;
  bool capturando = false;
  bool inicializando = false;
  bool usandoCamaraFrontal = false;
  List<Timer> consultas = [];
  bool haNavegado = false;

  // Lista de frames capturados y estado
  String mensajeEstado = "Presiona el botón de cámara para iniciar";
  
  int framesCapturadasActual = 0;
  static const int maxFrames = 50;

  double probabilidadAnalisis = 51.0; // Valor por defecto para confiabilidad

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mover aquí la inicialización del bloc
    asistenteBloc = BlocProvider.of<AsistenteBloc>(context);
  }

  @override
  void dispose() {
    print("🔴 DISPOSE: Limpiando todos los recursos de CapturaFrameScreen");
    _limpiarTodosLosRecursos();
    super.dispose();
  }

  void _limpiarTodosLosRecursos() {
    // Cancelar todos los timers
    for (Timer temporizador in consultas) {
      if (temporizador.isActive) {
        temporizador.cancel();
        print("⏹️ Timer cancelado");
      }
    }
    consultas.clear();

    // Limpiar cámara
    if (controladorCamara != null) {
      controladorCamara!.dispose();
      controladorCamara = null;
      print("📷 Cámara liberada");
    }

    // Resetear flags
    haNavegado = false;
    capturando = false;
    camaraLista = false;
    framesCapturadasActual = 0; 
  }

  /// Inicializa la cámara y solicita permisos necesarios
  Future<void> iniciarCamara() async {
    if (inicializando) return;

    setState(() {
      inicializando = true;
      mensajeEstado = "Inicializando cámara...";
      framesCapturadasActual = 0; 
    });

    try {
      // Solicitar permisos de cámara
      var estadoPermiso = await Permission.camera.request();
      if (estadoPermiso != PermissionStatus.granted) {
        setState(() {
          mensajeEstado = "Permiso de cámara denegado";
          inicializando = false;
        });
        return;
      }

      // Verificar disponibilidad de cámaras
      if (camarasDisponibles.isEmpty) {
        setState(() {
          mensajeEstado = "No hay cámaras disponibles";
          inicializando = false;
        });
        return;
      }

      // Seleccionar cámara (trasera por defecto)
      CameraDescription camaraSeleccionada = camarasDisponibles.first;
      for (var camara in camarasDisponibles) {
        if (camara.lensDirection ==
            (usandoCamaraFrontal
                ? CameraLensDirection.front
                : CameraLensDirection.back)) {
          camaraSeleccionada = camara;
          break;
        }
      }

      // Inicializar controlador de cámara
      controladorCamara = CameraController(
        camaraSeleccionada,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controladorCamara!.initialize();

      setState(() {
        camaraLista = true;
        inicializando = false;
        mensajeEstado = "Cámara lista - Iniciando captura automática...";
      });

      await Future.delayed(Duration(milliseconds: 500));
      if (mounted && !haNavegado) {
        capturarFramesAutomatico();
      }
    } catch (e) {
      setState(() {
        mensajeEstado = "Error al inicializar la cámara: $e";
        inicializando = false;
      });
    }
  }

  /// Captura frames automáticamente según el número configurado
  Future<void> capturarFramesAutomatico() async {
    if (!camaraLista || capturando) return;
    haNavegado = false;
    setState(() {
      capturando = true;
      mensajeEstado = "Capturando frames...";
      framesCapturadasActual = 0; // 🆕 Reiniciar contador
    });

    int contador = 0;

    while (capturando && contador < maxFrames) {
      try {
        if (controladorCamara != null &&
            controladorCamara!.value.isInitialized) {
          final imagen = await controladorCamara!.takePicture();

          
          setState(() {
            framesCapturadasActual = contador + 1;
            mensajeEstado = "Buscando... ${framesCapturadasActual} intentos";
          });

          var idTransaccion = await AnalisisImagenService.enviarImagen(
            imagen,
            probabilidadAnalisis,
          );

          if (idTransaccion != null) {
            Timer temporizadorConsulta = Timer.periodic(Duration(milliseconds: 1500), (
              timer,
            ) async {
              if (haNavegado || !mounted) {
                timer.cancel();
                return;
              }

              // Consultar el estado del análisis
              RespuestaClasificacion? procesamiento =
                  await AnalisisImagenService.consultarResultado(idTransaccion);

              if (procesamiento != null) {
                // Terminar temporizador
                timer.cancel();
                consultas.remove(timer);
                print(
                  "✅ Procesamiento completado: ${procesamiento.clasificaciones}",
                );

                // 🎯 AQUÍ PONES TU LÓGICA DE PARADA
                if (verificarRespuesta(procesamiento.clasificaciones)) {
                  setState(() {
                    mensajeEstado = "Análisis completado - Navegando...";
                  });
                } else {
                  print("⏳ Procesamiento aún en curso...");
                  setState(() {
                    mensajeEstado = "Procesamiento en curso...";
                  });
                }

                if (verificarRespuesta(procesamiento.clasificaciones)) {
                  if (!haNavegado && mounted) {
                    haNavegado = true;
                    print("✅ Navegando a resultado...");

                    // PRIMERO detener todo
                    _detenerTodoYTerminar();

                    // LUEGO actualizar el bloc
                    asistenteBloc.add(
                      OnChangeConfiabilidadAnalisis(probabilidadAnalisis),
                    );
                    asistenteBloc.add(
                      OnChagendRespuestaClasificacion(procesamiento),
                    );

                    // FINALMENTE navegar con delay
                    await Future.delayed(Duration(milliseconds: 100));
                    if (mounted) {
                      context.push('/resultado');
                    }
                  }
                  return;
                }
              }
            });

            consultas.add(temporizadorConsulta);
          }

          contador++;

          if (contador < maxFrames) {
            await Future.delayed(Duration(milliseconds: 300));
          }
        }
      } catch (e) {
        setState(() {
          mensajeEstado = "Error capturando frame: $e";
          capturando = false;
        });
        break;
      }
    }

    // ✅ LLEGÓ AL MÁXIMO → LIMPIAR TODO Y EMPEZAR DE NUEVO
    if (contador >= maxFrames) {
      _detenerTodoYReiniciar();
    }
  }

  // Metodo : Terminar de capturar Frames y Eliminar todos los temporizadores activos en el "consultas"
  void _detenerTodoYTerminar() {
    for (Timer temporizador in consultas) {
      temporizador.cancel();
    }
    consultas.clear();
    setState(() {
      capturando = false;
      mensajeEstado = "Análisis exitoso - Terminado";
    });
  }

  // Método: Limpiar todo y reiniciar automáticamente
  void _detenerTodoYReiniciar() async {
    for (Timer temporizador in consultas) {
      temporizador.cancel();
    }
    consultas.clear();
    setState(() {
      capturando = false;
      mensajeEstado = "Máximo alcanzado - Reiniciando...";
    });
    await Future.delayed(Duration(milliseconds: 800));

    if (mounted && !haNavegado) {
      capturarFramesAutomatico(); // Reinicia automáticamente
    }
  }

  bool verificarRespuesta(List<ResultadoClasificacion> clasificaciones) {
    for (var clasificacion in clasificaciones) {
      print(
        "Clasificación 1: ${clasificacion.confiabilidad}, Confiabilidad 2: ${probabilidadAnalisis}",
      );
      if (clasificacion.confiabilidad >= probabilidadAnalisis) {
        return true; // Al menos una clasificación cumple el criterio
      }
    }
    return false; // Ninguna clasificación cumple el criterio
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Container(
          width: size.width,
          height: size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0A0A),
                Color(0xFF1A1A1A),
                Color(0xFF2A2A2A),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Column(
            children: [
              // Título elegante
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.08,
                  vertical: size.height * 0.02,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Proyecto-3 Tópicos",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width * 0.06,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.03,
                        vertical: size.height * 0.008,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(size.width * 0.02),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        "IA",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * 0.03,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Área de cámara con diseño moderno - Expandida
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: size.width * 0.06,
                    vertical: size.height * 0.02,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size.width * 0.04),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.05),
                        Colors.white.withOpacity(0.02),
                      ],
                    ),
                    border: Border.all(
                      color: camaraLista 
                          ? Colors.greenAccent.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(size.width * 0.04),
                    child: camaraLista
                        ? Stack(
                            children: [
                              // Vista previa de la cámara
                              Positioned.fill(
                                child: CameraPreview(controladorCamara!),
                              ),
                              
                              if (capturando)
                                Positioned(
                                  top: size.height * 0.02,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: size.width * 0.04,
                                        vertical: size.height * 0.012,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(size.width * 0.03),
                                        border: Border.all(
                                          color: Colors.cyanAccent.withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        "$framesCapturadasActual / $maxFrames",
                                        style: TextStyle(
                                          color: Colors.cyanAccent,
                                          fontSize: size.width * 0.035,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              
                              // Overlay con información de estado - Top Left
                              if (capturando)
                                Positioned(
                                  top: size.height * 0.02,
                                  left: size.width * 0.04,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: size.width * 0.03,
                                      vertical: size.height * 0.01,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(size.width * 0.02),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: size.width * 0.02,
                                          height: size.width * 0.02,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: size.width * 0.02),
                                        Text(
                                          "CAPTURANDO",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: size.width * 0.025,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              
                              // 🆕 BARRA DE PROGRESO - Bottom
                              if (capturando)
                                Positioned(
                                  bottom: size.height * 0.02,
                                  left: size.width * 0.04,
                                  right: size.width * 0.04,
                                  child: Container(
                                    height: size.height * 0.006,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(size.width * 0.01),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: framesCapturadasActual / maxFrames,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.cyanAccent,
                                              Colors.blueAccent,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(size.width * 0.01),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              
                              // Botón invisible para interacciones
                              Positioned.fill(
                                child: GestureDetector(
                                  onTap: () {
                                    // TODO: Agregar funcionalidad de captura al presionar el centro
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.grey.shade800,
                                  Colors.grey.shade900,
                                ],
                              ),
                            ),
                            child: Center(
                              child: inicializando
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: size.width * 0.15,
                                          height: size.width * 0.15,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                            backgroundColor: Colors.white.withOpacity(0.2),
                                          ),
                                        ),
                                        SizedBox(height: size.height * 0.03),
                                        Text(
                                          "Preparando cámara...",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: size.width * 0.035,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ],
                                    )
                                  : GestureDetector(
                                      onTap: () async {
                                        await iniciarCamara();
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(size.width * 0.08),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(size.width * 0.03),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.camera_alt_outlined,
                                              size: size.width * 0.12,
                                              color: Colors.white.withOpacity(0.9),
                                            ),
                                            SizedBox(height: size.height * 0.02),
                                            Text(
                                              "Iniciar Cámara",
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.9),
                                                fontSize: size.width * 0.04,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}