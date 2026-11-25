# GitHub Copilot repository instructions

- AI Repo Onboard uses Windows PowerShell 5.1, Git, and browser-native HTML, CSS, and JavaScript. The toolkit starts with `Start.cmd` and runs on localhost.
- Keep file inventory in `Profile.ps1`, readiness checks and draft content in `Engine.ps1`, HTTP handling in `Server.ps1`, and browser rendering in `web/index.html`.
- Preserve session checks and explicit approval before writes. Keep writes create-only, and render scanned metadata with text APIs.
- For an engine change, use the README walkthrough to scan a clean SampleCatalog copy, inspect the affected preview, and approve a draft in that copy.
- For sample changes, run `dotnet test ./examples/SampleCatalog/SampleCatalog.slnx` with the .NET 10 SDK. Include the checks run and their results in the pull request.
