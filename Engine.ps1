function Get-Checks($root) {
 $defs = @(
 @('AGENTS.md','Shared AI guidance','AGENTS.md'),@('Copilot instructions','Repository guidance','.github/copilot-instructions.md'),@('Scoped instructions','Technology conventions','.github/instructions'),@('Project Guide','Copilot onboarding agent','.github/agents/project-guide.agent.md'),@('Agent skills','Reusable workflows','.agents/skills'),@('Instruction consistency','Review shared guidance',''),@('Project knowledge','Architecture and business context','docs/ai/project-overview.md'),@('Build and run','Build documentation','README.md'),@('Testing guide','Documentation for running and maintaining tests','docs/ai/testing.md'),@('CI/CD','Delivery pipeline','azure-pipelines.yml'),@('Quality and security','Engineering guardrails','docs/ai/standards.md'),@('Developer onboarding','Setup guidance','docs/ai/developer-guide.md'))
 for($i=0;$i -lt $defs.Count;$i++){ $d=$defs[$i]; $exists=$d[2] -and (Test-Path -LiteralPath (Join-Path $root $d[2])); $status=if($exists){'Review'}elseif($i -eq 5){'Review'}else{'Missing'}; [pscustomobject]@{id=$i;name=$d[0];description=$d[1];path=$d[2];status=$status;canCreate=($i -in @(0,1,3,6,8,10,11) -and !$exists)} }
}
function Get-InstructionEvidence($root, $profile) {
    $code = [char]96
    $projectName = ($profile.name -replace '[^\p{L}\p{N} ._-]', ' ').Trim()
    if (!$projectName) { $projectName = 'this repository' }

    $stack = @($profile.projects.technology) + @($profile.projects | ForEach-Object { $_.frameworks }) + @($profile.languages.name) + @($profile.javaBuilds.tool)
    $stack = @($stack | Where-Object { $_ -match '^[\p{L}\p{N} .+#/-]+$' } | Select-Object -Unique -First 10)
    $stackText = if ($stack.Count) { $stack -join ', ' } else { 'Check the project manifests for the technology stack.' }

    $known = @('README.md', 'CONTRIBUTING.md', 'AGENTS.md', 'GLOSSARY.md', 'CONTEXT.md', 'docs/architecture.md',
        'docs/ai/project-overview.md', 'docs/ai/testing.md', '.editorconfig', 'global.json', 'Directory.Build.props',
        'package.json', 'pyproject.toml', 'go.mod', 'Cargo.toml', 'Makefile', '.github/workflows', 'azure-pipelines.yml')
    $referencePaths = @($known | Where-Object { Test-Path -LiteralPath (Join-Path $root $_) })
    $solutionPaths = @($profile.solutions | Where-Object { $_ -match '^[\p{L}\p{N} ./_-]+$' })
    $projects = @($profile.projects | Where-Object { $_.path -match '^[\p{L}\p{N} ./_-]+$' })
    $map = @(
        $solutionPaths | Select-Object -First 3 | ForEach-Object { "- Solution: $code$_$code" }
        $profile.javaBuilds | Select-Object -First 6 | ForEach-Object { "- $($_.tool) build file: $code$($_.path)$code" }
        $profile.javaSourceRoots | Select-Object -First 6 | ForEach-Object { "- Java sources: $code$_$code" }
        $projects | Select-Object -First 6 | ForEach-Object {
            $kind = if ($_.isTest) { 'Test project' } else { 'Project' }
            "$('- ' + $kind): $code$($_.path)$code"
        }
    )
    if (!$map.Count) { $map = @('- Find the affected entry point in the project manifest or repository documentation.') }
    $references = if ($referencePaths.Count) {
        ($referencePaths | Select-Object -First 10 | ForEach-Object { "$code$_$code" }) -join ', '
    } else { 'Check the repository for contribution guidance and build configuration.' }

    $validation = @(
        if ($solutionPaths.Count -eq 1) {
            $solution = $solutionPaths[0]
            $commands = "Start with ${code}dotnet build `"$solution`"$code"
            if (@($projects | Where-Object isTest).Count) { $commands += " and ${code}dotnet test `"$solution`"$code" }
            "$commands. Confirm the SDK, prerequisites, and CI options before running. These commands are inferred from the solution."
        }
        if ($profile.javaBuilds.Count) {
            'Check the build files and CI for the required JDK, build profiles and module-specific checks.'
            if ($profile.javaCommands.Count) {
                $commands = ($profile.javaCommands | ForEach-Object { "$code$_$code" }) -join ', '
                "Root build command candidates: $commands. Confirm which build applies before running. These commands were inferred from the build files and were not run."
            } else {
                'Run the documented checks from the relevant module or build root.'
            }
        }
    )
    if (!$validation.Count) {
        $validation = @('Use the setup, build, test, and lint commands documented for the area you changed. Check CI when a command or prerequisite is unclear.')
    }
    [pscustomobject]@{
        name = $projectName
        stack = $stackText
        map = $map -join "`n"
        references = $references
        validation = $validation -join "`n`n"
    }
}

