import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Avalia/presentation/cubit/exams_cubit.dart';
import 'package:Avalia/presentation/cubit/class_cubit.dart';
import 'package:Avalia/core/state/base_state.dart';
import 'package:Avalia/data/models/class_model.dart';
import 'package:Avalia/data/models/exam_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class ModalCreatedExams extends StatefulWidget {
  final ExamModel? exam;
  const ModalCreatedExams({super.key, this.exam});

  @override
  State<ModalCreatedExams> createState() => _ModalCreatedExamsState();
}

class _ModalCreatedExamsState extends State<ModalCreatedExams> {
  Color picked = Colors.blue;
  final TextEditingController _nameController = TextEditingController();

  // Lista de turmas selecionadas (objetos completos)
  List<ClassModel> _selectedClasses = [];

  File? _gabaritoImage;
  String? _existingGabaritoUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _classesInitialized = false;

  // Estados de upload de gabarito
  bool _isUploadingGabarito = false;
  double _uploadProgress = 0.0;
  bool _uploadSuccess = false;
  String? _uploadError;

  // Estados de preview e validação
  bool _showPreview = false;
  bool _imageConfirmed = false;
  String? _imageDimensionWarning;
  int? _imageWidth;
  int? _imageHeight;

  // Estado para controlar se já buscou os dados completos do banco
  bool _examDataLoaded = false;
  ExamModel? _loadedExam;

  // Flag para controlar se estamos salvando (create/update)
  bool _isSaving = false;

  // Getters para estado explícito
  bool get isEditing => widget.exam != null;
  ExamModel? get originalExam => _loadedExam ?? widget.exam;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      print('═══════════════════════════════════════════════════════');
      print('📝 MODO EDIÇÃO - DADOS RECEBIDOS NO MODAL');
      print('═══════════════════════════════════════════════════════');
      print('🔹 ExamModel recebido (pode estar incompleto):');
      print('   - ID: ${widget.exam!.id}');
      print('   - Nome: ${widget.exam!.nome}');
      print('   - Cor: ${widget.exam!.cor}');
      print('   - Status: ${widget.exam!.status}');
      print('   - URL Prova (gabarito): ${widget.exam!.urlProva}');
      print('   - User ID: ${widget.exam!.userId}');
      print('   - Created At: ${widget.exam!.createdAt}');
      print('   - Turmas ID: ${widget.exam!.turmasId}');
      print('   - Quantidade de turmas: ${widget.exam!.turmasId.length}');
      print('═══════════════════════════════════════════════════════');

      // Inicializar com dados básicos enquanto busca os completos
      _nameController.text = widget.exam!.nome ?? '';
      if (widget.exam!.cor != null) {
        try {
          String colorString = widget.exam!.cor!;
          final buffer = StringBuffer();
          if (colorString.length == 6 || colorString.length == 7)
            buffer.write('ff');
          buffer.write(colorString.replaceFirst('#', ''));
          picked = Color(int.parse(buffer.toString(), radix: 16));
        } catch (_) {}
      }
      _existingGabaritoUrl = widget.exam!.urlProva;

