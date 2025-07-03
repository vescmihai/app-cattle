import 'package:app_p3topicos/services/analisisImagen.service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'asistente_event.dart';
part 'asistente_state.dart';

class AsistenteBloc extends Bloc<AsistenteEvent, AsistenteState> {
  AsistenteBloc() : super(AsistenteState()) {
    on<OnChagendRespuestaClasificacion>(_onChangeResultadoClasificacion);
    on<OnChangeConfiabilidadAnalisis>(_onChangeConfiabilidadAnalisis);
  }

  void _onChangeResultadoClasificacion(
    OnChagendRespuestaClasificacion event,
    Emitter<AsistenteState> emit,
  ) {
    emit(state.copyWith(respuestaClasificacion: event.respuestaClasificacion));
  }

  void _onChangeConfiabilidadAnalisis(
    OnChangeConfiabilidadAnalisis event,
    Emitter<AsistenteState> emit,
  ) {
    emit(state.copyWith(confiabilidadAnalisis: event.confiabilidadAnalisis));
  }
}
