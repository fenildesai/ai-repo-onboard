function Get-Checks($root) {
 $defs = @(
 @('AGENTS.md','Shared AI guidance','AGENTS.md'),@('Copilot instructions','Repository guidance','.github/copilot-instructions.md'),@('Scoped instructions','Technology conventions','.github/instructions'),@('Project Guide','Copilot onboarding agent','.github/agents/project-guide.agent.md'),@('Agent skills','Reusable workflows','.agents/skills'),@('Instruction consistency','Review shared guidance',''),@('Project knowledge','Architecture and business context','docs/ai/project-overview.md'),@('Build and run','Build documentation','README.md'),@('Testing','Test guidance','docs/ai/testing.md'),@('CI/CD','Delivery pipeline','azure-pipelines.yml'),@('Quality and security','Engineering guardrails','docs/ai/standards.md'),@('Developer onboarding','Setup guidance','docs/ai/developer-guide.md'))
 for($i=0;$i -lt $defs.Count;$i++){ $d=$defs[$i]; $exists=$d[2] -and (Test-Path -LiteralPath (Join-Path $root $d[2])); $status=if($exists){'Review'}elseif($i -eq 5){'Review'}else{'Missing'}; [pscustomobject]@{id=$i;name=$d[0];description=$d[1];path=$d[2];status=$status;canCreate=($i -in @(0,1,3,6,8,10,11) -and !$exists)} }
}
function Get-Draft($root,$id){
 $c=@(Get-Checks $root)[$id]; if(!$c.canCreate){throw 'This check requires manual review.'}; $name=Split-Path $root -Leaf
 $body="# $($c.name)`n`nRepository: $name`n`n## Guidance`n- Follow existing conventions and inspect relevant source before changes.`n- Do not expose secrets or modify unrelated files.`n- Verify build and test commands with the team before running them.`n`n## Repository-specific details`nTODO: Confirm architecture, commands and ownership with maintainers.`n"
 if($id -eq 3){$body="---`ndescription: Explain repository structure using verified source evidence`n---`n$body"}; @{path=$c.path;content=$body}
}
