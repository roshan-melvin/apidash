/**
 * APIDash CLI — AI / LLM Executor
 * Sends chat-completion requests to any OpenAI-compatible endpoint.
 * Supports: OpenAI, Gemini (via OpenAI-compat), Ollama, Mistral, Groq, etc.
 */
export interface AIMessage {
    role: "system" | "user" | "assistant";
    content: string;
}
export interface AIRequestContext {
    url: string;
    apiKey?: string;
    model: string;
    messages: AIMessage[];
    systemPrompt?: string;
    temperature?: number;
    maxTokens?: number;
    stream?: boolean;
    headers?: Record<string, string>;
    timeoutMs?: number;
}
export interface AIResponseData {
    url: string;
    model: string;
    status: number;
    statusText: string;
    content: string;
    inputTokens?: number;
    outputTokens?: number;
    totalTokens?: number;
    finishReason?: string;
    duration: number;
    rawBody: string;
}
export interface AIResult {
    success: boolean;
    data: AIResponseData;
    errorMsg?: string;
}
export declare const AI_PROVIDERS: Record<string, {
    url: string;
    label: string;
}>;
export declare function executeAIRequest(ctx: AIRequestContext): Promise<AIResult>;
