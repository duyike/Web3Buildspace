local json = require "json"

Pending = Pending or Queue.new()
Messages = Messages or {}
Responses = Responses or {}

-- Ainvoke: call the chain on an input async 
--  1. ignore keeping context for now
Handlers.add(
    "Ainvoke",
    Handlers.utils.hasMatchingTag("Action", "Ainvoke"),
    function (msg)
        local msgId = msg.Id
        local message = json.decode(msg.Data)
        Pending.pushright(msgId)
        Handlers.utils.reply("Success")(msg)
    end
)

-- Response: submit a response to the chain
-- 1. ignroe multiple responses for one request for now
-- Handlers.add(
--     "Response",
--     Handlers.utils.hasMatchingTag("Action", "Response"),
--     function (msg)
--         local msgId = msg.Id
--         local response = json.decode(msg.Data)
--         Responses[msgId] = response
--         Handlers.utils.reply("Success")(msg)
--     end
-- )
