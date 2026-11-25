# AI Repo Onboard

Assess a local Git repository for AI readiness and see what guidance is missing for GitHub Copilot and OpenAI Codex.

AI Repo Onboard runs on Windows and opens a local browser interface. It checks 12 areas, including agent instructions, skills, project documentation, testing, and CI/CD. The baseline scan runs without an AI subscription.

## Requirements

- Windows PowerShell and Git
- An existing local Git clone to assess
- Permission to run a local HTTP listener on port `8765`

## Quick start

1. Download the repository from **Code → Download ZIP** and extract it, or clone it with Git.

   ```powershell
   git clone https://github.com/fenildesai/ai-repo-onboard.git
   ```

2. Open the toolkit folder and double-click [`Start.cmd`](Start.cmd). Use the launcher to open the app in your browser.
3. Enter the path to the local Git repository you want to assess, then select **Assess repository**.
4. Review the project summary and checklist. Where **Create** is available, preview the proposed file and select **Approve & create** to write it to the target repository.

Close the PowerShell window to stop the service. If startup is blocked, check that port `8765` is available and that your organisation permits local PowerShell scripts and HTTP listeners.

## Read the results

The project summary lists detected .NET projects, target frameworks, and source files and non-blank lines by language. Counts include comments and use tracked and unignored working-tree files. Common build, dependency, and generated files are excluded.

| Status | Meaning |
| --- | --- |
| **Missing** | The expected file or folder was absent. Selected checks offer a baseline draft. |
| **Review** | The expected path exists or the check requires manual inspection. Review the content before treating the check as complete. |

The scanner checks expected paths. Each supported draft has guidance for its specific purpose and uses detected project facts where relevant. The toolkit writes drafts only after approval. The toolkit leaves existing files intact and creates no Git commits or pushes.

## Assess the content with Copilot or Codex

Copy the full [`skills/ai-repo-onboard`](skills/ai-repo-onboard) directory to a skill location supported by your installed client. Then ask the client to assess your repository using the skill. The skill guides the client to cite repository evidence, distinguish missing guidance from unverified items, and request approval before editing.

## Current scope

This first release supports local Git clones. Remote repository URLs, platform selection, quality scoring, editing existing files, and a native folder picker are outside the current release. Skill installation and authentication are manual. The local service was tested on Windows against an ASP.NET Core sample targeting .NET 10.
