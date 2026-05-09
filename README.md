# 🐾 Track Pet API

> API REST para **gestão e rastreamento de animais de estimação** via QR Code, desenvolvida como Trabalho de Conclusão de Curso (TCC) para a UNIFIO.

---

## 📋 Índice

- [Sobre o Projeto](#-sobre-o-projeto)
- [Tecnologias Utilizadas](#-tecnologias-utilizadas)
- [Arquitetura](#-arquitetura)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Banco de Dados](#-banco-de-dados)
- [Pré-requisitos](#-pré-requisitos)
- [Como Rodar o Projeto](#-como-rodar-o-projeto)
  - [Opção 1: Docker Compose (recomendado)](#opção-1-docker-compose-recomendado)
  - [Opção 2: Execução Local com Maven](#opção-2-execução-local-com-maven)
- [Variáveis de Ambiente](#-variáveis-de-ambiente)
- [Endpoints da API](#-endpoints-da-api)
- [Autenticação](#-autenticação)
- [Documentação Swagger](#-documentação-swagger)

---

## 📖 Sobre o Projeto

O **Track Pet** é uma API de rastreamento de animais de estimação que funciona em conjunto com coleiras equipadas com **QR Codes**. Quando alguém encontra um animal perdido e lê o QR Code com qualquer smartphone, os dados de localização (latitude/longitude), data/hora e uma mensagem personalizada são registrados no sistema — permitindo que o tutor saiba onde seu pet foi avistado pela última vez.

### Principais funcionalidades:

- 🔐 **Cadastro e autenticação** de tutores via JWT
- 🐶 **Gestão de animais** — cadastrar, listar, atualizar e desativar pets
- 📸 **Upload de foto** do animal
- 📍 **Registro de leituras de QR Code** com localização geográfica e mensagem
- 🔍 **Consulta pública** das informações do animal (sem autenticação) para quem encontrou o pet
- 🏷️ **Marcação de animais como perdidos**

---

## 🛠 Tecnologias Utilizadas

| Tecnologia | Versão | Papel |
|---|---|---|
| Java | 17 | Linguagem principal |
| Spring Boot | 3.5.6 | Framework web |
| Spring Security | — | Segurança e autenticação |
| Spring Data JPA | — | Persistência de dados |
| MySQL | 8.0 | Banco de dados relacional |
| Flyway | — | Migrações de banco de dados |
| Auth0 JWT | 4.4.0 | Geração e validação de tokens JWT |
| MapStruct | 1.6.3 | Mapeamento entre DTOs e entidades de domínio |
| Lombok | — | Redução de boilerplate |
| Springdoc OpenAPI (Swagger) | 2.8.6 | Documentação interativa da API |
| Docker + Docker Compose | — | Containerização e orquestração |
| spring-dotenv | 4.0.0 | Leitura de variáveis do arquivo `.env` |

---

## 🏛 Arquitetura

O projeto adota a **Arquitetura Hexagonal** (também conhecida como *Ports and Adapters*), que isola o núcleo de negócio (*domínio*) de frameworks, bancos de dados e mecanismos de entrega (HTTP).

```
┌──────────────────────────────────────────────────────────┐
│                   ADAPTERS (IN)                          │
│        Controllers REST  →  DTOs  →  Mappers            │
├──────────────────────────────────────────────────────────┤
│                APPLICATION (Use Cases)                   │
│           Services que implementam os Use Cases          │
├──────────────────────────────────────────────────────────┤
│                     DOMAIN                               │
│  Entidades  |  Use Cases (interfaces)  |  Repositórios   │
├──────────────────────────────────────────────────────────┤
│                   ADAPTERS (OUT)                         │
│     Persistência JPA  |  Upload de Arquivos              │
└──────────────────────────────────────────────────────────┘
```

### Por que Hexagonal?

- **Testabilidade**: o domínio não depende de Spring, banco ou HTTP — pode ser testado de forma isolada.
- **Manutenibilidade**: trocar o banco de dados ou o mecanismo de entrega (REST → gRPC, por exemplo) requer mudanças apenas nos adaptadores.
- **Separação de responsabilidades**: regras de negócio ficam exclusivamente no domínio.

---

## 📁 Estrutura do Projeto

```
src/main/java/com/unifio/tcc/track_pet/
│
├── TrackPetApplication.java           # Ponto de entrada Spring Boot
│
├── adapters/                          # Adaptadores (camada mais externa)
│   ├── in/                            # Adaptadores de entrada (HTTP)
│   │   ├── controllers/               # Controllers REST
│   │   │   ├── AnimalController.java
│   │   │   ├── AuthController.java
│   │   │   ├── LeituraQrController.java
│   │   │   └── UsuarioController.java
│   │   ├── dtos/                      # Objetos de transferência de dados
│   │   └── mappers/                   # MapStruct: DTO ↔ Domínio
│   ├── out/                           # Adaptadores de saída
│   │   ├── persistence/               # Repositórios JPA
│   │   └── files/                     # Serviço de upload de fotos
│   └── exceptions/                    # Tratamento global de erros
│
├── application/                       # Camada de aplicação
│   └── services/                      # Implementações dos Use Cases
│       ├── animal/
│       ├── auth/
│       ├── leituraqr/
│       └── usuario/
│
├── domain/                            # Núcleo do negócio (sem dependências externas)
│   ├── animal/                        # Entidade Animal, enums Sexo e Situacao
│   ├── usuario/                       # Entidade Usuario
│   ├── qr/                            # Entidade LeituraQr
│   ├── sk/                            # Value Objects de ID (AnimalId, LeituraId, UsuarioId)
│   ├── repositories/                  # Interfaces de repositório (portas de saída)
│   └── usecases/                      # Interfaces dos Use Cases (portas de entrada)
│       ├── animal/
│       ├── leituraqr/
│       └── usuario/
│
└── infra/                             # Infraestrutura transversal
    ├── config/                        # Configurações (OpenAPI/Swagger)
    └── security/                      # Filtro JWT, TokenService, UserDetailsService

src/main/resources/
├── application.properties             # Config para execução local
├── application-docker.properties      # Config para execução via Docker
└── db/migration/                      # Scripts Flyway
    ├── V1__criar_tabelas.sql
    ├── V2__adicionar_status_animal.sql
    ├── V3__remover_status_animal.sql
    └── V4__atualizar_campos_usuario.sql
```

---

## 🗄 Banco de Dados

O banco é gerenciado automaticamente pelo **Flyway** — ao subir a aplicação, as migrações são executadas em ordem.

### Diagrama das tabelas:

```
┌──────────────────────┐       ┌───────────────────────┐
│       usuario        │       │        animal         │
├──────────────────────┤       ├───────────────────────┤
│ id (BINARY 16 / UUID)│◄──────│ usuario_id (FK)       │
│ nome                 │       │ id (BINARY 16 / UUID) │
│ sobrenome            │       │ nome                  │
│ email (UNIQUE)       │       │ data_nascimento        │
│ senha (hash bcrypt)  │       │ peso                  │
│ cidade               │       │ situacao (ENUM)        │
│ bairro               │       │   VIVO/MORTO/PERDIDO  │
│ numero               │       │ foto_url              │
│ telefone             │       │ raca                  │
└──────────────────────┘       │ sexo (ENUM)           │
                               │   MACHO/FEMEA         │
                               │ cor                   │
                               └──────────┬────────────┘
                                          │
                               ┌──────────▼────────────┐
                               │       leitura_qr      │
                               ├───────────────────────┤
                               │ id (BINARY 16 / UUID) │
                               │ animal_id (FK)        │
                               │ data_hora             │
                               │ latitude              │
                               │ longitude             │
                               │ mensagem              │
                               └───────────────────────┘
```

> **Nota**: Os IDs são armazenados como `BINARY(16)` para otimizar performance no MySQL, mas a API aceita e retorna UUIDs no formato string padrão (ex: `468ffe98-eff4-4947-b078-fbd3beb713a5`).

---

## ✅ Pré-requisitos

| Ferramenta | Versão mínima |
|---|---|
| Docker | 24+ |
| Docker Compose | v2+ |
| Java (apenas para execução local) | 17 |
| Maven (apenas para execução local) | 3.9+ |

---

## 🚀 Como Rodar o Projeto

### Opção 1: Docker Compose (recomendado)

Esta é a forma mais simples — sobe a aplicação e o banco MySQL juntos, sem precisar instalar nada além do Docker.

**1. Clone o repositório:**
```bash
git clone <url-do-repositorio>
cd track-pet-api-v1
```

**2. Crie o arquivo `.env`** na raiz do projeto (veja a seção [Variáveis de Ambiente](#-variáveis-de-ambiente)):
```bash
cp .env.example .env
# Edite o .env com seus valores
```

**3. Suba os containers:**
```bash
docker compose up --build
```

**4. Acesse a API:**
- API: `http://localhost:8080`
- Swagger UI: `http://localhost:8080/swagger-ui/index.html`

**Para parar:**
```bash
docker compose down
```

**Para parar e remover os dados do banco:**
```bash
docker compose down -v
```

---

### Opção 2: Execução Local com Maven

Use este modo se preferir rodar sem Docker (requer MySQL instalado localmente).

**1. Suba um MySQL local** (porta padrão 3306) e crie o banco:
```sql
CREATE DATABASE trackpet_db;
CREATE USER 'trackpet_user'@'localhost' IDENTIFIED BY 'trackpet_pass';
GRANT ALL PRIVILEGES ON trackpet_db.* TO 'trackpet_user'@'localhost';
```

**2. Configure o `.env`** apontando para o banco local:
```env
DB_URL=jdbc:mysql://localhost:3306/trackpet_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo
DB_USERNAME=trackpet_user
DB_PASSWORD=trackpet_pass
API_SECRET=minha-chave-secreta-jwt
```

**3. Execute com Maven:**
```bash
./mvnw spring-boot:run
```

---

## ⚙️ Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto com as seguintes variáveis:

```env
# ---- MySQL (usado pelo Docker Compose para criar o container) ----
MYSQL_ROOT_PASSWORD=rootpass123
MYSQL_DATABASE=trackpet_db
MYSQL_USER=trackpet_user
MYSQL_PASSWORD=trackpet_pass

# ---- Datasource para execução local (sem Docker) ----
DB_URL=jdbc:mysql://localhost:3307/trackpet_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo
DB_USERNAME=trackpet_user
DB_PASSWORD=trackpet_pass

# ---- Datasource para execução dentro do Docker Compose ----
DB_URL_DOCKER=jdbc:mysql://mysql:3306/trackpet_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo
SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/trackpet_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=America/Sao_Paulo
SPRING_DATASOURCE_USERNAME=trackpet_user
SPRING_DATASOURCE_PASSWORD=trackpet_pass

# ---- Spring e Segurança ----
SPRING_PROFILES_ACTIVE=docker
API_SECRET=minha-chave-secreta-jwt-super-segura-2024
```

> ⚠️ O arquivo `.env` está no `.gitignore` e **nunca deve ser commitado** em repositórios públicos.

---

## 📡 Endpoints da API

### 🔐 Autenticação (`/auth`)

| Método | Rota | Autenticação | Descrição |
|---|---|---|---|
| `POST` | `/auth/registrar` | ❌ Pública | Cadastra novo usuário |
| `POST` | `/auth/login` | ❌ Pública | Efetua login e retorna token JWT |

**Exemplo de cadastro:**
```json
POST /auth/registrar
{
  "nome": "João",
  "sobrenome": "Silva",
  "email": "joao@email.com",
  "senha": "senha123",
  "cidade": "São Paulo",
  "bairro": "Centro",
  "numero": "123",
  "telefone": "11999999999"
}
```

**Exemplo de login:**
```json
POST /auth/login
{
  "email": "joao@email.com",
  "senha": "senha123"
}
// Resposta: { "token": "eyJhbGciOiJIUzI1NiIsInR5..." }
```

---

### 🐶 Animais (`/animal`)

| Método | Rota | Autenticação | Descrição |
|---|---|---|---|
| `POST` | `/animal/foto` | ✅ JWT | Cadastra animal com foto (multipart/form-data) |
| `GET` | `/animal` | ✅ JWT | Lista todos os animais ativos do usuário |
| `GET` | `/animal/{idAnimal}` | ✅ JWT | Busca animal por ID |
| `PUT` | `/animal/{idAnimal}` | ✅ JWT | Atualiza dados do animal |
| `PATCH` | `/animal/{idAnimal}` | ✅ JWT | Desativa/exclui logicamente o animal |
| `PATCH` | `/animal/perdido/{idAnimal}` | ✅ JWT | Marca o animal como perdido |
| `GET` | `/animal/informacoes-publicas/{idAnimal}` | ❌ Pública | Retorna dados públicos do animal (para quem achou) |

**Exemplo de cadastro com foto:**
```bash
POST /animal/foto
Content-Type: multipart/form-data

dados: {"nome":"Rex","peso":15.5,"raca":"Labrador","sexo":"MACHO","cor":"amarelo"}
foto: [arquivo de imagem]
```

---

### 📍 Leituras de QR Code (`/leitura`)

| Método | Rota | Autenticação | Descrição |
|---|---|---|---|
| `POST` | `/leitura/{idAnimal}` | ❌ Pública | Registra leitura com localização e mensagem |
| `GET` | `/leitura/animal/{idAnimal}` | ✅ JWT | Lista todas as leituras de um animal |
| `GET` | `/leitura/{idLeitura}` | ✅ JWT | Busca uma leitura pelo ID |
| `DELETE` | `/leitura/{idLeitura}` | ✅ JWT | Exclui uma leitura |

**Exemplo de registro de leitura:**
```json
POST /leitura/468ffe98-eff4-4947-b078-fbd3beb713a5
{
  "latitude": "-23.5505",
  "longitude": "-46.6333",
  "mensagem": "Encontrei seu cachorro no Parque Ibirapuera!"
}
```

---

### 👤 Usuário (`/usuario`)

| Método | Rota | Autenticação | Descrição |
|---|---|---|---|
| `GET` | `/usuario/perfil` | ✅ JWT | Retorna dados do perfil do usuário autenticado |

---

## 🔐 Autenticação

A API usa **JWT (JSON Web Token)** com o algoritmo HMAC. Após fazer login, inclua o token no cabeçalho de todas as requisições protegidas:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Rotas públicas (sem autenticação):
- `POST /auth/registrar`
- `POST /auth/login`
- `POST /leitura/{idAnimal}` ← qualquer pessoa pode registrar uma avistagem
- `GET /animal/informacoes-publicas/{idAnimal}` ← exibe dados do pet sem login

---

## 📚 Documentação Swagger

Com a aplicação rodando, acesse a documentação interativa:

**`http://localhost:8080/swagger-ui/index.html`**

O Swagger permite:
- Visualizar todos os endpoints com descrições
- Testar requisições diretamente pelo navegador
- Autenticar com o token JWT clicando em **Authorize**

---

## 🧪 Como testar

1. Crie um usuário via `POST /auth/registrar`
2. Faça login via `POST /auth/login` e copie o token
3. No Swagger, clique em **Authorize** e cole o token no formato: `Bearer <token>`
4. Cadastre um animal via `POST /animal/foto`
5. Use o ID do animal para simular uma leitura de QR Code via `POST /leitura/{idAnimal}`
6. Consulte as leituras via `GET /leitura/animal/{idAnimal}`

---

## 📂 Uploads de Fotos

As fotos dos animais são armazenadas localmente no diretório `./uploads/` (mapeado como volume no Docker). A URL da foto é salva no campo `foto_url` do animal e pode ser acessada via:

```
http://localhost:8080/uploads/<nome-do-arquivo>
```

---

## 👥 Autores

Desenvolvido como Trabalho de Conclusão de Curso (TCC) — UNIFIO.

---

## 📄 Licença

Este projeto é de uso acadêmico.
