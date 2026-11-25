function Get-ProjectProfile($root) {
    $extensions = @{
        '.cs' = 'C#'; '.fs' = 'F#'; '.vb' = 'Visual Basic'; '.razor' = 'Razor'; '.cshtml' = 'Razor'
        '.js' = 'JavaScript'; '.jsx' = 'JavaScript'; '.ts' = 'TypeScript'; '.tsx' = 'TypeScript'
        '.py' = 'Python'; '.java' = 'Java'; '.kt' = 'Kotlin'; '.go' = 'Go'; '.rs' = 'Rust'
        '.c' = 'C'; '.cpp' = 'C++'; '.h' = 'C/C++ headers'; '.hpp' = 'C++'
        '.rb' = 'Ruby'; '.php' = 'PHP'; '.swift' = 'Swift'; '.sql' = 'SQL'
        '.ps1' = 'PowerShell'; '.psm1' = 'PowerShell'; '.sh' = 'Shell'; '.cmd' = 'Batch'; '.bat' = 'Batch'
        '.html' = 'HTML'; '.css' = 'CSS'; '.scss' = 'SCSS'; '.vue' = 'Vue'
    }
    # Preserve Unicode and use Git's escaped paths for names containing control characters.
    $paths = @(git -C $root -c core.quotePath=false ls-files --cached --others --exclude-standard)
    if ($LASTEXITCODE -ne 0) { throw 'Git could not list the repository files.' }

    $languages = @{}
    $solutions = New-Object 'System.Collections.Generic.List[string]'
    $projects = New-Object 'System.Collections.Generic.List[object]'
    $javaSourceRoots = New-Object 'System.Collections.Generic.HashSet[string]'
    $files = 0
    foreach ($path in ($paths | Sort-Object -CaseSensitive -Unique)) {
        if ($path.StartsWith('"') -or $path -match '(^|/)(bin|obj|target|build|\.gradle|node_modules|vendor|dist|coverage)(/|$)') { continue }
        $file = Get-Item -LiteralPath (Join-Path $root $path) -Force -ErrorAction SilentlyContinue
        if (!$file -or $file.PSIsContainer -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { continue }
        $files++
        if ($path -match '^(?<source>(?:[\p{L}\p{N} ._-]+/)*src/(?:main|test)/java)/.+\.java$') {
            [void]$javaSourceRoots.Add($Matches.source)
        }
        if ($file.Extension -in '.slnx', '.sln') { $solutions.Add($path) }
        if ($file.Extension -in '.csproj', '.fsproj', '.vbproj') {
            $frameworks = @()
            $sdk = ''; $isTest = $false
            try {
                $xml = New-Object System.Xml.XmlDocument
                $xml.XmlResolver = $null
                $xml.Load($file.FullName)
                $sdk = $xml.DocumentElement.GetAttribute('Sdk')
                $isTest = $null -ne $xml.SelectSingleNode("//*[local-name()='IsTestProject' and normalize-space(.)='true'] | //*[local-name()='PackageReference' and @Include='Microsoft.NET.Test.Sdk']")
                $frameworks = @($xml.SelectNodes("//*[local-name()='TargetFramework' or local-name()='TargetFrameworks' or local-name()='TargetFrameworkVersion']") |
                    ForEach-Object { $_.InnerText -split ';' } |
                    ForEach-Object { $_.Trim() } |
                    Where-Object { $_ -and !($_.Contains('$(')) } |
                    Sort-Object -Unique)
            } catch [System.Xml.XmlException] {
                # Keep the project in the inventory when its framework cannot be read.
            }
            $technology = if ($sdk -like '*Microsoft.NET.Sdk.Web*') { 'ASP.NET Core' } else { '.NET' }
            $projects.Add([pscustomobject]@{
                name = $file.BaseName; path = $path; technology = $technology; frameworks = $frameworks; isTest = $isTest
            })
        }

        $language = $extensions[$file.Extension]
        if (!$language -or $file.Name -match '(\.g(\.i)?\.cs|\.designer\.cs|\.min\.(js|css))$') { continue }
        if (!$languages.ContainsKey($language)) {
            $languages[$language] = [pscustomobject]@{ name = $language; files = 0; lines = 0 }
        }
        $languages[$language].files++
        foreach ($line in [IO.File]::ReadLines($file.FullName)) {
            if (![string]::IsNullOrWhiteSpace($line)) { $languages[$language].lines++ }
        }
    }

    $breakdown = @($languages.Values | Sort-Object -Property @{Expression='lines'; Descending=$true}, name)
    $javaBuilds = @(
        $paths | Where-Object { $_ -match '^(?:[\p{L}\p{N} ._-]+/)*(?:pom\.xml|(?:build|settings)\.gradle(?:\.kts)?)$' -and
            $_ -notmatch '(^|/)(bin|obj|target|build|\.gradle|node_modules|vendor|dist|coverage)(/|$)' } |
            Sort-Object -Unique | Where-Object { Test-Path -LiteralPath (Join-Path $root $_) -PathType Leaf } |
            ForEach-Object {
                $tool = if ($_ -match '(^|/)pom\.xml$') { 'Maven' } else { 'Gradle' }
                [pscustomobject]@{ tool = $tool; path = $_ }
            }
    )
    $javaCommands = @(
        if ($javaBuilds.path -contains 'pom.xml') {
            if ($paths -contains 'mvnw.cmd' -and (Test-Path -LiteralPath (Join-Path $root 'mvnw.cmd') -PathType Leaf)) { '.\mvnw.cmd verify' }
            elseif ($paths -contains 'mvnw' -and (Test-Path -LiteralPath (Join-Path $root 'mvnw') -PathType Leaf)) { './mvnw verify' }
            else { 'mvn verify' }
        }
        if (@($javaBuilds | Where-Object { $_.path -notlike '*/*' -and $_.tool -eq 'Gradle' }).Count -and
            @($breakdown | Where-Object { $_.name -in 'Java', 'Kotlin' }).Count) {
            if ($paths -contains 'gradlew.bat' -and (Test-Path -LiteralPath (Join-Path $root 'gradlew.bat') -PathType Leaf)) { '.\gradlew.bat build' }
            elseif ($paths -contains 'gradlew' -and (Test-Path -LiteralPath (Join-Path $root 'gradlew') -PathType Leaf)) { './gradlew build' }
            else { 'gradle build' }
        }
    )
    $name = Split-Path $root -Leaf
    if ($solutions.Count -eq 1) { $name = [IO.Path]::GetFileNameWithoutExtension($solutions[0]) }
    elseif ($projects.Count -eq 1) { $name = $projects[0].name }
    [pscustomobject]@{
        name = $name
        files = $files
        sourceFiles = [int](($breakdown | Measure-Object -Property files -Sum).Sum)
        lines = [int](($breakdown | Measure-Object -Property lines -Sum).Sum)
        languages = $breakdown
        projects = @($projects.ToArray())
        solutions = @($solutions.ToArray())
        javaBuilds = $javaBuilds
        javaCommands = $javaCommands
        javaSourceRoots = @($javaSourceRoots | Sort-Object)
    }
}
