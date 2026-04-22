---
name: notebooklm
description: NotebookLM integration via MCP to enable the 10x performance research-to-code workflow. Use this skill when interacting with NotebookLM contexts, documents, and research data.
license: MIT
metadata:
  author: Antigravity
  version: "1.0.0"
  organization: StudySync
  date: April 2026
  abstract: Defines the interface and expected behaviors for the NotebookLM MCP server integration.
---

# NotebookLM Integration

This skill establishes the integration with the `notebooklm-mcp-cli` provider, bridging external research repositories with the local development environment for advanced agentic coding.

## Usage
- This MCP provides research documents, summaries, and notebook insights.
- The environment requires `uv` to be installed.
- Use `uvx --from notebooklm-mcp-cli nlm login` for authentication.
- Use `uvx --from notebooklm-mcp-cli nlm notebook list` to manage notebooks.
- All MCP tools are exposed via the `notebooklm-mcp` server.
