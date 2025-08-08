# PrismNg Firebase Functions

Firebase Cloud Functions for AI processing in the PrismNg cognitive augmentation system.

## Setup

### Prerequisites
- Node.js 18+
- Firebase CLI
- OpenAI API Key

### Installation

1. Install dependencies:
```bash
cd functions
npm install
```

2. Configure environment variables:
```bash
firebase functions:config:set openai.key="your-openai-api-key-here"
```

3. Initialize Firebase project:
```bash
firebase init
```

### Development

1. Build the functions:
```bash
npm run build
```

2. Start local emulator:
```bash
npm run serve
```

3. Deploy to production:
```bash
npm run deploy
```

## Available Functions

### Core AI Functions

#### `analyzeThought`
- **Endpoint**: POST `/analyzeThought`
- **Purpose**: Analyzes individual thoughts in context
- **Input**: 
  ```json
  {
    "nodeId": "uuid",
    "content": "thought content",
    "nodeType": "idea|question|insight",
    "context": [{"id": "uuid", "content": "...", "type": "..."}]
  }
  ```
- **Output**: Analysis with confidence, suggestions, and relationship scores

#### `generateAssociations`
- **Endpoint**: POST `/generateAssociations`
- **Purpose**: Finds semantic associations between thoughts
- **Input**: Target node + context nodes
- **Output**: Array of associations with strength scores

#### `generateInsight`
- **Endpoint**: POST `/generateInsight`
- **Purpose**: Generates meta-cognitive insights from thought clusters
- **Input**: Array of thought nodes
- **Output**: Synthesized insight with supporting evidence

#### `generateEmbedding`
- **Endpoint**: POST `/generateEmbedding`
- **Purpose**: Creates vector embeddings for semantic search
- **Input**: Text string
- **Output**: 1536-dimensional embedding vector

#### `analyzeEmotionalState`
- **Endpoint**: POST `/analyzeEmotionalState`
- **Purpose**: Emotional analysis of thought patterns
- **Input**: Array of thought nodes
- **Output**: Valence, arousal, and emotional trajectory

### Batch Processing

#### `batchAnalyze`
- **Endpoint**: POST `/batchAnalyze`
- **Purpose**: Efficiently processes multiple nodes
- **Input**: Array of nodes
- **Output**: Array of analysis results

## Authentication

All functions require Firebase Authentication. Include the user's ID token in the Authorization header:

```
Authorization: Bearer <firebase-id-token>
```

## Rate Limiting & Quotas

Functions implement usage tracking tied to user subscription tiers:
- **Free**: 2 AI calls per day
- **Explorer**: 50 AI calls per day  
- **Advanced**: 500 AI calls per day
- **Professional**: Unlimited

## Error Handling

Functions return structured error responses:
```json
{
  "error": "Error message",
  "details": "Additional details"
}
```

Common HTTP status codes:
- `401`: Authentication required
- `400`: Invalid request parameters
- `429`: Rate limit exceeded
- `500`: Internal server error

## Performance Optimization

- Functions use connection pooling for OpenAI API calls
- Batch processing for multiple nodes
- Caching for frequently accessed embeddings
- Automatic retry logic with exponential backoff

## Monitoring

Monitor function performance in the Firebase Console:
- Execution time and memory usage
- Error rates and success metrics
- Cost analysis and quota usage

## Local Development

For local testing with emulator:
```bash
firebase emulators:start --only functions
```

Functions will be available at:
`http://localhost:5001/prismng-app/us-central1/{functionName}`

## Security

- All functions validate authentication tokens
- Input sanitization and validation
- Rate limiting per user
- Firestore security rules enforcement
- OpenAI API key stored securely in Firebase config