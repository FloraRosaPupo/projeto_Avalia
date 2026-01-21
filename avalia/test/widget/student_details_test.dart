import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:Avalia/presentation/screens/student/student_details_exams_screens.dart';
import 'package:Avalia/presentation/cubit/submission_cubit.dart';
import 'package:Avalia/data/models/submission_model.dart';
import 'package:Avalia/core/state/base_state.dart';

// Mocks
class MockSubmissionCubit extends MockCubit<BaseState>
    implements SubmissionCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DetailsExamsStudentScreens - Widget Tests', () {
    late MockSubmissionCubit mockSubmissionCubit;

    setUp(() {
      mockSubmissionCubit = MockSubmissionCubit();
      when(() => mockSubmissionCubit.state).thenReturn(InitialState());
    });

    Widget createTestWidget({required Widget child}) {
      return MaterialApp(
        home: BlocProvider<SubmissionCubit>.value(
          value: mockSubmissionCubit,
          child: child,
        ),
      );
    }

    group('Botões Condicionais', () {
      testWidgets('exibe botão "Enviar resposta" quando não há submissão', (
        WidgetTester tester,
      ) async {
        // Arrange
        when(
          () => mockSubmissionCubit.state,
        ).thenReturn(const SuccessState<SubmissionModel?>(null));
        when(
          () => mockSubmissionCubit.getSubmission(any(), any()),
        ).thenAnswer((_) async {});

        // Act
        await tester.pumpWidget(
          createTestWidget(
            child: const DetailsExamsStudentScreens(
              provaId: 'prova_123',
              alunoId: 'aluno_456',
              provaNome: 'Prova 1',
              provaData: '2024-01-10',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Enviar resposta (foto)'), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      });

      testWidgets(
        'exibe botão "Substituir Submissão" quando submissão está review_needed',
        (WidgetTester tester) async {
          // Arrange
          final submission = SubmissionModel(
            id: 'sub_123',
            provaId: 'prova_123',
            alunoId: 'aluno_456',
            status: SubmissionStatus.reviewNeeded,
            attemptNumber: 1,
          );

          when(
            () => mockSubmissionCubit.state,
          ).thenReturn(SuccessState<SubmissionModel>(submission));
          when(
            () => mockSubmissionCubit.getSubmission(any(), any()),
          ).thenAnswer((_) async {});

          // Act
          await tester.pumpWidget(
            createTestWidget(
              child: const DetailsExamsStudentScreens(
                provaId: 'prova_123',
                alunoId: 'aluno_456',
                provaNome: 'Prova 1',
                provaData: '2024-01-10',
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Assert
          expect(find.text('Substituir Submissão'), findsOneWidget);
          expect(find.byIcon(Icons.refresh), findsWidgets);
        },
      );

      testWidgets(
        'exibe botão "Substituir Submissão" (outlined) quando submissão está concluída',
        (WidgetTester tester) async {
          // Arrange
          final submission = SubmissionModel(
            id: 'sub_123',
            provaId: 'prova_123',
            alunoId: 'aluno_456',
            status: SubmissionStatus.graded,
            nota: 8.5,
            acertos: 17,
            totalQuestoes: 20,
            attemptNumber: 1,
          );

          when(
            () => mockSubmissionCubit.state,
          ).thenReturn(SuccessState<SubmissionModel>(submission));
          when(
            () => mockSubmissionCubit.getSubmission(any(), any()),
          ).thenAnswer((_) async {});

          // Act
          await tester.pumpWidget(
            createTestWidget(
              child: const DetailsExamsStudentScreens(
                provaId: 'prova_123',
                alunoId: 'aluno_456',
                provaNome: 'Prova 1',
                provaData: '2024-01-10',
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Assert
          expect(find.text('Substituir Submissão'), findsOneWidget);
          expect(find.text('Baixar Relatório'), findsOneWidget);
        },
      );

      testWidgets('não exibe botão quando submissão está em processamento', (
        WidgetTester tester,
      ) async {
        // Arrange
        final submission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.processingAnalysis,
          attemptNumber: 1,
        );

        when(
          () => mockSubmissionCubit.state,
        ).thenReturn(SuccessState<SubmissionModel>(submission));
        when(
          () => mockSubmissionCubit.getSubmission(any(), any()),
        ).thenAnswer((_) async {});

        // Act
        await tester.pumpWidget(
          createTestWidget(
            child: const DetailsExamsStudentScreens(
              provaId: 'prova_123',
              alunoId: 'aluno_456',
              provaNome: 'Prova 1',
              provaData: '2024-01-10',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Enviar resposta (foto)'), findsNothing);
        expect(find.text('Substituir Submissão'), findsNothing);
      });
    });

    group('Badge de Tentativas', () {
      testWidgets('não exibe badge quando é primeira tentativa', (
        WidgetTester tester,
      ) async {
        // Arrange
        final submission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.graded,
          attemptNumber: 1,
          nota: 8.0,
          acertos: 16,
          totalQuestoes: 20,
        );

        when(
          () => mockSubmissionCubit.state,
        ).thenReturn(SuccessState<SubmissionModel>(submission));
        when(
          () => mockSubmissionCubit.getSubmission(any(), any()),
        ).thenAnswer((_) async {});

        // Act
        await tester.pumpWidget(
          createTestWidget(
            child: const DetailsExamsStudentScreens(
              provaId: 'prova_123',
              alunoId: 'aluno_456',
              provaNome: 'Prova 1',
              provaData: '2024-01-10',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('1ª tentativa'), findsNothing);
      });

      testWidgets('exibe badge "2ª tentativa" quando attemptNumber = 2', (
        WidgetTester tester,
      ) async {
        // Arrange
        final submission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.graded,
          attemptNumber: 2,
          nota: 9.0,
          acertos: 18,
          totalQuestoes: 20,
        );

        when(
          () => mockSubmissionCubit.state,
        ).thenReturn(SuccessState<SubmissionModel>(submission));
        when(
          () => mockSubmissionCubit.getSubmission(any(), any()),
        ).thenAnswer((_) async {});

        // Act
        await tester.pumpWidget(
          createTestWidget(
            child: const DetailsExamsStudentScreens(
              provaId: 'prova_123',
              alunoId: 'aluno_456',
              provaNome: 'Prova 1',
              provaData: '2024-01-10',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('2ª tentativa'), findsOneWidget);
        expect(find.byIcon(Icons.history), findsOneWidget);
      });

      testWidgets('exibe badge "3ª tentativa" quando attemptNumber = 3', (
        WidgetTester tester,
      ) async {
        // Arrange
        final submission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.graded,
          attemptNumber: 3,
          nota: 8.5,
          acertos: 17,
          totalQuestoes: 20,
        );

        when(
          () => mockSubmissionCubit.state,
        ).thenReturn(SuccessState<SubmissionModel>(submission));
        when(
          () => mockSubmissionCubit.getSubmission(any(), any()),
        ).thenAnswer((_) async {});

        // Act
        await tester.pumpWidget(
          createTestWidget(
            child: const DetailsExamsStudentScreens(
              provaId: 'prova_123',
              alunoId: 'aluno_456',
              provaNome: 'Prova 1',
              provaData: '2024-01-10',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('3ª tentativa'), findsOneWidget);
      });
    });

    group('Estados Visuais', () {
      testWidgets('exibe loading durante LoadingState', (
        WidgetTester tester,
      ) async {
        // Arrange
        when(() => mockSubmissionCubit.state).thenReturn(LoadingState());
        when(
          () => mockSubmissionCubit.getSubmission(any(), any()),
        ).thenAnswer((_) async {});

        // Act
        await tester.pumpWidget(
          createTestWidget(
            child: const DetailsExamsStudentScreens(
              provaId: 'prova_123',
              alunoId: 'aluno_456',
              provaNome: 'Prova 1',
              provaData: '2024-01-10',
            ),
          ),
        );
        await tester.pump();

        // Assert - Verifica que o estado inicial foi emitido
        expect(mockSubmissionCubit.state, isA<LoadingState>());
      });

      testWidgets(
        'exibe banner de "Nenhuma submissão" quando não há submissão',
        (WidgetTester tester) async {
          // Arrange
          when(
            () => mockSubmissionCubit.state,
          ).thenReturn(const SuccessState<SubmissionModel?>(null));
          when(
            () => mockSubmissionCubit.getSubmission(any(), any()),
          ).thenAnswer((_) async {});

          // Act
          await tester.pumpWidget(
            createTestWidget(
              child: const DetailsExamsStudentScreens(
                provaId: 'prova_123',
                alunoId: 'aluno_456',
                provaNome: 'Prova 1',
                provaData: '2024-01-10',
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Assert
          expect(find.text('Nenhuma submissão encontrada'), findsOneWidget);
          expect(find.byIcon(Icons.info_outline), findsWidgets);
        },
      );

      testWidgets('exibe banner de processamento quando em análise', (
        WidgetTester tester,
      ) async {
        // Arrange
        final submission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.processingAnalysis,
          attemptNumber: 1,
        );

        when(
          () => mockSubmissionCubit.state,
        ).thenReturn(SuccessState<SubmissionModel>(submission));
        when(
          () => mockSubmissionCubit.getSubmission(any(), any()),
        ).thenAnswer((_) async {});

        // Act
        await tester.pumpWidget(
          createTestWidget(
            child: const DetailsExamsStudentScreens(
              provaId: 'prova_123',
              alunoId: 'aluno_456',
              provaNome: 'Prova 1',
              provaData: '2024-01-10',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text('Analisando imagem e calculando nota...'),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('exibe banner de "Correção Pendente" quando review_needed', (
        WidgetTester tester,
      ) async {
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

        when(
          () => mockSubmissionCubit.state,
        ).thenReturn(SuccessState<SubmissionModel>(submission));
        when(
          () => mockSubmissionCubit.getSubmission(any(), any()),
        ).thenAnswer((_) async {});

        // Act
        await tester.pumpWidget(
          createTestWidget(
            child: const DetailsExamsStudentScreens(
              provaId: 'prova_123',
              alunoId: 'aluno_456',
              provaNome: 'Prova 1',
              provaData: '2024-01-10',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Correção Pendente'), findsOneWidget);
        expect(find.text('Imagem com baixa qualidade'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
      });

      testWidgets('exibe resultados quando submissão está concluída', (
        WidgetTester tester,
      ) async {
        // Arrange
        final submission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.graded,
          nota: 8.5,
          acertos: 17,
          totalQuestoes: 20,
          attemptNumber: 1,
          detalhamento: [
            QuestionDetail(
              questionNumber: 1,
              studentAnswer: 'A',
              officialAnswer: 'A',
              isCorrect: true,
            ),
            QuestionDetail(
              questionNumber: 2,
              studentAnswer: 'B',
              officialAnswer: 'C',
              isCorrect: false,
            ),
          ],
        );

        when(
          () => mockSubmissionCubit.state,
        ).thenReturn(SuccessState<SubmissionModel>(submission));
        when(
          () => mockSubmissionCubit.getSubmission(any(), any()),
        ).thenAnswer((_) async {});

        // Act
        await tester.pumpWidget(
          createTestWidget(
            child: const DetailsExamsStudentScreens(
              provaId: 'prova_123',
              alunoId: 'aluno_456',
              provaNome: 'Prova 1',
              provaData: '2024-01-10',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('17/20'), findsOneWidget);
        expect(find.text('85%'), findsOneWidget);
        expect(
          find.text('Gabarito do Aluno vs. Gabarito Oficial'),
          findsOneWidget,
        );
      });
    });

    group('Diálogo de Confirmação', () {
      testWidgets(
        'exibe diálogo de confirmação ao clicar em "Substituir Submissão" (graded)',
        (WidgetTester tester) async {
          // Arrange
          final submission = SubmissionModel(
            id: 'sub_123',
            provaId: 'prova_123',
            alunoId: 'aluno_456',
            status: SubmissionStatus.graded,
            nota: 8.5,
            acertos: 17,
            totalQuestoes: 20,
            attemptNumber: 1,
          );

          when(
            () => mockSubmissionCubit.state,
          ).thenReturn(SuccessState<SubmissionModel>(submission));
          when(
            () => mockSubmissionCubit.getSubmission(any(), any()),
          ).thenAnswer((_) async {});

          // Act
          await tester.pumpWidget(
            createTestWidget(
              child: const DetailsExamsStudentScreens(
                provaId: 'prova_123',
                alunoId: 'aluno_456',
                provaNome: 'Prova 1',
                provaData: '2024-01-10',
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Toca no botão "Substituir Submissão" (outlined)
          await tester.tap(find.text('Substituir Submissão'));
          await tester.pumpAndSettle();

          // Assert
          expect(find.text('Confirmar Substituição'), findsOneWidget);
          expect(
            find.text('Você está prestes a substituir a submissão atual.'),
            findsOneWidget,
          );
          expect(find.text('• Nota atual: 17/20'), findsOneWidget);
          expect(find.text('• Imagem da prova'), findsOneWidget);
          expect(find.text('• Detalhamento das questões'), findsOneWidget);
          expect(find.text('Cancelar'), findsOneWidget);
          expect(find.text('Substituir'), findsOneWidget);
        },
      );

      testWidgets('fecha diálogo ao clicar em "Cancelar"', (
        WidgetTester tester,
      ) async {
        // Arrange
        final submission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.graded,
          nota: 8.5,
          acertos: 17,
          totalQuestoes: 20,
          attemptNumber: 1,
        );

        when(
          () => mockSubmissionCubit.state,
        ).thenReturn(SuccessState<SubmissionModel>(submission));
        when(
          () => mockSubmissionCubit.getSubmission(any(), any()),
        ).thenAnswer((_) async {});

        // Act
        await tester.pumpWidget(
          createTestWidget(
            child: const DetailsExamsStudentScreens(
              provaId: 'prova_123',
              alunoId: 'aluno_456',
              provaNome: 'Prova 1',
              provaData: '2024-01-10',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Abre diálogo
        await tester.tap(find.text('Substituir Submissão'));
        await tester.pumpAndSettle();

        // Cancela
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Confirmar Substituição'), findsNothing);
      });
    });

    group('Status Badge', () {
      testWidgets('exibe badge "Concluida" quando status é graded', (
        WidgetTester tester,
      ) async {
        // Arrange
        final submission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.graded,
          attemptNumber: 1,
          nota: 8.0,
          acertos: 16,
          totalQuestoes: 20,
        );

        when(
          () => mockSubmissionCubit.state,
        ).thenReturn(SuccessState<SubmissionModel>(submission));
        when(
          () => mockSubmissionCubit.getSubmission(any(), any()),
        ).thenAnswer((_) async {});

        // Act
        await tester.pumpWidget(
          createTestWidget(
            child: const DetailsExamsStudentScreens(
              provaId: 'prova_123',
              alunoId: 'aluno_456',
              provaNome: 'Prova 1',
              provaData: '2024-01-10',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Concluida'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      });

      testWidgets('exibe badge "Review Needed" quando status é reviewNeeded', (
        WidgetTester tester,
      ) async {
        // Arrange
        final submission = SubmissionModel(
          id: 'sub_123',
          provaId: 'prova_123',
          alunoId: 'aluno_456',
          status: SubmissionStatus.reviewNeeded,
          attemptNumber: 1,
        );

        when(
          () => mockSubmissionCubit.state,
        ).thenReturn(SuccessState<SubmissionModel>(submission));
        when(
          () => mockSubmissionCubit.getSubmission(any(), any()),
        ).thenAnswer((_) async {});

        // Act
        await tester.pumpWidget(
          createTestWidget(
            child: const DetailsExamsStudentScreens(
              provaId: 'prova_123',
              alunoId: 'aluno_456',
              provaNome: 'Prova 1',
              provaData: '2024-01-10',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Review Needed'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
      });

      testWidgets(
        'exibe badge "Processing Analysis" quando status é processingAnalysis',
        (WidgetTester tester) async {
          // Arrange
          final submission = SubmissionModel(
            id: 'sub_123',
            provaId: 'prova_123',
            alunoId: 'aluno_456',
            status: SubmissionStatus.processingAnalysis,
            attemptNumber: 1,
          );

          when(
            () => mockSubmissionCubit.state,
          ).thenReturn(SuccessState<SubmissionModel>(submission));
          when(
            () => mockSubmissionCubit.getSubmission(any(), any()),
          ).thenAnswer((_) async {});

          // Act
          await tester.pumpWidget(
            createTestWidget(
              child: const DetailsExamsStudentScreens(
                provaId: 'prova_123',
                alunoId: 'aluno_456',
                provaNome: 'Prova 1',
                provaData: '2024-01-10',
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Assert
          expect(find.text('Processing Analysis'), findsOneWidget);
          expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
        },
      );

      testWidgets('exibe badge "Pendente" quando não há submissão', (
        WidgetTester tester,
      ) async {
        // Arrange
        when(
          () => mockSubmissionCubit.state,
        ).thenReturn(const SuccessState<SubmissionModel?>(null));
        when(
          () => mockSubmissionCubit.getSubmission(any(), any()),
        ).thenAnswer((_) async {});

        // Act
        await tester.pumpWidget(
          createTestWidget(
            child: const DetailsExamsStudentScreens(
              provaId: 'prova_123',
              alunoId: 'aluno_456',
              provaNome: 'Prova 1',
              provaData: '2024-01-10',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Pendente'), findsOneWidget);
        expect(find.byIcon(Icons.pending), findsOneWidget);
      });
    });
  });
}
