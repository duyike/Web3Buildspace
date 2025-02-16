import os

from django.utils import timezone
from dotenv import load_dotenv
from fastapi import BackgroundTasks, FastAPI
from fastapi.responses import StreamingResponse

from .agent import ChatMessage, TwitterAgent
from .django_setup import *  # noqa
from .models import Agent

load_dotenv()

app = FastAPI(title="Single AI Agent")
twitter_agent = TwitterAgent(
    openai_key=os.getenv("OPENAI_API_KEY"),
    openai_base_url=os.getenv("OPENAI_BASE_URL"),
    tweetscout_key=os.getenv("TWEETSCOUT_API_KEY"),
)

async def process_agent_creation(handle: str):
    """Async background task for agent generation"""
    try:
        success = await twitter_agent.generate_agent(handle)
        if not success:
            # Update status to failed
            Agent.objects.filter(handle=handle).update(
                status="failed"
            )
    except Exception as e:
        print(f"Error generating agent: {e}")
        # Update status to failed
        Agent.objects.filter(handle=handle).update(
            status="failed"
        )

@app.post("/generate-agent")
async def generate_agent(handle: str, background_tasks: BackgroundTasks):
    """
    Generate an AI agent for a Twitter handle.
    This is an async endpoint that will process the request in the background.
    """
    # Check if agent already exists
    agent = Agent.objects.filter(handle=handle).first()
    if agent and agent.status != "failed":
        return {"status": agent.status, "handle": handle}

    try:
        # Create or update agent record
        Agent.objects.update_or_create(
            handle=handle,  # lookup field
            defaults={
                'status': 'pending',
                'created_at': timezone.now()
            }
        )
        background_tasks.add_task(process_agent_creation, handle)
        return {"status": "processing", "handle": handle}
    except Exception as e:
        print(f"Error initiating agent generation: {e}")
        return {"status": "error", "message": str(e)}

@app.get("/agent-status/{handle}")
async def check_agent_status(handle: str):
    """
    Check if an agent has been generated for the given handle.
    """
    agent = Agent.objects.filter(handle=handle).first()
    
    if not agent:
        return {
            "status": "not_found",
            "handle": handle
        }
    
    return {
        "status": agent.status,
        "handle": handle,
        "created_at": agent.created_at.isoformat() if agent.created_at else None,
        "completed_at": agent.completed_at.isoformat() if agent.completed_at else None
    }

@app.post("/chat")
async def chat_with_agent(message: ChatMessage):
    """
    Chat with an AI agent. Returns a streaming response.
    """
    # Check if agent exists and is ready
    agent = Agent.objects.filter(handle=message.handle).first()
    
    if not agent:
        return StreamingResponse(
            iter(["Agent not found. Please generate the agent first."]),
            media_type="text/plain"
        )
    
    if agent.status != "completed":
        status_msg = (
            "Agent is still being generated. Please wait."
            if agent.status == "pending"
            else "Agent generation failed. Please try regenerating."
        )
        return StreamingResponse(
            iter([status_msg]),
            media_type="text/plain"
        )
    
    async def generate():
        async for token in twitter_agent.chat(message.handle, message.message):
            yield token

    return StreamingResponse(generate(), media_type="text/plain")
