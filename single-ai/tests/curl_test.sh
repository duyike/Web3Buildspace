#!/bin/bash

# Configuration
BASE_URL="http://localhost:8000"
TWITTER_HANDLE="elonmusk"  # Example handle

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Single AI API Tests${NC}\n"

# Test 1: Generate Agent
echo -e "${GREEN}Test 1: Generate Agent${NC}"
echo "POST /generate-agent?handle=$TWITTER_HANDLE"
curl -X POST "$BASE_URL/generate-agent?handle=$TWITTER_HANDLE" \
    -H "Content-Type: application/json"
echo -e "\n"

# Test 2: Check Generation Status (immediately after)
echo -e "${GREEN}Test 2: Check Generation Status (initial)${NC}"
echo "GET /agent-status/$TWITTER_HANDLE"
curl -X GET "$BASE_URL/agent-status/$TWITTER_HANDLE" \
    -H "Content-Type: application/json"
echo -e "\n"

# Test 3: Wait and Check Status Again
echo -e "${GREEN}Test 3: Check Generation Status (after 5 seconds)${NC}"
sleep 5
echo "GET /agent-status/$TWITTER_HANDLE"
curl -X GET "$BASE_URL/agent-status/$TWITTER_HANDLE" \
    -H "Content-Type: application/json"
echo -e "\n"

# Test 4: Try Chat Before Ready
echo -e "${GREEN}Test 4: Try Chat Before Ready${NC}"
echo "POST /chat"
curl -X POST "$BASE_URL/chat" \
    -H "Content-Type: application/json" \
    -d "{\"handle\":\"$TWITTER_HANDLE\",\"message\":\"Hello!\"}"
echo -e "\n"

# Test 5: Wait for Generation and Chat
echo -e "${GREEN}Test 5: Wait 30 seconds and Try Chat${NC}"
echo "Waiting 30 seconds for agent generation..."
sleep 30

echo "POST /chat"
curl -X POST "$BASE_URL/chat" \
    -H "Content-Type: application/json" \
    -d "{\"handle\":\"$TWITTER_HANDLE\",\"message\":\"What's your opinion on AI?\"}"
echo -e "\n"

# Test 6: Try Generate Existing Agent
echo -e "${GREEN}Test 6: Try Generate Existing Agent${NC}"
echo "POST /generate-agent?handle=$TWITTER_HANDLE"
curl -X POST "$BASE_URL/generate-agent?handle=$TWITTER_HANDLE" \
    -H "Content-Type: application/json"
echo -e "\n"

# Test 7: Chat with Context
echo -e "${GREEN}Test 7: Chat with Previous Context${NC}"
echo "POST /chat"
curl -X POST "$BASE_URL/chat" \
    -H "Content-Type: application/json" \
    -d "{\"handle\":\"$TWITTER_HANDLE\",\"message\":\"Can you elaborate on that?\"}"
echo -e "\n"

echo -e "${BLUE}Testing list agents endpoint${NC}"
curl -s http://localhost:8000/agents | jq .
echo -e "\n"

echo -e "${BLUE}Tests Complete${NC}"

curl -H "ApiKey: $TWEETSCOUT_API_KEY" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{"link": "https://twitter.com/elonmusk"}' \
    https://api.tweetscout.io/v2/user-tweets
