import 'dart:io';
import 'dart:typed_data';
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

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class MockFunctionResponse extends Mock implements FunctionResponse {}

class MockUser extends Mock implements User {}

class FakeFile extends Fake implements File {
  final String _path;
  final int _size;
  final Uint8List _bytes;

  FakeFile(this._path, this._size, List<int> bytes)
      : _bytes = Uint8List.fromList(bytes);

  @override
  String get path => _path;

  @override
  Future<int> length() async => _size;

  @override
  Future<Uint8List> readAsBytes() async => _bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubmissionCubit - Testes Unitários', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockAuth;
    late MockSupabaseStorageClient mockStorage;
    late MockStorageFileApi mockStorageFileApi;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockPostgrestFilterBuilder;
    late MockFunctionsClient mockFunctions;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockStorage = MockSupabaseStorageClient();
      mockStorageFileApi = MockStorageFileApi();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockPostgrestFilterBuilder = MockPostgresFilterBuilder();
      mockFunctions = MockFunctionsClient();

      // Register fallback values
      registerFallbackValue(FakeFile('test.jpg', 1024, []));
      registerFallbackValue(const FileOptions());

      // Setup default mocks
      when(() => mockSupabaseClient.auth).thenReturn(mockAuth);
      when(() => mockSupabaseClient.storage).thenReturn(mockStorage);
      when(() => mockSupabaseClient.functions).thenReturn(mockFunctions);
    });

    group('getSubmission', () {
      test('emite SuccessState com null quando não existe submissão', () async {
        // Arrange
        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select())
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.maybeSingle())
            .thenAnswer((_) async => null);

        // Act & Assert
        final cubit = SubmissionCubit();
        expect(
          cubit.stream,
          emitsInOrder([
            isA<LoadingState>(),
            isA<SuccessState<SubmissionModel?>>(),
          ]),
        );

        await cubit.getSubmission('prova_123', 'aluno_456');
      });

      test('emite SuccessState com submissão quando existe', () async {
        // Arrange
        final mockResponse = {
          'id': 'sub_123',
          'prova_id': 'prova_123',
          'aluno_id': 'aluno_456',
          'image_url': 'https://example.com/image.jpg',
          'status': 'Concluida',
          'nota': 8.5,
          'acertos': 17,
          'total_questoes': 20,
          'attempt_number': 1,
          'uploaded_at': DateTime.now().toIso8601String(),
        };

        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select())
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.maybeSingle())
            .thenAnswer((_) async => mockResponse);

        // Act & Assert
        final cubit = SubmissionCubit();
        expect(
          cubit.stream,
          emitsInOrder([
            isA<LoadingState>(),
            predicate<SuccessState<SubmissionModel>>((state) {
              return state.data.id == 'sub_123' &&
                  state.data.provaId == 'prova_123' &&
                  state.data.alunoId == 'aluno_456' &&
                  state.data.attemptNumber == 1;
            }),
          ]),
        );

        await cubit.getSubmission('prova_123', 'aluno_456');
      });

      test('emite ErrorState quando ocorre erro na busca', () async {
        // Arrange
        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select())
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.maybeSingle())
            .thenThrow(Exception('Database error'));

        // Act & Assert
        final cubit = SubmissionCubit();
        expect(
          cubit.stream,
          emitsInOrder([
            isA<LoadingState>(),
            predicate<ErrorState>(
              (state) => state.message.contains('Erro ao buscar submissão'),
            ),
          ]),
        );

        await cubit.getSubmission('prova_123', 'aluno_456');
      });
    });

    group('validateImage', () {
      test('valida arquivo pequeno (< 50MB) com formato válido', () async {
        // Arrange
        final cubit = SubmissionCubit();
        final validFile = FakeFile(
          'test.jpg',
          10 * 1024 * 1024, // 10MB
          [],
        );

        // Act
        final result = await cubit.validateImage(validFile);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.error, isNull);
      });

      test('rejeita arquivo muito grande (> 50MB)', () async {
        // Arrange
        final cubit = SubmissionCubit();
        final largeFile = FakeFile(
          'large.jpg',
          60 * 1024 * 1024, // 60MB
          [],
        );

        // Act
        final result = await cubit.validateImage(largeFile);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.error, contains('muito grande'));
        expect(result.error, contains('50MB'));
      });

      test('rejeita formato inválido (.pdf)', () async {
        // Arrange
        final cubit = SubmissionCubit();
        final invalidFile = FakeFile(
          'test.pdf',
          1024,
          [],
        );

        // Act
        final result = await cubit.validateImage(invalidFile);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.error, contains('Formato inválido'));
        expect(result.error, contains('JPG ou PNG'));
      });

      test('aceita formato .jpeg', () async {
        // Arrange
        final cubit = SubmissionCubit();
        final validFile = FakeFile(
          'test.jpeg',
          1024,
          [],
        );

        // Act
        final result = await cubit.validateImage(validFile);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('aceita formato .png', () async {
        // Arrange
        final cubit = SubmissionCubit();
        final validFile = FakeFile(
          'test.png',
          1024,
          [],
        );

        // Act
        final result = await cubit.validateImage(validFile);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('é case-insensitive para extensões (.JPG, .PNG)', () async {
        // Arrange
        final cubit = SubmissionCubit();
        final upperCaseFile = FakeFile(
          'test.JPG',
          1024,
          [],
        );

        // Act
        final result = await cubit.validateImage(upperCaseFile);

        // Assert
        expect(result.isValid, isTrue);
      });
    });

    group('uploadSubmission - Primeira submissão (INSERT)', () {
      test('faz INSERT quando não existe submissão anterior', () async {
        // Arrange
        when(() => mockSupabaseClient.storage.from('exam-submissions'))
            .thenReturn(mockStorageFileApi);
        when(() => mockStorageFileApi.upload(
              any(),
              any(),
              fileOptions: any(named: 'fileOptions'),
            )).thenAnswer((_) async => 'path/to/file.jpg');
        when(() => mockStorageFileApi.getPublicUrl(any()))
            .thenReturn('https://example.com/file.jpg');

        // Não existe submissão anterior
        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select())
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.maybeSingle())
            .thenAnswer((_) async => null);

        // INSERT
        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.select())
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.single()).thenAnswer((_) async => {
              'id': 'new_sub_123',
              'prova_id': 'prova_123',
              'aluno_id': 'aluno_456',
              'image_url': 'https://example.com/file.jpg',
              'status': 'processing_upload',
              'attempt_number': 1,
              'uploaded_at': DateTime.now().toIso8601String(),
            });

        final cubit = SubmissionCubit();
        final validFile = FakeFile('test.jpg', 1024, []);

        // Act
        await cubit.uploadSubmission(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: validFile,
          attemptNumber: 1,
        );

        // Assert
        verify(() => mockQueryBuilder.insert(any())).called(1);
        verify(() => mockPostgrestFilterBuilder.single()).called(1);
      });

      test('emite estados corretos durante upload inicial', () async {
        // Arrange
        when(() => mockSupabaseClient.storage.from('exam-submissions'))
            .thenReturn(mockStorageFileApi);
        when(() => mockStorageFileApi.upload(
              any(),
              any(),
              fileOptions: any(named: 'fileOptions'),
            )).thenAnswer((_) async => 'path/to/file.jpg');
        when(() => mockStorageFileApi.getPublicUrl(any()))
            .thenReturn('https://example.com/file.jpg');

        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select())
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.maybeSingle())
            .thenAnswer((_) async => null);
        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.single()).thenAnswer((_) async => {
              'id': 'new_sub_123',
              'prova_id': 'prova_123',
              'aluno_id': 'aluno_456',
              'image_url': 'https://example.com/file.jpg',
              'status': 'processing_upload',
              'attempt_number': 1,
              'uploaded_at': DateTime.now().toIso8601String(),
            });

        final cubit = SubmissionCubit();
        final validFile = FakeFile('test.jpg', 1024, []);

        // Act & Assert
        expect(
          cubit.stream,
          emitsInOrder([
            predicate<SubmissionUploadingState>(
              (state) => state.percent == 0,
            ),
            predicate<SubmissionUploadingState>(
              (state) => state.percent == 25,
            ),
            predicate<SubmissionUploadingState>(
              (state) => state.percent == 50,
            ),
            predicate<SubmissionUploadingState>(
              (state) => state.percent == 75,
            ),
            predicate<SubmissionUploadingState>(
              (state) => state.percent == 100,
            ),
            isA<SubmissionProcessingState>(),
          ]),
        );

        await cubit.uploadSubmission(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: validFile,
          attemptNumber: 1,
        );
      });
    });

    group('uploadSubmission - Substituição (UPDATE)', () {
      test('faz UPDATE quando já existe submissão', () async {
        // Arrange
        when(() => mockSupabaseClient.storage.from('exam-submissions'))
            .thenReturn(mockStorageFileApi);
        when(() => mockStorageFileApi.upload(
              any(),
              any(),
              fileOptions: any(named: 'fileOptions'),
            )).thenAnswer((_) async => 'path/to/file.jpg');
        when(() => mockStorageFileApi.getPublicUrl(any()))
            .thenReturn('https://example.com/file_new.jpg');

        // Já existe submissão
        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select())
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.maybeSingle())
            .thenAnswer((_) async => {
                  'id': 'existing_sub_123',
                  'prova_id': 'prova_123',
                  'aluno_id': 'aluno_456',
                  'image_url': 'https://example.com/old_image.jpg',
                  'status': 'Concluida',
                  'attempt_number': 1,
                });

        // UPDATE
        when(() => mockQueryBuilder.update(any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.select())
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.single()).thenAnswer((_) async => {
              'id': 'existing_sub_123',
              'prova_id': 'prova_123',
              'aluno_id': 'aluno_456',
              'image_url': 'https://example.com/file_new.jpg',
              'status': 'processing_upload',
              'attempt_number': 2,
              'uploaded_at': DateTime.now().toIso8601String(),
            });

        final cubit = SubmissionCubit();
        final validFile = FakeFile('test.jpg', 1024, []);

        // Act
        await cubit.uploadSubmission(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: validFile,
          attemptNumber: 2,
        );

        // Assert
        verify(() => mockQueryBuilder.update(any())).called(1);
        verify(() => mockPostgrestFilterBuilder.eq('id', 'existing_sub_123')).called(1);
        verify(() => mockPostgrestFilterBuilder.single()).called(1);
      });

      test('incrementa attempt_number na substituição', () async {
        // Arrange
        when(() => mockSupabaseClient.storage.from('exam-submissions'))
            .thenReturn(mockStorageFileApi);
        when(() => mockStorageFileApi.upload(
              any(),
              any(),
              fileOptions: any(named: 'fileOptions'),
            )).thenAnswer((_) async => 'path/to/file.jpg');
        when(() => mockStorageFileApi.getPublicUrl(any()))
            .thenReturn('https://example.com/file_new.jpg');

        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select())
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.maybeSingle())
            .thenAnswer((_) async => {
                  'id': 'existing_sub_123',
                  'attempt_number': 2, // 2ª tentativa anterior
                });

        when(() => mockQueryBuilder.update(any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.single()).thenAnswer((_) async => {
              'id': 'existing_sub_123',
              'prova_id': 'prova_123',
              'aluno_id': 'aluno_456',
              'attempt_number': 3, // 3ª tentativa
              'uploaded_at': DateTime.now().toIso8601String(),
            });

        final cubit = SubmissionCubit();
        final validFile = FakeFile('test.jpg', 1024, []);

        // Act
        await cubit.uploadSubmission(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: validFile,
          attemptNumber: 3,
        );

        // Assert - Verifica que o update foi chamado com attempt_number = 3
        verify(() => mockQueryBuilder.update(
              any(that: predicate<Map<String, dynamic>>(
                (data) => data['attempt_number'] == 3,
              )),
            )).called(1);
      });
    });

    group('uploadSubmission - Edge Cases', () {
      test('emite SubmissionErrorState quando validação falha', () async {
        // Arrange
        final cubit = SubmissionCubit();
        final invalidFile = FakeFile(
          'test.pdf',
          1024,
          [],
        );

        // Act & Assert
        expect(
          cubit.stream,
          emitsInOrder([
            predicate<SubmissionUploadingState>(
              (state) => state.percent == 0,
            ),
            predicate<SubmissionErrorState>(
              (state) => state.code == 'VALIDATION_ERROR',
            ),
          ]),
        );

        await cubit.uploadSubmission(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: invalidFile,
          attemptNumber: 1,
        );
      });

      test('emite SubmissionErrorState quando upload falha', () async {
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

        final cubit = SubmissionCubit();
        final validFile = FakeFile('test.jpg', 1024, []);

        // Act & Assert
        expect(
          cubit.stream,
          emitsInOrder([
            isA<SubmissionUploadingState>(),
            isA<SubmissionUploadingState>(),
            predicate<SubmissionErrorState>(
              (state) => state.code == 'UPLOAD_ERROR',
            ),
          ]),
        );

        await cubit.uploadSubmission(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: validFile,
          attemptNumber: 1,
        );
      });
    });

    group('submitAndAutoCorrect', () {
      test('executa fluxo completo com sucesso (primeira submissão)', () async {
        // Arrange
        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('user_123');
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        when(() => mockSupabaseClient.storage.from('exam-submissions'))
            .thenReturn(mockStorageFileApi);
        when(() => mockStorageFileApi.upload(
              any(),
              any(),
              fileOptions: any(named: 'fileOptions'),
            )).thenAnswer((_) async => 'path/to/file.jpg');
        when(() => mockStorageFileApi.getPublicUrl(any()))
            .thenReturn('https://example.com/file.jpg');

        // Não existe submissão
        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.maybeSingle())
            .thenAnswer((_) async => null);

        // INSERT
        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.single()).thenAnswer((_) async => {
              'id': 'new_sub_123',
              'prova_id': 'prova_123',
              'aluno_id': 'aluno_456',
            });

        // Buscar metadados da prova
        when(() => mockSupabaseClient.from('provas'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select('url_prova'))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.single()).thenAnswer((_) async => {
              'url_prova': 'https://example.com/gabarito.jpg',
            });

        // Edge Function
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
          'uploaded_at': DateTime.now().toIso8601String(),
        });
        when(() => mockFunctions.invoke('quick-api', body: any(named: 'body')))
            .thenAnswer((_) async => mockFunctionResponse);

        final cubit = SubmissionCubit();
        final validFile = FakeFile('test.jpg', 1024, []);

        // Act & Assert
        expect(
          cubit.stream,
          emitsInOrder([
            isA<SubmissionUploadingState>(),
            isA<SubmissionUploadingState>(),
            isA<SubmissionUploadingState>(),
            isA<SubmissionUploadingState>(),
            isA<SubmissionUploadingState>(),
            isA<SubmissionProcessingState>(),
            predicate<SubmissionCompletedState>(
              (state) =>
                  state.submission.id == 'new_sub_123' &&
                  state.submission.nota == 9.0 &&
                  state.submission.acertos == 18,
            ),
          ]),
        );

        await cubit.submitAndAutoCorrect(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: validFile,
          attemptNumber: 1,
        );
      });

      test('faz UPDATE quando existe submissão anterior', () async {
        // Arrange
        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('user_123');
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        when(() => mockSupabaseClient.storage.from('exam-submissions'))
            .thenReturn(mockStorageFileApi);
        when(() => mockStorageFileApi.upload(
              any(),
              any(),
              fileOptions: any(named: 'fileOptions'),
            )).thenAnswer((_) async => 'path/to/file.jpg');
        when(() => mockStorageFileApi.getPublicUrl(any()))
            .thenReturn('https://example.com/file_new.jpg');

        // Existe submissão
        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.maybeSingle())
            .thenAnswer((_) async => {
                  'id': 'existing_sub_123',
                });

        // UPDATE
        when(() => mockQueryBuilder.update(any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('id', any()))
            .thenReturn(mockPostgrestFilterBuilder);

        // Buscar metadados da prova
        when(() => mockSupabaseClient.from('provas'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select('url_prova'))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.single()).thenAnswer((_) async => {
              'url_prova': 'https://example.com/gabarito.jpg',
            });

        // Edge Function
        final mockFunctionResponse = MockFunctionResponse();
        when(() => mockFunctionResponse.status).thenReturn(200);
        when(() => mockFunctionResponse.data).thenReturn({
          'id': 'existing_sub_123',
          'prova_id': 'prova_123',
          'aluno_id': 'aluno_456',
          'status': 'Concluida',
          'nota': 8.5,
          'acertos': 17,
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
        verify(() => mockQueryBuilder.update(
              any(that: predicate<Map<String, dynamic>>(
                (data) => data['attempt_number'] == 2,
              )),
            )).called(1);
        verify(() => mockPostgrestFilterBuilder.eq('id', 'existing_sub_123')).called(1);
      });

      test('emite erro quando usuário não está autenticado', () async {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(null);

        when(() => mockSupabaseClient.storage.from('exam-submissions'))
            .thenReturn(mockStorageFileApi);
        when(() => mockStorageFileApi.upload(
              any(),
              any(),
              fileOptions: any(named: 'fileOptions'),
            )).thenAnswer((_) async => 'path/to/file.jpg');
        when(() => mockStorageFileApi.getPublicUrl(any()))
            .thenReturn('https://example.com/file.jpg');

        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.maybeSingle())
            .thenAnswer((_) async => null);

        when(() => mockSupabaseClient.from('provas'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select('url_prova'))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.single()).thenAnswer((_) async => {
              'url_prova': 'https://example.com/gabarito.jpg',
            });

        final cubit = SubmissionCubit();
        final validFile = FakeFile('test.jpg', 1024, []);

        // Act & Assert
        expect(
          cubit.stream,
          emitsInOrder([
            isA<SubmissionUploadingState>(),
            isA<SubmissionUploadingState>(),
            isA<SubmissionUploadingState>(),
            isA<SubmissionUploadingState>(),
            isA<SubmissionUploadingState>(),
            isA<SubmissionProcessingState>(),
            predicate<SubmissionErrorState>(
              (state) =>
                  state.message.contains('não autenticado') &&
                  state.code == 'PROCESSING_ERROR',
            ),
          ]),
        );

        await cubit.submitAndAutoCorrect(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: validFile,
          attemptNumber: 1,
        );
      });

      test('emite erro quando Edge Function falha', () async {
        // Arrange
        final mockUser = MockUser();
        when(() => mockUser.id).thenReturn('user_123');
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        when(() => mockSupabaseClient.storage.from('exam-submissions'))
            .thenReturn(mockStorageFileApi);
        when(() => mockStorageFileApi.upload(
              any(),
              any(),
              fileOptions: any(named: 'fileOptions'),
            )).thenAnswer((_) async => 'path/to/file.jpg');
        when(() => mockStorageFileApi.getPublicUrl(any()))
            .thenReturn('https://example.com/file.jpg');

        when(() => mockSupabaseClient.from('submissoes'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select(any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('prova_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.eq('aluno_id', any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.maybeSingle())
            .thenAnswer((_) async => null);

        when(() => mockQueryBuilder.insert(any()))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.single()).thenAnswer((_) async => {
              'id': 'new_sub_123',
            });

        when(() => mockSupabaseClient.from('provas'))
            .thenReturn(mockQueryBuilder);
        when(() => mockQueryBuilder.select('url_prova'))
            .thenReturn(mockPostgrestFilterBuilder);
        when(() => mockPostgrestFilterBuilder.single()).thenAnswer((_) async => {
              'url_prova': 'https://example.com/gabarito.jpg',
            });

        // Edge Function falha
        final mockFunctionResponse = MockFunctionResponse();
        when(() => mockFunctionResponse.status).thenReturn(500);
        when(() => mockFunctionResponse.data)
            .thenReturn({'error': 'Internal Server Error'});
        when(() => mockFunctions.invoke('quick-api', body: any(named: 'body')))
            .thenAnswer((_) async => mockFunctionResponse);

        final cubit = SubmissionCubit();
        final validFile = FakeFile('test.jpg', 1024, []);

        // Act & Assert
        expect(
          cubit.stream,
          emitsInOrder([
            isA<SubmissionUploadingState>(),
            isA<SubmissionUploadingState>(),
            isA<SubmissionUploadingState>(),
            isA<SubmissionUploadingState>(),
            isA<SubmissionUploadingState>(),
            isA<SubmissionProcessingState>(),
            predicate<SubmissionErrorState>(
              (state) =>
                  state.message.contains('Edge Function') &&
                  state.code == 'PROCESSING_ERROR',
            ),
          ]),
        );

        await cubit.submitAndAutoCorrect(
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          imageFile: validFile,
          attemptNumber: 1,
        );
      });
    });

    group('resetToInitial', () {
      test('reseta cubit para InitialState', () {
        // Arrange
        final cubit = SubmissionCubit();

        // Act
        cubit.resetToInitial();

        // Assert
        expect(cubit.state, isA<InitialState>());
      });
    });
  });
}

// Mock adicional para User
class MockUser extends Mock implements User {}
