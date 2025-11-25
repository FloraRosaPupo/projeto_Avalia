import 'package:flutter/material.dart';

class DetailsExamsStudentScreens extends StatelessWidget {
  const DetailsExamsStudentScreens({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock dos resultados (substitua pelos seus dados reais)
    final answers = <AnswerCompare>[
      AnswerCompare(1, 'C', 'C'),
      AnswerCompare(2, 'A', 'B'),
      AnswerCompare(3, 'E', 'E'),
      AnswerCompare(4, 'D', 'D'),
      AnswerCompare(5, 'B', 'C'),
      AnswerCompare(6, 'A', 'A'),
    ];

    final total = answers.length;
    final correct = answers.where((a) => a.isCorrect).length;

    return Scaffold(
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
        title: const Text('Detalhes da Prova', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Card(
              color: Colors.white, // cor de fund,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Nome da Prova',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Data da Prova: 12/05/2023', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(59, 132, 231, 135),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.black),
                        SizedBox(width: 8),
                        Text('Corrigida',
                            style: TextStyle(
                                fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: _statBox(title: 'Nota', value: '$correct/$total'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statBox(title: 'Acertos', value: '$correct'),
                    ),
                  ])
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Gabarito do Aluno vs. Gabarito Oficial',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // Cabeçalho da lista
                  _headerRow(),
                  const Divider(height: 16),
                  // A LISTA QUE VOCÊ QUER
                  ListView.separated(
                    itemCount: answers.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (_, index) {
                      final a = answers[index];
                      return _answerRow(a);
                    },
                  ),
                ]),
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Anexo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Image.network('https://www.obbiotec.com.br/wp-content/uploads/2022/03/gabarito.jpg')

                  ])
                )
              ),
            ),
          ]),
        ),
      ),
    );
  }

  static Widget _statBox({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 230, 229, 229),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.black)),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
      ]),
    );
  }

  static Widget _headerRow() {
    return Row(
      children: const [
        SizedBox(width: 28, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Center(child: Text('Aluno', style: TextStyle(fontWeight: FontWeight.bold)))),
        Expanded(child: Center(child: Text('Oficial', style: TextStyle(fontWeight: FontWeight.bold)))),
        SizedBox(width: 28), // espaço para o ícone
      ],
    );
  }

  static Widget _answerRow(AnswerCompare a) {
    return Row(
      children: [
        SizedBox(width: 28, child: Text('${a.number}.')),
        Expanded(
          child: Center(child: Text(a.studentAnswer)),
        ),
        Expanded(
          child: Center(child: Text(a.officialAnswer)),
        ),
        SizedBox(
          width: 28,
          child: Icon(
            a.isCorrect ? Icons.check_circle : Icons.cancel,
            color: a.isCorrect ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
      ],
    );
  }
}

class AnswerCompare {
  final int number;
  final String studentAnswer;
  final String officialAnswer;

  const AnswerCompare(this.number, this.studentAnswer, this.officialAnswer);

  bool get isCorrect => studentAnswer.toUpperCase() == officialAnswer.toUpperCase();
}
