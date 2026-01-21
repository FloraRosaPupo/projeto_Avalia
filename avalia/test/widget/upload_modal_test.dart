import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:Avalia/presentation/widgets/submission_upload_modal.dart';
import 'package:Avalia/presentation/cubit/submission_cubit.dart';
import 'package:Avalia/data/models/submission_model.dart';
import 'package:Avalia/core/state/base_state.dart';

// Mocks
class MockSubmissionCubit extends MockCubit<BaseState>
    implements SubmissionCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubmissionUploadModal - Widget Tests', () {
    late MockSubmissionCubit mockSubmissionCubit;

    setUp(() {
      mockSubmissionCubit = MockSubmissionCubit();
      when(() => mockSubmissionCubit.state).thenReturn(InitialState());
    });

    Widget createTestWidget({
      SubmissionModel? existingSubmission,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => BlocProvider<SubmissionCubit>.value(
                      value: mockSubmissionCubit,
                      child: SubmissionUploadModal(
                        provaId: 'prova_123',
                        alunoId: 'aluno_456',
                        existingSubmission: existingSubmission,
                      ),
                    ),
                  );
                },
                child: const Text('Open Modal'),
              );
            },
          ),
        ),
      );
    }

    group('Contexto Visual', () {
      testWidgets('exibe título "Enviar Resposta" quando é primeira submissão',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockSubmissionCubit.state).thenReturn(InitialState());

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Enviar Resposta'), findsOneWidget);
      });

      testWidgets(
          'exibe título "Substituir Submissão" quando é substituição',
          (WidgetTester tester) async {
        // Arrange
        final existingSubmission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.graded,
          attemptNumber: 1,
        );

        when(() => mockSubmissionCubit.state).thenReturn(InitialState());

        // Act
        await tester.pumpWidget(
          createTestWidget(existingSubmission: existingSubmission),
        );
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Substituir Submissão'), findsOneWidget);
      });

      testWidgets('exibe badge de tentativa quando é substituição',
          (WidgetTester tester) async {
        // Arrange
        final existingSubmission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.graded,
          attemptNumber: 2, // 2ª tentativa anterior
        );

        when(() => mockSubmissionCubit.state).thenReturn(InitialState());

        // Act
        await tester.pumpWidget(
          createTestWidget(existingSubmission: existingSubmission),
        );
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Tentativa 3'), findsOneWidget); // Próxima tentativa
      });

      testWidgets(
          'exibe mensagem de aviso laranja quando é substituição',
          (WidgetTester tester) async {
        // Arrange
        final existingSubmission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.graded,
          attemptNumber: 1,
        );

        when(() => mockSubmissionCubit.state).thenReturn(InitialState());

        // Act
        await tester.pumpWidget(
          createTestWidget(existingSubmission: existingSubmission),
        );
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text(
              'Esta nova imagem substituirá a submissão anterior e será recorrigida pela IA'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.refresh), findsWidgets);
      });

      testWidgets(
          'exibe mensagem informativa azul quando é primeira submissão',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockSubmissionCubit.state).thenReturn(InitialState());

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text('Certifique-se de marcar claramente as bolhas (A–E)'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.info_outline), findsWidgets);
      });

      testWidgets('exibe informações de tamanho máximo e formatos',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockSubmissionCubit.state).thenReturn(InitialState());

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text('Tamanho máximo: 50MB | Formatos: JPG, PNG'),
          findsOneWidget,
        );
      });
    });

    group('Botões de Seleção de Origem', () {
      testWidgets('exibe botão "Tirar Foto"', (WidgetTester tester) async {
        // Arrange
        when(() => mockSubmissionCubit.state).thenReturn(InitialState());

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Tirar Foto'), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      });

      testWidgets('exibe botão "Selecionar da Galeria"',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockSubmissionCubit.state).thenReturn(InitialState());

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Selecionar da Galeria'), findsOneWidget);
        expect(find.byIcon(Icons.photo_library), findsOneWidget);
      });
    });

    group('Estados de Upload', () {
      testWidgets('exibe progresso durante SubmissionUploadingState',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockSubmissionCubit.state)
            .thenReturn(SubmissionUploadingState(50));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Fazendo upload...'), findsOneWidget);
        expect(find.text('50%'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('exibe progresso 0% no início do upload',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockSubmissionCubit.state)
            .thenReturn(SubmissionUploadingState(0));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('0%'), findsOneWidget);
      });

      testWidgets('exibe progresso 100% no final do upload',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockSubmissionCubit.state)
            .thenReturn(SubmissionUploadingState(100));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('100%'), findsOneWidget);
      });
    });

    group('Estados de Processamento', () {
      testWidgets('exibe "IA analisando" durante SubmissionProcessingState',
          (WidgetTester tester) async {
        // Arrange
        final submission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.processingAnalysis,
          attemptNumber: 1,
        );

        when(() => mockSubmissionCubit.state)
            .thenReturn(SubmissionProcessingState('analysis', submission));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Corrigindo com IA'), findsOneWidget);
        expect(find.text('IA analisando suas respostas...'), findsOneWidget);
        expect(find.text('Identificando questões e marcações...'),
            findsOneWidget);
      });

      testWidgets('exibe "Calculando nota" durante grading',
          (WidgetTester tester) async {
        // Arrange
        final submission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.processingAnalysis,
          attemptNumber: 1,
        );

        when(() => mockSubmissionCubit.state)
            .thenReturn(SubmissionProcessingState('grading', submission));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Calculando nota'), findsOneWidget);
        expect(find.text('Enviando resultado para o servidor...'),
            findsOneWidget);
      });
    });

    group('Preview de Imagem', () {
      testWidgets('exibe título correto no preview para primeira submissão',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockSubmissionCubit.state)
            .thenReturn(SubmissionPreviewState(FakeMockFile()));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Preview da Resposta'), findsOneWidget);
      });

      testWidgets('exibe título correto no preview para substituição',
          (WidgetTester tester) async {
        // Arrange
        final existingSubmission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.graded,
          attemptNumber: 1,
        );

        when(() => mockSubmissionCubit.state)
            .thenReturn(SubmissionPreviewState(FakeMockFile()));

        // Act
        await tester.pumpWidget(
          createTestWidget(existingSubmission: existingSubmission),
        );
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Preview da Substituição'), findsOneWidget);
      });

      testWidgets('exibe botões "Trocar" e "Enviar" no preview',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockSubmissionCubit.state)
            .thenReturn(SubmissionPreviewState(FakeMockFile()));

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Trocar'), findsOneWidget);
        expect(find.text('Enviar'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsWidgets);
        expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
      });

      testWidgets('exibe botão "Substituir" no preview de substituição',
          (WidgetTester tester) async {
        // Arrange
        final existingSubmission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.graded,
          attemptNumber: 1,
        );

        when(() => mockSubmissionCubit.state)
            .thenReturn(SubmissionPreviewState(FakeMockFile()));

        // Act
        await tester.pumpWidget(
          createTestWidget(existingSubmission: existingSubmission),
        );
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Substituir'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsWidgets);
      });
    });

    group('Estado de Erro', () {
      testWidgets('exibe SnackBar com erro em SubmissionErrorState',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockSubmissionCubit.state).thenReturn(InitialState());
        whenListen(
          mockSubmissionCubit,
          Stream.fromIterable([
            InitialState(),
            SubmissionErrorState('Erro ao enviar', 'UPLOAD_ERROR'),
          ]),
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Simular mudança de estado
        await tester.pump();

        // Assert
        expect(find.text('❌ Erro ao enviar'), findsOneWidget);
      });

      testWidgets('SnackBar de erro tem botão "Tentar novamente"',
          (WidgetTester tester) async {
        // Arrange
        when(() => mockSubmissionCubit.state).thenReturn(InitialState());
        whenListen(
          mockSubmissionCubit,
          Stream.fromIterable([
            InitialState(),
            SubmissionErrorState(
                'Erro de validação', 'VALIDATION_ERROR'),
          ]),
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Simular mudança de estado
        await tester.pump();

        // Assert
        expect(find.text('Tentar novamente'), findsOneWidget);
      });
    });

    group('Estado de Sucesso', () {
      testWidgets('fecha modal e exibe SnackBar em SubmissionCompletedState',
          (WidgetTester tester) async {
        // Arrange
        final completedSubmission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.graded,
          nota: 9.0,
          acertos: 18,
          totalQuestoes: 20,
          attemptNumber: 1,
        );

        when(() => mockSubmissionCubit.state).thenReturn(InitialState());
        whenListen(
          mockSubmissionCubit,
          Stream.fromIterable([
            InitialState(),
            SubmissionCompletedState(completedSubmission),
          ]),
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Simular mudança de estado
        await tester.pump();

        // Assert
        expect(find.text('✅ Corrigido! Nota: 9.0. Submetendo resultado...'),
            findsOneWidget);
      });
    });

    group('Review Needed', () {
      testWidgets('exibe tela de revisão necessária em SubmissionNeedsReviewState',
          (WidgetTester tester) async {
        // Arrange
        final submission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.reviewNeeded,
          attemptNumber: 1,
          issues: [
            SubmissionIssue(
              type: 'IMAGE_QUALITY',
              message: 'Imagem com baixa qualidade',
              severity: 'warning',
            ),
          ],
        );

        when(() => mockSubmissionCubit.state).thenReturn(
          SubmissionNeedsReviewState(submission.issues!, submission),
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Revisão Necessária'), findsOneWidget);
        expect(find.text('A submissão precisa ser revisada.'), findsOneWidget);
        expect(find.text('Imagem com baixa qualidade'), findsOneWidget);
      });

      testWidgets('exibe múltiplos issues em SubmissionNeedsReviewState',
          (WidgetTester tester) async {
        // Arrange
        final submission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.reviewNeeded,
          attemptNumber: 1,
          issues: [
            SubmissionIssue(
              type: 'IMAGE_QUALITY',
              message: 'Imagem com baixa qualidade',
              severity: 'warning',
            ),
            SubmissionIssue(
              type: 'BLUR_DETECTED',
              message: 'Imagem está desfocada',
              severity: 'error',
            ),
          ],
        );

        when(() => mockSubmissionCubit.state).thenReturn(
          SubmissionNeedsReviewState(submission.issues!, submission),
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.text('Open Modal'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Imagem com baixa qualidade'), findsOneWidget);
        expect(find.text('Imagem está desfocada'), findsOneWidget);
      });
    });
  });
}

// Mock adicional para File (usado no SubmissionPreviewState)
class FakeMockFile extends Fake implements File {
  @override
  String get path => 'test.jpg';
}

class File {}
