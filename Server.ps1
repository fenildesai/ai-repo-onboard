$ErrorActionPreference='Stop'
. "$PSScriptRoot/Engine.ps1"
$port=8765; $token=[guid]::NewGuid().ToString('N'); $listener=New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/"); $listener.Start(); $root=$null
Start-Process "http://localhost:$port/?token=$token"
try { while($listener.IsListening){ $ctx=$listener.GetContext(); $req=$ctx.Request; $res=$ctx.Response; $res.Headers['Cache-Control']='no-store'; $res.Headers['X-Content-Type-Options']='nosniff'; try {
 if($req.Url.AbsolutePath -eq '/' -and $req.HttpMethod -eq 'GET'){ $out=Get-Content "$PSScriptRoot/web/index.html" -Raw; $res.ContentType='text/html; charset=utf-8' }
 else { if($req.HttpMethod -ne 'POST' -or $req.Headers['X-Session'] -ne $token){throw 'Unauthorized request'}; if($req.Headers['Origin'] -and $req.Headers['Origin'] -ne "http://localhost:$port"){throw 'Invalid origin'}; $reader=New-Object IO.StreamReader($req.InputStream); $data=$reader.ReadToEnd()|ConvertFrom-Json; $reader.Dispose(); $res.ContentType='application/json; charset=utf-8'
 switch($req.Url.AbsolutePath){
 '/scan' { $candidate=(Resolve-Path -LiteralPath $data.path).Path; $gitRoot=& git -C $candidate rev-parse --show-toplevel 2>$null; if($LASTEXITCODE -ne 0){throw 'Select a local Git repository'}; $root=(Resolve-Path -LiteralPath $gitRoot).Path; $result=@{root=$root;checks=@(Get-Checks $root)} }
 '/draft' { if(!$root){throw 'Scan first'}; $result=Get-Draft $root ([int]$data.id) }
 '/create' { if(!$root -or !$data.approved){throw 'Approval required'}; $draft=Get-Draft $root ([int]$data.id); $target=Join-Path $root $draft.path; $parent=Split-Path $target -Parent; $cursor=$parent; while($cursor -and $cursor -ne $root){if(Test-Path -LiteralPath $cursor){if((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Linked directory not allowed'}}; $cursor=Split-Path $cursor -Parent}; if(Test-Path -LiteralPath $target){throw 'File already exists'}; [IO.Directory]::CreateDirectory($parent)|Out-Null; $stream=[IO.File]::Open($target,[IO.FileMode]::CreateNew); try{$bytes=[Text.Encoding]::UTF8.GetBytes($draft.content);$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}; $result=@{root=$root;checks=@(Get-Checks $root)} }
 default {throw 'Unknown endpoint'} }; $out=$result|ConvertTo-Json -Depth 6 -Compress }
 }catch{$res.StatusCode=400;$res.ContentType='application/json';$out=@{error=$_.Exception.Message}|ConvertTo-Json -Compress}; $bytes=[Text.Encoding]::UTF8.GetBytes($out);$res.OutputStream.Write($bytes,0,$bytes.Length);$res.Close() } } finally {$listener.Stop();$listener.Close()}
