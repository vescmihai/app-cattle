import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';

/// 🐄 Servicio simple para análisis de imágenes de ganado
class AnalisisImagenService {
  /// URL base del servidor backend
  static const String _urlBase =
      'https://70a7-181-115-134-243.ngrok-free.app';

  /// 🚀 FUNCIÓN 1: Enviar imagen y obtener ID de transacción
  ///
  /// Parámetros:
  /// - [archivoImagen]: Imagen capturada con la cámara
  /// - [porcentaje]: Porcentaje mínimo de confianza
  ///
  /// Retorna: ID de transacción para consultar después
  static Future<String?> enviarImagen(
    XFile archivoImagen,
    double porcentaje,
  ) async {
    try {
      // print('🐄 Enviando imagen al servidor...');
      // print('📁 Archivo: ${archivoImagen.name}');
      print('📊 Porcentaje: $porcentaje%');

      // Configurar cliente Dio
      final cliente = Dio(
        BaseOptions(
          baseUrl: _urlBase,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // Preparar archivo para envío
      final archivo = File(archivoImagen.path);
      final datosFormulario = FormData.fromMap({
        'archivo_imagen': await MultipartFile.fromFile(
          archivo.path,
          filename: archivoImagen.name,
        ),
        'porcentaje_minimo': porcentaje,
      });

      // Enviar petición
      final respuesta = await cliente.post(
        '/clasificar-asincrono/',
        data: datosFormulario,
      );

      if (respuesta.statusCode == 200) {
        final datos = respuesta.data;
        final idTransaccion = datos['id_transaccion'] ?? '';
        final estado = datos['estado'] ?? '';
        final mensaje = datos['mensaje'] ?? '';

        // print('✅ Imagen enviada exitosamente');
        // print('🆔 ID: $idTransaccion');
        // print('📊 Estado: $estado');
        // print('💬 Mensaje: $mensaje');

        return idTransaccion;
      } else {
        // print('❌ Error del servidor: ${respuesta.statusCode}');
        return null;
      }
    } catch (error) {
      // print('❌ Error enviando imagen: $error');
      return null;
    }
  }

  /// 📋 FUNCIÓN 2: Consultar resultado con ID de transacción
  ///
  /// Parámetros:
  /// - [idTransaccion]: ID devuelto por enviarImagen()
  ///
  /// Retorna: Resultado completo de clasificación (o null si aún está procesando)
  static Future<RespuestaClasificacion?> consultarResultado(
    String idTransaccion,
  ) async {
    try {
      // print('🔍 Consultando resultado...');
      // print('🆔 ID: $idTransaccion');

      // Configurar cliente Dio
      final cliente = Dio(
        BaseOptions(
          baseUrl: _urlBase,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // Consultar estado
      final respuesta = await cliente.get('/resultado/$idTransaccion');

      if (respuesta.statusCode == 200) {
        final datos = respuesta.data;
        final estado = datos['estado'] ?? '';

        // print('📊 Estado actual: $estado');

        if (estado == 'completado') {
          // ¡Procesamiento completado!
          // print('🎉 ¡Procesamiento completado!');

          final resultado = RespuestaClasificacion.fromJson(datos['resultado']);

          // Imprimir resultado en consola
          print('📋 Resultado: $resultado');
          // _imprimirResultado(resultado);

          return resultado;
        } else if (estado == 'procesando') {
          // print('⏳ Aún procesando...');
          return null; // Aún no está listo
        } else if (estado == 'error') {
          // print('❌ Error en el procesamiento');
          return null;
        }
      } else {
        // print('❌ Error consultando: ${respuesta.statusCode}');
        return null;
      }
    } catch (error) {
      print('❌ Error en consulta: $error');
      return null;
    }

    return null;
  }

  /// 📋 Imprimir resultado en consola
  static void _imprimirResultado(RespuestaClasificacion resultado) {
    print('\n' + '=' * 60);
    print('🏆 RESULTADO DE CLASIFICACIÓN');
    print('=' * 60);

    print('📅 Fecha: ${resultado.fechaProcesamiento}');
    print('💬 ${resultado.mensaje}');
    print('');

    print('📋 CLASIFICACIONES:');
    print('-' * 50);

    for (int i = 0; i < resultado.clasificaciones.length; i++) {
      final clasificacion = resultado.clasificaciones[i];
      final posicion = i + 1;
      final emoji = posicion == 1 ? '🏆' : '📊';

      print(
        '$emoji $posicion. ${clasificacion.nombreRaza.padRight(25)} ${clasificacion.confiabilidad.toStringAsFixed(1).padLeft(6)}%',
      );

      // Detalles solo del ganador
      if (posicion == 1 && clasificacion.descripcion != null) {
        final desc = clasificacion.descripcion!;
        print('   📝 Origen: ${desc.origen}');
        print('   ⚖️  Peso: ${desc.pesoPromedioKg}');
        print('   📏 Altura: ${desc.alturaPromedioCm}');
        print('   🥛 Producción: ${desc.produccionLecheLitrosDia}');
        print('   😊 Temperamento: ${desc.temperamento}');
        print('');
      }
    }

    print('-' * 50);
    print('✅ Análisis completado\n');
  }
}

// ========== MODELOS DE DATOS ==========

/// Información detallada de una raza de ganado
class DescripcionRaza {
  final String nombre;
  final String pesoPromedioKg;
  final String alturaPromedioCm;
  final String esperanzaVidaAnos;
  final String origen;
  final String produccionLecheLitrosDia;
  final List<String> caracteristicasPrincipales;
  final String temperamento;

  DescripcionRaza({
    required this.nombre,
    required this.pesoPromedioKg,
    required this.alturaPromedioCm,
    required this.esperanzaVidaAnos,
    required this.origen,
    required this.produccionLecheLitrosDia,
    required this.caracteristicasPrincipales,
    required this.temperamento,
  });

  factory DescripcionRaza.fromJson(Map<String, dynamic> json) {
    return DescripcionRaza(
      nombre: json['nombre'] ?? '',
      pesoPromedioKg: json['peso_promedio_kg'] ?? '',
      alturaPromedioCm: json['altura_promedio_cm'] ?? '',
      esperanzaVidaAnos: json['esperanza_vida_anos'] ?? '',
      origen: json['origen'] ?? '',
      produccionLecheLitrosDia: json['produccion_leche_litros_dia'] ?? '',
      caracteristicasPrincipales: List<String>.from(
        json['caracteristicas_principales'] ?? [],
      ),
      temperamento: json['temperamento'] ?? '',
    );
  }
}

/// Resultado individual de clasificación
class ResultadoClasificacion {
  final String nombreRaza;
  final double confiabilidad;
  final DescripcionRaza? descripcion;

  ResultadoClasificacion({
    required this.nombreRaza,
    required this.confiabilidad,
    this.descripcion,
  });

  factory ResultadoClasificacion.fromJson(Map<String, dynamic> json) {
    return ResultadoClasificacion(
      nombreRaza: json['nombre_raza'] ?? '',
      confiabilidad: (json['confiabilidad'] ?? 0.0).toDouble(),
      descripcion:
          json['descripcion'] != null
              ? DescripcionRaza.fromJson(json['descripcion'])
              : null,
    );
  }
}

/// Respuesta completa de clasificación
class RespuestaClasificacion {
  final bool exito;
  final String mensaje;
  final List<ResultadoClasificacion> clasificaciones;
  final String fechaProcesamiento;

  RespuestaClasificacion({
    required this.exito,
    required this.mensaje,
    required this.clasificaciones,
    required this.fechaProcesamiento,
  });

  factory RespuestaClasificacion.fromJson(Map<String, dynamic> json) {
    return RespuestaClasificacion(
      exito: json['exito'] ?? false,
      mensaje: json['mensaje'] ?? '',
      clasificaciones:
          (json['clasificaciones'] as List? ?? [])
              .map((item) => ResultadoClasificacion.fromJson(item))
              .toList(),
      fechaProcesamiento: json['fecha_procesamiento'] ?? '',
    );
  }
}
