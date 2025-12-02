import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:avalia/presentation/cubit/submission_cubit.dart';
import 'package:avalia/data/models/submission_model.dart';

class SubmissionUploadModal extends StatefulWidget {
  final String provaId;
  final String alunoId;
  final SubmissionModel? existingSubmission;

  const SubmissionUploadModal({
    Key? key,
    required this.provaId,
    required this.alunoId,
    this.existingSubmission,
  }) : super(key: key);

  @override
  State<SubmissionUploadModal> createState() => _SubmissionUploadModalState();
}

class _SubmissionUploadModalState extends State<SubmissionUploadModal> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SubmissionCubit(),
      child: BlocConsumer<SubmissionCubit, dynamic>(
        listener: (context, state) {
          if (state is SubmissionCompletedState) {
            Navigator.pop(context, state.submission);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Submissão concluída com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is SubmissionErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${state.message}'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Tentar novamente',
                  textColor: Colors.white,
                  onPressed: () {
                    if (_selectedImage != null) {
                      _uploadImage(context);
                    }
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (_selectedImage == null) {
            return _buildImageSourceSelection(context);
          } else if (state is SubmissionPreviewState ||
              _selectedImage != null && state is! SubmissionUploadingState) {
            return _buildImagePreview(context);
          } else if (state is SubmissionUploadingState) {
            return _buildUploadProgress(context, state.percent);
          } else if (state is SubmissionProcessingState) {
            return _buildProcessingView(context, state);
          } else if (state is SubmissionNeedsReviewState) {
            return _buildReviewNeededView(context, state);
          }

          return _buildImageSourceSelection(context);
        },
      ),
    );
  }

  Widget _buildImageSourceSelection(BuildContext context) {
    return Container(
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
                'Enviar Resposta',
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Certifique-se de marcar claramente as bolhas (A–E)',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSourceButton(
            context,
            icon: Icons.camera_alt,
            label: 'Tirar Foto',
            onTap: () => _pickImage(context, ImageSource.camera),
          ),
          const SizedBox(height: 12),
          _buildSourceButton(
            context,
            icon: Icons.photo_library,
            label: 'Selecionar da Galeria',
            onTap: () => _pickImage(context, ImageSource.gallery),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSourceButton(
    BuildContext context, {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Container(
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
                'Preview da Imagem',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_selectedImage!, height: 300, fit: BoxFit.cover),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Trocar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _uploadImage(context),
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Enviar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildUploadProgress(BuildContext context, int percent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '1/4 — Enviando imagem...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: percent / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 12),
          Text(
            '$percent%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
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
    int stepNumber;

    switch (state.step) {
      case 'analysis':
        stepNumber = 2;
        stepText = 'Processando imagem';
        stepDescription = 'Extraindo marcações do gabarito...';
        break;
      case 'ai_validation':
        stepNumber = 3;
        stepText = 'Validação por IA';
        stepDescription = 'Verificando qualidade e inconsistências...';
        break;
      case 'grading':
        stepNumber = 4;
        stepText = 'Calculando nota';
        stepDescription = 'Comparando com gabarito oficial...';
        break;
      default:
        stepNumber = 2;
        stepText = 'Processando';
        stepDescription = 'Aguarde...';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$stepNumber/4 — $stepText',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            stepDescription,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReviewNeededView(
    BuildContext context,
    SubmissionNeedsReviewState state,
  ) {
    return Container(
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
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
              SizedBox(width: 12),
              Text(
                'Problemas Detectados',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: state.issues.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final issue = state.issues[index];
                return _buildIssueCard(issue);
              },
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedImage = null;
              });
              context.read<SubmissionCubit>().resetToInitial();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reenviar Foto'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              context.read<SubmissionCubit>().requestReprocessing(
                state.submission.id!,
              );
            },
            icon: const Icon(Icons.replay),
            label: const Text('Solicitar Revisão Manual'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(SubmissionIssue issue) {
    Color severityColor;
    IconData severityIcon;

    switch (issue.severity) {
      case 'critical':
        severityColor = Colors.red;
        severityIcon = Icons.error;
        break;
      case 'error':
        severityColor = Colors.orange;
        severityIcon = Icons.warning;
        break;
      default:
        severityColor = Colors.yellow.shade700;
        severityIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(severityIcon, color: severityColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.type,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(issue.message, style: const TextStyle(fontSize: 14)),
                if (issue.affectedQuestions != null &&
                    issue.affectedQuestions!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Questões: ${issue.affectedQuestions!.join(", ")}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 2560,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        // Validar imagem
        final cubit = context.read<SubmissionCubit>();
        final validation = await cubit.validateImage(_selectedImage!);

        if (!validation.isValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validation.error ?? 'Imagem inválida'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _selectedImage = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _uploadImage(BuildContext context) {
    if (_selectedImage == null) return;

    final attemptNumber = widget.existingSubmission != null
        ? (widget.existingSubmission!.attemptNumber + 1)
        : 1;

    context.read<SubmissionCubit>().uploadSubmission(
      provaId: widget.provaId,
      alunoId: widget.alunoId,
      imageFile: _selectedImage!,
      attemptNumber: attemptNumber,
    );
  }
}
