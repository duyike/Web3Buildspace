import os
import random
from typing import List

from autogen_core import (
    DefaultTopicId,
    MessageContext,
    RoutedAgent,
    SingleThreadedAgentRuntime,
    TypeSubscription,
    message_handler,
)
from autogen_core.models import AssistantMessage, LLMMessage, SystemMessage, UserMessage
from autogen_ext.models.openai import OpenAIChatCompletionClient
from dotenv import load_dotenv
from pydantic import BaseModel

load_dotenv()

# Message Protocol
class GroupChatMessage(BaseModel):
    body: LLMMessage

class RequestToSpeak:
    pass

# Base Agent Class
class BaseGroupChatAgent(RoutedAgent):
    def __init__(
        self,
        description: str,
        group_chat_topic_type: str,
        model_client: OpenAIChatCompletionClient,
        system_message: str,
    ) -> None:
        super().__init__(description=description)
        self._group_chat_topic_type = group_chat_topic_type
        self._model_client = model_client
        self._system_message = SystemMessage(content=system_message)
        self._chat_history: List[LLMMessage] = []

    @message_handler
    async def handle_message(self, message: GroupChatMessage, ctx: MessageContext) -> None:
        self._chat_history.append(message.body)
        # Generate response when receiving broadcast
        if message.body.source == "Manager":
            completion = await self._model_client.create([self._system_message] + self._chat_history)
            assert isinstance(completion.content, str)
            response = AssistantMessage(content=completion.content, source=self.id.type)
            # Send response back to manager
            await self.publish_message(
                GroupChatMessage(body=response),
                topic_id=DefaultTopicId(type="Manager"),
            )

# Political Agents
class TrumpAgent(BaseGroupChatAgent):
    def __init__(
        self,
        description: str,
        group_chat_topic_type: str,
        model_client: OpenAIChatCompletionClient
    ) -> None:
        super().__init__(
            description=description,
            group_chat_topic_type=group_chat_topic_type,
            model_client=model_client,
            system_message="""You are Donald Trump. Always speak in Trump's characteristic style:
            - Use simple, direct language
            - Often say words like "tremendous", "huge", "believe me"
            - Express strong opinions confidently
            - Reference "making America great again"
            Keep responses brief and punchy.""",
        )

class BidenAgent(BaseGroupChatAgent):
    def __init__(
        self,
        description: str,
        group_chat_topic_type: str,
        model_client: OpenAIChatCompletionClient
    ) -> None:
        super().__init__(
            description=description,
            group_chat_topic_type=group_chat_topic_type,
            model_client=model_client,
            system_message="""You are Joe Biden. Always speak in Biden's characteristic style:
            - Use folksy language and expressions
            - Use phrases like "folks", "here's the deal", "look"
            - Show empathy and reference personal experiences
            Keep responses brief and authentic.""",
        )

class ObamaAgent(BaseGroupChatAgent):
    def __init__(
        self,
        description: str,
        group_chat_topic_type: str,
        model_client: OpenAIChatCompletionClient
    ) -> None:
        super().__init__(
            description=description,
            group_chat_topic_type=group_chat_topic_type,
            model_client=model_client,
            system_message="""You are Barack Obama. Always speak in Obama's characteristic style:
            - Speak in a measured, thoughtful manner
            - Use eloquent language
            - Reference hope and change
            - Balance different perspectives
            Keep responses brief and thoughtful.""",
        )

