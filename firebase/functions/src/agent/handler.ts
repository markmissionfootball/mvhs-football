import Anthropic from "@anthropic-ai/sdk";
import { assemblePlayerContext } from "./context";
import { buildSystemPrompt } from "./systemPrompt";
import { agentToolDefinitions, executeTool } from "./tools";

interface AgentRequest {
  playerId: string;
  uid: string;
  message: string;
  conversationHistory: Anthropic.MessageParam[];
}

interface AgentResponse {
  response: string;
  toolsUsed: string[];
}

/**
 * Handles a message from a player to the Claude AI agent.
 *
 * Flow:
 * 1. Assemble player context from Firestore
 * 2. Build dynamic system prompt based on player profile + preferences
 * 3. Send to Claude API with tool definitions
 * 4. If Claude calls tools, execute them against Firestore and loop back
 * 5. Return final text response to the Flutter app
 */
export async function handleAgentMessage(
  request: AgentRequest
): Promise<AgentResponse> {
  const { playerId, message, conversationHistory } = request;

  // 1. Assemble player context
  const playerContext = await assemblePlayerContext(playerId);

  // 2. Build system prompt
  const systemPrompt = buildSystemPrompt(playerContext);

  // 3. Initialize Claude client
  const client = new Anthropic();

  // 4. Build messages array
  const messages: Anthropic.MessageParam[] = [
    ...conversationHistory,
    { role: "user", content: message },
  ];

  const toolsUsed: string[] = [];
  let currentMessages = messages;

  // 5. Agent loop — keeps going until Claude returns a final text response
  const maxIterations = 10;
  for (let i = 0; i < maxIterations; i++) {
    const response = await client.messages.create({
      model: "claude-sonnet-4-6-20250514",
      max_tokens: 1024,
      system: systemPrompt,
      tools: agentToolDefinitions,
      messages: currentMessages,
    });

    // Check if Claude wants to use tools
    const toolUseBlocks = response.content.filter(
      (block): block is Anthropic.ToolUseBlock => block.type === "tool_use"
    );

    if (toolUseBlocks.length === 0 || response.stop_reason === "end_turn") {
      // No tool calls — extract text response
      const textBlocks = response.content.filter(
        (block): block is Anthropic.TextBlock => block.type === "text"
      );
      const finalText =
        textBlocks.map((b) => b.text).join("\n") ||
        "I couldn't generate a response. Please try again.";

      return { response: finalText, toolsUsed };
    }

    // Execute each tool call
    const toolResults: Anthropic.ToolResultBlockParam[] = [];

    for (const toolUse of toolUseBlocks) {
      toolsUsed.push(toolUse.name);
      const result = await executeTool(
        toolUse.name,
        toolUse.input as Record<string, unknown>,
        playerId
      );

      toolResults.push({
        type: "tool_result",
        tool_use_id: toolUse.id,
        content: result,
      });
    }

    // Add assistant response + tool results to conversation
    currentMessages = [
      ...currentMessages,
      { role: "assistant", content: response.content },
      { role: "user", content: toolResults },
    ];
  }

  return {
    response:
      "I got a bit lost in my research. Could you ask your question again?",
    toolsUsed,
  };
}
