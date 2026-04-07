/**
 * Code generator utility for APIDash MCP
 * Generates code snippets for HTTP requests in various languages
 */
export interface CodeGenInput {
    method: string;
    url: string;
    headers?: Record<string, string>;
    body?: string;
    contentType?: string;
}
export declare function generateCurl(input: CodeGenInput): string;
export declare function generatePythonRequests(input: CodeGenInput): string;
export declare function generateJavaScriptFetch(input: CodeGenInput): string;
export declare function generateJavaScriptAxios(input: CodeGenInput): string;
export declare function generateNodeFetch(input: CodeGenInput): string;
export declare function generateDartHttp(input: CodeGenInput): string;
export declare function generateGo(input: CodeGenInput): string;
export declare function generateJava(input: CodeGenInput): string;
export declare function generateKotlin(input: CodeGenInput): string;
export declare function generatePhp(input: CodeGenInput): string;
export declare function generateRuby(input: CodeGenInput): string;
export declare function generateRust(input: CodeGenInput): string;
export declare function generateCode(generatorId: string, input: CodeGenInput): string;