function Get-Draft($root, $id, $profile) {
    $check = Get-Checks $root | Where-Object { $_.id -eq $id }
    if (!$check -or !$check.canCreate) { throw 'This check requires manual review.' }

    $projectPaths = @($profile.projects | ForEach-Object { $_.path }) + @($profile.javaBuilds | ForEach-Object { $_.path })
    $projectList = if ($projectPaths.Count) { $projectPaths -join ', ' } else { 'No supported project manifests detected.' }
    $technology = @(@($profile.projects.technology) + @($profile.javaBuilds.tool) | Where-Object { $_ } | Sort-Object -Unique) -join ', '
    $frameworks = @($profile.projects | ForEach-Object { $_.frameworks } | Sort-Object -Unique) -join ', '
    $languages = @($profile.languages | ForEach-Object { $_.name }) -join ', '

    $testPaths = @($profile.projects | Where-Object isTest | ForEach-Object { $_.path }) + @($profile.javaSourceRoots | Where-Object { $_ -like '*src/test/java' })
    $testList = if ($testPaths.Count) { $testPaths -join ', ' } else { 'No supported test projects or conventional Java test directories detected.' }

    $body = switch ($id) {
        0 {
            $evidence = Get-InstructionEvidence $root $profile
            @"
# AGENTS.md

## Project context

- Repository: $($evidence.name)
- Detected stack: $($evidence.stack)

$($evidence.map)

## Working in this repository

- Follow any more specific AGENTS.md in the directory you change.
- Start with the relevant project files and documentation. Known references: $($evidence.references)
- Use the repository's established domain terms and conventions. Preserve public interfaces unless the task requires a change.
- Keep the diff focused. Leave unrelated work and generated or vendored files alone unless the task covers them.
- Keep secrets out of source, fixtures, and logs. Ask before deploying or changing production data.

## Validation

$($evidence.validation)

Run the checks that cover the change. Report checks that could not run and the reason.
"@
        }
        1 {
            $evidence = Get-InstructionEvidence $root $profile
            @"
# GitHub Copilot repository instructions

- Work in $($evidence.name). Detected stack: $($evidence.stack)
- Use the relevant repository references for setup, build rules, and conventions: $($evidence.references)
- Follow matching instructions under .github/instructions/ when present. Use the nearest implementation and tests as examples for naming, error handling, and test style.
- Preserve the target framework and public API behavior unless the task requires a change. Keep changes small and use established domain terms.
- Keep credentials and private data out of code, logs, and fixtures.

## Project and test entry points

$($evidence.map)

## Build and test

$($evidence.validation)

Use the affected tests for changed behavior. Include the commands and results in the pull request or handoff.
"@
        }
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

Look for test configuration and test commands in CI before choosing a test runner. Detected test projects and directories:

$testList

## Validate a change

- Run the documented checks for the affected area.
- Check the project manifest and CI for the test runner, prerequisites, and any integration-test flags.
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
