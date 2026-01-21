# 📚 Avalia

Correção inteligente de provas objetivas a partir de fotos.

Professores tiram uma foto da folha de respostas e recebem, em segundos, a nota, o detalhamento por questão e o ranking da turma.

📸 Foto → 🤖 IA → 📊 Resultado  
Sem planilha, sem caneta vermelha, sem dor de cabeça.

---

## ✨ Visão Geral

O Avalia é uma plataforma que automatiza a correção de provas objetivas usando inteligência artificial. A ideia é reduzir o tempo e o esforço na correção, oferecendo feedback imediato e organização clara dos resultados por turma.

---

## 🎯 Objetivo

- Reduzir o tempo e o esforço na correção de provas.
- Oferecer correção automática confiável.
- Fornecer feedback imediato ao professor.
- Manter organização clara dos resultados por turma.

---

## 🚀 Funcionalidades do MVP

### 👨‍🏫 Área do Professor

- Interface para gerenciamento de provas e turmas.
- Visualização de resultados e ranking por prova/turma.

### 📚 Gestão Acadêmica

- Cadastro de matérias.
- Criação e gerenciamento de turmas.
- Associação de turmas a uma ou mais matérias.

### 📝 Provas

- Criação de provas com:
  - Título
  - Número de questões
  - Alternativas (A–E)
  - Gabarito
- Bloqueio automático do gabarito após o início da correção.

### 📷 Correção por Foto (IA)

- Envio da imagem da folha de respostas.
- Processamento via Google Gemini:
  - Identificação das alternativas marcadas.
  - Detecção de rasuras e respostas inválidas.
  - Comparação direta com o gabarito.
- Retorno imediato com:
  - Nota final
  - Acertos e erros por questão

### 📊 Resultados

- Lista de submissões por prova.
- Exibição de nota, aluno e horário de envio.
- Ranking automático da turma.

---

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

## 🛠️ Stack Tecnológica

| Camada     | Tecnologia                   |
|------------|-----------------------------:|
| Frontend   | Flutter                      |
| Backend    | Supabase                     |
| Banco      | PostgreSQL                   |
| Storage    | Supabase Storage             |
| Funções    | Supabase Edge Functions      |
| IA         | Google Gemini API            |

---

## 🔒 Segurança e Confiabilidade

- Autenticação via Supabase Auth.
- Gabarito bloqueado após início das correções.
- Processamento isolado por prova.
- Histórico de submissões preservado.

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
