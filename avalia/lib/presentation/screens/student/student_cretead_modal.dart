import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avalia/presentation/cubit/student_cubit.dart';

class ModalCreatedStudent extends StatefulWidget {
  final int classId;
  const ModalCreatedStudent({super.key, required this.classId});

  @override
  State<ModalCreatedStudent> createState() => _ModalCreatedStudentState();
}

class _ModalCreatedStudentState extends State<ModalCreatedStudent> {
  final _nameController = TextEditingController();
  final _matriculaController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return BlocListener<StudentCubit, StudentState>(
      listener: (context, state) {
        if (state.status == StudentStatus.success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aluno criado com sucesso!')),
          );
        } else if (state.status == StudentStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Erro ao criar aluno'),
            ),
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          height: MediaQuery.of(context).size.height * 0.45,
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Criar Aluno',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Nome do Aluno',
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
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _matriculaController,
                decoration: InputDecoration(
                  hintText: 'Matricula',
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
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  if (_nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nome do aluno é obrigatório'),
                      ),
                    );
                    return;
                  }

                  context.read<StudentCubit>().createStudent(
                    turmaId: widget.classId,
                    nome: _nameController.text.trim(),
                    matricula: _matriculaController.text.trim().isEmpty
                        ? null
                        : _matriculaController.text.trim(),
                  );
                },
                child: Text(
                  'Salvar',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
