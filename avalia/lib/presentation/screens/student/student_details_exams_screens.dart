import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avalia/core/state/base_state.dart';
import 'package:avalia/data/models/submission_model.dart';
import 'package:avalia/presentation/cubit/submission_cubit.dart';
import 'package:avalia/presentation/widgets/submission_upload_modal.dart';

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
    extends State<DetailsExamsStudentScreens> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SubmissionCubit()..getSubmission(widget.provaId, widget.alunoId),
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
            SubmissionModel? submission;

            if (state is SuccessState<SubmissionModel>) {
              submission = state.data;
            } else if (state is SuccessState<SubmissionModel?>) {
              submission = state.data;
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
                    else if (submission.status == SubmissionStatus.reviewNeeded)
                      _buildReviewNeededBanner(context, submission)
                    else if (submission.status == SubmissionStatus.graded)
                      _buildGradedContent(submission)
                    else
                      _buildProcessingBanner(submission),

                    const SizedBox(height: 16),

                    // Botão de submissão (se não houver submissão ou se precisar reenviar)
                    if (submission == null ||
                        submission.status == SubmissionStatus.reviewNeeded)
                      _buildSubmissionButton(context, submission),
                  ],
                ),
              ),
            );
          },
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
          Text(
            widget.provaNome ?? 'Nome da Prova',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Data: ${widget.provaData ?? "12/05/2023"}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                    value:
                        '${((submission.acertos! / submission.totalQuestoes!) * 100).toInt()}%',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pending_outlined, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Aguardando Submissão',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (submission.status) {
      case SubmissionStatus.graded:
        badgeColor = const Color.fromARGB(59, 132, 231, 135);
        badgeIcon = Icons.check_circle_outline;
        badgeText = 'Corrigida';
        break;
      case SubmissionStatus.reviewNeeded:
        badgeColor = const Color.fromARGB(26, 247, 180, 80);
        badgeIcon = Icons.warning_amber_rounded;
        badgeText = 'Revisão Necessária';
        break;
      case SubmissionStatus.processingAnalysis:
      case SubmissionStatus.aiValidation:
        badgeColor = Colors.blue.shade50;
        badgeIcon = Icons.hourglass_empty;
        badgeText = 'Processando';
        break;
      default:
        badgeColor = Colors.grey.shade200;
        badgeIcon = Icons.pending;
        badgeText = 'Pendente';
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
            badgeText,
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
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: const [
            Icon(Icons.info_outline, color: Colors.blue, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nenhuma submissão encontrada',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Envie uma foto da sua prova para correção automática',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
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
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 32,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Correção Pendente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Problemas detectados na imagem enviada:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            if (submission.issues != null)
              ...submission.issues!.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          issue.message,
                          style: const TextStyle(fontSize: 14),
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
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradedContent(SubmissionModel submission) {
    if (submission.detalhamento == null || submission.detalhamento!.isEmpty) {
      return const SizedBox.shrink();
    }

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
                        errorBuilder: (context, error, stackTrace) {
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
  }

  Widget _buildSubmissionButton(
    BuildContext context,
    SubmissionModel? existingSubmission,
  ) {
    if (existingSubmission?.status == SubmissionStatus.graded) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implementar download do relatório
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download não implementado')),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Baixar Relatório'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () =>
                  _openSubmissionModal(context, existingSubmission),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Reprocessar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _openSubmissionModal(context, existingSubmission),
        icon: const Icon(Icons.camera_alt),
        label: Text(
          existingSubmission == null
              ? 'Enviar resposta (foto)'
              : 'Reenviar foto',
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _openSubmissionModal(
    BuildContext context,
    SubmissionModel? existingSubmission,
  ) async {
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
      // Atualizar a tela com a nova submissão imediatamente
      context.read<SubmissionCubit>().updateSubmission(result);

      // Buscar dados atualizados do banco (para garantir sincronia)
      context.read<SubmissionCubit>().getSubmission(
        widget.provaId,
        widget.alunoId,
      );
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
