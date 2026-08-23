# SaaS de Gestão Empresarial — Setup do Projeto

Documento de referência para configurar o ambiente de desenvolvimento local e organizar a base do projeto.

## 1. Visão Geral do Produto

SaaS de gestão empresarial com foco em operação, simplificado e modular. Módulos (MVP):

| Módulo | Descrição resumida |
|---|---|
| **Agendamento** | Criação e gestão de compromissos/horários (clientes, equipe, recursos) |
| **Controle de Tempo** | Registro de horas trabalhadas, entrada/saída, apontamento por tarefa |
| **Ausências e Disponibilidades** | Férias, faltas, folgas, horários disponíveis por colaborador |
| **Relatórios** | Visões consolidadas dos módulos acima (horas, presença, produtividade) |
| **Checklists Customizados** | Listas de verificação configuráveis por tipo de processo/operação |
| **Arquivo Pessoal** | Repositório de documentos por colaborador (contratos, atestados, etc.) |

---

## 2. Stack Sugerida — Rails Monolito com Hotwire

- **Backend + Frontend**: Ruby on Rails (monolito, sem API/frontend separados)
- **Linguagem**: Ruby 3.3+
- **Interatividade**: Hotwire (Turbo + Stimulus), já incluído por padrão no Rails 7+
- **Views**: ERB + [ViewComponent](https://viewcomponent.org/) (opcional, mas recomendado para componentes reutilizáveis como cards de checklist, tabelas de relatório etc.)
- **CSS**: TailwindCSS (via `tailwindcss-rails`)
- **Banco de dados**: PostgreSQL
- **Autenticação**: Devise (sessão via cookie — sem necessidade de JWT)
- **Autorização**: Pundit (políticas por módulo/papel)
- **Background jobs**: Sidekiq + Redis (útil para relatórios, notificações, geração de PDF)
- **Upload de arquivos** (módulo Arquivo Pessoal): Active Storage + S3-compatible (MinIO local / AWS S3 em produção)
- **Infra local**: Docker + Docker Compose
- **Gerenciador de pacotes Ruby**: Bundler
- **Testes**: RSpec + FactoryBot + Capybara (para testes de sistema/Turbo)

> Vantagem dessa abordagem: um único repositório, sem CORS, sem API JSON, sem cliente separado — mais rápido de entregar o MVP. Turbo Frames/Streams cobrem boa parte da interatividade que normalmente exigiria um SPA (ex: atualizar um checklist em tempo real, abrir um modal de agendamento sem recarregar a página).

---

## 3. Pré-requisitos

Instale localmente:

- [Ruby](https://www.ruby-lang.org/) 3.3+ (recomendado via [rbenv](https://github.com/rbenv/rbenv) ou [asdf](https://asdf-vm.com/))
- [Rails](https://rubyonrails.org/) 7.1+ (`gem install rails`)
- [Docker](https://www.docker.com/) e Docker Compose
- [Git](https://git-scm.com/)
- `libpq-dev` (dependência nativa do gem `pg` no Linux)
- Node.js LTS 20+ (usado internamente pelo pipeline de assets do Rails/Tailwind — não é um servidor separado)
- Editor recomendado: VS Code ou RubyMine (extensões: Ruby LSP, Solargraph, ERB formatter)

---

## 4. Estrutura de Pastas

```
gestao-saas/
├── app/
│   ├── controllers/
│   │   ├── agendamentos_controller.rb
│   │   ├── registros_ponto_controller.rb
│   │   ├── ausencias_controller.rb
│   │   ├── disponibilidades_controller.rb
│   │   ├── relatorios_controller.rb
│   │   ├── checklists_controller.rb
│   │   └── arquivos_pessoais_controller.rb
│   ├── models/
│   │   ├── empresa.rb
│   │   ├── usuario.rb
│   │   ├── agendamento.rb
│   │   ├── registro_ponto.rb
│   │   ├── ausencia.rb
│   │   ├── disponibilidade.rb
│   │   ├── checklist.rb
│   │   ├── checklist_item.rb
│   │   ├── checklist_instancia.rb
│   │   └── recurso.rb
│   ├── policies/                # Pundit
│   ├── services/                # regras de negócio isoladas por módulo
│   ├── components/              # ViewComponents (ex: checklist_card_component.rb)
│   ├── views/
│   │   ├── agendamentos/
│   │   ├── registros_ponto/
│   │   ├── ausencias/
│   │   ├── checklists/
│   │   ├── relatorios/
│   │   └── layouts/
│   └── javascript/
│       └── controllers/         # Stimulus controllers
├── config/
├── db/
│   ├── migrate/
│   └── schema.rb
├── spec/                        # RSpec
├── Gemfile
└── docker-compose.yml
```

---

## 5. Passo a Passo — Setup Local

### 5.1 Criar o projeto Rails

```bash
rails new gestao-saas --database=postgresql --css=tailwind
cd gestao-saas
git init
```

O Rails 7+ já inclui Turbo e Stimulus por padrão (via `importmap-rails` ou `esbuild`, dependendo da opção escolhida). Não é necessário nenhum setup adicional de frontend.

### 5.2 Subir infraestrutura local com Docker

Crie `docker-compose.yml` na raiz:

```yaml
version: "3.9"
services:
  db:
    image: postgres:16
    restart: always
    environment:
      POSTGRES_USER: gestao
      POSTGRES_PASSWORD: gestao
      POSTGRES_DB: gestao_saas_development
    ports:
      - "5432:5432"
    volumes:
      - db_data:/var/lib/postgresql/data

  redis:
    image: redis:7
    ports:
      - "6379:6379"

  minio:
    image: minio/minio
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - minio_data:/data

volumes:
  db_data:
  minio_data:
```

```bash
docker compose up -d
```

### 5.3 Adicionar gems ao `Gemfile`

```ruby
gem "devise"
gem "pundit"
gem "sidekiq"
gem "redis"
gem "image_processing" # para Active Storage (redimensionar avatares/anexos)
gem "view_component"

group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "dotenv-rails"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
```

```bash
bundle install
```

Instalar Devise, Pundit e Active Storage:

```bash
bin/rails generate devise:install
bin/rails generate devise Usuario
bin/rails generate pundit:install
bin/rails active_storage:install
```

Configurar RSpec:

```bash
bin/rails generate rspec:install
```

### 5.4 Configurar variáveis de ambiente

Crie `.env` na raiz do projeto:

```env
DATABASE_URL="postgresql://gestao:gestao@localhost:5432/gestao_saas_development"
REDIS_URL="redis://localhost:6379/0"

# Storage (MinIO local)
S3_ENDPOINT="http://localhost:9000"
S3_ACCESS_KEY="minioadmin"
S3_SECRET_KEY="minioadmin"
S3_BUCKET="arquivo-pessoal"
```

### 5.5 Criar o banco e rodar migrations

```bash
bin/rails db:create
bin/rails db:migrate
```

(As migrations dos módulos ficam na seção 7 — crie-as com `bin/rails generate migration ...`.)

### 5.6 Subir o servidor de desenvolvimento

```bash
# Servidor Rails (já serve as views com Turbo/Stimulus — sem servidor de frontend separado)
bin/rails server

# Sidekiq (jobs em background, em outro terminal)
bundle exec sidekiq

# Se estiver usando esbuild/tailwind em modo watch (verifique bin/dev gerado pelo Rails)
bin/dev
```

Aplicação disponível em: `http://localhost:3000`

> O Rails 7+ costuma gerar um `bin/dev` que já sobe o servidor Rails junto com o watcher do Tailwind/esbuild via Procfile (Foreman/Overmind). Prefira `bin/dev` no dia a dia.

---

## 6. Multi-tenant (Empresas)

Cada cliente é uma **empresa** (tenant) com colaboradores e dados isolados. Recomenda-se desde o início:

- Model `Empresa` (tenant)
- Toda entidade principal com `belongs_to :empresa`
- Um `before_action` no `ApplicationController` que escopa todas as queries pela empresa do usuário logado (`current_usuario.empresa`)
- Considerar a gem [`acts_as_tenant`](https://github.com/ErwinM/acts_as_tenant) para automatizar esse isolamento

---

## 7. Modelagem Inicial do Banco (rascunho por módulo)

Entidades de partida — refine conforme regras de negócio reais. Gere as migrations com `bin/rails generate migration NomeDaMigration`.

**Núcleo**
- `empresas` (id, nome, created_at)
- `usuarios` (id, empresa_id, nome, email, senha_hash [Devise], papel)

**Agendamento**
- `agendamentos` (id, empresa_id, titulo, usuario_id, data_inicio, data_fim, status, recurso_id?)
- `recursos` (id, empresa_id, nome, tipo) — salas, equipamentos, etc.

**Controle de Tempo**
- `registros_ponto` (id, empresa_id, usuario_id, tipo [entrada/saida/pausa], timestamp)
- `apontamentos_tarefa` (id, usuario_id, tarefa, duracao_minutos, data)

**Ausências e Disponibilidades**
- `ausencias` (id, empresa_id, usuario_id, tipo [ferias/atestado/falta], data_inicio, data_fim, status)
- `disponibilidades` (id, usuario_id, dia_semana, hora_inicio, hora_fim)

**Checklists Customizados**
- `checklists` (id, empresa_id, nome, descricao)
- `checklist_itens` (id, checklist_id, titulo, ordem, obrigatorio)
- `checklist_instancias` (id, checklist_id, usuario_id, data, status)
- `checklist_instancia_itens` (id, instancia_id, item_id, concluido, concluido_em)

**Arquivo Pessoal**
- Usar **Active Storage** (`has_many_attached :documentos` no model `Usuario`), evitando reinventar tabela de arquivos

**Relatórios**
- Geralmente não precisa de tabelas próprias no início — são queries/scopes agregando os dados acima. Pode-se usar a gem `groupdate` para agregações por data.

---

## 8. Interatividade com Hotwire — Como cada módulo se beneficia

| Módulo | Uso sugerido de Turbo/Stimulus |
|---|---|
| **Agendamento** | Turbo Frames para abrir/editar um agendamento em modal sem reload; Turbo Streams para atualizar a agenda quando outro usuário cria um evento |
| **Controle de Tempo** | Stimulus controller para o botão de "bater ponto" com feedback imediato (otimista) antes da resposta do servidor |
| **Checklists** | Turbo Streams para marcar itens como concluídos em tempo real, sem reload da página |
| **Relatórios** | Turbo Frames para filtros (período, colaborador) recarregando só a tabela/gráfico |
| **Arquivo Pessoal** | Stimulus controller para drag-and-drop de upload com Active Storage direct upload |

---

## 9. Gems Úteis Complementares

```ruby
gem "groupdate"      # agregações de dados por período (útil em Relatórios)
gem "ransack"         # filtros/buscas dinâmicas
gem "pagy"            # paginação leve
gem "chartkick"        # gráficos simples para Relatórios (integra com groupdate)
```

---

## 10. Próximos Passos Sugeridos

1. Criar os models e migrations da seção 7
2. Implementar autenticação (Devise) + multi-tenant primeiro (base para tudo)
3. Implementar módulos em ordem de dependência: Empresas/Usuários → Agendamento → Controle de Tempo → Ausências/Disponibilidades → Checklists → Arquivo Pessoal → Relatórios
4. Definir os primeiros ViewComponents reutilizáveis (ex: card de checklist, tabela de relatório, formulário de agendamento)
5. Mapear onde usar Turbo Frames vs. Turbo Streams em cada módulo (seção 8)
6. Configurar CI básico (RuboCop + RSpec + Capybara) antes de crescer o time

---

## 11. Referências Rápidas

- Rails Guides: https://guides.rubyonrails.org
- Hotwire: https://hotwired.dev
- Turbo Handbook: https://turbo.hotwired.dev/handbook/introduction
- Stimulus Handbook: https://stimulus.hotwired.dev/handbook/introduction
- ViewComponent: https://viewcomponent.org
- Devise: https://github.com/heartcombo/devise
- Pundit: https://github.com/varvet/pundit
- Sidekiq: https://github.com/sidekiq/sidekiq
- Active Storage: https://guides.rubyonrails.org/active_storage_overview.html
- MinIO (S3 local): https://min.io/docs/minio/container/index.html
