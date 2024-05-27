local http_request = require "http.request"
local json = require "json"

Handlers.add(
    "Request",
    Handlers.utils.hasMatchingTag("Action", "Request"),
    function (msg)
        assert(type(msg.Data) == "string", "data must be a string")
        local data = json.decode(msg.Data)
        assert(type(data.uri) == "string", "uri must be a string")

        local headers, stream = assert(http_request.new_from_uri(data.uri):go())
        local body = assert(stream:get_body_as_string())
        if headers:get ":status" ~= "200" then
            error(body)
        end
        Handlers.utils.reply(body)(msg)
    end
)
