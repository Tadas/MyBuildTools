$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.ps1', '.psd1'
Import-Module "$here\..\$sut" -Force

Describe "BuildTools" {
	BeforeEach {
		$TwoComponentLastVersion = [Version]"1.12"
		$LastVersion = [Version]"2.3.4.5"
	}

	Context "Hint parsing" {
		It "accepts no leading space 'blah+semver: minor'" {
			$NewVersion = Bump-Version -StartingVersion $LastVersion `
				-CommitMessages @(
					"Commit one",
					"Commit two",
					"Commit three",
					"Commit four+semver: minor",
					"Commit five"
				)
			$NewVersion | Should -Be "2.4.0.0"
		}

		It "accepts no middle space 'blah +semver:minor'" {
			$NewVersion = Bump-Version -StartingVersion $LastVersion `
				-CommitMessages @(
					"Commit one",
					"Commit two",
					"Commit three",
					"Commit four +semver:minor",
					"Commit five"
				)
			$NewVersion | Should -Be "2.4.0.0"
		}

		It "accepts no trailing space 'blah +semver: minorblah'" {
			$NewVersion = Bump-Version -StartingVersion $LastVersion `
				-CommitMessages @(
					"Commit one",
					"Commit two",
					"Commit three",
					"Commit four +semver: minorblahblah",
					"Commit five"
				)
			$NewVersion | Should -Be "2.4.0.0"
		}

		It "unknown hints gets ignored" {
			$NewVersion = Bump-Version -StartingVersion $LastVersion `
				-CommitMessages @(
					"Commit one +semver: fexfix",
					"Commit two +semver+semver:",
					"Commit three +semver: +semver:",
					"Commit four+semver: manor",
					"Commit five+semver: mansion"
				)
			$NewVersion | Should -Be "2.3.5.0"
		}
	}

	Context "Short version numbers" {
		It "expands a two component version" {
			$NewVersion = Bump-Version -StartingVersion $TwoComponentLastVersion `
				-CommitMessages @(
					"Commit one",
					"Commit two",
					"Commit three",
					"Commit four",
					"Commit five"
				)
				$NewVersion | Should -Be "1.12.1"
			
		}

		It "increments a two component version without expanding" {
			$NewVersion = Bump-Version -StartingVersion $TwoComponentLastVersion `
				-CommitMessages @(
					"Commit one",
					"Commit two +semver: minor",
					"Commit three",
					"Commit four",
					"Commit five"
				)
				$NewVersion | Should -Be "1.13"
			
		}
	}


	Context "Patch" {
		It "increments patch without any hints" {
			$NewVersion = Bump-Version -StartingVersion $LastVersion `
				-CommitMessages @(
					"Commit one",
					"Commit two",
					"Commit three",
					"Commit four",
					"Commit five"
				)
			$NewVersion | Should -Be "2.3.5.0"
		}

		It "increments patch once with a single 'patch' hint" {
			$NewVersion = Bump-Version -StartingVersion $LastVersion `
				-CommitMessages @(
					"Commit one",
					"Commit two",
					"Commit three +semver: patch",
					"Commit four",
					"Commit five"
				)
			$NewVersion | Should -Be "2.3.5.0"
		}

		It "increments patch once with an alternative 'fix' hint" {
			$NewVersion = Bump-Version -StartingVersion $LastVersion `
				-CommitMessages @(
					"Commit one",
					"Commit two",
					"Commit three +semver: fix",
					"Commit four",
					"Commit five"
				)
			$NewVersion | Should -Be "2.3.5.0"
		}

		It "increments patch once with multiple 'patch' hints" {
			$NewVersion = Bump-Version -StartingVersion $LastVersion `
				-CommitMessages @(
					"Commit one +semver: patch",
					"Commit two",
					"Commit three +semver: patch",
					"Commit four",
					"Commit five +semver: patch"
				)
			$NewVersion | Should -Be "2.3.5.0"
		}
	}



	Context "Minor" {
		It "increments minor once with a single 'minor' hint" {
			$NewVersion = Bump-Version -StartingVersion $LastVersion `
				-CommitMessages @(
					"Commit one",
					"Commit two",
					"Commit three",
					"Commit four +semver: minor",
					"Commit five"
				)
			$NewVersion | Should -Be "2.4.0.0"
		}

		It "increments minor once with an alternative 'feature' hint" {
			$NewVersion = Bump-Version -StartingVersion $LastVersion `
				-CommitMessages @(
					"Commit one",
					"Commit two",
					"Commit three",
					"Commit four +semver: feature",
					"Commit five"
				)
			$NewVersion | Should -Be "2.4.0.0"
		}

		It "increments minor once with multiple 'minor' hints" {
			$NewVersion = Bump-Version -StartingVersion $LastVersion `
				-CommitMessages @(
					"Commit one",
					"Commit two +semver: minor",
					"Commit three",
					"Commit four",
					"Commit five +semver: minor"
				)
			$NewVersion | Should -Be "2.4.0.0"
		}
	}



	Context "Major" {
		It "increments major once with a single 'major' hint" {
			$NewVersion = Bump-Version -StartingVersion $LastVersion `
				-CommitMessages @(
					"Commit one",
					"Commit two",
					"Commit three",
					"Commit four +semver: major",
					"Commit five"
				)
			$NewVersion | Should -Be "3.0.0.0"
		}

		It "increments major once with a 'breaking' hint" {
			$NewVersion = Bump-Version -StartingVersion $LastVersion `
				-CommitMessages @(
					"Commit one",
					"Commit two",
					"Commit three",
					"Commit four +semver: breaking",
					"Commit five"
				)
			$NewVersion | Should -Be "3.0.0.0"
		}

		It "increments major once with multiple 'major' hints" {
			$NewVersion = Bump-Version -StartingVersion $LastVersion `
				-CommitMessages @(
					"Commit one",
					"Commit two",
					"Commit three",
					"Commit four +semver: major",
					"Commit five +semver: major"
				)
			$NewVersion | Should -Be "3.0.0.0"
		}
	}



	Context "Hint supersedence" {
		It "'major' supersedes 'patch' hint" {
			$NewVersion = Bump-Version -StartingVersion $LastVersion `
				-CommitMessages @(
					"Commit one",
					"Commit two",
					"Commit three",
					"Commit four +semver: major",
					"Commit five +semver: patch"
				)
			$NewVersion | Should -Be "3.0.0.0"
		}

		It "'major' supersedes 'minor' hint" {
			$NewVersion = Bump-Version -StartingVersion $LastVersion `
				-CommitMessages @(
					"Commit one +semver: major",
					"Commit two",
					"Commit three",
					"Commit four +semver: minor",
					"Commit five"
				)
			$NewVersion | Should -Be "3.0.0.0"
		}

		It "'minor' supersedes 'patch' hint" {
			$NewVersion = Bump-Version -StartingVersion $LastVersion `
				-CommitMessages @(
					"Commit one",
					"Commit two +semver: minor",
					"Commit three +semver: patch",
					"Commit four",
					"Commit five"
				)
			$NewVersion | Should -Be "2.4.0.0"
		}
	}
}
