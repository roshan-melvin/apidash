/**
 * HTTP Methods and status codes data for APIDash MCP
 */
export declare const HTTP_METHODS: readonly ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS", "CONNECT", "TRACE"];
export type HttpMethod = typeof HTTP_METHODS[number];
export declare const HTTP_METHODS_WITH_BODY: HttpMethod[];
export declare const CONTENT_TYPES: readonly [{
    readonly value: "application/json";
    readonly label: "JSON";
}, {
    readonly value: "application/x-www-form-urlencoded";
    readonly label: "Form URL Encoded";
}, {
    readonly value: "multipart/form-data";
    readonly label: "Multipart Form";
}, {
    readonly value: "text/plain";
    readonly label: "Plain Text";
}, {
    readonly value: "application/xml";
    readonly label: "XML";
}, {
    readonly value: "application/graphql";
    readonly label: "GraphQL";
}, {
    readonly value: "text/html";
    readonly label: "HTML";
}];
export declare const STATUS_REASONS: Record<number, string>;
export declare const SAMPLE_REQUESTS: ({
    id: string;
    name: string;
    method: string;
    url: string;
    description: string;
    body?: undefined;
    contentType?: undefined;
} | {
    id: string;
    name: string;
    method: string;
    url: string;
    description: string;
    body: string;
    contentType: string;
})[];
export declare const CODE_GENERATORS: readonly [{
    readonly id: "curl";
    readonly name: "cURL";
    readonly icon: "🐚";
    readonly lang: "bash";
}, {
    readonly id: "python-requests";
    readonly name: "Python";
    readonly icon: "🐍";
    readonly lang: "python";
}, {
    readonly id: "javascript-fetch";
    readonly name: "JS Fetch";
    readonly icon: "🌐";
    readonly lang: "javascript";
}, {
    readonly id: "javascript-axios";
    readonly name: "JS Axios";
    readonly icon: "⚡";
    readonly lang: "javascript";
}, {
    readonly id: "nodejs-fetch";
    readonly name: "Node Fetch";
    readonly icon: "🟢";
    readonly lang: "javascript";
}, {
    readonly id: "dart-http";
    readonly name: "Dart";
    readonly icon: "🎯";
    readonly lang: "dart";
}, {
    readonly id: "go-http";
    readonly name: "Go";
    readonly icon: "🐹";
    readonly lang: "go";
}, {
    readonly id: "java-http";
    readonly name: "Java";
    readonly icon: "☕";
    readonly lang: "java";
}, {
    readonly id: "kotlin-okhttp";
    readonly name: "Kotlin";
    readonly icon: "🟣";
    readonly lang: "kotlin";
}, {
    readonly id: "php-curl";
    readonly name: "PHP";
    readonly icon: "🐘";
    readonly lang: "php";
}, {
    readonly id: "ruby-net";
    readonly name: "Ruby";
    readonly icon: "💎";
    readonly lang: "ruby";
}, {
    readonly id: "rust-reqwest";
    readonly name: "Rust";
    readonly icon: "🦀";
    readonly lang: "rust";
}];
export declare const GRAPHQL_SAMPLE_QUERY = "query {\n  countries {\n    code\n    name\n    capital\n    currency\n    emoji\n  }\n}";
export declare const GRAPHQL_SAMPLE_ENDPOINT = "https://countries.trevorblades.com/graphql";
