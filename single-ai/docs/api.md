# Single AI API Documentation

## Base URL

```txt
http://localhost:8000
```

## Endpoints

### 1. Generate Agent

Creates an AI agent based on a Twitter user's recent tweets.

```http
POST /generate-agent?handle={twitter_handle}
```

#### Parameters

| Parameter | Type   | Required | Description                         |
| --------- | ------ | -------- | ----------------------------------- |
| handle    | string | Yes      | Twitter handle without the @ symbol |

#### Response

```json
{
  "status": "processing_started",
  "handle": "twitter_handle"
}
```

Or if the agent is already being generated:
```json
{
  "status": "already_processing",
  "handle": "twitter_handle"
}
```

Or if the agent already exists:
```json
{
  "status": "already_exists",
  "handle": "twitter_handle"
}
```

#### Notes

- This is an asynchronous operation
- The agent generation process includes:
  1. Fetching recent tweets
  2. Analyzing writing style and tone
  3. Creating a character prompt
  4. Storing the agent in the database

### 1.1 Check Agent Status

Check if an agent has been generated for a Twitter handle.

```http
GET /agent-status/{handle}
```

#### Parameters

| Parameter | Type   | Required | Description                         |
| --------- | ------ | -------- | ----------------------------------- |
| handle    | string | Yes      | Twitter handle without the @ symbol |

#### Response

When agent is not found:
```json
{
  "status": "not_found",
  "handle": "twitter_handle"
}
```

When agent is pending:
```json
{
  "status": "pending",
  "handle": "twitter_handle",
  "created_at": "2025-02-15T08:33:29Z"
}
```

When agent generation failed:
```json
{
  "status": "failed",
  "handle": "twitter_handle",
  "created_at": "2025-02-15T08:33:29Z"
}
```

When agent generation is complete:
```json
{
  "status": "completed",
  "handle": "twitter_handle",
  "created_at": "2025-02-15T08:33:29Z",
  "completed_at": "2025-02-15T08:33:45Z"
}
```

#### Example Usage

```javascript
// Check agent generation status
async function checkAgentStatus(handle) {
  const response = await fetch(`/agent-status/${handle}`, {
    method: "GET"
  });
  const status = await response.json();
  
  if (status.status === "completed") {
    console.log(`Agent was created at ${status.created_at}`);
    return true;
  }
  return false;
}

// Poll status until complete
async function waitForAgentGeneration(handle) {
  while (true) {
    const isComplete = await checkAgentStatus(handle);
    if (isComplete) break;
    await new Promise(resolve => setTimeout(resolve, 2000)); // Wait 2 seconds
  }
  console.log("Agent generation complete!");
}

### 2. Chat with Agent

Send a message to chat with the generated AI agent.

```http
POST /chat
```

#### Request Body

```json
{
  "handle": "twitter_handle",
  "message": "Your message here"
}
```

#### Parameters

| Parameter | Type   | Required | Description                              |
| --------- | ------ | -------- | ---------------------------------------- |
| handle    | string | Yes      | Twitter handle of the agent to chat with |
| message   | string | Yes      | The message to send to the agent         |

#### Response

The response is a stream of text chunks that form the agent's reply.

Content-Type: `text/plain`

#### Example Usage

```javascript
// Generate Agent
async function generateAgent(handle) {
  const response = await fetch(`/generate-agent?handle=${handle}`, {
    method: "POST",
  });
  return response.json();
}

// Chat with Agent
async function chatWithAgent(handle, message) {
  const response = await fetch("/chat", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      handle,
      message,
    }),
  });

  // Handle streaming response
  const reader = response.body.getReader();
  const decoder = new TextDecoder();

  while (true) {
    const { value, done } = await reader.read();
    if (done) break;

    const text = decoder.decode(value);
    // Process each chunk of the response
    console.log(text);
  }
}
```

## Error Handling

### Common Error Responses

1. Agent Not Found

```text
Agent not found. Please generate the agent first.
```

2. API Error

```text
Error: {error_message}
```

## Rate Limiting

Currently, there are no rate limits implemented. However, be mindful of:

- OpenAI API rate limits
- TweetScout API rate limits

## Notes

1. The chat endpoint maintains conversation history and will use the last 5 messages for context
2. Agent generation may take some time as it needs to fetch and analyze tweets
3. All timestamps are in UTC ISO-8601 format
