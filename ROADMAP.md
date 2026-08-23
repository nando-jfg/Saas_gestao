# Roadmap — SaaS de Gestão Empresarial

Plano de construção modular, pensado para ser executado em fases incrementais. Cada fase entrega algo funcional e testável antes de avançar para a próxima — evita construir os 6 módulos em paralelo e travar tudo ao mesmo tempo.

## Princípio geral de modularização

- Cada módulo do domínio (Agendamento, Controle de Tempo, etc.) deve viver isolado em sua própria pasta de `models`, `controllers`, `views`, `services` e `policies` — evitando acoplamento direto entre módulos.
- Comunicação entre módulos (ex: Relatórios lendo dados de Controle de Tempo) deve passar por **services/queries dedicados**, não por chamadas diretas espalhadas pelos controllers.
- Cada fase abaixo termina com testes (RSpec) cobrindo o módulo antes de seguir adiante.

---

## Fase 0 — Fundação (Semana 1–2)

**Objetivo:** ter o esqueleto do projeto rodando localmente, com autenticação e multi-tenant funcionando — a base que todos os módulos vão usar.

**Entregáveis:**
- Projeto Rails criado (monolito + Hotwire), Docker Compose com Postgres/Redis/MinIO
- Model `Empresa` (tenant) e `Usuario` (Devise)
- Isolamento multi-tenant (`acts_as_tenant` ou `before_action` de escopo)
- Papéis/permissões básicos (admin da empresa vs. colaborador) via Pundit
- Layout base da aplicação (navegação, autenticação, tela de "minha empresa")
- CI básico (RuboCop + RSpec) rodando em cada push

**Dependências:** nenhuma — é o ponto de partida.

**Critério de conclusão:** um usuário consegue se cadastrar, criar uma empresa, convidar outro colaborador e logar — nada de funcionalidade de negócio ainda.

---

## Fase 1 — Agendamento (Semana 3–4)

**Objetivo:** primeiro módulo de negócio, porque é o que mais claramente valida a UX do produto (calendário, criação de eventos) e testa o padrão de Turbo Frames/Streams que os outros módulos vão reaproveitar.

**Entregáveis:**
- Models `Agendamento` e `Recurso`
- CRUD de agendamentos com Turbo Frame (criar/editar sem reload)
- Visualização em calendário (semana/mês)
- Validações de conflito de horário (mesmo colaborador/recurso)
- Notificação simples (e-mail via ActionMailer) ao criar/alterar agendamento

**Dependências:** Fase 0 (auth + multi-tenant).

**Critério de conclusão:** um colaborador cria, edita e cancela agendamentos, e o sistema impede conflitos de horário.

---

## Fase 2 — Controle de Tempo (Semana 5–6)

**Objetivo:** módulo de registro de ponto/horas, independente de Agendamento (não depende dele, mas pode futuramente se relacionar).

**Entregáveis:**
- Models `RegistroPonto` e `ApontamentoTarefa`
- Tela de "bater ponto" com Stimulus (feedback otimista) + Turbo Stream atualizando status em tempo real
- Cálculo de horas trabalhadas por dia/semana (service dedicado, reaproveitável por Relatórios depois)
- Histórico de registros por colaborador

**Dependências:** Fase 0.

**Critério de conclusão:** colaborador registra entrada/saída e visualiza o total de horas do período; dados já estruturados para consumo futuro por Relatórios.

---

## Fase 3 — Ausências e Disponibilidades (Semana 7–8)

**Objetivo:** módulo que se relaciona com Agendamento (não marcar compromissos em cima de ausência) e com Controle de Tempo (ausência impacta cálculo de horas esperadas).

**Entregáveis:**
- Models `Ausencia` e `Disponibilidade`
- Fluxo de solicitação de ausência (colaborador solicita → admin aprova/recusa)
- Validação cruzada com Agendamento (aviso ao tentar agendar em período de ausência)
- Tela de disponibilidade semanal por colaborador

**Dependências:** Fase 1 (Agendamento) para a validação cruzada; Fase 2 é desejável mas não bloqueante.

**Critério de conclusão:** ausências aprovadas bloqueiam/alertam sobre novos agendamentos no mesmo período.

---

## Fase 4 — Checklists Customizados (Semana 9–10)

**Objetivo:** módulo mais "genérico"/configurável do sistema — bom momento para introduzir porque já existe massa de dados de outros módulos para eventualmente vincular checklists a eles (ex: checklist de abertura de expediente ligado a um agendamento).