      print('✅ Inicialização básica do modal:');
      print('   - Nome no controller: ${_nameController.text}');
      print('   - URL do gabarito existente: $_existingGabaritoUrl');
      print('   - Cor selecionada: $picked');
      print('═══════════════════════════════════════════════════════');
    } else {
      print('📝 MODO CRIAÇÃO - Modal aberto para criar nova prova');
    }
  }

  /// Carrega os dados completos da prova do banco quando necessário
  void _loadExamDataIfNeeded(BuildContext context) {
    if (!isEditing || _examDataLoaded) return;

    // Verificar se precisa buscar dados completos (turmasId vazio ou urlProva null)
    final needsFullData =
        widget.exam!.turmasId.isEmpty || widget.exam!.urlProva == null;

    if (needsFullData) {
      print('🔄 Buscando dados completos da prova do banco...');
      final examsCubit = context.read<ExamsCubit>();
      examsCubit.getExamById(widget.exam!.id);
      _examDataLoaded = true;
    } else {
      // Dados já estão completos, usar diretamente
      _loadedExam = widget.exam;
      _examDataLoaded = true;
      print('✅ Dados da prova já estão completos, usando diretamente');
    }
  }

  /// Aguarda o carregamento das turmas e inicializa as turmas selecionadas
  /// no modo de edição. Usa stream para garantir que turmas estejam carregadas.
  Future<void> _waitForClassesAndInitialize(ClassCubit classCubit) async {
    if (!isEditing || _classesInitialized) return;

    await for (final state in classCubit.stream) {
      if (state is SuccessState<ClassListResponse>) {
        final allTurmas = state.data.classes;
        final examTurmasIds = originalExam!.turmasId;

        if (mounted) {
          setState(() {
            _selectedClasses = allTurmas
                .where((t) => examTurmasIds.contains(t.id))
                .toList();
            _classesInitialized = true;
          });
        }
        break; // Sair do loop após inicialização
      } else if (state is ErrorState) {
        break; // Sair se houver erro
      }
    }
  }

  /// Deleta o gabarito antigo do Storage
  Future<void> _deleteOldGabarito(String? gabaritoUrl) async {
    if (gabaritoUrl == null || gabaritoUrl.isEmpty) return;

    try {
      final cubit = context.read<ExamsCubit>();
      await cubit.deleteGabarito(gabaritoUrl);
      print('Gabarito antigo deletado com sucesso');
    } catch (e) {
      print('Erro ao deletar gabarito antigo: $e');
      // Não bloquear o fluxo se a deleção falhar
    }
  }

  void _showMultiSelect(List<ClassModel> availableClasses) async {
    final List<ClassModel>? results = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return MultiSelect(
          items: availableClasses,
          selectedItems: _selectedClasses,
        );
      },
    );

    if (results != null) {
      setState(() {
        _selectedClasses = results;
      });
    }
  }

  Future<void> _pickGabarito() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        final file = File(image.path);
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
        final validDimensions = await _validateImageDimensions(file);

        setState(() {
          _gabaritoImage = file;
          _showPreview = true;
          _imageConfirmed = false;
        });

        // Se dimensões inválidas, mostrar alerta mas permitir continuar
        if (!validDimensions && mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Atenção'),
              content: Text(
                _imageDimensionWarning ?? 'Problema com dimensões da imagem',
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
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao selecionar imagem: $e')));
    }
  }

  void _confirmImage() {
    setState(() {
      _imageConfirmed = true;
      _showPreview = false;
    });
  }

  void _selectNewImage() {
    setState(() {
      _gabaritoImage = null;
      _showPreview = false;
      _imageConfirmed = false;
      _imageDimensionWarning = null;
      _imageWidth = null;
      _imageHeight = null;
    });
    _pickGabarito();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

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

  Future<void> _saveExam(BuildContext context) async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira o nome da prova')),
      );
      return;
    }

    // Validação: não pode salvar sem gabarito (tanto insert quanto update)
    if (_gabaritoImage == null && _existingGabaritoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, carregue o gabarito antes de salvar'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_selectedClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione pelo menos uma turma'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadError = null;
      _uploadSuccess = false;
      _isSaving = true; // Marcar que estamos salvando
    });

    try {
      final cubit = context.read<ExamsCubit>();

      String? gabaritoUrl = _existingGabaritoUrl;
      String? oldGabaritoUrl = _existingGabaritoUrl;

      // 1. Upload do gabarito se houver nova imagem
      if (_gabaritoImage != null) {
        setState(() {
          _isUploadingGabarito = true;
          _uploadProgress = 0.0;
        });

        try {
          // Simular progresso gradual (0% -> 30%)
          for (int i = 0; i <= 30; i += 10) {
            if (!mounted) break;
            setState(() => _uploadProgress = i / 100);
            await Future.delayed(const Duration(milliseconds: 100));
          }

          // Upload real
          gabaritoUrl = await cubit.uploadGabarito(_gabaritoImage!);

          // Progresso 30% -> 100%
          for (int i = 40; i <= 100; i += 20) {
            if (!mounted) break;
            setState(() => _uploadProgress = i / 100);
            await Future.delayed(const Duration(milliseconds: 50));
          }

          if (gabaritoUrl == null || gabaritoUrl.isEmpty) {
            throw Exception('Falha ao obter URL do gabarito após upload');
          }

          setState(() {
            _uploadSuccess = true;
            _isUploadingGabarito = false;
          });

          // Feedback visual de sucesso
          await Future.delayed(const Duration(milliseconds: 500));

          // 2. Deletar gabarito antigo após upload bem-sucedido
          if (isEditing &&
              oldGabaritoUrl != null &&
              oldGabaritoUrl != gabaritoUrl) {
            await _deleteOldGabarito(oldGabaritoUrl);
          }
        } catch (uploadError) {
          setState(() {
            _isUploadingGabarito = false;
            _uploadError = uploadError.toString();
          });
          throw Exception('Erro ao fazer upload do gabarito: $uploadError');
        }
      }

      // Validação final: garantir que temos um gabarito válido antes de salvar
      if (gabaritoUrl == null || gabaritoUrl.isEmpty) {
        setState(() {
          _isLoading = false;
          _isUploadingGabarito = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Erro: É necessário ter um gabarito para salvar a prova',
              ),
            ),
          );
        }
        return;
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro: Usuário não autenticado')),
          );
        }
        return;
      }

      // Verificar se é edição baseado no originalExam (que pode ter sido carregado do banco)
      final examToUpdate = originalExam;
      final isUpdate = examToUpdate != null && examToUpdate.id > 0;

      final examData = {
        'nome': _nameController.text,
        'cor': picked.value.toRadixString(16).substring(2),
        'url_prova': gabaritoUrl,
        'user_id': userId,
        'turmas_id': _selectedClasses.map((c) => c.id).toList(),
      };

      // Adicionar atualizado_em no update
      if (isUpdate) {
        examData['atualizado_em'] = DateTime.now().toIso8601String();
        print(
          '🕒 Campo atualizado_em adicionado: ${examData['atualizado_em']}',
        );
      }

      print('═══════════════════════════════════════════════════════');
      print('💾 SALVANDO PROVA');
      print('═══════════════════════════════════════════════════════');
      print('🔹 Modo: ${isUpdate ? "UPDATE" : "CREATE"}');
      print('🔹 widget.exam: ${widget.exam?.id}');
      print('🔹 _loadedExam: ${_loadedExam?.id}');
      print('🔹 originalExam: ${examToUpdate?.id}');
      print('🔹 examToUpdate != null: ${examToUpdate != null}');
      print('🔹 Dados a serem enviados:');
      examData.forEach((key, value) {
        print('   - $key: $value');
      });
      print('═══════════════════════════════════════════════════════');

      // Chamar create ou update - o cubit vai emitir o estado e o BlocListener vai fechar o modal
      if (!isUpdate) {
        // Create
        print('📝 Criando nova prova via cubit...');
        examData['created_at'] = DateTime.now().toIso8601String();
        await cubit.createExam(examData);
        // O BlocListener vai tratar o sucesso e fechar o modal
      } else {
        // Update
        print('📝 Atualizando prova ID: ${examToUpdate.id} via cubit...');
        await cubit.updateExam(examToUpdate.id, examData);
        // O Blo
        //
        //cListener vai tratar o sucesso e fechar o modal
      }

      Navigator.of(context).pop(); //Ta quebrando a navegação
      // O BlocListener vai tratar o sucesso e fechar o modal automaticamente
    } catch (e) {
      print('❌ Erro ao salvar prova: $e');
      if (mounted) {
        setState(() {
          _uploadError = e.toString();
          _isUploadingGabarito = false;
          _uploadSuccess = false;
          _isLoading = false;
          _isSaving = false; // Resetar flag de salvamento
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao salvar prova: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      // Garantir que sempre reseta os estados, mesmo se houver erro
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _isUploadingGabarito = false;
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ExamsCubit()),
        BlocProvider(
          create: (context) {
            final cubit = ClassCubit();
            final userId = Supabase.instance.client.auth.currentUser?.id;
            if (userId != null) {
              cubit.getClassesByUserId(userId: userId);
            }
            return cubit;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          // Buscar dados completos da prova se necessário
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadExamDataIfNeeded(context);
          });

          return BlocListener<ExamsCubit, BaseState>(
            listener: (context, state) {
              // Listener para buscar dados completos da prova (modo edição)
              if (isEditing && !_isSaving && state is SuccessState<ExamModel>) {
                final exam = state.data;
                print(
                  '═══════════════════════════════════════════════════════',
                );
                print('✅ DADOS COMPLETOS DA PROVA RECEBIDOS DO BANCO');
                print(
                  '═══════════════════════════════════════════════════════',
                );
                print('🔹 ExamModel completo:');
                print('   - ID: ${exam.id}');
                print('   - Nome: ${exam.nome}');
                print('   - Cor: ${exam.cor}');
                print('   - Status: ${exam.status}');
                print('   - URL Prova (gabarito): ${exam.urlProva}');
                print('   - User ID: ${exam.userId}');
                print('   - Created At: ${exam.createdAt}');
                print('   - Turmas ID: ${exam.turmasId}');
                print('   - Quantidade de turmas: ${exam.turmasId.length}');
                print(
                  '═══════════════════════════════════════════════════════',
                );

                if (mounted) {
                  setState(() {
                    _loadedExam = exam;
                    // Atualizar campos se necessário
                    if (_nameController.text.isEmpty && exam.nome != null) {
                      _nameController.text = exam.nome!;
                    }
                    if (_existingGabaritoUrl == null && exam.urlProva != null) {
                      _existingGabaritoUrl = exam.urlProva;
                    }
                    if (exam.cor != null) {
                      try {
                        String colorString = exam.cor!;
                        final buffer = StringBuffer();
                        if (colorString.length == 6 || colorString.length == 7)
                          buffer.write('ff');
                        buffer.write(colorString.replaceFirst('#', ''));
                        picked = Color(int.parse(buffer.toString(), radix: 16));
                      } catch (_) {}
                    }
                    // Resetar flag de inicialização para forçar nova busca de turmas
                    _classesInitialized = false;
                  });
                }
              }
              // Listener para sucesso de create/update
              else if (_isSaving && state is SuccessState<List<ExamModel>>) {
                print('✅ Prova salva com sucesso via cubit!');
                print('🔹 Estado recebido: SuccessState<List<ExamModel>>');
                print('🔹 Quantidade de provas na lista: ${state.data.length}');

                if (mounted) {
                  // Resetar estados primeiro
                  setState(() {
                    _isLoading = false;
                    _isUploadingGabarito = false;
                    _uploadSuccess = false;
                    _uploadError = null;
                    _isSaving = false;
                  });

                  // Mostrar mensagem de sucesso
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing
                            ? 'Prova atualizada com sucesso!'
                            : 'Prova criada com sucesso!',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  print('🚪 Fechando modal via cubit...');

                  // Fechar modal - usar addPostFrameCallback para garantir que setState seja processado
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop(true);
                    }
                  });
                }
              }
              // Listener para erro durante save
              else if (_isSaving && state is ErrorState) {
                print('❌ Erro ao salvar prova via cubit: ${state.message}');
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _isUploadingGabarito = false;
                    _uploadError = state.message;
                    _isSaving = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao salvar prova: ${state.message}'),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
              // Listener para erro ao buscar dados
              else if (isEditing && !_isSaving && state is ErrorState) {
                print(
                  '❌ Erro ao buscar dados completos da prova: ${state.message}',
                );
              }
            },
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEditing ? 'Editar Prova' : 'Criar Prova',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Nome da Prova',
                          hintStyle: TextStyle(
                            color: Color.fromARGB(99, 158, 158, 158),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(99, 158, 158, 158),
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botão de vincular turmas com BlocBuilder para estado das turmas
                      BlocBuilder<ClassCubit, BaseState>(
                        builder: (context, state) {
                          List<ClassModel> availableClasses = [];
                          bool isLoadingClasses = false;

                          if (state is LoadingState) {
                            isLoadingClasses = true;
                          } else if (state is SuccessState<ClassListResponse>) {
                            availableClasses = state.data.classes;

                            // Inicializar turmas selecionadas no modo edição
                            if (isEditing && !_classesInitialized) {
                              final examTurmasIds = originalExam!.turmasId;

                              print(
                                '═══════════════════════════════════════════════════════',
                              );
                              print(
                                '🏫 INICIALIZAÇÃO DAS TURMAS NO MODO EDIÇÃO',
                              );
                              print(
                                '═══════════════════════════════════════════════════════',
                              );
                              print(
                                '🔹 IDs das turmas da prova: $examTurmasIds',
                              );
                              print(
                                '🔹 Total de turmas disponíveis: ${availableClasses.length}',
                              );
                              print('🔹 Turmas disponíveis:');
                              for (var turma in availableClasses) {
                                print(
                                  '   - ID: ${turma.id}, Nome: ${turma.nome}',
                                );
                              }

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && !_classesInitialized) {
                                  final selected = availableClasses
                                      .where(
                                        (t) => examTurmasIds.contains(t.id),
                                      )
                                      .toList();

                                  print(
                                    '🔹 Turmas encontradas e selecionadas:',
                                  );
                                  if (selected.isEmpty) {
                                    print('   ⚠️ NENHUMA TURMA ENCONTRADA!');
                                    print(
                                      '   ⚠️ Verifique se os IDs das turmas estão corretos.',
                                    );
                                  } else {
                                    for (var turma in selected) {
                                      print(
                                        '   ✅ ID: ${turma.id}, Nome: ${turma.nome}',
                                      );
                                    }
                                  }
                                  print(
                                    '═══════════════════════════════════════════════════════',
                                  );

                                  setState(() {
                                    _selectedClasses = selected;
                                    _classesInitialized = true;
                                  });
                                }
                              });
                            }
                          }

                          return ElevatedButton(
                            onPressed: isLoadingClasses
                                ? null
                                : () => _showMultiSelect(availableClasses),
                            child: isLoadingClasses
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Vincular Turmas'),
                          );
                        },
                      ),

                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _selectedClasses
                            .map(
                              (turma) => Chip(
                                label: Text(turma.nome),
                                onDeleted: () {
                                  setState(() {
                                    _selectedClasses.remove(turma);
                                  });
                                },
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                backgroundColor: Colors.white,
                                deleteIconColor: Colors.grey.shade600,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Cor:'),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () async {
                              final selected = await showDialog<Color>(
                                context: context,
                                builder: (context) {
                                  Color temp = picked;
                                  return AlertDialog(
                                    backgroundColor: Colors.white,
                                    title: const Text(
                                      'Escolha uma cor',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: StatefulBuilder(
                                      builder: (context, setStateSB) {
                                        return SingleChildScrollView(
                                          child: ColorPicker(
                                            pickerAreaBorderRadius:
                                                BorderRadius.circular(8),
                                            pickerColor: temp,
                                            onColorChanged: (c) =>
                                                setStateSB(() => temp = c),
                                            showLabel: true,
                                            pickerAreaHeightPercent: 0.8,
                                          ),
                                        );
                                      },
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('CANCELAR'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(temp),
                                        child: const Text('Selecionar'),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (selected != null) {
                                setState(() => picked = selected);
                              }
                            },
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: picked,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Indicador de progresso de upload
                      if (_isUploadingGabarito)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF87CEEB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF87CEEB).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: const Color(0xFF87CEEB),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Enviando gabarito... ${(_uploadProgress * 100).toInt()}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: _uploadProgress,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF87CEEB),
                                      ),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Feedback de sucesso
                      if (_uploadSuccess && !_isUploadingGabarito)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Gabarito enviado com sucesso!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Feedback de erro com retry
                      if (_uploadError != null && !_isUploadingGabarito)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.shade300,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade700,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Erro ao enviar gabarito',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.red.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _uploadError!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _saveExam(context),
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Tentar Novamente'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_isUploadingGabarito ||
                          _uploadSuccess ||
                          _uploadError != null)
                        const SizedBox(height: 16),

                      // Preview aprimorado com validações
                      if (_showPreview && _gabaritoImage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF87CEEB),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Preview do Gabarito',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _gabaritoImage!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Informações da imagem
                              if (_imageWidth != null && _imageHeight != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Dimensões: ${_imageWidth}x${_imageHeight}px',
                                        style: const TextStyle(fontSize: 12),
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
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orange.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_outlined,
                                        size: 20,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _imageDimensionWarning!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 16),
                              // Botões de ação
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _selectNewImage,
                                      icon: const Icon(Icons.swap_horiz),
                                      label: const Text('Trocar'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        side: BorderSide(
                                          color: const Color(0xFF87CEEB),
                                        ),
                                        foregroundColor: const Color(
                                          0xFF87CEEB,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton.icon(
                                      onPressed: _confirmImage,
                                      icon: const Icon(Icons.check),
                                      label: const Text('Confirmar'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        backgroundColor: const Color(
                                          0xFF87CEEB,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else if (_imageConfirmed && _gabaritoImage != null)
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _gabaritoImage!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _gabaritoImage = null;
                                  _imageConfirmed = false;
                                  _showPreview = false;
                                  _imageDimensionWarning = null;
                                });
                              },
                            ),
                          ],
                        )
                      else if (_existingGabaritoUrl != null)
                        Builder(
                          builder: (context) {
                            // Print para debug quando a imagem é exibida
                            if (isEditing) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                print(
                                  '🖼️ Exibindo gabarito existente: $_existingGabaritoUrl',
                                );
                              });
                            }
                            return Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _existingGabaritoUrl!,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print(
                                        '❌ Erro ao carregar imagem do gabarito: $error',
                                      );
                                      print('   URL: $_existingGabaritoUrl');
                                      return const Center(
                                        child: Text('Erro ao carregar imagem'),
                                      );
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    // Confirmar remoção
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Remover Gabarito'),
                                        content: const Text(
                                          'Tem certeza que deseja remover o gabarito atual? '
                                          'Esta ação não pode ser desfeita.',
                                        ),
                                        actions: [
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              'Remover',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      final urlToDelete = _existingGabaritoUrl;
                                      setState(() {
                                        _existingGabaritoUrl = null;
                                      });

                                      // Deletar do Storage em background
                                      if (urlToDelete != null) {
                                        await _deleteOldGabarito(urlToDelete);
                                      }

                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Gabarito removido com sucesso',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        ),

                      ElevatedButton.icon(
                        onPressed: _isUploadingGabarito || _isLoading
                            ? null
                            : _pickGabarito,
                        icon: _isUploadingGabarito
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(
                          _isUploadingGabarito
                              ? 'Enviando...'
                              : _gabaritoImage == null &&
                                    _existingGabaritoUrl == null
                              ? 'Carregar Gabarito'
                              : 'Trocar Gabarito',
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isLoading || _isUploadingGabarito
                            ? null
                            : () => _saveExam(context),
                        child: _isLoading || _isUploadingGabarito
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isUploadingGabarito
                                        ? 'Enviando gabarito...'
                                        : 'Salvando...',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Salvar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MultiSelect extends StatefulWidget {
  final List<ClassModel> items;
  final List<ClassModel> selectedItems;
  const MultiSelect({
    Key? key,
    required this.items,
    required this.selectedItems,
  }) : super(key: key);

  @override
  State<MultiSelect> createState() => _MultiSelectState();
}

class _MultiSelectState extends State<MultiSelect> {
  final List<ClassModel> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _selectedItems.addAll(widget.selectedItems);
  }

  void _itemChange(ClassModel itemValue, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedItems.add(itemValue);
      } else {
        _selectedItems.removeWhere((element) => element.id == itemValue.id);
      }
    });
  }

  void _cancel() {
    Navigator.pop(context);
  }

  void _submit() {
    Navigator.pop(context, _selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Selecione as Turmas',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: widget.items
              .map(
                (item) => CheckboxListTile(
                  value: _selectedItems.any((element) => element.id == item.id),
                  title: Text(item.nome),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (isChecked) => _itemChange(item, isChecked!),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: _cancel, child: const Text('Cancelar')),
        ElevatedButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }
}
