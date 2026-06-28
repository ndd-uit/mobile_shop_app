import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { CallToolRequestSchema, ListToolsRequestSchema, ErrorCode, McpError, } from "@modelcontextprotocol/sdk/types.js";
import { exec } from "child_process";
import * as fs from "fs/promises";
import * as path from "path";
import { fileURLToPath } from "url";
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
// Project root directory is the parent of the mcp-server directory
const PROJECT_ROOT = path.resolve(__dirname, "../..");
class MobileShopMcpServer {
    server;
    constructor() {
        this.server = new Server({
            name: "mobile-shop-mcp-server",
            version: "1.0.0",
        }, {
            capabilities: {
                tools: {},
            },
        });
        this.setupTools();
        // Error handling
        this.server.onerror = (error) => console.error("[MCP Error]", error);
        process.on("SIGINT", async () => {
            await this.server.close();
            process.exit(0);
        });
    }
    setupTools() {
        // 1. List available tools
        this.server.setRequestHandler(ListToolsRequestSchema, async () => {
            return {
                tools: [
                    {
                        name: "run_flutter_command",
                        description: "Run standard Flutter commands in the project (e.g., pub get, analyze, test, clean)",
                        inputSchema: {
                            type: "object",
                            properties: {
                                command: {
                                    type: "string",
                                    enum: ["pub get", "analyze", "test", "clean"],
                                    description: "The Flutter command argument to execute (e.g., 'pub get' will run 'flutter pub get')"
                                }
                            },
                            required: ["command"]
                        }
                    },
                    {
                        name: "get_supabase_schema",
                        description: "Read the Supabase SQL database schema (schema.sql)",
                        inputSchema: {
                            type: "object",
                            properties: {}
                        }
                    }
                ]
            };
        });
        // 2. Handle tool execution requests
        this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
            const { name, arguments: args } = request.params;
            try {
                switch (name) {
                    case "run_flutter_command": {
                        const commandArg = args?.command;
                        if (!commandArg) {
                            throw new McpError(ErrorCode.InvalidParams, "Missing 'command' argument");
                        }
                        const fullCommand = `flutter ${commandArg}`;
                        const result = await this.executeCommand(fullCommand, PROJECT_ROOT);
                        return {
                            content: [
                                {
                                    type: "text",
                                    text: result
                                }
                            ]
                        };
                    }
                    case "get_supabase_schema": {
                        const schemaPath = path.join(PROJECT_ROOT, "supabase", "schema.sql");
                        try {
                            const schemaContent = await fs.readFile(schemaPath, "utf-8");
                            return {
                                content: [
                                    {
                                        type: "text",
                                        text: schemaContent
                                    }
                                ]
                            };
                        }
                        catch (err) {
                            throw new McpError(ErrorCode.InternalError, `Could not read schema.sql: ${err.message}`);
                        }
                    }
                    default:
                        throw new McpError(ErrorCode.MethodNotFound, `Unknown tool: ${name}`);
                }
            }
            catch (error) {
                return {
                    content: [
                        {
                            type: "text",
                            text: `Error: ${error.message || error}`
                        }
                    ],
                    isError: true
                };
            }
        });
    }
    executeCommand(command, cwd) {
        return new Promise((resolve, reject) => {
            exec(command, { cwd }, (error, stdout, stderr) => {
                // We resolve even with errors sometimes since compilation/tests outputs are useful
                const output = stdout + (stderr ? `\n[STDERR]\n${stderr}` : "");
                if (error) {
                    resolve(`Command failed with exit code ${error.code}.\n\nOutput:\n${output}`);
                }
                else {
                    resolve(output);
                }
            });
        });
    }
    async run() {
        const transport = new StdioServerTransport();
        await this.server.connect(transport);
        console.error("Mobile Shop MCP Server running on stdio");
    }
}
const server = new MobileShopMcpServer();
server.run().catch((error) => {
    console.error("Fatal error starting server:", error);
    process.exit(1);
});
