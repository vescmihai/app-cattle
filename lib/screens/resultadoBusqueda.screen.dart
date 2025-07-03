import 'package:app_p3topicos/bloc/asistente/asistente_bloc.dart';
import 'package:app_p3topicos/main.dart';
import 'package:app_p3topicos/services/analisisImagen.service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ResultadoBusquedaScreen extends StatelessWidget {
  const ResultadoBusquedaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final asistenteBloc = BlocProvider.of<AsistenteBloc>(context);
    asistenteBloc.state.respuestaClasificacion;
    asistenteBloc.state.confiabilidadAnalisis;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
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
        child: BlocBuilder<AsistenteBloc, AsistenteState>(
          builder: (context, state) {
            if (state.respuestaClasificacion == null) {
              return _construirEstadoVacio(size);
            }

            return _construirContenido(context, size, state.respuestaClasificacion!);
          },
        ),
      ),
    );
  }

  Widget _construirEstadoVacio(Size size) {
    return SafeArea(
      child: Center(
        child: Container(
          margin: EdgeInsets.all(size.width * 0.08),
          padding: EdgeInsets.all(size.width * 0.08),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(size.width * 0.04),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(size.width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(size.width * 0.03),
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: size.width * 0.12,
                  color: Colors.redAccent,
                ),
              ),
              SizedBox(height: size.height * 0.03),
              Text(
                "No hay resultados disponibles",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: size.width * 0.045,
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirContenido(BuildContext context, Size size, RespuestaClasificacion respuesta) {
    // Encontrar la clasificación con mayor porcentaje
    ResultadoClasificacion mejorClasificacion = respuesta.clasificaciones.first;
    for (var clasificacion in respuesta.clasificaciones) {
      if (clasificacion.confiabilidad > mejorClasificacion.confiabilidad) {
        mejorClasificacion = clasificacion;
      }
    }

    return SafeArea(
      child: Column(
        children: [
          // Encabezado simple
          Container(
            width: size.width,
            padding: EdgeInsets.all(size.width * 0.06),
            child: Row(
              children: [
                // Botón de volver
                GestureDetector(
                  onTap: () {
                    print("🔄 Limpiando estado y volviendo...");
                    context.pushReplacement('/capturaFrames');
                  },
                  child: Container(
                    padding: EdgeInsets.all(size.width * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(size.width * 0.02),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white.withOpacity(0.9),
                      size: size.width * 0.06,
                    ),
                  ),
                ),

                SizedBox(width: size.width * 0.04),

                // Título
                Text(
                  "Resultado",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * 0.06,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal centrado
          Expanded(
            child: Center(
              child: Container(
                margin: EdgeInsets.all(size.width * 0.08),
                padding: EdgeInsets.all(size.width * 0.08),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(size.width * 0.06),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nombre de la raza
                    Text(
                      mejorClasificacion.nombreRaza,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width * 0.08,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: size.height * 0.03),

                    // Porcentaje de confianza
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.06,
                        vertical: size.height * 0.02,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(size.width * 0.04),
                        border: Border.all(
                          color: Colors.greenAccent.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        "${mejorClasificacion.confiabilidad.toStringAsFixed(1)}% de confianza",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: size.width * 0.045,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.04),

                    // Información de peso y altura
                    if (mejorClasificacion.descripcion != null)
                      _construirInformacionBasica(size, mejorClasificacion.descripcion!),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirInformacionBasica(Size size, DescripcionRaza descripcion) {
    return Row(
      children: [
        // Peso
        Expanded(
          child: Container(
            padding: EdgeInsets.all(size.width * 0.05),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(size.width * 0.03),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(size.width * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(size.width * 0.02),
                  ),
                  child: Icon(
                    Icons.monitor_weight_outlined,
                    color: Colors.blueAccent,
                    size: size.width * 0.06,
                  ),
                ),
                SizedBox(height: size.height * 0.015),
                Text(
                  "Peso",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: size.width * 0.032,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(height: size.height * 0.008),
                Text(
                  descripcion.pesoPromedioKg.isNotEmpty 
                      ? descripcion.pesoPromedioKg 
                      : "N/A",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: size.width * 0.04),

        // Altura
        Expanded(
          child: Container(
            padding: EdgeInsets.all(size.width * 0.05),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(size.width * 0.03),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(size.width * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(size.width * 0.02),
                  ),
                  child: Icon(
                    Icons.height_outlined,
                    color: Colors.orangeAccent,
                    size: size.width * 0.06,
                  ),
                ),
                SizedBox(height: size.height * 0.015),
                Text(
                  "Altura",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: size.width * 0.032,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(height: size.height * 0.008),
                Text(
                  descripcion.alturaPromedioCm.isNotEmpty 
                      ? descripcion.alturaPromedioCm 
                      : "N/A",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}