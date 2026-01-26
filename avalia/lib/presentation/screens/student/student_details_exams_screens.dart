import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avalia/core/state/base_state.dart';
import 'package:avalia/data/models/submission_model.dart';
import 'package:avalia/presentation/cubit/submission_cubit.dart';
import 'package:avalia/presentation/widgets/submission_upload_modal.dart';
import 'package:avalia/core/navigation/app_route_observer.dart';

class DetailsExamsStudentScreens extends StatefulWidget {
  final String provaId;
  final String alunoId;
  final String? provaNome;
  final String? provaData;

  const DetailsExamsStudentScreens({
    super.key,
    required this.provaId,
    required this.alunoId,
    this.provaNome,
    this.provaData,
  });

  @override
  State<DetailsExamsStudentScreens> createState() =>
      _DetailsExamsStudentScreensState();
}

class _DetailsExamsStudentScreensState
    extends AutoRefreshRouteAwareState<DetailsExamsStudentScreens> {
  SubmissionCubit? _cubit;

  @override
  Future<void> refreshData() async {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          print('ERROR: refreshData - Widget não está montado');
          return;
        }
        final cubit = _cubit;
        if (cubit == null) {
          print('ERROR: refreshData - Cubit é null');
          return;
        }
        print(
          'DEBUG: refreshData - Buscando submissão para provaId: ${widget.provaId}, alunoId: ${widget.alunoId}',
        );
        cubit.getSubmission(widget.provaId, widget.alunoId);
      });
    } catch (e, stackTrace) {
      print('ERROR: refreshData - Exceção ao atualizar dados: $e');
      print('ERROR: StackTrace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        try {
          print('DEBUG: BlocProvider.create - Criando SubmissionCubit');
          print(
            'DEBUG: provaId: ${widget.provaId}, alunoId: ${widget.alunoId}',
          );
          final cubit = SubmissionCubit();
          _cubit = cubit;
          cubit.getSubmission(widget.provaId, widget.alunoId);
          print('DEBUG: BlocProvider.create - getSubmission chamado');
          return cubit;
        } catch (e, stackTrace) {
          print('ERROR: BlocProvider.create - Erro ao criar cubit: $e');
          print('ERROR: StackTrace: $stackTrace');
          final cubit = SubmissionCubit();
          _cubit = cubit;
          return cubit;
        }
      },
      child: BlocListener<SubmissionCubit, BaseState>(
        listener: (context, state) {
          if (state is SubmissionCompletedState) {
            print('DEBUG: SubmissionCompletedState - Submissão concluída');
            // Atualizar submissão na tela
            context.read<SubmissionCubit>().updateSubmission(state.submission);
            // Buscar dados atualizados do banco
            context.read<SubmissionCubit>().getSubmission(
              widget.provaId,
              widget.alunoId,
            );
            // Mostrar mensagem de sucesso
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Submissão substituída com sucesso! Nota: ${state.submission.acertos ?? 0}/${state.submission.totalQuestoes ?? 0}',
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is SubmissionErrorState) {
            print('ERROR: SubmissionErrorState - ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${state.message}'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Tentar novamente',
                  textColor: Colors.white,
                  onPressed: () {
                    // Não faz nada - o usuário precisa clicar no botão novamente
                  },
                ),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            shadowColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Detalhes da Prova',
              style: TextStyle(color: Colors.black),
            ),
          ),
          body: BlocBuilder<SubmissionCubit, BaseState>(
            builder: (context, state) {
              print('DEBUG: Current State: $state');
              print('DEBUG: State Type: ${state.runtimeType}');

              // Tratamento de erros
              if (state is ErrorState) {
                print(
                  'ERROR: ErrorState detectado - Mensagem: ${state.message}',
                );
                print(
                  'ERROR: Context - provaId: ${widget.provaId}, alunoId: ${widget.alunoId}',
                );
              }

              SubmissionModel? submission;

              if (state is SuccessState<SubmissionModel>) {
                submission = state.data;
                print(
                  'DEBUG: SuccessState<SubmissionModel> - Submission carregada',
                );
              } else if (state is SuccessState<SubmissionModel?>) {
                submission = state.data;
                print(
                  'DEBUG: SuccessState<SubmissionModel?> - Submission: ${submission != null ? "existe" : "null"}',
                );
              } else if (state is LoadingState) {
                print('DEBUG: LoadingState - Carregando submissão...');
              } else if (state is InitialState) {
                print('DEBUG: InitialState - Estado inicial');
              }

              print('DEBUG: Submission Object: $submission');
              if (submission != null) {
                print('DEBUG: Submission Status: ${submission.status}');
                print('DEBUG: Submission ID: ${submission.id}');
                print(
                  'DEBUG: Submission Acertos: ${submission.acertos}/${submission.totalQuestoes}',
                );
              } else {
                print(
                  'WARNING: Submission é null - Nenhuma submissão encontrada',
                );
              }

              // Mostrar erro se houver
              if (state is ErrorState) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 100),
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar dados',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            _cubit?.getSubmission(
                              widget.provaId,
                              widget.alunoId,
                            );
                          },
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Mostrar loading
              if (state is LoadingState) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card de informações da prova
                      _buildExamInfoCard(submission),
                      const SizedBox(height: 16),

                      // Banner de submissão ou resultados
                      if (submission == null)
                        _buildNoSubmissionBanner(context)
                      else if (submission.status ==
                          SubmissionStatus.reviewNeeded)
                        _buildReviewNeededBanner(context, submission)
                      else if (submission.status == SubmissionStatus.graded)
                        _buildGradedContent(submission)
                      else
                        _buildProcessingBanner(submission),

                      const SizedBox(height: 16),

                      // Botão de submissão (se não houver submissão ou se precisar reenviar)
                      if (submission == null ||
                          submission.status == SubmissionStatus.reviewNeeded ||
                          submission.status == SubmissionStatus.graded)
                        _buildSubmissionButton(context, submission),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExamInfoCard(SubmissionModel? submission) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.provaNome ?? 'Nome da Prova',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Data: ${widget.provaData ?? "12/05/2023"}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (submission != null && submission.attemptNumber > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history,
                        size: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${submission.attemptNumber}ª tentativa',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusBadge(submission),
          if (submission?.status == SubmissionStatus.graded) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _scoreCard(
                    label: 'Nota',
                    value: '${submission!.acertos}/${submission.totalQuestoes}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _scoreCard(
                    label: 'Aproveitamento',
                    value: _calculatePercentage(
                      submission.acertos,
                      submission.totalQuestoes,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _calculatePercentage(int? acertos, int? totalQuestoes) {
    try {
      if (acertos == null || totalQuestoes == null || totalQuestoes == 0) {
        print(
          'WARNING: _calculatePercentage - Valores inválidos: acertos=$acertos, totalQuestoes=$totalQuestoes',
        );
        return '0%';
      }
      final percentage = ((acertos / totalQuestoes) * 100).toInt();
      return '$percentage%';
    } catch (e, stackTrace) {
      print('ERROR: _calculatePercentage - Erro ao calcular porcentagem: $e');
      print('ERROR: StackTrace: $stackTrace');
      return '0%';
    }
  }

  Widget _scoreCard({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SubmissionModel? submission) {
    if (submission == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pending, color: Colors.black),
            const SizedBox(width: 8),
            Text(
              submission?.status.formatted ?? 'Pendente',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    Color badgeColor;
    IconData badgeIcon;

    switch (submission.status) {
      case SubmissionStatus.graded:
        badgeColor = const Color.fromARGB(59, 132, 231, 135);
        badgeIcon = Icons.check_circle_outline;
        break;
      case SubmissionStatus.reviewNeeded:
        badgeColor = const Color.fromARGB(26, 247, 180, 80);
        badgeIcon = Icons.warning_amber_rounded;
        break;
      case SubmissionStatus.processingAnalysis:
      case SubmissionStatus.aiValidation:
        badgeColor = Colors.blue.shade50;
        badgeIcon = Icons.hourglass_empty;
        break;
      default:
        badgeColor = Colors.grey.shade200;
        badgeIcon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: Colors.black),
          const SizedBox(width: 8),
          Text(
            submission.status.formatted,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubmissionBanner(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).primaryColor,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nenhuma submissão encontrada',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Envie uma foto da sua prova para correção automática',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewNeededBanner(
    BuildContext context,
    SubmissionModel submission,
  ) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Correção Pendente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Problemas detectados na imagem enviada:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 8),
            if (submission.issues != null)
              ...submission.issues!.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          issue.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingBanner(SubmissionModel submission) {
    String message;
    switch (submission.status) {
      case SubmissionStatus.processingUpload:
        message = 'Upload em andamento...';
        break;
      case SubmissionStatus.processingAnalysis:
        message = 'Analisando imagem e calculando nota...';
        break;
      case SubmissionStatus.aiValidation:
        message = 'Validando qualidade da imagem...';
        break;
      default:
        message = 'Processando submissão...';
    }

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradedContent(SubmissionModel submission) {
    try {
      if (submission.detalhamento == null || submission.detalhamento!.isEmpty) {
        print('WARNING: _buildGradedContent - Detalhamento está null ou vazio');
        return const SizedBox.shrink();
      }

      print(
        'DEBUG: _buildGradedContent - Renderizando ${submission.detalhamento!.length} questões',
      );

      return Column(
        children: [
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gabarito do Aluno vs. Gabarito Oficial',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _headerRow(),
                  const Divider(height: 16),
                  ListView.separated(
                    itemCount: submission.detalhamento!.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (_, index) {
                      final detail = submission.detalhamento![index];
                      return _answerRow(detail);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (submission.imageUrl != null)
            SizedBox(
              width: double.infinity,
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Anexo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          submission.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              print(
                                'DEBUG: Imagem carregada com sucesso: ${submission.imageUrl}',
                              );
                              return child;
                            }

                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('ERROR: Erro ao carregar imagem: $error');
                            print(
                              'ERROR: URL da imagem: ${submission.imageUrl}',
                            );
                            print('ERROR: StackTrace: $stackTrace');
                            return Container(
                              height: 200,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    } catch (e, stackTrace) {
      print('ERROR: _buildGradedContent - Erro ao construir conteúdo: $e');
      print('ERROR: StackTrace: $stackTrace');
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Erro ao carregar detalhamento: $e',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
  }

  Widget _buildSubmissionButton(
    BuildContext context,
    SubmissionModel? existingSubmission,
  ) {
    // Só permite substituir se a submissão existir E estiver corrigida
    if (existingSubmission != null &&
        existingSubmission.status == SubmissionStatus.graded) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openReplaceModal(context, existingSubmission),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Substituir Submissão',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Theme.of(context).colorScheme.secondary,
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'A nota atual será substituída pela nova correção',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: existingSubmission == null
            ? () => _openSubmissionModal(context, existingSubmission)
            : null, // Ação removida para substituir - será criada do zero
        icon: Icon(
          existingSubmission == null ? Icons.camera_alt : Icons.refresh,
        ),
        label: Text(
          existingSubmission == null
              ? 'Enviar resposta (foto)'
              : 'Substituir Submissão',
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: existingSubmission == null
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _openReplaceModal(
    BuildContext context,
    SubmissionModel existingSubmission,
  ) async {
    try {
      // Validação: garantir que a submissão existe e tem ID válido
      if (existingSubmission.id == null || existingSubmission.id!.isEmpty) {
        print('ERROR: _openReplaceModal - Submission ID é null ou vazio');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Erro: Submissão inválida. Não é possível substituir.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print(
        'DEBUG: _openReplaceModal - Abrindo modal para substituir submissão',
      );
      print('DEBUG: Submission ID: ${existingSubmission.id}');

      // Abrir modal para selecionar nova imagem e processar substituição
      final result = await showModalBottomSheet<SubmissionModel>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _ReplaceImageModal(
          submissionId: existingSubmission.id!,
          provaId: widget.provaId,
          alunoId: widget.alunoId,
        ),
      );

      if (result != null && context.mounted) {
        print('DEBUG: _openReplaceModal - Submissão substituída: ${result.id}');
        print('DEBUG: Status da nova submissão: ${result.status}');

        // Atualizar a tela com a nova submissão imediatamente
        try {
          context.read<SubmissionCubit>().updateSubmission(result);
          print('DEBUG: _openReplaceModal - Submissão atualizada no cubit');
        } catch (e, stackTrace) {
          print('ERROR: _openReplaceModal - Erro ao atualizar submissão: $e');
          print('ERROR: StackTrace: $stackTrace');
        }

        // Buscar dados atualizados do banco (para garantir sincronia)
        try {
          context.read<SubmissionCubit>().getSubmission(
            widget.provaId,
            widget.alunoId,
          );
          print(
            'DEBUG: _openReplaceModal - Buscando submissão atualizada do banco',
          );
        } catch (e, stackTrace) {
          print('ERROR: _openReplaceModal - Erro ao buscar submissão: $e');
          print('ERROR: StackTrace: $stackTrace');
        }
      } else {
        print('DEBUG: _openReplaceModal - Modal fechado sem resultado');
      }
    } catch (e, stackTrace) {
      print('ERROR: _openReplaceModal - Erro: $e');
      print('ERROR: StackTrace: $stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir modal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openSubmissionModal(
    BuildContext context,
    SubmissionModel? existingSubmission,
  ) async {
    try {
      print('DEBUG: _openSubmissionModal - Abrindo modal de submissão');
      print('DEBUG: provaId: ${widget.provaId}, alunoId: ${widget.alunoId}');
      print(
        'DEBUG: existingSubmission: ${existingSubmission != null ? "existe" : "null"}',
      );

      final result = await showModalBottomSheet<SubmissionModel>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SubmissionUploadModal(
          provaId: widget.provaId,
          alunoId: widget.alunoId,
          existingSubmission: existingSubmission,
        ),
      );

      if (result != null) {
        print(
          'DEBUG: _openSubmissionModal - Nova submissão recebida: ${result.id}',
        );
        print('DEBUG: Status da nova submissão: ${result.status}');

        // Atualizar a tela com a nova submissão imediatamente
        try {
          context.read<SubmissionCubit>().updateSubmission(result);
          print('DEBUG: _openSubmissionModal - Submissão atualizada no cubit');
        } catch (e, stackTrace) {
          print(
            'ERROR: _openSubmissionModal - Erro ao atualizar submissão: $e',
          );
          print('ERROR: StackTrace: $stackTrace');
        }

        // Buscar dados atualizados do banco (para garantir sincronia)
        try {
          context.read<SubmissionCubit>().getSubmission(
            widget.provaId,
            widget.alunoId,
          );
          print(
            'DEBUG: _openSubmissionModal - Buscando submissão atualizada do banco',
          );
        } catch (e, stackTrace) {
          print('ERROR: _openSubmissionModal - Erro ao buscar submissão: $e');
          print('ERROR: StackTrace: $stackTrace');
        }
      } else {
        print('DEBUG: _openSubmissionModal - Modal fechado sem resultado');
      }
    } catch (e, stackTrace) {
      print('ERROR: _openSubmissionModal - Erro ao abrir modal: $e');
      print('ERROR: StackTrace: $stackTrace');
    }
  }

  Widget _headerRow() {
    return Row(
      children: const [
        SizedBox(
          width: 28,
          child: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Center(
            child: Text('Aluno', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Oficial',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(width: 28),
      ],
    );
  }

  Widget _answerRow(QuestionDetail detail) {
    return Row(
      children: [
        SizedBox(width: 28, child: Text('${detail.questionNumber}.')),
        Expanded(child: Center(child: Text(detail.studentAnswer ?? '-'))),
        Expanded(child: Center(child: Text(detail.officialAnswer))),
        SizedBox(
          width: 28,
          child: Icon(
            detail.isCorrect ? Icons.check_circle : Icons.cancel,
            color: detail.isCorrect ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
      ],
    );
  }
}

// Modal simples para selecionar nova imagem para substituição
class _ReplaceImageModal extends StatefulWidget {
  final String submissionId;
  final String provaId;
  final String alunoId;

  const _ReplaceImageModal({
    required this.submissionId,
    required this.provaId,
    required this.alunoId,
  });

  @override
  State<_ReplaceImageModal> createState() => _ReplaceImageModalState();
}

class _ReplaceImageModalState extends State<_ReplaceImageModal> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      print('ERROR: Erro ao selecionar imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return BlocProvider(
      create: (_) => SubmissionCubit(),
      child: BlocConsumer<SubmissionCubit, BaseState>(
        listener: (context, state) {
          if (state is SubmissionCompletedState) {
            Navigator.pop(context, state.submission);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Submissão substituída e corrigida! Nota: ${state.submission.nota ?? 0}.',
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is SubmissionErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Erro ao substituir: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SubmissionUploadingState) {
            return _buildUploadProgress(context);
          } else if (state is SubmissionProcessingState) {
            return _buildProcessingView(context, state);
          } else if (_selectedImage == null) {
            return _buildImageSourceSelection(context);
          } else {
            return _buildImagePreview(context, userId);
          }
        },
      ),
    );
  }

  Widget _buildImageSourceSelection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Substituir Imagem',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSourceButton(
            icon: Icons.camera_alt,
            label: 'Tirar Foto',
            onTap: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(height: 12),
          _buildSourceButton(
            icon: Icons.photo_library,
            label: 'Selecionar da Galeria',
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context, String? userId) {
    if (userId == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Text('Erro: Usuário não autenticado'),
      );
    }

    // Converter IDs para int
    final submissionIdInt = int.tryParse(widget.submissionId);
    final provaIdInt = int.tryParse(widget.provaId);
    final alunoIdInt = int.tryParse(widget.alunoId);

    if (submissionIdInt == null || provaIdInt == null || alunoIdInt == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Text('Erro: IDs inválidos'),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Substituir Imagem',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                _selectedImage!,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Trocar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context
                        .read<SubmissionCubit>()
                        .replaceSubmissionWithQuickFunction(
                          submissionId: submissionIdInt,
                          imageFile: _selectedImage!,
                          userId: userId,
                        );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress(BuildContext context) {
    String stepText = 'Enviando imagem...';
    List<String> stepDescriptions = [
      'Preparando envio...',
      'Iniciando upload...',
      'Enviando dados...',
      'Processando imagem...',
      'Quase pronto...',
      'Finalizando...',
      'Upload concluído!',
    ];

    // Start timer if not already running
    _messageTimer?.cancel();
    setState(() {
      _currentMessageIndex = 0;
    });
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentMessageIndex < stepDescriptions.length - 1) {
        setState(() {
          _currentMessageIndex++;
        });
      } else {
        timer.cancel();
      }
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enviando imagem',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 110,
            child: Lottie.network(
              'https://lottie.host/84fb930b-82d1-4a00-add4-140b822062ca/rvImINITg2.json',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          Text(
            stepText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            stepDescriptions[_currentMessageIndex],
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProcessingView(
    BuildContext context,
    SubmissionProcessingState state,
  ) {
    String stepText;
    String stepDescription;
    switch (state.step) {
      case 'analysis':
        stepText = 'IA analisando suas respostas...';
        stepDescription = 'Identificando questões e marcações...';
        break;
      case 'grading':
        stepText = 'Calculando nota';
        stepDescription = 'Enviando resultado para o servidor...';
        break;
      default:
        stepText = 'Processando';
        stepDescription = 'Aguarde...';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Corrigindo com IA',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 110,
            child: Lottie.network(
              'https://lottie.host/84fb930b-82d1-4a00-add4-140b822062ca/rvImINITg2.json',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            stepText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            stepDescription,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
