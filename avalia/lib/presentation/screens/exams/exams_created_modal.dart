import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ModalCreatedExams extends StatefulWidget {
  const ModalCreatedExams({super.key});

  @override
  State<ModalCreatedExams> createState() => _ModalCreatedExamsState();
}

class _ModalCreatedExamsState extends State<ModalCreatedExams> {
  Color picked = Colors.blue;
  final List<String> _classes = ['Turma A', 'Turma B', 'Turma C', 'Turma de Férias'];
  List<String> _selectedClasses = [];

  void _showMultiSelect() async {
    final List<String>? results = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return MultiSelect(items: _classes, selectedItems: _selectedClasses);
      },
    );

    if (results != null) {
      setState(() {
        _selectedClasses = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return  Container(
        
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Criar Prova',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Nome da Prova',
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
              ElevatedButton(
                onPressed: _showMultiSelect,
                child: const Text('Vincular Turmas'),
              ),
              Wrap(
                spacing: 8.0, // Espaçamento horizontal entre os chips
                runSpacing: 4.0, // Espaçamento vertical entre as linhas de chips
                children: _selectedClasses
                    .map((turma) => Chip(
                          label: Text(turma),
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
                        ))
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
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implementar lógica para fazer upload da imagem do gabarito
                },
                icon: Icon(Icons.upload_file),
                label: const Text('Carregar Gabarito'),
              ),
              const SizedBox(height: 24),
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

// Adicione esta nova classe ao final do arquivo
class MultiSelect extends StatefulWidget {
  final List<String> items;
  final List<String> selectedItems;
  const MultiSelect({Key? key, required this.items, required this.selectedItems}) : super(key: key);

  @override
  State<MultiSelect> createState() => _MultiSelectState();
}

class _MultiSelectState extends State<MultiSelect> {
  final List<String> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _selectedItems.addAll(widget.selectedItems);
  }

  void _itemChange(String itemValue, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedItems.add(itemValue);
      } else {
        _selectedItems.remove(itemValue);
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
      title: const Text('Selecione as Turmas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
      content: SingleChildScrollView(
        child: ListBody(
          children: widget.items
              .map((item) => CheckboxListTile(
                    value: _selectedItems.contains(item),
                    title: Text(item),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (isChecked) => _itemChange(item, isChecked!),
                  ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
