import traceback
from datetime import datetime
from typing import AsyncGenerator

import openai
import requests
from django.utils import timezone
from pydantic import BaseModel

# Initialize Django first
from .django_setup import *  # noqa
from .models import Agent, Chat, SystemPrompt


class AgentPrompt(BaseModel):
    prompt: str
    
class ChatMessage(BaseModel):
    handle: str
    message: str
    
class TweetScoutAPI:
    def __init__(self, api_key: str):
        self.api_key = api_key
        
    async def fetch_user_tweets(
        self, handle: str, count: int = 100
    ) -> tuple[list[dict], str, str]:
        """Fetch tweets for a specific user using TweetScout API."""
        url = "https://api.tweetscout.io/v2/user-tweets"
        headers = {
            "ApiKey": self.api_key,
            "Content-Type": "application/json",
            "Accept": "application/json",
        }
        
        payload = {
            "link": f"https://twitter.com/{handle}",
        }
        
        request_count = count // 20
        cursor = None
        tweets = []
        screen_name, name = "", ""
        for i in range(request_count):
            print(f"Fetching tweets for {handle}... {i+1}/{request_count}")
            if cursor is not None:
                payload["cursor"] = cursor
            response = requests.post(url, headers=headers, json=payload)
            if response.status_code != 200:
                msg = f"API request failed: {response.status_code}"
                raise Exception(msg)
            data = response.json()
            cursor = data['next_cursor']
            if i == 0:
                screen_name = data['tweets'][0]['user']['screen_name']
                name = data['tweets'][0]['user']['name']
            tweets.extend(data['tweets'])
            
        return tweets[:count], screen_name, name
        
    def format_tweets(self, tweets_data: list[dict]) -> list[str]:
        """Format tweets for character analysis."""
        formatted_tweets = []
        
        for tweet in tweets_data:
            created_at = datetime.strptime(
                tweet['created_at'], 
                "%a %b %d %H:%M:%S %z %Y"
            )
            formatted_date = created_at.strftime("%Y-%m-%dT%H:%M:%SZ")
            text = tweet['full_text'].replace('\n', ' ').strip()
            formatted_tweet = f"- {text} ({formatted_date})"
            formatted_tweets.append(formatted_tweet)
        
        return formatted_tweets

class TwitterAgent:
    def __init__(
        self,
        openai_key: str,
        openai_base_url: str | None = None,
        tweetscout_key: str | None = None,
    ):
        self.openai_client = openai.AsyncOpenAI(
            api_key=openai_key, 
            base_url=openai_base_url
        )
        self.tweetscout = TweetScoutAPI(tweetscout_key)
        
    def _get_system_prompt(self, name: str = "generate_agent") -> str:
        try:
            prompt = SystemPrompt.objects.get(name=name)
            return prompt.content
        except SystemPrompt.DoesNotExist:
            # Fallback to default prompt if not found in database
            return (
                "You are a prompt engineer. Based on the given tweets, "
                "create a character prompt that captures the user's tone, "
                "style, and personality."
            )

    async def generate_agent(self, handle: str) -> bool:
        """Generate an AI agent based on user's tweets."""
        try:
            # Fetch and format tweets
            tweets, screen_name, name = await self.tweetscout.fetch_user_tweets(handle)
            formatted_tweets = self.tweetscout.format_tweets(tweets)
            
            # Generate character prompt
            system_prompt = self._get_system_prompt()
            tweets_text = "\n".join(formatted_tweets)
            user_prompt = (
                f"Twitter:{name}(@{screen_name})\nTweets:\n{tweets_text}\n\n"
            )
            prompt_response = await self.openai_client.chat.completions.create(
                model="o1",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ]
            )
            
            # Extract the generated prompt
            character_prompt = prompt_response.choices[0].message.content
            
            # Update agent record with prompt and mark as completed
            agent, created = Agent.objects.get_or_create(handle=handle)
            agent.prompt = character_prompt
            agent.status = "completed"
            agent.completed_at = timezone.now()
            agent.save()
            
            return True
            
        except Exception as e:
            # Log full error information
            error_info = {
                'error_type': type(e).__name__,
                'error_message': str(e),
                'traceback': traceback.format_exc()
            }
            error_msg = (
                f"Error generating agent:\n"
                f"{error_info['error_type']}: {error_info['error_message']}\n"
                f"{error_info['traceback']}"
            )
            print(error_msg)
            return False
    
    async def chat(self, handle: str, user_input: str) -> AsyncGenerator[str, None]:
        """Chat with the AI agent."""
        try:
            # Get agent prompt
            agent = Agent.objects.get(handle=handle)
            if not agent:
                yield "Agent not found. Please generate the agent first."
                return
                
            character_prompt = agent.prompt
            
            # Get chat history
            history = Chat.objects.filter(handle=handle).order_by('created_at')[:5]
            
            # Format last 5 messages
            chat_pairs = [
                f"User: {msg.message}\nAssistant: {msg.response}"
                for msg in history
            ]
            chat_context = "\n".join(chat_pairs)
            
            # Generate response
            context_msg = (
                f"Previous conversation:\n{chat_context}"
                if chat_context else "No previous conversation."
            )
            response = await self.openai_client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": character_prompt},
                    {"role": "system", "content": context_msg},
                    {"role": "user", "content": user_input}
                ],
                stream=True
            )
            
            full_response = ""
            async for chunk in response:
                if len(chunk.choices) > 0 and chunk.choices[0].delta and \
                    chunk.choices[0].delta.content:
                    content = chunk.choices[0].delta.content
                    full_response += content
                    yield content
            
            # Save chat history
            Chat.objects.create(
                handle=handle,
                message=user_input,
                response=full_response,
                created_at=timezone.now()
            )
            
        except Exception as e:
            # Log full error information
            error_info = {
                'error_type': type(e).__name__,
                'error_message': str(e),
                'traceback': traceback.format_exc()
            }
            error_msg = (
                f"Error in chat:\n"
                f"{error_info['error_type']}: {error_info['error_message']}\n"
                f"{error_info['traceback']}"
            )
            print(error_msg)
            yield f"Error: {str(e)}"
