part of 'asistente_bloc.dart';

class AsistenteState extends Equatable {
  final RespuestaClasificacion? respuestaClasificacion;
  final double confiabilidadAnalisis;

  const AsistenteState({
    this.respuestaClasificacion,
    this.confiabilidadAnalisis = 0.0,
  }); // ← Aquí faltaba el punto y coma

  AsistenteState copyWith({
    RespuestaClasificacion? respuestaClasificacion,
    double? confiabilidadAnalisis,
  }) {
    return AsistenteState(
      respuestaClasificacion:
          respuestaClasificacion ?? this.respuestaClasificacion,
      confiabilidadAnalisis:
          confiabilidadAnalisis ?? this.confiabilidadAnalisis,
    );
  }

  @override
  List<Object?> get props => [respuestaClasificacion, confiabilidadAnalisis];
}
