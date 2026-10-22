// submission_upload_modal.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:avalia/features/submissions/presentation/cubit/submission_cubit.dart';
import 'package:avalia/features/submissions/data/models/submission_model.dart';
import 'package:path/path.dart' as path;

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

  // Estados de validação
  String? _imageDimensionWarning;
  int? _imageWidth;
  int? _imageHeight;

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
            print('ERROR: SubmissionErrorState - ${state.message}');
            print('ERROR: Code: ${state.code}');

            // Trata erros específicos de type cast
            String errorMessage = state.message;
            if (errorMessage.contains('type') &&
                errorMessage.contains('is not a subtype')) {
              errorMessage =
                  'Erro ao processar dados da submissão. Por favor, tente novamente.';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ $errorMessage'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
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
    final isReplacing = widget.existingSubmission != null;
    final attemptNumber = widget.existingSubmission?.attemptNumber ?? 0;

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
              Text(
                isReplacing ? 'Substituir Submissão' : 'Enviar Resposta',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Close button handled by parent modal
            ],
          ),
          if (isReplacing) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Tentativa ${attemptNumber + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (isReplacing)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.refresh,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esta nova imagem substituirá a submissão anterior e será recorrigida pela IA',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Certifique-se de marcar claramente as bolhas (A–E)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tamanho máximo: 50MB | Formatos: JPG, PNG',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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

  Widget _buildImagePreview(BuildContext context) {
    final isReplacing = widget.existingSubmission != null;
    final attemptNumber = widget.existingSubmission?.attemptNumber ?? 0;

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
              Text(
                isReplacing ? 'Preview da Substituição' : 'Preview da Resposta',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isReplacing)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Tentativa ${attemptNumber + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Container com border destacado
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
          const SizedBox(height: 12),
          // Informações da imagem
          if (_imageWidth != null && _imageHeight != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dimensões: ${_imageWidth}x${_imageHeight}px',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          // Warning de qualidade
          if (_imageDimensionWarning != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _imageDimensionWarning!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                      _imageDimensionWarning = null;
                      _imageWidth = null;
                      _imageHeight = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Trocar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    foregroundColor: isReplacing
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _uploadImage(context),
                  icon: Icon(isReplacing ? Icons.refresh : Icons.cloud_upload),
                  label: Text(isReplacing ? 'Substituir' : 'Enviar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: isReplacing
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).primaryColor,
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
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
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
  // Validation helpers
  // ---------------------------------------------------------------------

  /// Valida formato da imagem
  bool _validateImageFormat(File imageFile) {
    // Validação flexível: ImagePicker já faz conversão de formatos
    // Imagens da galeria podem não ter extensão no caminho
    String extension = path.extension(imageFile.path).toLowerCase();
    final hasValidExtension = [
      '.jpg',
      '.jpeg',
      '.png',
      '.heic',
      '.heif',
      '.webp',
    ].contains(extension);

    // Se não tem extensão conhecida, aceita mesmo assim
    // O ImagePicker já faz conversão e o servidor fará validação final
    if (!hasValidExtension) {
      print(
        'WARNING: Arquivo sem extensão conhecida ($extension), mas aceitando (ImagePicker faz conversão)',
      );
    }

    return true; // Sempre aceita, validação final será no servidor
  }

  /// Valida dimensões da imagem
  Future<bool> _validateImageDimensions(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final ui.Image image = await decodeImageFromList(bytes);

      setState(() {
        _imageWidth = image.width;
        _imageHeight = image.height;
      });

      // Dimensões mínimas: 400x300px
      const int minWidth = 400;
      const int minHeight = 300;

      if (image.width < minWidth || image.height < minHeight) {
        setState(() {
          _imageDimensionWarning =
              'Imagem muito pequena (${image.width}x${image.height}px). '
              'Recomendado: mínimo ${minWidth}x${minHeight}px para melhor qualidade.';
        });
        return false;
      }

      // Warning para imagens com baixa resolução
      if (image.width < 800 || image.height < 600) {
        setState(() {
          _imageDimensionWarning =
              'Imagem com resolução baixa (${image.width}x${image.height}px). '
              'Para melhor resultado, use imagens com resolução superior.';
        });
      } else {
        setState(() {
          _imageDimensionWarning = null;
        });
      }

      return true;
    } catch (e) {
      setState(() {
        _imageDimensionWarning = 'Erro ao validar dimensões da imagem';
      });
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Interaction helpers
  // ---------------------------------------------------------------------
  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked != null) {
      final file = File(picked.path);
      final fileSize = await file.length();
      const maxSize = 50 * 1024 * 1024; // 50MB in bytes

      if (fileSize > maxSize) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Arquivo muito grande'),
              content: Text(
                'O arquivo selecionado tem ${_formatFileSize(fileSize)}.\n\n'
                'O tamanho máximo permitido é 50MB.\n\n'
                'Por favor, selecione uma imagem menor ou comprima a imagem atual.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Validar formato (validação flexível - ImagePicker já faz conversão)
      _validateImageFormat(file);

      // Validar dimensões
      await _validateImageDimensions(file);

      setState(() {
        _selectedImage = file;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