**Entregáveis:**
- Models `Checklist`, `ChecklistItem`, `ChecklistInstancia`, `ChecklistInstanciaItem`
- Tela de criação de template de checklist (admin) com itens ordenáveis
- Execução de checklist por colaborador com Turbo Stream (marcar item concluído em tempo real)
- Histórico de instâncias concluídas por checklist

**Dependências:** Fase 0. Integração opcional com Agendamento (vincular checklist a um evento) pode ficar para depois.

**Critério de conclusão:** admin cria um checklist customizado, colaborador executa e conclui uma instância, histórico fica registrado.

---

## Fase 5 — Arquivo Pessoal (Semana 11)

**Objetivo:** módulo mais isolado tecnicamente (Active Storage + MinIO/S3), pode ser desenvolvido em paralelo a outra fase se houver mais de uma pessoa no time.

**Entregáveis:**
- `has_many_attached :documentos` no model `Usuario`
- Upload com Stimulus (drag-and-drop) + direct upload do Active Storage
- Categorização de documentos (contrato, atestado, outro)
- Controle de visibilidade (colaborador vê só os seus; admin vê de todos)

**Dependências:** Fase 0 apenas. Pode ser antecipado no cronograma se fizer sentido para o time.

**Critério de conclusão:** colaborador faz upload de um documento, admin consegue visualizar/baixar arquivos de qualquer colaborador da empresa.

---

## Fase 6 — Relatórios (Semana 12–13)

**Objetivo:** último módulo por design — depende de dados reais dos outros cinco para ter sentido (horas trabalhadas, taxa de ausência, checklists concluídos, agendamentos por período).

**Entregáveis:**
- Services/queries de agregação por módulo (reaproveitando os services criados nas fases anteriores, ex: cálculo de horas da Fase 2)
- Dashboard com filtros (período, colaborador, equipe) usando Turbo Frame
- Gráficos com `chartkick` + `groupdate`
- Exportação simples (CSV/PDF) dos relatórios principais

**Dependências:** Fases 1 a 4 (quanto mais módulos prontos, mais relatórios fazem sentido — pode ser entregue incrementalmente, um relatório por módulo já existente).

**Critério de conclusão:** admin visualiza pelo menos 3 relatórios (horas trabalhadas, ausências, checklists concluídos) com filtro de período.

---

## Fase 7 — Polimento e Preparação para Produção (Semana 14–15)

**Objetivo:** fechar lacunas de qualidade e preparar deploy.

**Entregáveis:**
- Revisão de permissões (Pundit) em todos os módulos
- Testes de sistema (Capybara) cobrindo os fluxos críticos de cada módulo
- Ajustes de UX/responsividade (mobile)
- Configuração de ambiente de produção (deploy, variáveis de ambiente, backups do Postgres, storage em S3 real)
- Onboarding de nova empresa (fluxo de cadastro self-service, se aplicável)

**Dependências:** todas as fases anteriores.

**Critério de conclusão:** aplicação pronta para os primeiros clientes reais (beta fechado).

---

## Visão Consolidada (Gantt simplificado)

```
Semana:        1   2   3   4   5   6   7   8   9   10  11  12  13  14  15
Fundação       ██  ██
Agendamento            ██  ██
Ctrl. Tempo                    ██  ██
Ausências/Disp.                        ██  ██
Checklists                                     ██  ██
Arquivo Pessoal                                        ██
Relatórios                                                 ██  ██
Polimento                                                          ██  ██
```

> As durações são estimativas de referência para 1–2 desenvolvedores full-time. Ajuste conforme o tamanho real do time — módulos marcados como "dependência opcional" (Arquivo Pessoal, por exemplo) podem ser paralelizados se houver mais gente disponível.

---

## Ordem de Prioridade Alternativa (se precisar de MVP mais enxuto)

Se o objetivo for validar o produto o quanto antes com o mínimo de módulos:

1. **Fundação** (obrigatório)
2. **Agendamento** ou **Controle de Tempo** — escolha o que for o "gancho" principal do seu público-alvo
3. **Checklists** — módulo simples e genérico, agrega valor rápido
4. **Relatórios básicos** (só do que já existe) — mostra valor consolidado cedo
5. Deixar **Ausências/Disponibilidades** e **Arquivo Pessoal** para uma segunda onda pós-validação

---

## Próximos Passos Imediatos

1. Confirmar o time disponível (1 dev? 2+ devs? isso muda o paralelismo possível entre módulos)
2. Validar se a ordem de fases faz sentido para o seu público-alvo (ex: se o cliente-piloto se importa mais com Controle de Tempo do que Agendamento, inverter Fase 1 e 2)
3. Criar os épicos/issues no seu gerenciador de tarefas espelhando as fases acima
4. Iniciar Fase 0 seguindo o `SETUP.md`
