import 'package:bloc/bloc.dart';
import 'package:avalia/core/state/base_state.dart';
import '../../data/class_repository.dart';
import '../../data/models/class_model.dart';
import '../../data/models/class_detail_model.dart';

class ClassCubit extends Cubit<BaseState> {
  final ClassRepository repository;
  ClassCubit({ClassRepository? repository})
    : repository = repository ?? SupabaseClassRepository(),
      super(InitialState());
  Future<void> _run(Future<BaseState> Function() action) async {
    if (isClosed) return;
    emit(LoadingState());
    try {
      final state = await action();
      if (!isClosed) emit(state);
    } catch (e) {
      if (!isClosed) emit(ErrorState(e.toString()));
    }
  }

  Future<void> getClassesByUserId({required String userId}) => _run(
    () async => SuccessState<ClassListResponse>(await repository.list(userId)),
  );
  Future<void> createClass({
    required String userId,
    required String nome,
    String? descricao,
  }) => _run(() async {
    await repository.create(userId: userId, nome: nome, descricao: descricao);
    return SuccessState<ClassListResponse>(await repository.list(userId));
  });
  Future<void> updateClass({
    required int classId,
    required String userId,
    required String nome,
    String? descricao,
  }) => _run(() async {
    await repository.update(
      classId: classId,
      userId: userId,
      nome: nome,
      descricao: descricao,
    );
    return SuccessState<ClassListResponse>(await repository.list(userId));
  });
  Future<void> getClassDetails({required int classId}) => _run(
    () async =>
        SuccessState<ClassDetailModel>(await repository.details(classId)),
  );
}
