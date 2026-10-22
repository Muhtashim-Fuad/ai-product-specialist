# 🛍️ AI Product Specialist

**An intelligent, cross-platform AI product advisor powered by Retrieval-Augmented Generation (RAG), Flutter, and BLoC.**

AI Product Specialist is a Flutter-based chatbot designed to answer customer questions about products using information retrieved directly from a product catalog. By combining vector embeddings, semantic similarity search, and Large Language Models (LLMs), it provides context-aware product recommendations while minimizing hallucinations and unsupported claims.

The application supports multiple AI backends, including OpenRouter for cloud-based inference, Ollama for local inference, and a fake repository for offline development and testing.

## ✨ Features

### 🧠 Retrieval-Augmented Generation (RAG)

- **Catalog ingestion:** Converts structured product data, such as CSV files, into searchable text chunks.
    
- **Vector embeddings:** Generates embeddings for product catalog entries using configurable embedding models.
    
- **Local vector storage:** Persists embeddings and associated catalog content on the device.
    
- **Semantic search:** Retrieves relevant product information using vector similarity and cosine similarity scoring.
    
- **Grounded responses:** Instructs the AI to answer using retrieved product context instead of inventing product specifications, prices, or availability.
    
- **Product comparison:** Compares relevant products concisely using the available catalog information.
    
- **Multilingual support:** Handles product inquiries in multiple languages.
    
- **Topic boundaries:** Politely redirects questions unrelated to the product catalog.
    

### 🔌 Pluggable AI Backends

Switch between cloud-based inference, local Ollama inference, and mock responses through the repository abstraction.

|Backend|Chat model|Embedding model|Inference|
|---|---|---|---|
|OpenRouter|`google/gemma-4-31b-it`|`liquid/lfm-2.5-embedding-350m:free`|Cloud API|
|Ollama|`gemma4:e2b-it-qat`|`all-minilm`|Local server|
|Fake repository|Mock responses|Not required|Offline/testing|

_Model availability and provider requirements may change. Verify the configured model identifiers against the relevant provider before running the application._

### State Management

`**ChatBloc**` manages the conversation lifecycle, user input, document indexing, and response generation.

| Event            | Responsibility                                     |
| ---------------- | -------------------------------------------------- |
| `DraftChanged`   | Updates the current message draft.                 |
| `MessageSent`    | Initiates message processing and reply generation. |
| `MessageCleared` | Clears the conversation and resets the composer.   |
| `DocumentLoaded` | Handles catalog loading or indexing operations.    |

The chat state includes:

- `messages` — Conversation messages.
    
- `draft` — Current composer text.
    
- `status` — Current state: `idle`, `awaitingReply`, or `failure`.
    
- `composerResetCount` — Coordinates composer resets after conversation changes.
    
- `documentLoading` — Tracks catalog indexing activity.
    

`**ThemeBloc**` manages the application's current brightness mode and coordinates light/dark theme switching.

### Repository Pattern

The abstract `ChatRepository` interface separates the chat UI and business logic from individual AI providers.

Its primary operations are:

- `getReply` — Generates a response to a user query using the relevant retrieved context.
    
- `embedContext` — Supports the embedding workflow for product catalog content.
    

The concrete implementations are:

- `OpenRouterChatRepository` — Sends chat and embedding requests to OpenRouter.
    
- `OllamaChatRepository` — Uses a local Ollama server for inference and embeddings.
    
- `FakeChatRepository` — Supplies mock behavior for development and testing.
    

This separation makes it easier to change providers, test application behavior, and extend the project without tightly coupling the UI to a particular LLM.

## 🛠️ Tech Stack

