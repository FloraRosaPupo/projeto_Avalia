// submission_upload_modal.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
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
      create: (_) => SubmissionCubit(),
      child: BlocConsumer<SubmissionCubit, dynamic>(
        listener: (context, state) {
          if (state is SubmissionCompletedState) {
            Navigator.pop(context, state.submission);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Corrigido! Nota: ${state.submission.nota ?? 0}. Submetendo resultado...',
                ),
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
          if (state is SubmissionUploadingState) {
            return _buildUploadProgress(context, state.percent);
          } else if (state is SubmissionProcessingState) {
            return _buildProcessingView(context, state);
          } else if (state is SubmissionNeedsReviewState) {
            return _buildReviewNeededView(context, state);
          } else if (_selectedImage == null) {
            return _buildImageSourceSelection(context);
          } else {
            // Default to preview if image is selected and not in other active states
            return _buildImagePreview(context);
          }
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------
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
            children: const [
              Text(
                'Enviar Resposta',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              // Close button handled by parent modal
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
            children: const [
              Text(
                'Preview da Imagem',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              // Close button handled by parent modal
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
                    setState(() => _selectedImage = null);
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
            'Fazendo upload...',
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

  Widget _buildReviewNeededView(
    BuildContext context,
    SubmissionNeedsReviewState state,
  ) {
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
            'Revisão Necessária',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Show a generic message; you can customize based on state
          const Text(
            'A submissão precisa ser revisada.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          // If there are specific issues, display them
          if (state.issues.isNotEmpty) ...[
            ...state.issues.map(_buildIssueCard).toList(),
            const SizedBox(height: 24),
          ],
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // Simple card for an issue; adjust layout as needed
  Widget _buildIssueCard(SubmissionIssue issue) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.error_outline, color: Colors.red),
        title: Text(issue.type),
        subtitle: Text(issue.message),
        trailing: Text(issue.severity),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Interaction helpers
  // ---------------------------------------------------------------------
  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  void _uploadImage(BuildContext context) {
    if (_selectedImage == null) return;
    final int attemptNumber = widget.existingSubmission != null
        ? (widget.existingSubmission!.attemptNumber + 1)
        : 1;
    context.read<SubmissionCubit>().submitAndAutoCorrect(
      provaId: widget.provaId,
      alunoId: widget.alunoId,
      imageFile: _selectedImage!,
      attemptNumber: attemptNumber,
    );
  }
}
