import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:avalia/presentation/cubit/exams_cubit.dart';
import 'package:avalia/presentation/cubit/class_cubit.dart';
import 'package:avalia/core/state/base_state.dart';
import 'package:avalia/data/models/class_model.dart';
import 'package:avalia/data/models/exam_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.exam != null) {
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
        setState(() {
          _gabaritoImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao selecionar imagem: $e')));
    }
  }

  Future<void> _saveExam(BuildContext context) async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira o nome da prova')),
      );
      return;
    }

    if (_gabaritoImage == null && _existingGabaritoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, carregue o gabarito')),
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
    });

    try {
      final cubit = context.read<ExamsCubit>();

      String? gabaritoUrl = _existingGabaritoUrl;

      // 1. Upload do gabarito se houver nova imagem
      if (_gabaritoImage != null) {
        gabaritoUrl = await cubit.uploadGabarito(_gabaritoImage!);
        if (gabaritoUrl == null) {
          throw Exception('Falha ao obter URL do gabarito');
        }
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      final examData = {
        'nome': _nameController.text,
        'cor': picked.value.toRadixString(16).substring(2),
        'url_prova': gabaritoUrl,
        'user_id': userId,
        'status': 'Aberto', // Mantém 'Aberto' ou atualiza se necessário
        'turmas_id': _selectedClasses.map((c) => c.id).toList(),
      };

      if (widget.exam == null) {
        // Create
        examData['created_at'] = DateTime.now().toIso8601String();
        await cubit.createExam(examData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prova criada com sucesso!')),
          );
        }
      } else {
        // Update
        await cubit.updateExam(widget.exam!.id, examData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prova atualizada com sucesso!')),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar prova: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
          return Padding(
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
                      widget.exam == null ? 'Criar Prova' : 'Editar Prova',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
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
                            color: Colors.purple,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Botão de vincular turmas com BlocBuilder para estado das turmas
                    BlocConsumer<ClassCubit, BaseState>(
                      listener: (context, state) {
                        if (state is SuccessState<ClassListResponse> &&
                            widget.exam != null &&
                            !_classesInitialized) {
                          // Pre-selecionar turmas na edição
                          final allTurmas = state.data.classes;
                          final examTurmasIds = widget.exam!.turmasId;
                          setState(() {
                            _selectedClasses = allTurmas
                                .where((t) => examTurmasIds.contains(t.id))
                                .toList();
                            _classesInitialized = true;
                          });
                        }
                      },
                      builder: (context, state) {
                        List<ClassModel> availableClasses = [];
                        bool isLoadingClasses = false;

                        if (state is LoadingState) {
                          isLoadingClasses = true;
                        } else if (state is SuccessState<ClassListResponse>) {
                          availableClasses = state.data.classes;
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
                    if (_gabaritoImage != null)
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
                              });
                            },
                          ),
                        ],
                      )
                    else if (_existingGabaritoUrl != null)
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _existingGabaritoUrl!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Text('Erro ao carregar imagem'),
                                  ),
                            ),
                          ),
                          // Opção para remover a imagem existente se desejar (opcional)
                        ],
                      ),

                    ElevatedButton.icon(
                      onPressed: _pickGabarito,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        _gabaritoImage == null && _existingGabaritoUrl == null
                            ? 'Carregar Gabarito'
                            : 'Trocar Gabarito',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isLoading ? null : () => _saveExam(context),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
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
