Send({ Target = ao.id, Action = "AsycnRequest", Data = "{\"content\": \"What is the purpose of model regularization?\"}"})

Send({ Target = ao.id, Action = "FetchPending"})

Send({ Target = ao.id, Action = "Response", Data = "{\"content\": \"Success\", \"msgId\": \"O5K8bPD7_TcsbiNHAtSrOIFlZA_CFZ2yXebkJYnaJHo\"}"})

Send({ Target = ao.id, Action = "GetResponse", Data = "{\"msgId\": \"O5K8bPD7_TcsbiNHAtSrOIFlZA_CFZ2yXebkJYnaJHo\"}"})

-- Inbox[#Inbox].Data
