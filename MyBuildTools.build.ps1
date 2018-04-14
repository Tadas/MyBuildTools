# Set-StrictMode -Version Latest

$ProjectName      = ($BuildRoot -split '\\')[-1]
$ArtifactPath     = "$BuildRoot\Artifacts"
$ArtifactFullPath = "$ArtifactPath\$ProjectName.zip"

task . <# Analyze, #> Test, SetVersion, BuildArtifact

# Installs other modules we might need and imports the build utils module itself
task InstallDependencies {
	Install-Module Pester -Scope CurrentUser
	# Install-Module PSScriptAnalyzer -Scope CurrentUser

	Import-Module "$BuildRoot\$ProjectName.psd1" -Force
}

# task Analyze InstallDependencies,{
# 	$scriptAnalyzerParams = @{
# 		Path = "$BuildRoot\"
# 		Severity = @('Error', 'Warning')
# 		Recurse = $true
# 		Verbose = $false
# 		ExcludeRule = 'PSAvoidUsingWriteHost'
# 	}
	
# 	$Results = Invoke-ScriptAnalyzer @scriptAnalyzerParams

# 	if ($Results) {
# 		$Results | Format-Table
# 		throw "One or more PSScriptAnalyzer errors/warnings where found."
# 	}
# }

task Test InstallDependencies,{
	$invokePesterParams = @{
		Path = '.\Tests\*'
		Strict = $true
		PassThru = $true
		Verbose = $false
		EnableExit = $false
	}

	# Publish Test Results as NUnitXml
	$testResults = Invoke-Pester @invokePesterParams;

	$numberFails = $testResults.FailedCount
	assert($numberFails -eq 0) ('Failed "{0}" unit tests.' -f $numberFails)
}

# Determines the next version and sets it in the appropriate places
task SetVersion InstallDependencies,{
	$LastVersion = Get-LastVersionByTag
	$LatestCommitMessages = Get-CommitsSinceVersionTag $LastVersion

	$script:NewVersion = Bump-Version -StartingVersion $LastVersion -CommitMessages $LatestCommitMessages
	$script:NewReleaseNotes = ""

	$ManifestFile = "$BuildRoot\$ProjectName.psd1"

	(Get-Content $ManifestFile) `
		-replace "ModuleVersion = .*", "ModuleVersion = '$NewVersion'" |
	Out-File -FilePath $ManifestFile -Encoding utf8
}

task Clean {
	if (Test-Path -Path $ArtifactPath) {
		Remove-Item "$ArtifactPath/*" -Recurse -Force
	}
	New-Item -ItemType Directory -Path $ArtifactPath -Force | Out-Null
}

# Builds an artifact into the artifact folder
task BuildArtifact Clean,{
	try {
		$TempPath = New-TemporaryFolder

		Get-ChildItem -File -Recurse $BuildRoot | Where-Object {
			(-not $_.FullName.Contains("\.vscode\")) -and
			(-not $_.FullName.Contains("\.git")) -and
			(-not $_.FullName.Contains("\Artifacts\")) -and
			(-not $_.FullName.Contains("\BuildTools\")) -and
			(-not $_.FullName.Contains("\Tests\")) -and
			(-not $_.FullName.EndsWith(".build.ps1"))

		} | ForEach-Object {
			$DestinationPath = [System.IO.Path]::Combine(
				$TempPath,
				$_.FullName.Substring($BuildRoot.Length + 1)
			)
			Write-Host "`tMoving $($_.FullName)`r`n`t`t to $DestinationPath`r`n"

			# Makes sure the path is available
			New-Item -ItemType File -Path $DestinationPath -Force | Out-Null
			Copy-Item -LiteralPath $_.FullName -Destination $DestinationPath -Force
		}
		Compress-Archive -Path "$TempPath\*" -DestinationPath "$ArtifactPath\$ProjectName.zip" -Verbose -Force

	} finally {
		if(Test-Path -PathType Container -LiteralPath $TempPath) { Remove-Item -Recurse $TempPath -Force }
	}
}

task CreateGithubReleaseAndUpload <# Analyze, #> Test, SetVersion, BuildArtifact, {
	$LastVersion = Get-LastVersionByTag
	$LatestCommitMessages = Get-CommitsSinceVersionTag $LastVersion
	$NewVersion = Bump-Version -StartingVersion $LastVersion -CommitMessages $LatestCommitMessages

	New-GithubRelease `
		-Uri          "https://api.github.com/repos/Tadas/$ProjectName/releases" `
		-NewVersion   $NewVersion `
		-ReleaseNotes $NewReleaseNotes `
		-Draft        $true `
		-PreRelease   $false `
		-ArtifactPath $ArtifactFullPath

}