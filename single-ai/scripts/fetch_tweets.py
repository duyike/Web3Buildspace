import os
from datetime import datetime

import requests
from dotenv import load_dotenv


def fetch_user_tweets(api_key, link, count=500):
    """Fetch tweets for a specific user using TweetScout API."""
    url = "https://api.tweetscout.io/v2/user-tweets"
    headers = {
        "ApiKey": api_key,
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    
    payload = {
        "link": link,
    }
    
    # 20 tweets per request
    request_count = count // 20
    cursor = None
    tweets = []
    for i in range(request_count):
        if cursor is not None:
            payload["cursor"] = cursor
        print(f"Fetching tweets... {i+1}/{request_count}")
        response = requests.post(url, headers=headers, json=payload)
        if response.status_code != 200:
            msg = f"API request failed: {response.status_code}"
            raise Exception(msg)
        cursor = response.json()['next_cursor']
        tweets.extend(response.json()['tweets'])
        
    return tweets

def format_tweets(tweets_data):
    """Format tweets according to the character analysis template."""
    formatted_tweets = []
    
    for tweet in tweets_data:
        # Convert Twitter's timestamp to the required format
        created_at = datetime.strptime(
            tweet['created_at'],
            "%a %b %d %H:%M:%S %z %Y"
        )
        formatted_date = created_at.strftime("%Y-%m-%dT%H:%M:%SZ")
        
        # Format the tweet text
        text = tweet['full_text'].replace('\n', ' ').strip()
        formatted_tweet = f"- {text} ({formatted_date})"
        formatted_tweets.append(formatted_tweet)
    
    return formatted_tweets

def save_to_template(tweets_text, template_path, output_path):
    """Save formatted tweets to the character analysis template."""
    with open(template_path, 'r') as f:
        template = f.read()
    
    # Replace the placeholder with actual tweets
    output_text = template.replace(
        "[The tweets will be inserted here in the format above]",
        tweets_text
    )
    
    with open(output_path, 'w+') as f:
        f.write(output_text)

def main():
    load_dotenv()
    
    api_key = os.getenv("TWEETSCOUT_API_KEY")
    if not api_key:
        raise ValueError("TWEETSCOUT_API_KEY not found in environment variables")
    
    link = input("Enter Twitter profile URL: ")
    tweets = fetch_user_tweets(api_key, link)
    formatted_tweets = format_tweets(tweets)
    tweets_text = "\n".join(formatted_tweets)
    
    template_path = "prompts/character_analysis_template.txt"
    output_path = "prompts/character_analysis.txt"
    save_to_template(tweets_text, template_path, output_path)
    print(f"Character analysis saved to {output_path}")

if __name__ == "__main__":
    main()
