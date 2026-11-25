function Get-Checks($root) {
 $defs = @(
 @('AGENTS.md','Shared AI guidance','AGENTS.md'),@('Copilot instructions','Repository guidance','.github/copilot-instructions.md'),@('Scoped instructions','Technology conventions','.github/instructions'),@('Project Guide','Copilot onboarding agent','.github/agents/project-guide.agent.md'),@('Agent skills','Reusable workflows','.agents/skills'),@('Instruction consistency','Review shared guidance',''),@('Project knowledge','Architecture and business context','docs/ai/project-overview.md'),@('Build and run','Build documentation','README.md'),@('Testing guide','Documentation for running and maintaining tests','docs/ai/testing.md'),@('CI/CD','Delivery pipeline','azure-pipelines.yml'),@('Quality and security','Engineering guardrails','docs/ai/standards.md'),@('Developer onboarding','Setup guidance','docs/ai/developer-guide.md'))
 for($i=0;$i -lt $defs.Count;$i++){ $d=$defs[$i]; $exists=$d[2] -and (Test-Path -LiteralPath (Join-Path $root $d[2])); $status=if($exists){'Review'}elseif($i -eq 5){'Review'}else{'Missing'}; [pscustomobject]@{id=$i;name=$d[0];description=$d[1];path=$d[2];status=$status;canCreate=($i -in @(0,1,3,6,8,10,11) -and !$exists)} }
}
function Get-Draft($root, $id, $profile) {
    $check = Get-Checks $root | Where-Object { $_.id -eq $id }
    if (!$check -or !$check.canCreate) { throw 'This check requires manual review.' }

    $projectPaths = @($profile.projects | ForEach-Object { $_.path })
    $projectList = if ($projectPaths.Count) { $projectPaths -join ', ' } else { 'No .NET project files detected.' }
    $technology = @($profile.projects | ForEach-Object { $_.technology } | Sort-Object -Unique) -join ', '
    $frameworks = @($profile.projects | ForEach-Object { $_.frameworks } | Sort-Object -Unique) -join ', '
    $languages = @($profile.languages | ForEach-Object { $_.name }) -join ', '

    $testPaths = @($profile.projects | Where-Object isTest | ForEach-Object { $_.path })
    $testList = if ($testPaths.Count) { $testPaths -join ', ' } else { 'No .NET test projects detected.' }

    $body = switch ($id) {
        0 { @"
# Repository instructions for $($profile.name)

## Before editing

- Read the nearest project file and existing repository guidance.
- Keep changes scoped to the request and preserve established conventions.
- Review the diff for unrelated changes and run the repository's documented checks.

## Project entry points

$projectList
"@ }
        1 { @"
# GitHub Copilot instructions

Use the existing implementation and tests as examples when suggesting changes to **$($profile.name)**.

- Inspect neighboring files for naming, error handling, and dependency patterns.
- Keep APIs compatible with the target frameworks declared by project files.
- When adding behavior, identify the nearest existing test and explain how to verify the change.
- Flag any command or assumption you could not verify.
"@ }
        3 { @"
---
name: Project Guide
description: Explain repository structure with links to verified source files.
---

# Project Guide

Help developers navigate **$($profile.name)**. Start with the repository README and these detected project files:

$projectList

For each question, locate the relevant entry point, trace its dependencies, and cite concrete file paths. Explain how to run or test the area using documented commands. Ask before editing files.
"@ }
        6 { @"
# Project overview

| Item | Detected value |
| --- | --- |
| Project | $($profile.name) |
| Technology | $technology |
| Target frameworks | $frameworks |
| Source languages | $languages |

## Project files

$projectList

## Architecture to document

Record the purpose, key entry points, dependencies, and data flow after checking the source. Confirm business context and ownership with the maintainers.
"@ }
        8 { @"
# Testing guide

## Locate tests

Look for test configuration and test commands in CI before choosing a test runner. Detected .NET test projects:

$testList

## Validate a change

- Run the documented checks for the affected area.
- For a .NET test project, use dotnet test with the verified project or solution path.
- Record the commands, results, and any unavailable dependencies.
"@ }
        10 { @"
# Quality and security standards

- Validate input at application boundaries and follow the existing error-handling conventions.
- Keep credentials and private data out of source, logs, and test fixtures.
- Use the repository's documented formatter, linter, dependency checks, and security scans.
- Record any check that could not run and confirm exceptions with the maintainers.
"@ }
        11 { @"
# Developer setup

## Find the entry point

$projectList

## Set up and run

1. Check the README and build configuration for required SDKs and tools. Detected target frameworks: $frameworks
2. Follow the repository's documented restore and build instructions.
3. Configure local dependencies using the project's documented settings.
4. Run the documented smoke checks and record any setup steps that need confirmation.
"@ }
    }

    @{ path = $check.path; content = $body + "`n" }
}
