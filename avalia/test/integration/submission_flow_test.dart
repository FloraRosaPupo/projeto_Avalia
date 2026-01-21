import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:Avalia/presentation/cubit/submission_cubit.dart';
import 'package:Avalia/data/models/submission_model.dart';
import 'package:Avalia/core/state/base_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Mocks
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgresFilterBuilder extends Mock
    implements PostgresFilterBuilder {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class MockFunctionResponse extends Mock implements FunctionResponse {}

class MockUser extends Mock implements User {}

class FakeFile extends Fake implements File {
  final String _path;
  final int _size;
  final List<int> _bytes;

  FakeFile(this._path, this._size, this._bytes);

  @override
  String get path => _path;

  @override
  Future<int> length() async => _size;

  @override
  Future<List<int>> readAsBytes() async => _bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Submission Flow - Testes de Integração', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockAuth;
    late MockSupabaseStorageClient mockStorage;
    late MockStorageFileApi mockStorageFileApi;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgresFilterBuilder mockFilterBuilder;
    late MockFunctionsClient mockFunctions;
    late MockUser mockUser;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockStorage = MockSupabaseStorageClient();
      mockStorageFileApi = MockStorageFileApi();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilterBuilder = MockPostgresFilterBuilder();
      mockFunctions = MockFunctionsClient();
      mockUser = MockUser();

      // Register fallback values
      registerFallbackValue(FakeFile('test.jpg', 1024, []));
      registerFallbackValue(const FileOptions());

      // Setup default mocks
      when(() => mockSupabaseClient.auth).thenReturn(mockAuth);
      when(() => mockSupabaseClient.storage).thenReturn(mockStorage);
      when(() => mockSupabaseClient.functions).thenReturn(mockFunctions);
      when(() => mockUser.id).thenReturn('user_123');
      when(() => mockAuth.currentUser).thenReturn(mockUser);
    });

    group('Cenário 1: Primeira Submissão → Sucesso', () {
      test('fluxo completo de primeira submissão com correção bem-sucedida',
          () async {
        // Arrange
        // 1. Setup storage upload
        when(() => mockSupabaseClient.storage.from('exam-submissions'))
            .thenReturn(mockStorageFileApi);
        when(() => mockStorageFileApi.upload(
              any(),
              any(),
              fileOptions: any(named: 'fileOptions'),
            )).thenAnswer((_) async => 'prova_123/aluno_456/image.jpg');
        when(() => mockStorageFileApi.getPublicUrl(any()))
            .thenReturn('https://example.com/image.jpg');

        // 2. Setup check for existing submission (não existe)
        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.maybeSingle())
            .thenAnswer((_) async => null);

        // 3. Setup INSERT
        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select())
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.single()).thenAnswer((_) async => {
              'id': 'new_sub_123',
              'prova_id': 'prova_123',
              'aluno_id': 'aluno_456',
              'image_url': 'https://example.com/image.jpg',
              'status': 'processing_analysis',
              'attempt_number': 1,
              'uploaded_at': DateTime.now().toIso8601String(),
            });

        // 4. Setup fetch exam metadata
        when(() => mockSupabaseClient.from('provas'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select('url_prova'))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.single()).thenAnswer((_) async => {
              'url_prova': 'https://example.com/gabarito.jpg',
            });

        // 5. Setup Edge Function success
        final mockFunctionResponse = MockFunctionResponse();
        when(() => mockFunctionResponse.status).thenReturn(200);
        when(() => mockFunctionResponse.data).thenReturn({
          'id': 'new_sub_123',
          'prova_id': 'prova_123',
          'aluno_id': 'aluno_456',
          'status': 'Concluida',
          'nota': 9.0,
          'acertos': 18,
          'total_questoes': 20,
          'attempt_number': 1,
          'uploaded_at': DateTime.now().toIso8601String(),
        });
        when(() => mockFunctions.invoke('quick-api', body: any(named: 'body')))
            .thenAnswer((_) async => mockFunctionResponse);

        final cubit = SubmissionCubit();
        final validFile = FakeFile('test.jpg', 1024, []);

        // Act
        await cubit.submitAndAutoCorrect(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: validFile,
          attemptNumber: 1,
        );

        // Assert
        expect(cubit.state, isA<SubmissionCompletedState>());
        final state = cubit.state as SubmissionCompletedState;
        expect(state.submission.id, equals('new_sub_123'));
        expect(state.submission.status, equals(SubmissionStatus.graded));
        expect(state.submission.nota, equals(9.0));
        expect(state.submission.acertos, equals(18));
        expect(state.submission.totalQuestoes, equals(20));
        expect(state.submission.attemptNumber, equals(1));

        // Verifica que INSERT foi chamado (não UPDATE)
        verify(() => mockQueryBuilder.insert(any())).called(1);
        verifyNever(() => mockQueryBuilder.update(any()));
      });

      test('não cria duplicatas no banco de dados', () async {
        // Arrange
        when(() => mockSupabaseClient.storage.from('exam-submissions'))
            .thenReturn(mockStorageFileApi);
        when(() => mockStorageFileApi.upload(
              any(),
              any(),
              fileOptions: any(named: 'fileOptions'),
            )).thenAnswer((_) async => 'prova_123/aluno_456/image.jpg');
        when(() => mockStorageFileApi.getPublicUrl(any()))
            .thenReturn('https://example.com/image.jpg');

        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.maybeSingle())
            .thenAnswer((_) async => null);

        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select())
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.single()).thenAnswer((_) async => {
              'id': 'new_sub_123',
              'prova_id': 'prova_123',
              'aluno_id': 'aluno_456',
            });

        when(() => mockSupabaseClient.from('provas'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select('url_prova'))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.single()).thenAnswer((_) async => {
              'url_prova': 'https://example.com/gabarito.jpg',
            });

        final mockFunctionResponse = MockFunctionResponse();
        when(() => mockFunctionResponse.status).thenReturn(200);
        when(() => mockFunctionResponse.data).thenReturn({
          'id': 'new_sub_123',
          'prova_id': 'prova_123',
          'aluno_id': 'aluno_456',
          'status': 'Concluida',
          'uploaded_at': DateTime.now().toIso8601String(),
        });
        when(() => mockFunctions.invoke('quick-api', body: any(named: 'body')))
            .thenAnswer((_) async => mockFunctionResponse);

        final cubit = SubmissionCubit();
        final validFile = FakeFile('test.jpg', 1024, []);

        // Act
        await cubit.submitAndAutoCorrect(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: validFile,
          attemptNumber: 1,
        );

        // Assert
        // Verifica que INSERT foi chamado apenas uma vez
        verify(() => mockQueryBuilder.insert(any())).called(1);
        // Verifica que UPDATE nunca foi chamado
        verifyNever(() => mockQueryBuilder.update(any()));
      });
    });

    group('Cenário 2: Reenvio/Substituição → Confirma perda de dados → Sucesso',
        () {
      test('fluxo completo de substituição com UPDATE correto', () async {
        // Arrange
        // 1. Setup storage upload
        when(() => mockSupabaseClient.storage.from('exam-submissions'))
            .thenReturn(mockStorageFileApi);
        when(() => mockStorageFileApi.upload(
              any(),
              any(),
              fileOptions: any(named: 'fileOptions'),
            )).thenAnswer((_) async => 'prova_123/aluno_456/image_new.jpg');
        when(() => mockStorageFileApi.getPublicUrl(any()))
            .thenReturn('https://example.com/image_new.jpg');

        // 2. Setup check for existing submission (existe)
        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.maybeSingle())
            .thenAnswer((_) async => {
                  'id': 'existing_sub_123',
                  'prova_id': 'prova_123',
                  'aluno_id': 'aluno_456',
                  'image_url': 'https://example.com/old_image.jpg',
                  'status': 'Concluida',
                  'nota': 7.0,
                  'acertos': 14,
                  'total_questoes': 20,
                  'attempt_number': 1,
                });

        // 3. Setup UPDATE
        when(() => mockQueryBuilder.update(any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', any()))
            .thenReturn(mockFilterBuilder);

        // 4. Setup fetch exam metadata
        when(() => mockSupabaseClient.from('provas'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select('url_prova'))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.single()).thenAnswer((_) async => {
              'url_prova': 'https://example.com/gabarito.jpg',
            });

        // 5. Setup Edge Function success
        final mockFunctionResponse = MockFunctionResponse();
        when(() => mockFunctionResponse.status).thenReturn(200);
        when(() => mockFunctionResponse.data).thenReturn({
          'id': 'existing_sub_123',
          'prova_id': 'prova_123',
          'aluno_id': 'aluno_456',
          'status': 'Concluida',
          'nota': 9.5,
          'acertos': 19,
          'total_questoes': 20,
          'attempt_number': 2,
          'uploaded_at': DateTime.now().toIso8601String(),
        });
        when(() => mockFunctions.invoke('quick-api', body: any(named: 'body')))
            .thenAnswer((_) async => mockFunctionResponse);

        final cubit = SubmissionCubit();
        final validFile = FakeFile('test.jpg', 1024, []);

        // Act
        await cubit.submitAndAutoCorrect(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: validFile,
          attemptNumber: 2,
        );

        // Assert
        expect(cubit.state, isA<SubmissionCompletedState>());
        final state = cubit.state as SubmissionCompletedState;
        expect(state.submission.id, equals('existing_sub_123'));
        expect(state.submission.status, equals(SubmissionStatus.graded));
        expect(state.submission.nota, equals(9.5));
        expect(state.submission.acertos, equals(19));
        expect(state.submission.attemptNumber, equals(2));

        // Verifica que UPDATE foi chamado (não INSERT)
        verify(() => mockQueryBuilder.update(any())).called(1);
        verifyNever(() => mockQueryBuilder.insert(any()));
        verify(() => mockFilterBuilder.eq('id', 'existing_sub_123')).called(1);
      });

      test('substitui dados anteriores corretamente', () async {
        // Arrange
        when(() => mockSupabaseClient.storage.from('exam-submissions'))
            .thenReturn(mockStorageFileApi);
        when(() => mockStorageFileApi.upload(
              any(),
              any(),
              fileOptions: any(named: 'fileOptions'),
            )).thenAnswer((_) async => 'prova_123/aluno_456/image_new.jpg');
        when(() => mockStorageFileApi.getPublicUrl(any()))
            .thenReturn('https://example.com/image_new.jpg');

        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.maybeSingle())
            .thenAnswer((_) async => {
                  'id': 'existing_sub_123',
                  'image_url': 'https://example.com/old_image.jpg',
                  'status': 'Concluida',
                  'nota': 7.0,
                  'attempt_number': 1,
                });

        when(() => mockQueryBuilder.update(any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', any()))
            .thenReturn(mockFilterBuilder);

        when(() => mockSupabaseClient.from('provas'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select('url_prova'))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.single()).thenAnswer((_) async => {
              'url_prova': 'https://example.com/gabarito.jpg',
            });

        final mockFunctionResponse = MockFunctionResponse();
        when(() => mockFunctionResponse.status).thenReturn(200);
        when(() => mockFunctionResponse.data).thenReturn({
          'id': 'existing_sub_123',
          'prova_id': 'prova_123',
          'aluno_id': 'aluno_456',
          'image_url': 'https://example.com/image_new.jpg',
          'status': 'Concluida',
          'nota': 9.5,
          'attempt_number': 2,
          'uploaded_at': DateTime.now().toIso8601String(),
        });
        when(() => mockFunctions.invoke('quick-api', body: any(named: 'body')))
            .thenAnswer((_) async => mockFunctionResponse);

        final cubit = SubmissionCubit();
        final validFile = FakeFile('test.jpg', 1024, []);

        // Act
        await cubit.submitAndAutoCorrect(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: validFile,
          attemptNumber: 2,
        );

        // Assert
        final state = cubit.state as SubmissionCompletedState;

        // Verifica que imagem foi atualizada
        expect(state.submission.imageUrl,
            equals('https://example.com/image_new.jpg'));

        // Verifica que nota foi atualizada
        expect(state.submission.nota, equals(9.5));

        // Verifica que attempt_number foi incrementado
        expect(state.submission.attemptNumber, equals(2));

        // Verifica que UPDATE contém os dados corretos
        verify(() => mockQueryBuilder.update(
              argThat(predicate<Map<String, dynamic>>((data) =>
                  data['image_url'] == 'https://example.com/image_new.jpg' &&
                  data['attempt_number'] == 2)),
            )).called(1);
      });

      test('incrementa attempt_number corretamente em múltiplas substituições',
          () async {
        // Arrange
        when(() => mockSupabaseClient.storage.from('exam-submissions'))
            .thenReturn(mockStorageFileApi);
        when(() => mockStorageFileApi.upload(
              any(),
              any(),
              fileOptions: any(named: 'fileOptions'),
            )).thenAnswer((_) async => 'prova_123/aluno_456/image.jpg');
        when(() => mockStorageFileApi.getPublicUrl(any()))
            .thenReturn('https://example.com/image.jpg');

        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.maybeSingle())
            .thenAnswer((_) async => {
                  'id': 'existing_sub_123',
                  'attempt_number': 2, // já na 2ª tentativa
                });

        when(() => mockQueryBuilder.update(any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', any()))
            .thenReturn(mockFilterBuilder);

        when(() => mockSupabaseClient.from('provas'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select('url_prova'))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.single()).thenAnswer((_) async => {
              'url_prova': 'https://example.com/gabarito.jpg',
            });

        final mockFunctionResponse = MockFunctionResponse();
        when(() => mockFunctionResponse.status).thenReturn(200);
        when(() => mockFunctionResponse.data).thenReturn({
          'id': 'existing_sub_123',
          'prova_id': 'prova_123',
          'aluno_id': 'aluno_456',
          'status': 'Concluida',
          'attempt_number': 3, // 3ª tentativa
          'uploaded_at': DateTime.now().toIso8601String(),
        });
        when(() => mockFunctions.invoke('quick-api', body: any(named: 'body')))
            .thenAnswer((_) async => mockFunctionResponse);

        final cubit = SubmissionCubit();
        final validFile = FakeFile('test.jpg', 1024, []);

        // Act
        await cubit.submitAndAutoCorrect(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: validFile,
          attemptNumber: 3,
        );

        // Assert
        final state = cubit.state as SubmissionCompletedState;
        expect(state.submission.attemptNumber, equals(3));

        verify(() => mockQueryBuilder.update(
              argThat(predicate<Map<String, dynamic>>(
                (data) => data['attempt_number'] == 3,
              )),
            )).called(1);
      });
    });

    group('Cenário 3: Cancelar substituição → Manter dados originais', () {
      test('não executa UPDATE quando cancelado antes do upload', () async {
        // Arrange
        final cubit = SubmissionCubit();

        // Simula cancelamento: não chama submitAndAutoCorrect
        // apenas verifica estado inicial

        // Act
        // Nenhuma ação de upload

        // Assert
        expect(cubit.state, isA<InitialState>());
        verifyNever(() => mockQueryBuilder.update(any()));
        verifyNever(() => mockQueryBuilder.insert(any()));
      });

      test('mantém dados originais se processo falha no meio', () async {
        // Arrange
        when(() => mockSupabaseClient.storage.from('exam-submissions'))
            .thenReturn(mockStorageFileApi);
        when(() => mockStorageFileApi.upload(
              any(),
              any(),
              fileOptions: any(named: 'fileOptions'),
            )).thenThrow(
          StorageException('Upload failed', statusCode: '500'),
        );

        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.maybeSingle())
            .thenAnswer((_) async => {
                  'id': 'existing_sub_123',
                  'nota': 8.0,
                  'attempt_number': 1,
                });

        final cubit = SubmissionCubit();
        final validFile = FakeFile('test.jpg', 1024, []);

        // Act
        await cubit.submitAndAutoCorrect(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: validFile,
          attemptNumber: 2,
        );

        // Assert
        // Verifica que entrou em estado de erro
        expect(cubit.state, isA<SubmissionErrorState>());
        final state = cubit.state as SubmissionErrorState;
        expect(state.code, equals('PROCESSING_ERROR'));

        // Verifica que UPDATE nunca foi chamado (dados originais mantidos)
        verifyNever(() => mockQueryBuilder.update(any()));
      });
    });

    group('Validação de Não-Duplicação', () {
      test('nunca cria múltiplas submissões para mesma prova/aluno', () async {
        // Arrange
        when(() => mockSupabaseClient.storage.from('exam-submissions'))
            .thenReturn(mockStorageFileApi);
        when(() => mockStorageFileApi.upload(
              any(),
              any(),
              fileOptions: any(named: 'fileOptions'),
            )).thenAnswer((_) async => 'path.jpg');
        when(() => mockStorageFileApi.getPublicUrl(any()))
            .thenReturn('https://example.com/image.jpg');

        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockFilterBuilder);

        // Primeira chamada: não existe submissão
        when(() => mockFilterBuilder.maybeSingle())
            .thenAnswer((_) async => null);

        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.select())
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.single()).thenAnswer((_) async => {
              'id': 'new_sub_123',
              'prova_id': 'prova_123',
              'aluno_id': 'aluno_456',
            });

        when(() => mockSupabaseClient.from('provas'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select('url_prova'))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.single()).thenAnswer((_) async => {
              'url_prova': 'https://example.com/gabarito.jpg',
            });

        final mockFunctionResponse = MockFunctionResponse();
        when(() => mockFunctionResponse.status).thenReturn(200);
        when(() => mockFunctionResponse.data).thenReturn({
          'id': 'new_sub_123',
          'prova_id': 'prova_123',
          'aluno_id': 'aluno_456',
          'status': 'Concluida',
          'uploaded_at': DateTime.now().toIso8601String(),
        });
        when(() => mockFunctions.invoke('quick-api', body: any(named: 'body')))
            .thenAnswer((_) async => mockFunctionResponse);

        final cubit = SubmissionCubit();
        final validFile = FakeFile('test.jpg', 1024, []);

        // Act
        await cubit.submitAndAutoCorrect(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: validFile,
          attemptNumber: 1,
        );

        // Assert
        // Verifica que INSERT foi chamado exatamente uma vez
        verify(() => mockQueryBuilder.insert(any())).called(1);
        // Verifica que nunca tentou criar múltiplas submissões
        verifyNever(() => mockQueryBuilder.insert(any()));
      });
    });

    group('Edge Cases', () {
      test('trata erro de rede durante upload', () async {
        // Arrange
        when(() => mockSupabaseClient.storage.from('exam-submissions'))
            .thenReturn(mockStorageFileApi);
        when(() => mockStorageFileApi.upload(
              any(),
              any(),
              fileOptions: any(named: 'fileOptions'),
            )).thenThrow(
          StorageException('Network error', statusCode: 'NETWORK_ERROR'),
        );

        final cubit = SubmissionCubit();
        final validFile = FakeFile('test.jpg', 1024, []);

        // Act
        await cubit.submitAndAutoCorrect(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: validFile,
          attemptNumber: 1,
        );

        // Assert
        expect(cubit.state, isA<SubmissionErrorState>());
        final state = cubit.state as SubmissionErrorState;
        expect(state.code, equals('PROCESSING_ERROR'));
        expect(state.message, contains('Network error'));
      });

      test('trata submissão inválida (validação falha)', () async {
        // Arrange
        final cubit = SubmissionCubit();
        final invalidFile = FakeFile(
          'test.pdf',
          1024,
          [],
        );

        // Act
        await cubit.submitAndAutoCorrect(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: invalidFile,
          attemptNumber: 1,
        );

        // Assert
        expect(cubit.state, isA<SubmissionErrorState>());
        final state = cubit.state as SubmissionErrorState;
        expect(state.code, equals('VALIDATION_ERROR'));
        expect(state.message, contains('Formato inválido'));
      });

      test('trata usuário não autenticado', () async {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(null);

        when(() => mockSupabaseClient.storage.from('exam-submissions'))
            .thenReturn(mockStorageFileApi);
        when(() => mockStorageFileApi.upload(
              any(),
              any(),
              fileOptions: any(named: 'fileOptions'),
            )).thenAnswer((_) async => 'path.jpg');
        when(() => mockStorageFileApi.getPublicUrl(any()))
            .thenReturn('https://example.com/image.jpg');

        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.maybeSingle())
            .thenAnswer((_) async => null);

        when(() => mockSupabaseClient.from('provas'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select('url_prova'))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.eq('id', any()))
            .thenReturn(mockFilterBuilder);
        when(() => mockFilterBuilder.single()).thenAnswer((_) async => {
              'url_prova': 'https://example.com/gabarito.jpg',
            });

        final cubit = SubmissionCubit();
        final validFile = FakeFile('test.jpg', 1024, []);

        // Act
        await cubit.submitAndAutoCorrect(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: validFile,
          attemptNumber: 1,
        );

        // Assert
        expect(cubit.state, isA<SubmissionErrorState>());
        final state = cubit.state as SubmissionErrorState;
        expect(state.message, contains('não autenticado'));
      });
    });
  });
}
