# Use a pipeline as a high-level helper
from transformers import pipeline, AutoTokenizer
from openai import OpenAI

# Initialize the pipeline and tokenizer
model_name = "covalenthq/cryptoNER"
tokenizer = AutoTokenizer.from_pretrained(model_name)
pipe = pipeline(
    "token-classification", 
    model=model_name,
    tokenizer=tokenizer,
    aggregation_strategy="none"  # Don't aggregate so we can see individual tokens
)

client = OpenAI(api_key="your_api_key")

# Test text with various potential entities
# https://x.com/Remy_Ryy/status/1887272002253099130
# text = """
# The lore behind 
# @fartemojisol
#  is deep.

# Fartcoin dev creates #FARTCOIN 

# It runs to $40-$50 mill off the back of $GOAT run.

# Creates $💨 - leaves it the community to push the narrative.

# *Checks dev notes on PumpFun*

# No buy bots, no market makers, just community held tokens 💨
# """

text = """
I checked out 
@agentcookiefun
's terminal at >>http://terminal.cookie.fun<<

It's conceptually similar to 
@AndyAyrey
's InfiniteBackrooms which spawned $GOAT & sparked the Ai x Crypto sector currently valued at almost $10 billion

But this is different — Agent $COOKIE & "minions" are trained for crypto and DeFAI
"""

pre_process_prompt = """You are a crypto content analyzer. Your task is to determine if the input content is related to cryptocurrency and extract any mentioned project or token names.
Please analyze the input content and return a JSON response with:
- "low_score": boolean indicating if the content is low quality (no factual information or sentiment, e.g. only GM @project's name) or spam.
- "crypto_related": boolean indicating if the content is about cryptocurrency.
- "projects": list of strings containing any discussed project/token names that are primarily discussed or focused on within the text. Only include the projects that are the main subject of the conversation, and exclude any cryptocurrencies that are merely mentioned in passing or used as supplementary information. The goal is to identify the key crypto projects that the tweet is centered around. The result should be a well-known or official name of the project/token instead of any aliases.
- "alias": list of lists of strings containing all aliases: identify and link all names, abbreviations, or aliases that refer to the same project or token. For example, if 'Bitcoin', 'BTC', and '₿' are used interchangeably, group them together as referring to the same cryptocurrency. The goal is to identify the key crypto projects that the tweet is centered around and consolidate all references to the same project/token.
- "sentiment": string indicating the sentiment of the content, e.g. "positive", "negative", "neutral".
Only include projects/tokens that are explicitly mentioned. If no specific projects are mentioned, return an empty list.
Keep your response strictly in the requested JSON format without any additional text."""

def use_ner(text):
    print("\nUse NER:")
    print("-" * 50)
    results = pipe(text)
    for i, item in enumerate(results):
        if item['entity'].startswith("B-"):
            type = item['entity'].split("-")[1]
            start = item['start']
            end = item['end']
            while text[end] not in " ,.!?\n" and end < len(text):
                end += 1
            symbol = text[start:end]
            print(f"{type}: {symbol}")

def use_llm(text):
    print("\nUse LLM:")
    print("-" * 50)
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": pre_process_prompt},
            {"role": "user", "content": text},
        ],
    )
    print(response.choices[0].message.content)

print(text)
use_ner(text)
use_llm(text)
