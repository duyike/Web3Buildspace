const {
  message,
  spawn,
  monitor,
  unmonitor,
  dryrun,
  createDataItemSigner,
} = require("@permaweb/aoconnect");
const { readFileSync } = require("fs");
const { Ollama } = require("ollama");

const PROCESS_ID = "qQ3AmKj0PxoB1jOJLWfR01iu_GjArTmG4orrpXfMheU";
const wallet = JSON.parse(readFileSync("/Users/yikedu/.aos.json").toString());
const ollama = new Ollama();
const handling = [];

async function main() {
  async function procsess() {
    console.log("Running FetchPending: ", new Date());
    const result = await dryrun({
      process: PROCESS_ID,
      data: "",
      tags: [{ name: "Action", value: "FetchPending" }],
    });
    const requests = JSON.parse(result.Messages[0].Data);
    if (requests.length > 0) {
      await handleRequest(requests);
    } else {
      console.log("No messages found");
    }
  }
  // every 5 seconds
  setInterval(procsess, 5000);
}

async function handleRequest(requests) {
  for (let request of requests) {
    if (handling.includes(request.msgId)) {
      continue;
    }
    handling.push(request.msgId);
    // send response
    console.log("Handle request: ", request);
    // call ollama
    const ollamaResponse = await ollama.chat({
      model: "llama2",
      messages: [{ role: "user", content: request.content }],
    });
    // send response
    const response = {
      content: ollamaResponse.message.content,
      msgId: request.msgId,
    };
    await message({
      process: PROCESS_ID,
      tags: [{ name: "Action", value: "Response" }],
      signer: createDataItemSigner(wallet),
      data: JSON.stringify(response),
    })
      .then(console.log)
      .catch(console.error);
  }
}

main();
