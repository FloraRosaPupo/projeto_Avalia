import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:avalia/core/state/base_state.dart';
import 'package:avalia/features/classes/data/class_repository.dart';
import 'package:avalia/features/classes/data/models/class_model.dart';
import 'package:avalia/features/classes/data/models/class_detail_model.dart';
import 'package:avalia/features/classes/presentation/cubit/class_cubit.dart';

class FakeClasses implements ClassRepository {
  bool fail = false;
  final calls = <String>[];
  Completer<ClassListResponse>? pending;
  @override
  Future<ClassListResponse> list(String userId) async {
    calls.add('list:$userId');
    if (fail) throw StateError('offline');
    return pending == null ? ClassListResponse(classes: []) : pending!.future;
  }

  @override
  Future<void> create({
    required String userId,
    required String nome,
    String? descricao,
  }) async {
    calls.add('create:$userId:$nome');
  }

  @override
  Future<void> update({
    required int classId,
    required String userId,
    required String nome,
    String? descricao,
  }) async {
    calls.add('update:$classId:$userId');
  }

  @override
  Future<ClassDetailModel> details(int classId) async =>
      throw StateError('not found');
}

void main() {
  test('criar turma recarrega apenas a lista do usuário informado', () async {
    final repo = FakeClasses();
    final cubit = ClassCubit(repository: repo);
    addTearDown(cubit.close);
    await cubit.createClass(userId: 'user', nome: 'Turma A');
    expect(repo.calls, ['create:user:Turma A', 'list:user']);
    expect(cubit.state, isA<SuccessState<ClassListResponse>>());
  });
  test('erro pode ser recuperado sem inicializar Supabase', () async {
    final repo = FakeClasses()..fail = true;
    final cubit = ClassCubit(repository: repo);
    addTearDown(cubit.close);
    await cubit.getClassesByUserId(userId: 'user');
    expect(cubit.state, isA<ErrorState>());
    repo.fail = false;
    await cubit.getClassesByUserId(userId: 'user');
    expect(cubit.state, isA<SuccessState<ClassListResponse>>());
  });
  test('resposta após fechar a tela não emite no cubit fechado', () async {
    final repo = FakeClasses()..pending = Completer<ClassListResponse>();
    final cubit = ClassCubit(repository: repo);
    final loading = cubit.getClassesByUserId(userId: 'user');
    await cubit.close();
    repo.pending!.complete(ClassListResponse(classes: []));
    await loading;
  });
}
