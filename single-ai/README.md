# Single AI Agent

A streaming AI agent service built with OpenAI and FastAPI.

## Setup

1. Install dependencies:

   ```bash
   poetry install
   ```

2. Create a `.env` file in the project root with your OpenAI API key and database configuration:

   ```bash
   OPENAI_API_KEY=your_api_key_here
   OPENAI_BASE_URL=your_base_url
   DB_NAME=postgres
   DB_USER=your_db_user
   DB_PASSWORD=your_db_password
   DB_HOST=your_db_host
   DB_PORT=your_db_port
   DB_SCHEMA=single_ai
   ```

3. Apply database migrations (only when there is a schema change):

   ```bash
   # Set Django settings module

   export DJANGO_SETTINGS_MODULE=single_ai.settings

   # Generate migrations
   poetry run python -m django makemigrations single_ai

   # Apply migrations
   source .env && poetry run python -m django migrate single_ai
   ```

4. Lint the project:

   ```bash
   poetry run ruff check
   ```

## Database Schema

The project uses Django ORM with PostgreSQL. The following tables are created:

### Agents Table

- `handle` (unique): Twitter handle of the agent
- `status`: Current status (pending/completed/failed)
- `prompt`: Generated character prompt
- `created_at`: Creation timestamp
- `completed_at`: Completion timestamp

### Chats Table

- `handle`: Twitter handle of the agent
- `message`: User's message
- `response`: Agent's response
- `created_at`: Message timestamp

## Running the Service

Start the server:

```bash
poetry run uvicorn single_ai.server:app --reload
```

The service will be available at `http://localhost:8000`.

## Docker Deployment

1. Build the Docker image:

   ```bash
   docker build -t single-ai .
   ```

2. Create a `.env` file with your configuration (see `.env.example`).

3. Run the container:

   ```bash
   docker run -d \
     --name single-ai \
     -p 8000:8000 \
     --env-file .env \
     single-ai
   ```

The service will be available at `http://localhost:8000`.

## API Usage

### Reason Endpoint

Send a POST request to `/reason` with a JSON body:

```bash
curl -X POST http://localhost:8000/reason \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Tell me a joke"}'
```

The response will be streamed as plain text.
