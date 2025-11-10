import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ModalCreatedClass extends StatefulWidget {
  const ModalCreatedClass({super.key});

  @override
  State<ModalCreatedClass> createState() => _ModalCreatedClassState();
}

class _ModalCreatedClassState extends State<ModalCreatedClass> {
  Color picked = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        height: MediaQuery.of(context).size.height * 0.4,
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Criar Turma',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Nome da Turma',
                hintStyle: TextStyle(color: Color.fromARGB(99, 158, 158, 158)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(99, 158, 158, 158)),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Nome da Matéria',
                hintStyle: TextStyle(color: Color.fromARGB(99, 158, 158, 158)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color.fromARGB(99, 158, 158, 158)),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                // use "picked" aqui para salvar a cor escolhida
                //Navigator.of(context).pop(picked);
              },
              child: const Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
