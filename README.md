# Avalia — Gestão de Turmas e Provas

## Descrição

Aplicativo Flutter para professores organizarem turmas, alunos, provas e submissões. A interface prevê envio de fotos e consulta de resultados de correção. Autenticação, armazenamento, RPCs e correção externa dependem de um backend Supabase configurado; as migrações e Edge Functions desse backend não estão incluídas neste repositório.

## Stack e bibliotecas

Flutter/Dart, bloc/flutter_bloc (Cubit), supabase_flutter, equatable, image_picker, file_picker e google_generative_ai.

Dependências e versões declaradas: [avalia/pubspec.yaml](avalia/pubspec.yaml).

## Funcionalidades

- Cadastro e consulta de turmas e alunos.
- Criação e organização de provas e seus gabaritos.
- Envio de imagens e consulta de submissões, com processamento dependente do backend externo.
- Painel para acompanhar resultados e desempenho.

## Licença

Não há uma licença de distribuição definida para este repositório. Nenhuma licença MIT, Apache ou equivalente é concedida por este README. As atribuições e os direitos dos materiais de terceiros permanecem preservados.

## Validação e limites

Modelo de prova, erro/recuperação de turmas, criação seguida de recarga e conclusão após fechamento. Upload, RPCs e correção externa dependem do backend configurado.

## 🧠 Arquitetura

Fluxo de alto nível:

```
Flutter App
   │
   │  (upload da imagem)
   ▼
Supabase Storage
   │
   │  (Edge Function)
   ▼
Google Gemini API
   │
   │  (respostas + nota)
   ▼
Supabase Database
   │
   ▼
Flutter App (resultados e ranking)
```

---

## 🧭 Roadmap

- Reprocessamento de imagens com baixa qualidade.
- Detecção avançada de inconsistências.
- Histórico de notas por aluno, turma e matéria.
- Filtros e buscas avançadas.
- Métricas de desempenho por turma.

---

## 🤝 Contribuição

Contribuições são bem-vindas! Para mudanças maiores, abra uma issue antes.

---

<div align="center">
⭐ Se esse projeto te ajudou ou te inspirou, deixa uma estrela! ⭐
</div>

## Desenvolvimento e validação

O aplicativo está em `avalia`. Use Flutter 3.41.1. Na pasta do aplicativo, execute:

```sh
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter run
```

A CI valida análise e testes em pushes e pull requests. Serviços externos precisam de configuração própria.

## Organização por funcionalidade

`avalia/lib/features/` agrupa autenticação, turmas, provas, alunos, dashboard e submissões. Cada área reúne seus modelos, estados e telas; `core/` conserva apenas infraestrutura compartilhada. O repositório não inclui migrações SQL nem o código das Edge Functions descritas acima: o backend precisa ser provisionado separadamente.

## Organização e manutenção

Features auth/classes/students/exams/submissions/dashboard agrupam seus modelos e apresentação. `ClassCubit` depende do contrato `ClassRepository`, com implementação Supabase separada; autenticação também usa contrato. Os demais Cubits recebem cliente Supabase por injeção onde acessavam o singleton. Cubit exerce o papel de estado da apresentação; não foi duplicado com outro ViewModel.

Veja [a revisão de desenvolvimento](docs/REVISAO.md) para decisões, testes e limites, e [o guia de contribuição](CONTRIBUTING.md) para o fluxo de manutenção.