|Technology|Purpose|
|---|---|
|[Flutter](https://flutter.dev/)|Cross-platform application framework|
|[Dart](https://dart.dev/)|Application programming language|
|[flutter_bloc](https://pub.dev/packages/flutter_bloc)|BLoC state management|
|[equatable](https://pub.dev/packages/equatable)|Value equality for states and events|
|[http](https://pub.dev/packages/http)|HTTP requests to AI provider APIs|
|[flutter_dotenv](https://pub.dev/packages/flutter_dotenv)|Environment variable configuration|
|[flutter_markdown](https://pub.dev/packages/flutter_markdown)|Markdown rendering for chat messages|
|[markdown](https://pub.dev/packages/markdown)|Markdown parsing utilities|
|[path_provider](https://pub.dev/packages/path_provider)|Platform-specific local storage paths|

## 🚀 Getting Started

### Prerequisites

Before running the project, ensure you have:

- Flutter SDK installed and configured.
    
- Dart SDK compatible with the Flutter version used by the project.
    
- Git installed.
    
- An OpenRouter API key for cloud inference, or Ollama installed and running for local inference.
    
- A product catalog file in the format expected by the application's ingestion pipeline.
    

### 1. Clone the Repository

```bash
git clone https://github.com/Muhtashim-Fuad/ai-product-specialist
cd ai-chatbot
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Environment Variables

If using OpenRouter, create a `.env` file in the project root and configure your API key:

```dotenv
API_KEY=your_openrouter_api_key
```

Ensure that `.env` is loaded by the application and that its asset configuration is included in `pubspec.yaml`, as required by the project.

**Security note:** Never commit real API keys or other secrets to Git. Add `.env` to `.gitignore` and provide a sanitized `.env.example` for other developers.

Example `.env.example`:

```dotenv
API_KEY=your_openrouter_api_key
```

### 4. Configure the Product Catalog

Place your product catalog in the location expected by the application's indexing configuration.

For example, a CSV file might contain:

```csv
id,name,description,price,category
1,Wireless Headphones,Over-ear headphones with Bluetooth connectivity,79.99,Electronics
2,Mechanical Keyboard,Mechanical keyboard with tactile switches,59.99,Accessories
3,Smart Watch,Fitness tracking and notification support,129.99,Wearables
```

This is an illustrative example. Use the actual column names, parsing rules, and file paths supported by the implementation.

The application processes the catalog into text chunks, generates embeddings, and stores the indexed content locally for retrieval.

### 5. Run the Application

```bash
flutter run
```

To list available development devices:

```bash
flutter devices
```

Select a device or emulator and run the application using the standard Flutter workflow.

## ⚙️ AI Backend Configuration

### OpenRouter — Cloud Inference

The default backend uses OpenRouter's API.

- Configure the `API_KEY` environment variable.
    
- Ensure the configured chat and embedding models are available to your account.
    
- Verify network connectivity and provider-specific request requirements.
    
- Keep API keys out of source control and production client bundles.
    

OpenRouter provides access to hosted models through a unified API.

Documentation: [OpenRouter API](https://openrouter.ai/docs)

### Ollama — Local Inference

The Ollama backend uses a local Ollama server for chat generation and embeddings.

Install Ollama from [ollama.com](https://ollama.com/), then pull the configured models:

```bash
ollama pull gemma4:e2b-it-qat
ollama pull all-minilm
```

Start the Ollama server:

```bash
ollama serve
```

The repository is configured to use:

```text
http://localhost:11434
```

**Platform note:** `localhost` refers to the device or environment running the Flutter application. For Android emulators, physical devices, or deployed applications, the Ollama base URL may need to be changed to an address reachable from that environment. Ensure the server is accessible and appropriately secured.

### Fake Repository — Development and Testing

The fake repository supplies mock responses without requiring a live AI service. It is useful for developing UI components, testing BLoC behavior, and validating chat flows without incurring API costs.

## 💡 Usage

Once the application is running:

1. **Index the catalog:** Use the indexing or synchronization action in the app bar to load product data and generate or refresh embeddings.
    
2. **Ask a question:** Enter a product-related query in the message composer.
    
3. **Retrieve relevant information:** The application searches the local vector store for matching catalog entries.
    
4. **Generate a response:** The selected AI backend receives the query and retrieved product context.
    
5. **Review the answer:** Read the formatted response, compare products, and ask follow-up questions.
    
6. **Change appearance:** Toggle between light and dark modes.
    
7. **Reset the conversation:** Clear chat history when you want to start a new conversation.
    

Example questions:

- "Which headphones support Bluetooth?"
    
- "Compare the mechanical keyboard and wireless headphones."
    
- "What is the price of the smart watch?"
    
- "Do you have any products in the Electronics category?"
    
- "Can you recommend a product for my needs?"
    

Answers depend on the products and fields present in the indexed catalog. If the retrieved context does not contain the requested information, the assistant should avoid making unsupported claims.

## 🛡️ Grounding and Hallucination Prevention

The chatbot is designed to treat retrieved catalog content as the source of truth for product-related responses.

Its prompting strategy aims to enforce the following rules:

- Use retrieved product context as the factual basis for answers.
    
- Never invent product prices, specifications, or availability.
    
- Compare products only using information supported by the catalog.
    
- Acknowledge when the requested information is missing.
    
- Handle supported multilingual queries without changing the underlying product facts.
    
- Redirect unrelated questions politely.
    

**Important:** Prompting and retrieval reduce hallucinations but do not guarantee their complete elimination. Production deployments should also validate retrieval quality, handle conflicting or stale catalog entries, and test responses against known product facts.

## 🔒 Security and Privacy Considerations

- Keep provider API keys out of committed files.
    
- Avoid embedding privileged API credentials in distributed mobile applications.
    
- Consider a backend proxy for production deployments that require protected provider credentials.
    
- Validate catalog inputs before indexing.
    
- Set appropriate request timeouts and handle network failures gracefully.
    
- Review how locally persisted catalog data is stored, updated, and deleted.
    
- Avoid logging sensitive user queries or API credentials.
    
- Configure local AI server access carefully when using Ollama on a network.