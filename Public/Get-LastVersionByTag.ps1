function Get-LastVersionByTag {
	[OutputType([Version])]
	Param(
		[string]$TagFilter
	)

	$AllVersionTags = git tag -l --sort=-version:refname $TagFilter
	if($AllVersionTags.Count -ge 1) {
		return [Version]($AllVersionTags[0])
	} else {
		return [Version]$null # there is no last version
	}
}