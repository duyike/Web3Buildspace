# Single AI

## Goals

- Based on user's 100 recent tweets, generate an AI Agent with similar tone and style, and chat with the user
- Use Reasoning Model to generate responses
- Conversational tone

## Implementation

- Get recent 100 tweets from TweetScout API
- Generate character prompt based on the tweets (conversational tone, few-shot)
- Generate AI Agent based on the prompt (Reasoning Model, Streaming)
- Serve the AI Agent over HTTP

## APIs

- generate agent:
  - input: twitter handle
  - output: success or failure
  - do:
    - get 100 recent tweets by hanlde (tweetscout api)
    - generate character prompt (using the tweets, openai o1 or o3mini)
    - store handle + prompt (supabase pg)
  - note:
    - maybe take long time, should make api async
- chat:
  - input: handle, user input
  - output: agent response (streaming)
  - do:
    - get agent from supabase (based on handle)
    - get chat history from supabase (based on handle)
    - generate response (openai)
    - stream the response

## User Flow

### 1. Agent Creation

1. User enters a Twitter handle they want to create an agent for
2. System initiates agent generation:
   - Shows loading state
   - Polls status endpoint every 2 seconds
   - Updates UI with progress (fetching tweets → analyzing → generating)
3. Once complete:
   - Shows success message
   - Transitions to chat interface
4. If error occurs:
   - Shows error message with details
   - Provides option to retry

### 2. Chat Experience

1. User sees:
   - Chat input field
   - Message history (if any)
   - Clear indication of which Twitter user's agent they're talking to
2. When user sends message:
   - Message appears in chat immediately
   - Loading indicator shows while waiting for response
   - Agent's response streams in real-time
   - Each message pair is saved for context

### 3. Error Handling

1. Network Issues:
   - Retry options for failed requests
   - Clear error messages
   - Maintain chat state
2. Rate Limits:
   - Show remaining API quotas
   - Graceful degradation when limits hit
3. Invalid Handles:
   - Immediate validation
   - Clear error message
   - Suggestion to check spelling

### 4. Performance Considerations

1. Agent Generation:
   - Can take 10-30 seconds
   - Show progress updates
   - Allow background generation
2. Chat Response:
   - Streaming reduces perceived latency
   - Maintain context with last 5 messages
   - Smooth scrolling for new messages

### 5. UI/UX Guidelines

1. Loading States:
   - Skeleton screens for initial load
   - Typing indicators for streaming
   - Progress bars for generation
2. Error States:
   - Clear error messages
   - Action buttons for recovery
   - Contextual help
3. Success States:
   - Visual confirmation
   - Clear next steps
   - Smooth transitions
