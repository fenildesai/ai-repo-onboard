# How we draft repository instructions

`AGENTS.md` gives coding agents the repository's durable context, work boundaries, and validation route. `.github/copilot-instructions.md` gives Copilot compact, self-contained guidance. Copilot support for agent and path-specific instructions varies by feature, so its repository-wide file carries the essential facts on its own.

Drafts use detected paths and framework metadata. They cap the repository map and point to relevant documentation, configuration, and CI. A single detected .NET solution can supply candidate build and test commands. A maintainer should run the commands and review project-specific conventions before treating the draft as authoritative.

- Put setup, build, test, and lint instructions near the code or documentation they govern. Include prerequisites and a known-good invocation when you can verify it. [GitHub repository custom instructions](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/add-custom-instructions/add-repository-instructions)
- Keep root instructions compact. Use more specific instructions for local rules and open detailed documentation when the task needs it. [OpenAI AGENTS.md guidance](https://learn.chatgpt.com/docs/agent-configuration/agents-md) · [OpenAI guidance on context size](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra)
- Use the project's established terms, and point to its glossary when one exists. Keep task workflows in separate skills. [Matt Pocock's skills](https://github.com/mattpocock/skills)
- Prefer a small change and a focused verification pass. Keep specialist workflows available for work that needs them. [Lauren Tan's pstack](https://github.com/cursor/plugins/tree/main/pstack)
