# Agromotion App - Controlo de Sistema

<p align="center">
  <img src="assets/logo_w_512.png" alt="Agromotion logo" width="180">
</p>

A **Agromotion App** é o centro de controlo do ecossistema Agromotion. Desenvolvida em **Flutter**, esta aplicação permite aos utilizadores gerir a alimentação dos animais de forma remota, intuitiva e em tempo real.

---

## Funcionalidades Principais

* **Painel de Monitorização:** Visualização do estado atual do robô e níveis de ração.
* **Gestão de Horários:** Agendamento flexível com suporte para múltiplos lembretes.
* **Controlo Manual:** Interface para acionar o alimentador instantaneamente.
* **Notificações em Tempo Real:** Alertas via Firebase Cloud Messaging (FCM) sobre diversos casos.
* **Segurança:** Autenticação via Email/Password ou Google Sign-In.

## Stack Tecnológica

* **Framework:** [Flutter](https://flutter.dev) (Dart)
* **Backend as a Service:** [Firebase](https://firebase.google.com)
    * **Authentication:** Gestão de utilizadores.
    * **Cloud Firestore:** Base de dados NoSQL em tempo real para sincronização de horários.
    * **Cloud Messaging:** Notificações push.
* **Plataformas Alvo:** Android, iOS e Windows.

---

## Arquitetura do Sistema

A app comunica com o robô através de uma arquitetura baseada na nuvem, garantindo que o utilizador possa controlar o sistema a partir de qualquer lugar com acesso à internet.

---

## Configuração e Instalação

### Pré-requisitos
* Flutter SDK (v3.x ou superior)
* Dart SDK
* Ficheiro `secrets.json` na raiz do projeto (criar com base no ficheiro exemplar `secrets.example.json`).

### Instalação
1.  Clonar o repositório:
    ```bash
    git clone [https://github.com/Agromotion/agromotion-app.git](https://github.com/Agromotion/agromotion-app.git)
    ```
2.  Instalar dependências:
    ```bash
    flutter pub get
    ```
3.  Configurar o Firebase:
    * Adicionar os ficheiros `google-services.json` (Android) e `GoogleService-Info.plist` (iOS).

### Execução (Exemplo Chrome/Web)
```bash
flutter run -d chrome --web-port 5555 --dart-define-from-file secrets.json
