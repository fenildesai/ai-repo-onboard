# AGENTS.md

AI Repo Onboard is a local Windows PowerShell toolkit for inspecting Git repositories and previewing onboarding files.

- `Start.cmd` launches `Server.ps1`. The server handles the local browser requests.
- `Profile.ps1` inventories repository files and .NET projects. `Engine.ps1` owns readiness checks and draft content. `web/index.html` renders the assessment.
- `examples/SampleCatalog/SampleCatalog.slnx` is the .NET 10 validation fixture. See the [README](README.md) for the local workflow.

Keep the launcher compatible with Windows PowerShell 5.1. Keep the listener on localhost and preserve session checks, explicit approval, and create-only writes. Render text from scanned repositories as text in the browser. Keep unrelated changes and generated sample output out of commits.

For engine changes, assess a clean SampleCatalog copy and check the affected preview and approval flow. For sample changes, run `dotnet test ./examples/SampleCatalog/SampleCatalog.slnx` with the .NET 10 SDK. Report checks you could not run.
