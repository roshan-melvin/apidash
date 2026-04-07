/**
 * APIDash CLI — Code Generator
 * Generates HTTP request snippets in 12 languages.
 * Mirrors apidash-mcp/src/utils/codegen.ts for consistency.
 */
export interface CodeGenInput {
    method: string;
    url: string;
    headers?: Record<string, string>;
    body?: string;
}
export type GeneratorId = "curl" | "python-requests" | "javascript-fetch" | "javascript-axios" | "nodejs-fetch" | "dart-http" | "go-http" | "java-http" | "kotlin-okhttp" | "php-curl" | "ruby-net" | "rust-reqwest";
export declare function generateCurl({ method, url, headers, body }: CodeGenInput): string;
export declare function generatePythonRequests({ method, url, headers, body }: CodeGenInput): string;
export declare function generateJavaScriptFetch({ method, url, headers, body }: CodeGenInput): string;
export declare function generateJavaScriptAxios({ method, url, headers, body }: CodeGenInput): string;
export declare function generateNodeFetch({ method, url, headers, body }: CodeGenInput): string;
export declare function generateDartHttp({ method, url, headers, body }: CodeGenInput): string;
export declare function generateGo({ method, url, headers, body }: CodeGenInput): string;
export declare function generateJava({ method, url, headers, body }: CodeGenInput): string;
export declare function generateKotlin({ method, url, headers, body }: CodeGenInput): string;
export declare function generatePhp({ method, url, headers, body }: CodeGenInput): string;
export declare function generateRuby({ method, url, headers, body }: CodeGenInput): string;
export declare function generateRust({ method, url, headers, body }: CodeGenInput): string;
export declare function generateCode(id: GeneratorId | string, input: CodeGenInput): string;
export declare const SUPPORTED_GENERATORS: GeneratorId[];
//# sourceMappingURL=codegen.d.ts.map