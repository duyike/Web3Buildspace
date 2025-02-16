#!/usr/bin/env python3
import argparse
import asyncio
import os
import sys
from pathlib import Path

import openai
from dotenv import load_dotenv

# Add the project root to Python path
project_root = Path(__file__).parent.parent
sys.path.append(str(project_root))

from single_ai.agent import TweetScoutAPI  # noqa: E402


async def main():
    parser = argparse.ArgumentParser(description="Generate AI agent prompt from Twitter handle")
    parser.add_argument("handle", help="Twitter handle (without @)")
    args = parser.parse_args()

    # Load environment variables
    load_dotenv()
    
    # Initialize clients
    openai_client = openai.AsyncOpenAI(
        api_key=os.getenv("OPENAI_API_KEY"),
        base_url=os.getenv("OPENAI_BASE_URL")
    )
    tweetscout = TweetScoutAPI(os.getenv("TWEETSCOUT_API_KEY"))
    
    try:
        # Fetch and format tweets
        tweets, screen_name, name = await tweetscout.fetch_user_tweets(args.handle)
        formatted_tweets = tweetscout.format_tweets(tweets)
        
        # Read system prompt template
        with open(project_root / "prompts" / "character_analysis.txt") as f:
            system_prompt = f.read()
        
        # Generate prompt
        tweets_text = "\n".join(formatted_tweets)
        user_prompt = f"Twitter:{name}(@{screen_name})\nTweets:\n{tweets_text}\n\n"
        
        print("Generating prompt...\n")
        response = await openai_client.chat.completions.create(
            model="o1",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
        )
        
        print("Generated Prompt:\n")
        print(response.choices[0].message.content)
        
    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
