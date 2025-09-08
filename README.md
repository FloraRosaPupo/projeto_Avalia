# 📚 Avalia

O **Avalia** é um aplicativo para professores corrigirem provas de forma rápida e automática, usando foto da folha de respostas.  
Ele conecta **Flutter + Supabase + n8n** para oferecer uma experiência simples e escalável no processo de avaliação.

---

## 🚀 Funcionalidades do MVP

### 👨‍🏫 Para Professores
- **Gestão Acadêmica**  
  - Cadastro de matérias e turmas.  
  - Criação/edição de turmas com vínculo a uma ou mais matérias.  

- **Provas**  
  - Cadastro de provas com título, número de questões e gabarito.  
  - Gabarito bloqueado após início da correção.  

- **Correção por Foto**  
  - Tirar foto ou enviar imagem da folha de respostas preenchida.  
  - Correção automática via n8n (OCR + QR Code + comparação com gabarito).  
  - Resultado instantâneo com nota e detalhamento por questão.  

- **Resultados e Ranking**  
  - Lista de submissões da prova (aluno, nota, horário).  
  - Ranking da turma por prova.  
  - Exportação de resultados para Google Sheets.  

---

## ⚙️ Arquitetura Técnica
- **Frontend**: Flutter  
- **Backend**: Supabase (Auth, Database, Storage)  
- **Automação**: n8n (OCR, leitura de QR, cálculo de notas, integração Sheets)  

Fluxo básico:  
1. Professor cria turmas e provas.  
2. Folhas de resposta (PDF com QR Code) são geradas por aluno.  
3. O professor tira foto da folha → imagem sobe para o Supabase Storage.  
4. O n8n processa a imagem, identifica o aluno/prova, corrige e grava a nota.  
5. O app exibe resultado + ranking da turma.  

---

## 🛠️ Tecnologias
- Flutter  
- Supabase (Postgres + Storage + Auth)  
- n8n  
- Google Sheets API  

---

## 📌 Roadmap (Futuras Funcionalidades)
- Reprocessar fotos com problemas.  
- Detecção de inconsistências (respostas múltiplas).  
- Histórico de notas por aluno/turma/matéria.  
- Filtros e buscas avançadas.  

---

## 🤝 Contribuição
Pull requests são bem-vindos! Para mudanças maiores, abra uma issue antes.  

