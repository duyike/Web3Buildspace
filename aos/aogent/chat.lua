local json = require "json"

Pending = Pending or {}
Messages = Messages or {}
Responses = Responses or {}

-- AsycnRequest: send a request to the chain
--  1. ignore keeping context for now
Handlers.add(
    "AsycnRequest",
    Handlers.utils.hasMatchingTag("Action", "AsycnRequest"),
    function (msg)
        local msgId = msg.Id
        local message = json.decode(msg.Data)
        message.msgId = msgId
        Pending[msgId] = true
        Messages[msgId] = message
        Handlers.utils.reply("Success")(msg)
    end
)

-- Response: submit a response to the chain
-- 1. ignroe multiple responses for one request for now
Handlers.add(
    "Response",
    Handlers.utils.hasMatchingTag("Action", "Response"),
    function (msg)
        local response = json.decode(msg.Data)
        local msgId = response.msgId
        if not Pending[msgId] then
            Handlers.utils.reply("Invalid request")(msg)
            return
        end
        Pending[msgId] = nil
        Responses[msgId] = response
        Handlers.utils.reply("Success")(msg)
        ao.send({Target = Messages[msgId].From, Data = json.encode(response)})
    end
)

-- FetchPending: fetch pending requests
Handlers.add(
    "FetchPending",
    Handlers.utils.hasMatchingTag("Action", "FetchPending"),
    function (msg)
        local pending = {}
        for msgId, _ in pairs(Pending) do
            table.insert(pending, Messages[msgId])
        end
        Handlers.utils.reply(json.encode(pending))(msg)
    end
)

-- GetResponse: get response for a request
Handlers.add(
    "GetResponse",
    Handlers.utils.hasMatchingTag("Action", "GetResponse"),
    function (msg)
        local request = json.decode(msg.Data)
        local msgId = request.msgId
        if not Responses[msgId] then
            Handlers.utils.reply("No response")(msg)
            return
        end
        Handlers.utils.reply(json.encode(Responses[msgId]))(msg)
    end
)
