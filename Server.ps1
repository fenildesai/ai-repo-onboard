$ErrorActionPreference='Stop'
. "$PSScriptRoot/Engine.ps1"
. "$PSScriptRoot/Profile.ps1"
$listener = $null
foreach ($port in 8765..8784) {
    $origin = "http://localhost:$port"
    $candidateListener = New-Object System.Net.HttpListener
    $candidateListener.Prefixes.Add("$origin/")
    try {
        $candidateListener.Start()
        $listener = $candidateListener
        break
    } catch {
        $cause = $_.Exception.GetBaseException()
        $candidateListener.Close()
        # HTTP.sys can report an existing prefix or an occupied port.
        if ($cause -isnot [System.Net.HttpListenerException] -or $cause.NativeErrorCode -notin 32, 183, 10048) {
            throw "AI Repo Onboard could not start on $origin. $($cause.Message)"
        }
    }
}
if (!$listener) {
    throw 'AI Repo Onboard could not start because localhost ports 8765 through 8784 are busy. Close an earlier AI Repo Onboard launcher or free one of those ports, then run Start.cmd again.'
}

$token = [guid]::NewGuid().ToString('N')
$root = $null
$profile = $null
try {
 Write-Host "AI Repo Onboard is running at $origin. Close this window to stop it."
 Start-Process "$origin/?token=$token"
 while($listener.IsListening){ $ctx=$listener.GetContext(); $req=$ctx.Request; $res=$ctx.Response; $res.Headers['Cache-Control']='no-store'; $res.Headers['X-Content-Type-Options']='nosniff'; try {
 if($req.Url.AbsolutePath -eq '/' -and $req.HttpMethod -eq 'GET'){ $out=Get-Content "$PSScriptRoot/web/index.html" -Raw -Encoding UTF8; $res.ContentType='text/html; charset=utf-8' }
 else { if($req.HttpMethod -ne 'POST' -or $req.Headers['X-Session'] -ne $token){throw 'Unauthorized request'}; if($req.Headers['Origin'] -and $req.Headers['Origin'] -ne $origin){throw 'Invalid origin'}; $reader=New-Object IO.StreamReader($req.InputStream); $data=$reader.ReadToEnd()|ConvertFrom-Json; $reader.Dispose(); $res.ContentType='application/json; charset=utf-8'
 switch($req.Url.AbsolutePath){
 '/scan' { $candidate=(Resolve-Path -LiteralPath $data.path).Path; $gitRoot=& git -C $candidate rev-parse --show-toplevel 2>$null; if($LASTEXITCODE -ne 0){throw 'Select a local Git repository'}; $candidateRoot=(Resolve-Path -LiteralPath $gitRoot).Path; $profile=Get-ProjectProfile $candidateRoot; $root=$candidateRoot; $result=@{root=$root;profile=$profile;checks=@(Get-Checks $root)} }
 '/draft' { if(!$root){throw 'Scan first'}; $result=Get-Draft $root ([int]$data.id) $profile }
 '/create' { if(!$root -or !$data.approved){throw 'Approval required'}; $draft=Get-Draft $root ([int]$data.id) $profile; $target=Join-Path $root $draft.path; $parent=Split-Path $target -Parent; $cursor=$parent; while($cursor -and $cursor -ne $root){if(Test-Path -LiteralPath $cursor){if((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Linked directory not allowed'}}; $cursor=Split-Path $cursor -Parent}; if(Test-Path -LiteralPath $target){throw 'File already exists'}; [IO.Directory]::CreateDirectory($parent)|Out-Null; $stream=[IO.File]::Open($target,[IO.FileMode]::CreateNew); try{$bytes=[Text.Encoding]::UTF8.GetBytes($draft.content);$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}; git -C $root check-ignore --quiet -- $draft.path; if($LASTEXITCODE -eq 1){$profile.files++}; $result=@{root=$root;profile=$profile;checks=@(Get-Checks $root)} }
 default {throw 'Unknown endpoint'} }; $out=$result|ConvertTo-Json -Depth 6 -Compress }
 }catch{$res.StatusCode=400;$res.ContentType='application/json';$out=@{error=$_.Exception.Message}|ConvertTo-Json -Compress}; $bytes=[Text.Encoding]::UTF8.GetBytes($out);$res.OutputStream.Write($bytes,0,$bytes.Length);$res.Close() } } finally {$listener.Stop();$listener.Close()}