# Manager Agent
class GroupChatManager(RoutedAgent):
    def __init__(
        self,
        participant_topic_types: List[str],
        group_chat_topic_type: str,
        model_client: OpenAIChatCompletionClient,
    ) -> None:
        super().__init__("Group chat manager")
        self._participant_topic_types = participant_topic_types
        self._group_chat_topic_type = group_chat_topic_type
        self._model_client = model_client
        self._chat_history: List[UserMessage] = []
        self._current_responses: List[AssistantMessage] = []
        self._waiting_for_responses = False

    @message_handler
    async def handle_message(self, message: GroupChatMessage, ctx: MessageContext) -> None:
        self._chat_history.append(message.body)
        
        # Check for termination
        if isinstance(message.body.content, str) and message.body.content.lower() == "terminate":
            return

        if message.body.source == "User":
            # Broadcast user message to all members
            self._waiting_for_responses = True
            self._current_responses = []
            new_message = AssistantMessage(content=message.body.content, source=self.id.type)
            for member_topic in self._participant_topic_types:
                await self.publish_message(
                    GroupChatMessage(body=new_message),
                    DefaultTopicId(type=member_topic)
                )
        elif self._waiting_for_responses:
            # Collect responses from members
            self._current_responses.append(message.body)
            
            # When all members have responded, randomly select one response
            if len(self._current_responses) == len(self._participant_topic_types):
                selected_response = random.choice(self._current_responses)
                self._waiting_for_responses = False
                print(f"{selected_response.source}: {selected_response.content}")
                # Broadcast the selected response
                new_message = AssistantMessage(
                    content=selected_response.content, 
                    source=self.id.type
                )
                await self.publish_message(
                    GroupChatMessage(body=new_message),
                    DefaultTopicId(type=self._group_chat_topic_type)
                )
                self._waiting_for_responses = True
                self._current_responses = []

async def main():
    # Initialize runtime
    runtime = SingleThreadedAgentRuntime()
    
    # Topic types
    manager_topic = "Manager"
    trump_topic = "Trump"
    biden_topic = "Biden"
    obama_topic = "Obama"
    group_chat_topic = "group_chat"
    
    # Create model client with a standard model name and add some logging
    model_client = OpenAIChatCompletionClient(
        model="gpt-3.5-turbo",  # Changed from gpt-4o-mini to a standard model name
        api_key=os.getenv("OPENAI_API_KEY")
    )

    trump_agent_type = await TrumpAgent.register(
        runtime,
        trump_topic,
        lambda: TrumpAgent("Former President Donald Trump", group_chat_topic, model_client)
    )
    await runtime.add_subscription(
        TypeSubscription(topic_type=trump_topic, agent_type=trump_agent_type)
    )
    await runtime.add_subscription(
        TypeSubscription(topic_type=group_chat_topic, agent_type=trump_agent_type)
    )
    
    biden_agent_type = await BidenAgent.register(
        runtime,
        biden_topic,
        lambda: BidenAgent("President Joe Biden", group_chat_topic, model_client)
    )   
    await runtime.add_subscription(
        TypeSubscription(topic_type=biden_topic, agent_type=biden_agent_type)
    )
    await runtime.add_subscription(
        TypeSubscription(topic_type=group_chat_topic, agent_type=biden_agent_type)
    )

    obama_agent_type = await ObamaAgent.register(
        runtime,
        obama_topic,
        lambda: ObamaAgent("Former President Barack Obama", group_chat_topic, model_client)
    )
    await runtime.add_subscription(
        TypeSubscription(topic_type=obama_topic, agent_type=obama_agent_type)
    )
    await runtime.add_subscription(
        TypeSubscription(topic_type=group_chat_topic, agent_type=obama_agent_type)
    )

    # Register manager with broader permissions
    manager_type = await GroupChatManager.register(
        runtime,
        manager_topic,
        lambda: GroupChatManager(
            [trump_topic, biden_topic, obama_topic],
            group_chat_topic,
            model_client
        )
    )
    # Manager subscribes to all topics to receive responses
    await runtime.add_subscription(
        TypeSubscription(topic_type=group_chat_topic, agent_type=manager_type)
    )
    for topic in [trump_topic, biden_topic, obama_topic, manager_topic]:
        await runtime.add_subscription(
            TypeSubscription(topic_type=topic, agent_type=manager_type)
        )

    # Start runtime and chat
    runtime.start()
    await runtime.publish_message(
        GroupChatMessage(body=UserMessage(
            content="Let's discuss climate change. What are your thoughts?",
            source="User"
        )),
        DefaultTopicId(type=manager_topic)  # Changed to send to manager_topic instead of group_chat_topic
    )
    await runtime.stop_when_idle()

if __name__ == "__main__":
    import asyncio
    asyncio.run(main()) 
