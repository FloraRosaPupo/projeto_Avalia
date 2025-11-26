import 'package:avalia/core/state/base_state.dart';
import 'package:avalia/presentation/cubit/class_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ModalCreatedClass extends StatefulWidget {
  const ModalCreatedClass({super.key});

  @override
  State<ModalCreatedClass> createState() => _ModalCreatedClassState();
}

class _ModalCreatedClassState extends State<ModalCreatedClass> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  Color picked = Colors.blue;
  String descricao = "";
  String nome = "";
  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Usuário não autenticado')),
        );
      }
      return;
    }

    context.read<ClassCubit>().createClass(
      userId: userId,
      nome: _nameController.text.trim(),
      descricao: _subjectController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClassCubit(),
      child: BlocListener<ClassCubit, BaseState>(
        listener: (context, state) {
          if (state is SuccessState) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Turma criada com sucesso!')),
            );
            //Navigator.of(context).pop();
          } else if (state is ErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao criar turma: ${state.message}')),
            );
          }
        },

        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            height: MediaQuery.of(context).size.height * 0.45,
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Criar Turma',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nome da Turma é obrigatório';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Nome da Turma',
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
                        borderSide: BorderSide(color: Colors.purple, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    onChanged: (value) {
                      nome = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _subjectController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nome da Matéria é obrigatório';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Descrição',
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
                        borderSide: BorderSide(color: Colors.purple, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 1),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    onChanged: (value) {
                      descricao = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  /*Row(
                children: [
                  const Text('Cor:'),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      final selected = await showDialog<Color>(
                        context: context,
                        builder: (context) {
                          Color temp = picked; // estado local do diálogo
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            title: const Text('Escolha uma cor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
                            content: StatefulBuilder(
                              builder: (context, setStateSB) {
                                return SingleChildScrollView(
                                  child: ColorPicker(
                                    pickerAreaBorderRadius: BorderRadius.circular(8),
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
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('CANCELAR'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(temp),
                                child: const Text('Selecionar'),
                              ),
                            ],
                          );
                        },
                      );
                      if (selected != null) {
                        setState(() => picked = selected); // atualiza o container
                      }
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: picked, // agora pega a cor certa
                        borderRadius: BorderRadius.circular(8),
                        
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),*/
                  BlocBuilder<ClassCubit, BaseState>(
                    builder: (context, state) {
                      final isLoading = state is LoadingState;
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed:
                            isLoading || nome.isEmpty || descricao.isEmpty
                            ? () {}
                            : () {
                                context.read<ClassCubit>().createClass(
                                  userId: Supabase
                                      .instance
                                      .client
                                      .auth
                                      .currentUser!
                                      .id,
                                  nome: nome,
                                  descricao: descricao,
                                );
                              },
                        child: isLoading
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
                                style: TextStyle(color: Colors.white),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
