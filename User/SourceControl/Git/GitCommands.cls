Class User.SourceControl.Git.GitCommands Extends User.SourceControl.Git.Utils
{

ClassMethod CloneRepository(ByRef pSettings,tRepoFolder,tRepoURL,tGitPrefix, ByRef pOutput) As %Status
{
	s tCommandName = $O(pSettings(""))

	//Don't display clone command with password
	s tDisplay=0
	s tFolder = ##class(%File).ParentDirectoryName(tRepoFolder)
	s tSC = ##class(%File).CreateDirectoryChain(tRepoFolder)
	if 'tSC $$$ThrowOnError(..MakeError("unable to create folder: "_tRepoFolder))
	//For clone only, execute command at one level up from repofolder
	s tCommand = ..GitBinary()_" -C "_tFolder
	s tPassword = $REPLACE(pSettings(tCommandName),"""","\""")
	s tPassword = $ZCVT(tPassword,"O","URL")
	s tCommand = tCommand_" clone """_..RepoProtocol()_"://"_..UserName()_":"_tPassword_"@"_tRepoURL_""""
	
	s tSC = ..RunCmd(tCommand,.pOutput,tDisplay) $$$ThrowOnError(tSC)
	
	s pOutput($I(pOutput))="-------------------------------"
				
	s tCommand = tGitPrefix_" config user.name """_..PersonName()_""""
	s tSC = ..RunCmd(tCommand,.pOutput) $$$ThrowOnError(tSC)
	
	s tCommand = tGitPrefix_" config user.email """_..PersonEmail()_""""
	s tSC = ..RunCmd(tCommand,.pOutput) $$$ThrowOnError(tSC)
	
	s tCommand = tGitPrefix_" checkout master"
	s tSC = ..RunCmd(tCommand,.pOutput) $$$ThrowOnError(tSC)
	return tSC
}

}