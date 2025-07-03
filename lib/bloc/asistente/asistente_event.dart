part of 'asistente_bloc.dart';

class AsistenteEvent extends Equatable {
  const AsistenteEvent();

  @override
  List<Object?> get props => [];
}

class OnChagendRespuestaClasificacion extends AsistenteEvent {
  final RespuestaClasificacion respuestaClasificacion;

  const OnChagendRespuestaClasificacion(this.respuestaClasificacion);
}

class OnChangeConfiabilidadAnalisis extends AsistenteEvent {
  final double confiabilidadAnalisis;

  const OnChangeConfiabilidadAnalisis(this.confiabilidadAnalisis);
}
