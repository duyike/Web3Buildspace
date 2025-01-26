# Design

- According to [AutoGen Group Chat Documentation](https://microsoft.github.io/autogen/stable/user-guide/core-user-guide/design-patterns/group-chat.html#running-the-group-chat)
- Init the python project using poetry, ruff (as lint)
- Create a group chat contains following agents:
  1. manager: receive user message, broacast to members with chat history, receive members' reply, determine one of them to reply user randomly, and then next round
  2. Trump(member): reply broadcast message, speak like Trump
  3. Biden(member): reply broadcast message, speak like Biden
  4. Obama(member): reply broadcast message, speak like Obama
