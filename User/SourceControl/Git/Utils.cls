Include %occStatus

/// <a href="http://www.readycomputing.com/">
/// <img src="http://www.readycomputing.com/images/header/headerLogo.png" alt="Ready Computing" >
/// </a> 
/// <br/><br/>
Class User.SourceControl.Git.Utils [ Abstract, ProcedureBlock ]
{

Parameter Storage = "^Git";

Parameter UseUDL = 1;

/// Extensions that can not be exported as UDL. XML will always be used.
Parameter NOTUDLEXTENSIONS = {$lb("hl7","dfi","lut")};

Parameter InstallNamespace = "HSCUSTOM";

Parameter ReleaseBranchBase = "int/sqa2c";

Parameter RepoProtocol = "https";

Parameter RepoURL = "github.com/msimp019/vdifbuild-prototype.git";

/// If equals to 0 all tortoise-git calls are asynchronous<br/>
/// Otherwise calls are synchronous and import is automatically executed after git calls.
Parameter IsSYNC = 0;

/// Git menu commands
Parameter GitMenuItems = ",Pull,Clone Repository,Status,Switch to Branch,Load Branch,";

/// Git menu commands
Parameter GitDevelopMenuItems = ",Pull,Clone Repository,Status,Switch to Branch,Load Branch,Re-create Team Branch,Create Release Branch,";

/// Menu Items that show, but are only enabled when on a Feature branch.
Parameter GitFeatureMenuItems = ",Commit,Push,Pull,Pull from int/dev,Pull from Team,Diff with Team,Request Merge to Team Branch,";

/// Menu Items that show, but are only enabled when on a Team branch.
Parameter GitTeamMenuItems = ",Pull,Pull from int/dev,Create Feature Branch,Re-create Team Branch,Request Merge to int/dev Branch,";

/// Menu Items that show, but are only enabled when on a Team branch.
Parameter GitReleaseMenuItems = ",Pull,Create Bugfix Branch,";

Parameter GitBugfixMenuItems = ",Commit,Push,Pull,Request Merge to Release Branch,";

/// RC: Removed %Blame,
Parameter GitContextMenuItems = ",";

/// This method will allow for an extended global reference to the global which store configuration settings
/// By default, the database the global belongs to is defined by class parameter to be HSCUSTOM
/// However, this may be overridden on a namespace basis to use different storage
/// This is necessary in order for Studio to have different settings in a specific namespace
/// Note that only the specific namespace in which the setting is set may have a custom install namespace value
/// For all other namespaces, the default will be HSCUSTOM.
ClassMethod InstallNamespaceStorage() As %String [ CodeMode = expression ]
{
$Replace(..#Storage,"^","^["""_$G(@..#Storage@("%user",$USERNAME,"%installNamespace"),..#InstallNamespace)_"""]")
}

/// Returns root temp folder
ClassMethod RepoFolder() As %String [ CodeMode = expression ]
{
$G(@..InstallNamespaceStorage()@("%user",$USERNAME,"%repositoryFolder"))
}

/// Returns root temp folder
ClassMethod IsLoadBranchActive() As %String [ CodeMode = expression ]
{
$G(@..InstallNamespaceStorage()@("%user",$USERNAME,"%loadBranchActive"))
}

/// Returns stored repository username
ClassMethod UserName() As %String [ CodeMode = expression ]
{
$G(@..InstallNamespaceStorage()@("%user",$USERNAME,"%userName"))
}

ClassMethod PersonName() As %String [ CodeMode = expression ]
{
$G(@..InstallNamespaceStorage()@("%user",$USERNAME,"%personName"))
}

ClassMethod PersonEmail() As %String [ CodeMode = expression ]
{
$G(@..InstallNamespaceStorage()@("%user",$USERNAME,"%personEmail"))
}

ClassMethod TeamBranch() As %String [ CodeMode = expression ]
{
$G(@..InstallNamespaceStorage()@("%user",$USERNAME,"%teamBranch"))
}

ClassMethod ReleaseBranchBase() As %String [ CodeMode = expression ]
{
$G(@..InstallNamespaceStorage()@("%user",$USERNAME,"%releaseBranchBase"))
}

/// Returns root temp folder
ClassMethod RepoURL() As %String [ CodeMode = expression ]
{
$G(@..InstallNamespaceStorage()@("%user",$USERNAME,"%repoURL"))
}

/// Returns root temp folder
ClassMethod RepoAPI() As %String [ CodeMode = expression ]
{
"api."_$P(..RepoURL(),"/",1)_"/repos/"_$P(..RepoURL(),"/",2)_"/"_$P($P(..RepoURL(),"/",3),".",1)_"/"
}

/// Returns root temp folder
ClassMethod RepoBaseFolder() As %String [ CodeMode = expression ]
{
$G(@..InstallNamespaceStorage()@("%user",$USERNAME,"%repoBaseFolder"))
}

/// Returns root temp folder
ClassMethod RepoName() As %String [ CodeMode = expression ]
{
$P($P(..RepoURL(),"/",$L(..RepoURL(),"/")),".",1)
}

/// Returns root temp folder
ClassMethod RepoProtocol() As %String [ CodeMode = expression ]
{
$G(@..InstallNamespaceStorage()@("%user",$USERNAME,"%repoProtocol"))
}

/// Returns default git command prefix
ClassMethod GitCmdPrefix() As %String [ CodeMode = expression ]
{
..GitBinary()_" -C "_..RepoFolder()
}

/// 8012 because this error has corresponding error message
ClassMethod MakeError(msg As %String) As %Status [ CodeMode = expression, Private ]
{
$$$ERROR(8012,"Git",msg)
}

ClassMethod NeedSettings() As %Boolean [ CodeMode = expression ]
{
(..RepoFolder() = "") ||  (..RepoURL() = "") ||  (..RepoProtocol() = "") ||  (..UserName() = "")
}

ClassMethod InstallNamespace() As %String [ CodeMode = expression ]
{
$G(@..InstallNamespaceStorage()@("%user",$USERNAME,"%installNamespace"))
}

/// Returns path for git binary if set, otherwise "git"
ClassMethod GitBinary() As %String [ CodeMode = expression ]
{
$G(@..InstallNamespaceStorage()@("%user",$USERNAME,"%gitBinaryLocation"),"git")
}

ClassMethod CurrentBranch() As %String
{
	s tCurrentBranch=""
	s tCommand = ..GitCmdPrefix()
	s tCommand = tCommand_" branch"
	s tDisplay = 0
	s tSC = ..RunCmd(tCommand,.tOutput,tDisplay)
	if $$$ISERR(tSC) Quit "error"
	For i=1:1:tOutput {
		s tOutputLine = tOutput(i)
		if $E(tOutputLine,1,1) = "*" {
			s tCurrentBranch=$E(tOutputLine,3,*)
		}		
	}
	Quit tCurrentBranch
}

ClassMethod BranchList(pIncludeReleaseBranches As %Boolean = 0, pIncludeRemote As %Boolean = 1) As %String
{
	//Always include develop and team branches
	s tTeamBranch = ..TeamBranch()
	s tBranchList=",int/dev,"_tTeamBranch
	
	//Get a list of feature branches both local and remote as per paremeter
	s tCommand = ..GitCmdPrefix()
	s tCommand = tCommand_" branch"
	If pIncludeRemote s tCommand = tCommand_" --list -a"
	s tDisplay = 0
	s tSC = ..RunCmd(tCommand,.tOutput,tDisplay)
	if $$$ISERR(tSC) Quit "error"
	For i=1:1:tOutput {
		s tBranch = $REPLACE($E(tOutput(i),3,*),"remotes/origin/","")
		if tBranchList_"," '[ (tBranch_",") {
			if $E(tBranch,1,8)="feature/" {
				//only list feature branches created from the users team branch
				if $P(tBranch,"/",2) = $P(tTeamBranch,"/",2) {
					s tBranchList=tBranchList_","_tBranch
				}
			}
			if (pIncludeReleaseBranches && ($E(tBranch,1,8)="release/")) {
				s tBranchList=tBranchList_","_tBranch
			}
			if ($E(tBranch,1,7)="bugfix/") {
				s tBranchList=tBranchList_","_tBranch
			}
		}
	}
	if $$$ISERR(tSC) Quit "error"
	Quit tBranchList
}

ClassMethod CommitSelectList(ByRef pDisplayList As %String = "", ByRef pValueList As %String = "", pSourceBranch As %String = "int/dev", pIntegrationBranch As %String = "") As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	#dim tReturnList = ""
	
	Try {
		
		Set:pIntegrationBranch="" pIntegrationBranch = ..ReleaseBranchBase()
		
		s tCommand = ..GitCmdPrefix()
		s tCommand = tCommand_" checkout "_pIntegrationBranch
		s tDisplay = 0
		s tSC = ..RunCmd(tCommand,.tOutput,tDisplay)
		$$$ThrowOnError(tSC)
		
		//Kill tOutput
		s tCommand = ..GitCmdPrefix()
		s tCommand = tCommand_" pull --rebase"
		s tSC = ..RunCmd(tCommand,.tOutput,tDisplay)
		$$$ThrowOnError(tSC)

		//Kill tOutput
		s tCommand = ..GitCmdPrefix()
		s tCommand = tCommand_" checkout "_pSourceBranch
		s tDisplay = 0
		s tSC = ..RunCmd(tCommand,.tOutput,tDisplay)
		$$$ThrowOnError(tSC)
		
		//Kill tOutput
		s tCommand = ..GitCmdPrefix()
		s tCommand = tCommand_" pull --rebase"
		s tSC = ..RunCmd(tCommand,.tOutput,tDisplay)
		$$$ThrowOnError(tSC)

		//Kill tOutput
		s tCommand = ..GitCmdPrefix()
		s tCommand = tCommand_" diff --name-only HEAD "_pIntegrationBranch
		s tSC = ..RunCmd(tCommand,.tOutput,tDisplay)
		$$$ThrowOnError(tSC)
		
		
		Kill tOutput
		s tCommand = ..GitCmdPrefix()
		s tCommand = tCommand_" log --oneline --cherry-pick --right-only --no-decorate "_pIntegrationBranch_"..."_pSourceBranch
		s tSC = ..RunCmd(tCommand,.tOutput,tDisplay)
		$$$ThrowOnError(tSC)

		for i=1:1:tOutput {
			s tValue = $P(tOutput(i)," ",1)
			s tDisplay = $P(tOutput(i)," ",2,$LENGTH(tOutput(i)," "))_" ("_tValue_")"
			s pValueList=pValueList_$S(pValueList="":"",1:",")_tValue
			s pDisplayList=pDisplayList_$S(pDisplayList="":"",1:",")_tDisplay
		}
		
	} catch e {
		s tSC = e.AsStatus()
	}
	Quit tSC
}

ClassMethod UpdateSettings(ByRef settings) As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
		//Configure settings storage first
	    s tTempInstallNamespaceStorage = $Replace(..#Storage,"^","^["""_$G(settings("installNamespace"),..#InstallNamespace)_"""]")
	    s @tTempInstallNamespaceStorage@("%user",$USERNAME,"%installNamespace") = $G(settings("installNamespace"),..#InstallNamespace)
	    
	    // set environment properties - use class parameters if not supplied in settings array
	    s @..InstallNamespaceStorage()@("%user",$USERNAME,"%releaseBranchBase") = $G(settings("releaseBranchBase"),..#ReleaseBranchBase)
		s @..InstallNamespaceStorage()@("%user",$USERNAME,"%repoURL") = $G(settings("repoURL"),..#RepoURL)
	    s @..InstallNamespaceStorage()@("%user",$USERNAME,"%repoProtocol") = $G(settings("repoProtocol"),..#RepoProtocol)
	    
	    // set user properties - username and password to start with.
	    s @..InstallNamespaceStorage()@("%user",$USERNAME,"%userName") = settings("userName")
	    s @..InstallNamespaceStorage()@("%user",$USERNAME,"%personName") = settings("personName")
	    s @..InstallNamespaceStorage()@("%user",$USERNAME,"%personEmail") = settings("personEmail")
	    s @..InstallNamespaceStorage()@("%user",$USERNAME,"%teamBranch") = settings("teamBranch")
	    s @..InstallNamespaceStorage()@("%user",$USERNAME,"%repoBaseFolder") = ##class(%File).NormalizeDirectory(settings("repoBaseFolder"))
	    
	    //Build user's repo folder using the base folder, username, and repository name
	    s tFolder = ##class(%File).NormalizeDirectory(..RepoBaseFolder()_$USERNAME_"\"_..RepoName())
	    s @..InstallNamespaceStorage()@("%user",$USERNAME,"%repositoryFolder") = tFolder
		
		//Set git install location
		 s @..InstallNamespaceStorage()@("%user",$USERNAME,"%gitBinaryLocation") = settings("gitBinaryLocation")
		
	} catch e {
		s tSC = e.AsStatus()
	}
	Quit tSC
}

ClassMethod HandleDialogue(ByRef pSettings, ByRef pOutput) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
		
		s tCommandName = $O(pSettings(""))
		
		s tCommand = ..GitCmdPrefix()
		
		if tCommandName = "Clone Repository" {
			
			//Don't display clone command with password
			s tDisplay=0
			
			s tFolder = ##class(%File).ParentDirectoryName(..RepoFolder())
			s tRepoFolder = ..RepoFolder()
			s tSC = ##class(%File).CreateDirectoryChain(tRepoFolder)
			if 'tSC $$$ThrowOnError(..MakeError("unable to create folder: "_tRepoFolder))
			
			//For clone only, execute command at one level up from repofolder
			s tCommand = ..GitBinary()_" -C "_tFolder
			s tPassword = $REPLACE(pSettings(tCommandName),"""","\""")
			s tPassword = $ZCVT(tPassword,"O","URL")
			s tCommand = tCommand_" clone """_..RepoProtocol()_"://"_..UserName()_":"_tPassword_"@"_..RepoURL()_""""
			
			s tSC = ..RunCmd(tCommand,.pOutput,tDisplay) $$$ThrowOnError(tSC)
			
			s pOutput($I(pOutput))="-------------------------------"
						
			s tCommand = ..GitCmdPrefix()
			s tCommand = tCommand_" config user.name """_..PersonName()_""""
			s tSC = ..RunCmd(tCommand,.pOutput) $$$ThrowOnError(tSC)
			
			s tCommand = ..GitCmdPrefix()
			s tCommand = tCommand_" config user.email """_..PersonEmail()_""""
			s tSC = ..RunCmd(tCommand,.pOutput) $$$ThrowOnError(tSC)
			
			s tCommand = ..GitCmdPrefix()
			s tCommand = tCommand_" checkout master"
			
		} elseif tCommandName = "Status" {
			s tCommand = tCommand_" status"
		} elseif tCommandName="Switch to Branch" {
			s tCommand = tCommand_" checkout "_pSettings(tCommandName)
		} elseif tCommandName = "ListDiff" {
			//ListDiff compares the current HEAD (last commit on current branch) to a target branch.  Used to evaluate completeness of release branch.
			s tCommand = tCommand_" diff --name-only HEAD "_pSettings(tCommandName)
		} elseif tCommandName = "Commit" {
			s tCommand = tCommand_" commit -m """_$TR(pSettings(tCommandName),"'","")_""""
	//disabling the auto push at this time
#;			s tSC = ..RunCmd(tCommand,.pOutput) $$$ThrowOnError(tSC)
#;			s pOutput($I(pOutput))="-------------------------------"
#;			s tCommand = ..GitCmdPrefix()
#;			s tCommand = tCommand_" pull --rebase"
#;			s tSC = ..RunCmd(tCommand,.pOutput) $$$ThrowOnError(tSC)
#;			s pOutput($I(pOutput))="-------------------------------"
#;			s tCommand = ..GitCmdPrefix()
#;			s tCommand = tCommand_" push"
		} elseif tCommandName = "Pull" {
			s tCommand = tCommand_" pull --rebase"
		} elseif tCommandName = "Add" {
			s tCommand = tCommand_" add ."
		} elseif tCommandName = "Push" {
			s tCommand = tCommand_" push"
		} elseif tCommandName = "Create Feature Branch" {
			//consider adding checkbox to allow push to be optional, but currently it is default behavior
			//should add syntax checking for branch names
			s tBranchName = $TR(pSettings(tCommandName)," /","-")
			if '$FIND(tBranchName,"feature/") s tBranchName = $REPLACE(##class(User.SourceControl.Git.Utils).CurrentBranch(),"team-dev/","feature/")_"/"_tBranchName
			s tCreateBranchCommand = tCommand_" checkout -b "_tBranchName
			s tSC = ..RunCmd(tCreateBranchCommand,.pOutput) $$$ThrowOnError(tSC)
			s tCommand = tCommand_" push --set-upstream origin "_tBranchName
		} elseif tCommandName = "Create Release Branch" {
			//switch to release base branch and pull it, in prep for diff with feature branch
			//The release base branch is the int branch for the first target environment for deployment
			s tSwitchCommand = tCommand_" checkout "_..ReleaseBranchBase()
			s tSC = ..RunCmd(tSwitchCommand,.pOutput) $$$ThrowOnError(tSC)
			
			//Pull just to ensure the release branch base is up to date locally before creating release branch
			s tPullCommand = tCommand_" pull --rebase"
			s tSC = ..RunCmd(tPullCommand,.pOutput) $$$ThrowOnError(tSC)
			
			//should add syntax checking for branch names
			s tBranchName = $TR($P(pSettings(tCommandName),"^",1)," /","-")
			if '$FIND(tBranchName,"release/") s tBranchName = "release/"_tBranchName
			
			s tCreateBranchCommand = tCommand_" checkout -b "_tBranchName
			s tSC = ..RunCmd(tCreateBranchCommand,.pOutput) $$$ThrowOnError(tSC)
			
			s tCommitList = $P(pSettings(tCommandName),"^",2)
			s tCherryPickCommits = tCommand_" cherry-pick -x "_$TR(tCommitList,","," ")
			s tSC = ..RunCmd(tCherryPickCommits,.pOutput) $$$ThrowOnError(tSC)
						
			s tCommand = tCommand_" push --set-upstream origin "_tBranchName
		} elseif tCommandName = "Create Bugfix Branch" {
			//consider adding checkbox to allow push to be optional, but currently it is default behavior
			//should add syntax checking for branch names
			s tBranchName = $TR(pSettings(tCommandName)," /","-")
			if '$FIND(tBranchName,"bugfix/") s tBranchName = $REPLACE(##class(User.SourceControl.Git.Utils).CurrentBranch(),"release/","bugfix/")_"/"_tBranchName
			s tCreateBranchCommand = tCommand_" checkout -b "_tBranchName
			s tSC = ..RunCmd(tCreateBranchCommand,.pOutput) $$$ThrowOnError(tSC)
			s tCommand = tCommand_" push --set-upstream origin "_tBranchName
		} elseif tCommandName = "Pull from int/dev" {

			//Pull just to ensure the release branch base is up to date locally before creating release branch
			s tPullCommand = tCommand_" pull --rebase"
			s tSC = ..RunCmd(tPullCommand,.pOutput) $$$ThrowOnError(tSC)

			s tCommand = tCommand_" merge origin/int/dev"
		} elseif tCommandName = "Pull from Team" {
			
			//Pull just to ensure the release branch base is up to date locally before creating release branch
			s tPullCommand = tCommand_" pull --rebase"
			s tSC = ..RunCmd(tPullCommand,.pOutput) $$$ThrowOnError(tSC)

			s tCommand = tCommand_" merge origin/"_..TeamBranch()
		} elseif tCommandName = "Diff with Team" {
			
			s tCurrentBranch = ..CurrentBranch()
			
			//switch to team branch and pull it, in prep for diff with feature branch
			s tSwitchCommand = tCommand_" checkout "_..TeamBranch()
			s tSC = ..RunCmd(tSwitchCommand,.pOutput) $$$ThrowOnError(tSC)
			
			s tPullCommand = tCommand_" pull --rebase"
			s tSC = ..RunCmd(tPullCommand,.pOutput) $$$ThrowOnError(tSC)
			
			//Now switch back to do the Diff
			s tSwitchCommand = tCommand_" checkout "_tCurrentBranch
			s tSC = ..RunCmd(tSwitchCommand,.pOutput) $$$ThrowOnError(tSC)
			s pOutput($I(pOutput))="-------------------------------"
			s pOutput($I(pOutput))=""
			s pOutput($I(pOutput))="Changed files on feature branch compared to team branch:"
			s pOutput($I(pOutput))=""
			//Diff compares the current HEAD (last commit on current branch) to a target branch.  Used to evaluate completeness of release branch.
			s tCommand = tCommand_" diff --name-only HEAD "_..TeamBranch()

		} elseif tCommandName = "Request Merge to Team Branch" {
			//First, get the current branch
			s tCurrentBranch = ..CurrentBranch()
			
			//Push the feature branch to remote
			s tPushCommand = tCommand_" push"
			s tSC = ..RunCmd(tPushCommand,.pOutput) $$$ThrowOnError(tSC)
			
			//Call the github API to create the pull request
			s tPullRequestType = "FeatureMerge"
			s tSC = ..CreatePullRequest(tPullRequestType, .pOutput) $$$ThrowOnError(tSC)			
			
			//Now checkout the team branch in order to delete the local feature branch
			s tCheckoutTargetBranch = tCommand_" checkout "_..TeamBranch()
			s tSC = ..RunCmd(tCheckoutTargetBranch,.pOutput) $$$ThrowOnError(tSC)

			//Now delete the feature branch using -D to force the delete
			s tCommand = tCommand_" branch -D "_tCurrentBranch
			
		} elseif tCommandName = "Request Merge to Release Branch" {
			//First, get the current branch
			s tCurrentBranch = ..CurrentBranch()
			
			s tReleaseBranch = $P($REPLACE(tCurrentBranch,"bugfix/","release/"),"/",1,2)
			
			//Push the bugfix branch to remote
			s tPushCommand = tCommand_" push"
			s tSC = ..RunCmd(tPushCommand,.pOutput) $$$ThrowOnError(tSC)

			//Call the github API to create the pull request
			s tPullRequestType = "BugFixMerge"
			s tSC = ..CreatePullRequest(tPullRequestType, .pOutput) $$$ThrowOnError(tSC)			

			//Now checkout the release branch in order to delete the local bug fix branch
			s tCheckoutTargetBranch = tCommand_" checkout "_tReleaseBranch
			s tSC = ..RunCmd(tCheckoutTargetBranch,.pOutput) $$$ThrowOnError(tSC)

			//Now delete the bug fix branch using -D to force the delete
			s tCommand = tCommand_" branch -D "_tCurrentBranch
			
		} elseif tCommandName = "Request Merge to int/dev Branch" {
			//First, get the current branch
			s tCurrentBranch = ..CurrentBranch()
			
			//Push the team branch to remote
			s tPushCommand = tCommand_" push"
			s tSC = ..RunCmd(tPushCommand,.pOutput) $$$ThrowOnError(tSC)

			//Call the github API to create the pull request
			s tPullRequestType = "TeamMerge"
			s tSC = ..CreatePullRequest(tPullRequestType, .pOutput) $$$ThrowOnError(tSC)			

			//Now checkout the int/dev branch in order to delete the local team branch
			s tCheckoutTargetBranch = tCommand_" checkout int/dev"
			s tSC = ..RunCmd(tCheckoutTargetBranch,.pOutput) $$$ThrowOnError(tSC)

			//Now delete the team branch using -D to force the delete
			s tCommand = tCommand_" branch -D "_tCurrentBranch
			
		} elseif tCommandName = "Re-create Team Branch" {
			
			//Checkout the team branch to delete it
			s tCheckoutTeamBranch = tCommand_" checkout "_..TeamBranch()
			s tSC = ..RunCmd(tCheckoutTeamBranch,.pOutput) $$$ThrowOnError(tSC)

 			//Now delete the team branch from remote
			s tRemoteDeleteCommand = tCommand_" push --delete origin "_..TeamBranch()
			s tSC = ..RunCmd(tRemoteDeleteCommand,.pOutput) $$$ThrowOnError(tSC)

			//Now checkout the team branch in order to delete the local team branch
			s tCheckoutDevelopBranch = tCommand_" checkout int/dev"
			s tSC = ..RunCmd(tCheckoutDevelopBranch,.pOutput) $$$ThrowOnError(tSC)
			
			//Pull int/dev to ensure have latest before recreating the team branch
			s tPullCommand = tCommand_" pull --rebase"
			s tSC = ..RunCmd(tPullCommand,.pOutput) $$$ThrowOnError(tSC)

			//Now delete the team branch using -D to force the delete
			s tDeleteTeamBranch = tCommand_" branch -D "_..TeamBranch()
			s tSC = ..RunCmd(tDeleteTeamBranch,.pOutput) $$$ThrowOnError(tSC)
			
			s tCreateBranchCommand = tCommand_" checkout -b "_..TeamBranch()
			s tSC = ..RunCmd(tCreateBranchCommand,.pOutput) $$$ThrowOnError(tSC)
			
			s tCommand = tCommand_" push --set-upstream origin "_..TeamBranch()
			
		} elseif tCommandName = "Load Branch" {
			//a git command is expected, so just set it to status
			s tCommand = tCommand_" status"
			
			s tSC = ..LoadBranchLocal(.pOutput) $$$ThrowOnError(tSC)
			
		}
		
		s tSC = ..RunCmd(tCommand,.pOutput) $$$ThrowOnError(tSC)
				
	} catch e {
		//s tSC = e.AsStatus()
		s pOutput(1)="Command could not be completed due to error: "_e.DisplayString()
	}
	Quit tSC
}

ClassMethod GitCommand(commandName As %String, itemName As %String = "") As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
		
		s tDisplay = 1
		s tCommand = ..GitCmdPrefix()
	
		if commandName="add" {
			s tCommand = tCommand_" add "_itemName
		} elseif commandName="remove" {
			s tCommand = tCommand_" rm -f "_itemName
		} elseif commandName="pull" {
			//Pull before every export to always get latest updates from other developers in order to avoid conflicts when pushing.
			s tCommand = tCommand_" pull"
		} elseif commandName="checkout" {
			//Pull before every export to always get latest updates from other developers in order to avoid conflicts when pushing.
			s tCommand = tCommand_" checkout "_itemName
		}

		s tSC = ..RunCmd(tCommand,.tOutput,tDisplay) $$$ThrowOnError(tSC)
		
		For i=1:1:tOutput {
			w !,tOutput(i)
		}
		w !
		
	} catch e {
		s tSC = e.AsStatus()
	}
	Quit tSC
}

/// Run a shell command and report any error message, return <var>output</var> with 
/// lines as subscripts of the array if <var>stream</var> is false (the default) but if
/// <var>stream</var> is true then we will return the output as a stream to be read by the caller.
ClassMethod RunCmd(cmd As %String, ByRef output As %String, display As %Boolean = 1, stream As %Boolean = 0) As %Status
{
	Set sc=$$$OK,text=cmd
	set output=$G(output)+0 //This is to initialize the variable if it doesn't exist, but not increment it if it does exist
	If display Write !,"CMD: ",text
	
	Set outputfile=##class(%File).TempFilename("out")
	Set rc=$zf(-1,cmd_" 2> """_outputfile_""""_" 1>&2")
	Set outputstream=##class(%FileCharacterStream).%New()
	Set outputstream.Filename=outputfile

	If stream {
		Set output=outputstream,outputstream.RemoveOnClose=1
	} Else {
		If outputstream.Size>0 {
			Do outputstream.Rewind()
			While 'outputstream.AtEnd {
				Set line=outputstream.ReadLine()
				Set output($increment(output))=line
			}
		}
		Do outputstream.Clear()
	}
	Quit sc
}

ClassMethod IsMenuGitCommand(menuItemName As %String) As %Boolean [ CodeMode = expression ]
{
$F(..#GitMenuItems, ","_menuItemName_",") > 0
}

ClassMethod IsDevelopMenuGitCommand(menuItemName As %String) As %Boolean [ CodeMode = expression ]
{
$F(..#GitDevelopMenuItems, ","_menuItemName_",") > 0
}

ClassMethod IsFeatureMenuGitCommand(menuItemName As %String) As %Boolean [ CodeMode = expression ]
{
$F(..#GitFeatureMenuItems, ","_menuItemName_",") > 0
}

ClassMethod IsReleaseMenuGitCommand(menuItemName As %String) As %Boolean [ CodeMode = expression ]
{
$F(..#GitReleaseMenuItems, ","_menuItemName_",") > 0
}

ClassMethod IsBugfixMenuGitCommand(menuItemName As %String) As %Boolean [ CodeMode = expression ]
{
$F(..#GitBugfixMenuItems, ","_menuItemName_",") > 0
}

ClassMethod IsTeamMenuGitCommand(menuItemName As %String) As %Boolean [ CodeMode = expression ]
{
$F(..#GitTeamMenuItems, ","_menuItemName_",") > 0
}

ClassMethod IsContextMenuGitCommand(menuItemName As %String) As %Boolean [ CodeMode = expression ]
{
$F(..#GitContextMenuItems, ","_menuItemName_",") > 0
}

ClassMethod UserAction(InternalName As %String, MenuName As %String, ByRef Target As %String, ByRef Action As %String, ByRef Reload As %Boolean) As %Status
{
    #dim folder As %String = ..RepoFolder()
    #dim menuName As %String = $piece(MenuName,",")
    #dim menuItemName As %String = $piece(MenuName,",",2)
    #dim ec As %Status = $$$OK
    
    if (menuName = "Source Control Main Menu") {
        if (menuItemName = "Settings") {
            s Action = 2
            #dim defNamespace As %String = ..InstallNamespace()
            Set Target="/csp/healthshare/"_$ZCVT($NAMESPACE,"L")_"/User.SourceControl.Git.Setting.cls"
        } elseif ..IsMenuGitCommand(menuItemName) || ..IsFeatureMenuGitCommand(menuItemName) || ..IsReleaseMenuGitCommand(menuItemName) || ..IsTeamMenuGitCommand(menuItemName) || ..IsBugfixMenuGitCommand(menuItemName) {
            s Action = 2
            s Target = "/csp/healthshare/"_$ZCVT($NAMESPACE,"L")_"/User.SourceControl.Git.Dialogue.cls?UserAction="_menuItemName
        } elseif (menuItemName = "Create Release Branch") {
            s Action = 2
            s Target = "/csp/healthshare/"_$ZCVT($NAMESPACE,"L")_"/User.SourceControl.Git.Dialogue.cls?UserAction="_menuItemName
       	} elseif (menuItemName = "Resolve Merge Conflicts") {
            s Action = 2
            s Target = "/csp/healthshare/"_$ZCVT($NAMESPACE,"L")_"/User.SourceControl.Git.MergeConflicts.cls"        
        }
    }elseif (menuName [ "Context") {
        if (menuItemName = "Add To") {
            s ec = ..AddToSourceControl(InternalName)
        } elseif (menuItemName = "Add To Release") {
            s ec = ..AddToSourceControl(InternalName)
        } elseif (menuItemName = "Remove From") {
            s ec = ..RemoveFromSourceControl(InternalName)
        } elseif (menuItemName = "Check Out") {
            s ec = ..CheckOut(InternalName)
        } elseif (menuItemName = "Check In") {
            s ec = ..CheckIn(InternalName)
        } elseif ..IsContextMenuGitCommand(menuItemName) {
            s Action = 3
            //Currently there are no context menu git commands other than Add and Remove which are handled separately
            //s Target = ..GitCommand(command, InternalName)
        }
        
    }
#;    if (..#IsSYNC = 1) && (Action = 3) {
#;        s Action = 0
#;        d $zf(-1, "set HOME="_..RepoFolder()_"&"_Target)
#;    }

    Quit ec
}

ClassMethod AfterUserAction(Type As %Integer, Name As %String, InternalName As %String, Answer As %Integer, Msg As %String = "", ByRef Reload As %Boolean) As %Status
{
    Quit $$$OK
}

ClassMethod IsNamespaceInGit() As %Boolean [ CodeMode = expression ]
{
##class(%File).Exists(..RepoFolder()_".git")
}

/// Only returns internal name if files was exported via source control which sets the ExternNames subscript
ClassMethod InternalName(name As %String) As %String [ CodeMode = expression ]
{
$G(@..InstallNamespaceStorage()@("ExternalNames",name))
}

ClassMethod ExternalName(name As %String) As %String
{
    s InternalName = name
    
    If $System.Version.GetOS()="Windows" {
	    s tBackslash = "\"
	    s name = $TR(name,"/", tBackslash)
    } else {
	    s tBackslash = "/"
    }
    
    //lower case for extensions
    #dim extension As %String = $ZCVT($P(name,".",$L(name,".")),"L")
    s $P(name,".",$L(name,".")) = extension
    
    //Replace dots in class name with slashes to create subfolders, except the last dot which is the extension
    s name = $TR( $P(name,".", 1, $L(name,".")-1), ".", tBackslash)_"."_extension
    
    //remove the leading backslash from csp files
    if $E(name, 1) = tBackslash {
        s $E(name, 1) = ""
    }

	// put all items into a subfolder 
	s name = tBackslash_name

    s name = $TR(name," *?","___") //_".xml"
    
    s @..InstallNamespaceStorage()@("ExternalNames",name) = InternalName
    
    Quit name
}

ClassMethod AddToSourceControl(InternalName As %String) As %Status
{
    #dim i, item, sc
    #dim tSC As %Status = $$$OK
    For i = 1:1:$L(InternalName, ",") {
        Set item = $P(InternalName, ",", i)
        Set @..InstallNamespaceStorage()@("items", item) = ""
        Set sc =  ..ExportItem(item)
        Set tSC = $$$ADDSC(sc, tSC)
        Set sc =  ..CheckOutItem(item)
        Set tSC = $$$ADDSC(sc, tSC)

    }
    Quit tSC
}

ClassMethod IsCheckedOut(InternalName As %String, ByRef pUserName As %String = "") As %String
{
	#dim isCheckedOut As %Boolean = 0
	
	Set isCheckedOut = $D(@..InstallNamespaceStorage()@("locks",InternalName)) > 0
	
	if isCheckedOut Set pUserName = @..InstallNamespaceStorage()@("locks",InternalName)
	
	Quit isCheckedOut
}

ClassMethod CheckOut(InternalName As %String) As %Status
{
    #dim i, item, sc
    #dim tSC As %Status = $$$OK
    For i = 1:1:$L(InternalName, ",") {
        Set item = $P(InternalName, ",", i)
        Set sc =  ..CheckOutItem(item)
        Set tSC = $$$ADDSC(sc, tSC)

    }
    Quit tSC
}

ClassMethod CheckOutItem(InternalName As %String) As %Status
{
    Set @..InstallNamespaceStorage()@("locks", InternalName) = $USERNAME
    Quit $$$OK
}

ClassMethod CheckIn(InternalName As %String) As %Status
{
    #dim i, item, sc
    #dim tSC As %Status = $$$OK
    For i = 1:1:$L(InternalName, ",") {
        Set item = $P(InternalName, ",", i)
        Set sc =  ..CheckInItem(item)
        Set tSC = $$$ADDSC(sc, tSC)

    }
    Quit tSC
}

ClassMethod CheckInItem(InternalName As %String) As %Status
{
    Kill @..InstallNamespaceStorage()@("locks", InternalName)
    Quit $$$OK
}

ClassMethod IsStaged(InternalName As %String) As %String
{
	#dim tSC As %Status = $$$OK
	#dim tReturn As %Boolean = 0
	s tExternalName = ..ExternalName(InternalName)
	if "/\" [ $E(tExternalName,1,1) s tExternalName = $E(tExternalName,2,*)
	s tCommand = ..GitCmdPrefix()
	s tCommand = tCommand_" status --short"
	s tDisplay = 0
	s tSC = ..RunCmd(tCommand,.tOutput,tDisplay)
	if $$$ISERR(tSC) Quit
	For i=1:1:tOutput {
		s tOutputLine = tOutput(i)
		s tStagedItem = $E(tOutputLine,4,*)
		if tStagedItem = tExternalName {
			s tReturn = 1
		}		
	}
	Quit tReturn
}

ClassMethod DeleteExternalsForItem(InternalName As %String, FullExternalName As %String) As %Status
{
    #dim type As %String = ..Type(InternalName)
    #dim ec As %Status = $$$OK
    if (type = "prj") || (type = "pkg") || (type = "csp" && ..IsCspFolder(InternalName)) {
        // we delete complex items

	//The .itemsList is not for the specific item selected whether csp folder, pkg, or prj - it seems to be hardcoded to the repo folder or a specific folder for ereferral
	//So, if delete of prj, pkg, or csp folder is need, revisit this code.        
#;        //get all item in files
#;        #dim itemsList
#;        $$$QuitOnError(..ListItemsInFiles(.itemsList))
#;        
#;        #dim item As %String = ""
#;        //for all item in files
#;        For  {
#;            s item = $O(itemsList(item))
#;            Quit:item=""
#;            
#;            //if item is not in sc -- delete file
#;            if '..IsInSourceControl(item) {
#;                #dim sc As %Status = ..DeleteExternalFile(item)
#;                if 'sc {
#;                    s ec = $$$ADDSC(ec, sc)
#;                }
#;            }
#;        }
    } else {
        s ec = ..DeleteExternalFile(InternalName,FullExternalName)
    }
    Quit ec
}

ClassMethod RemoveFromSourceControl(InternalName As %String) As %Status
{
    #dim sc As %Status = $$$OK
    if $D(@..InstallNamespaceStorage()@("items", InternalName)) {
        //Get external file name first because items contains LibType reference
        s tFilename = ..ExternalName(InternalName)
        s tFullFilename = ..FullExternalName(InternalName)
        k @..InstallNamespaceStorage()@("items", InternalName)
        K @..InstallNamespaceStorage()@("ExternalNames",tFilename)
        s sc = ..DeleteExternalsForItem(InternalName,tFullFilename)
        Q:$$$ISERR(sc) sc
        s sc = ..GitCommand("remove",tFullFilename)
        Q:$$$ISERR(sc) sc
        d ..RemoveFolderIfEmpty(..RepoFolder())
    } else {
        #dim parentElement As %String = ""
        if ..IsInSourceControl(InternalName, .parentElement) {
            s sc = ..MakeError("This element is contained in "_parentElement_" that tracked by SourceControl")
        }else {
            s sc = ..MakeError("Element is not in SourceControl")
        }
        
    }
    Quit sc
}

ClassMethod IsCspFolder(InternalName As %String) As %Boolean
{
    #dim extension = $P(InternalName, ".", $L(InternalName, "."))
    Quit:extension="csp" 0
    
    #dim filename = $system.CSP.GetFileName(InternalName_"/")
    Quit filename'="" && ##class(%File).DirectoryExists(filename)
}

/// pkg -- package<br/>
/// prj -- project<br/>
/// csp -- csp-page or csp-folder. See <Method>IsCspFolder</Method>
ClassMethod Type(InternalName As %String) As %String
{
    #dim extension As %String = $ZCVT($P(InternalName,".",$L(InternalName,".")),"L")
    #dim type As %String = extension
    
    if $E(InternalName, 1, 4) = "/csp" {
        s type ="csp"
    }

    Quit type
}

ClassMethod NameWithoutExtension(InternalName As %String) As %String [ CodeMode = expression ]
{
$piece(InternalName, ".", 1, $length(InternalName,".")-1)
}

/// packageName without extension
ClassMethod IsClassInPackage(ClassName As %String, packageName As %String) As %Boolean [ CodeMode = expression ]
{
$E(ClassName, 1, $L(packageName)) = packageName
}

/// projectName without extension
ClassMethod IsItemInProject(InternalName As %String, projectName As %String) As %Boolean
{
    // we should check two cases
    // direct inclusion
    // inclusion in package or csp-folder that contained in project
    #dim type As %String = ..Type(InternalName)
    //w InternalName, "->"
    #dim name As %String = $case(type, "cls": ..NameWithoutExtension(InternalName), 
                                       "pkg": $TR(..NameWithoutExtension(InternalName), "/", "."), 
                                       "csp": $E(InternalName, 2, *),
                                       :InternalName)
    if $E(name) = "." && (type = "pkg") {
        s $E(name) = ""
    }
    
    //w name, " "
    #dim checkId = projectName_"||"_name_"||"_$ZCVT(type,"U")
    //w checkId
    #dim isItemInProject As %Boolean = ##class(%Studio.ProjectItem).%ExistsId(checkId)
    //w " ", isItemInProject, !
    
    #dim i As %Integer
    if 'isItemInProject && ((type = "cls") || (type="pkg")) {
        for i = 1:1:$L(name, ".") {
            s checkId = projectName_"||"_$P(name, ".", 1, i)_"||PKG"
            //w checkId, !
            if ##class(%Studio.ProjectItem).%ExistsId(checkId) {
                s isItemInProject = 1
                Quit
            }
        }
    }
    
    if 'isItemInProject && (type = "csp") {
        for i = 1:1:$L(name, "/") {
            s checkId = projectName_"||"_$P(name, "/", 1, i)_"||DIR"
            
            if ##class(%Studio.ProjectItem).%ExistsId(checkId) {
                s isItemInProject = 1
                Quit
            }
        }
    }
    Quit isItemInProject
}

ClassMethod IsItemInCSPFolder(InternalName As %String, cspFolder As %String) As %Boolean [ CodeMode = expression ]
{
$E(InternalName, 1, $L(cspFolder)) = cspFolder
}

ClassMethod FindInPackages(InternalName As %String, ByRef sourceControlItem As %String) As %Boolean
{
    #dim item As %String = ""
    #dim found As %Boolean = 0
    For  {
        s item = $O(@..InstallNamespaceStorage()@("items", item))
        Quit:item=""
        continue:..Type(item)'="pkg"
        #dim packageName As %String = ..NameWithoutExtension(item)

        if ..IsClassInPackage(InternalName, packageName) {
            s found = 1
            s sourceControlItem = packageName
            Quit
        }
    }
    Quit found
}

ClassMethod FindInProjects(InternalName As %String, ByRef sourceControlItem As %String) As %Boolean
{
    #dim item As %String = ""
    #dim found As %Boolean = 0
    For  {
        s item = $O(@..InstallNamespaceStorage()@("items", item))
        Quit:item=""
        continue:..Type(item)'="prj"
        #dim projectName As %String = ..NameWithoutExtension(item)
        
        if ..IsItemInProject(InternalName, projectName) {
            s found = 1
            s sourceControlItem = projectName
            Quit
        }
    }
    Quit found
}

ClassMethod FindInCspFolders(InternalName As %String, ByRef sourceControlItem As %String) As %Boolean
{
    #dim cspFolder As %String = ""
    #dim found As %Boolean = 0
    For  {
        s cspFolder = $O(@..InstallNamespaceStorage()@("items", cspFolder))
        Quit:cspFolder=""
        continue:'(..Type(cspFolder)="csp" && ..IsCspFolder(cspFolder))
        
        if ..IsItemInCSPFolder(InternalName, cspFolder) {
            s found = 1
            s sourceControlItem = cspFolder
            Quit 
        }
    }
    Quit found
}

ClassMethod IsInSourceControl(InternalName As %String, ByRef sourceControlItem As %String) As %String
{
    #dim isInSourceControl As %Boolean = 1
    
    s isInSourceControl = $D(@..InstallNamespaceStorage()@("items",InternalName)) > 0
    if isInSourceControl {
        s sourceControlItem = InternalName
    }else {
        //if no direct reference maybe we have to look in packages, projects or csp-apps ?
        //We have three groups of routines
        //packages for classes
        //projects for everything
        //csp-folders for csp and static files

        #dim type As %String = ..Type(InternalName)
        if type = "cls" {
            s isInSourceControl = ..FindInPackages(InternalName, .sourceControlItem)
        } elseif type = "csp" {
            s isInSourceControl = ..FindInCspFolders(InternalName, .sourceControlItem)
        }
        
        // our last chance to find item -- let's look in projects
        if 'isInSourceControl {
            s isInSourceControl = ..FindInProjects(InternalName, .sourceControlItem)
        }
    }
    //w "checking ", $G(type), " ", InternalName, "=", isInSourceControl, !
    Quit isInSourceControl
}

ClassMethod FullExternalName(InternalName As %String) As %String [ CodeMode = expression ]
{
$E(..RepoFolder(),1,*-1)_..ExternalName(InternalName)
}

ClassMethod NormalizeExtension(name As %String) As %String
{
    #dim extension = $P(name, ".", $L(name, "."))
    if $L(extension) <= 3 {
        s $P(name, ".", $L(name, ".")) = $zcvt(extension, "L")
    }
    Quit name
}

ClassMethod RoutineTSH(InternalName As %String) As %String
{
    #dim type = ..Type(InternalName)
    //for csp-files (csp,js,html,css, all that stored in csp/...) we always check for changes in external file
    #dim tsh = $case(type,"csp":"",:$G(@..InstallNamespaceStorage()@("TSH", ..NormalizeExtension(InternalName))))
    if tsh = "" {
        #dim ts As %String = ##class(%RoutineMgr).TS(InternalName)
        if ts '= "" {
            // prj files have milliseconds in timestamp, so we crop them
            s tsh = $P($zdth(ts, 3),".",1)
        }
    }
    Quit tsh
}

ClassMethod UpdateRoutineTSH(InternalName As %String, tsh As %String) As %Status
{
    s @..InstallNamespaceStorage()@("TSH", ..NormalizeExtension(InternalName)) = $G(tsh, $H)
    Quit $$$OK
}

ClassMethod RemoveRoutineTSH(InternalName As %String) As %Status
{
    k @..InstallNamespaceStorage()@("TSH", ..NormalizeExtension(InternalName))
    Quit $$$OK
}

ClassMethod DeleteExternalFile(InternalName As %String = "", FullExternalName As %String = "") As %Status
{
    if FullExternalName'="" {
    	set fullName = FullExternalName
    } else {
	    set fullName = ..FullExternalName(InternalName)
    }
    #dim tSC As %Status = $$$OK
    if ##class(%File).Exists(fullName) {
        s tSC = ##class(%File).Delete(fullName)
        if 'tSC {
	        s tSC = $$$ERROR($$$GeneralError,"Unable to delete file: "_fullName)
        } else {
	        d ..RemoveRoutineTSH(InternalName)
	        s tSC = ..GitCommand("remove",fullName)
	        w fullName, " for ", InternalName, " deleted!",!
        }
    }
    Quit tSC
}

ClassMethod ListItemsInFiles(ByRef itemList, ByRef err) As %Status
{
	//This method doesn't seem to do what it should do
	//It seems to get a list of items in a folder on disk using the ImportDir method
	//Shouldn't it get a list of items in the relevant prj, pkg, or csp folder?
	
#;    #define DoNotLoad 1
#;	// PR: Must find a better solution for tSubDir. *.cls.xml wildcard not working. Want to use the same git repository for client-side and server-side.
#;    set tSubDir = $CASE($FIND($ZCONVERT(..RepoFolder(),"U"),"EREFERRAL") > 0, 1:"eReferral",:"")
#;    $$$QuitOnError($system.OBJ.ImportDir(..RepoFolder()_tSubDir,"*.xml","-d",.err,1, .itemList, $$$DoNotLoad))
#;    
#;    //change all csp/ names to /csp/ names
#;    #dim item As %String = "csp"
#;    For  {
#;        s item = $O(itemList(item))
#;        Quit:item=""
#;        Quit:$E(item, 1, 4)'="csp/"
#;        k itemList(item)
#;        s itemList("/"_item)=""
#;    }
    Quit $$$OK
}

ClassMethod ExportRoutinesAux(path As %String, sep As %String = "", level As %Integer = 0) As %Status
{
    #define Dir
    #define OrderBy
    #define SystemFiles
    #define Flat
    #define NotStudio
    #define ShowGenerated 0
    #define Filter
    #define CspFile 5
    #define Directory 9
    #define CSPFolder 10
    
    #dim rs As %ResultSet = ##class(%ResultSet).%New("%RoutineMgr:StudioOpenDialog")
    #dim ec As %Status = rs.Execute(path_$case(path,"":"",:"/")_"*",$$$Dir, $$$OrderBy, $$$SystemFiles, $$$Flat, $$$NotStudio, $$$ShowGenerated, $$$Filter)
    Quit:'ec ec
    while rs.Next() {
        #dim name As %String = rs.Get("Name")
        #dim isdirectory As %String = rs.Get("IsDirectory")
        #dim type As %String = rs.Get("Type")
        
        if (type = $$$Directory) || (type = $$$CSPFolder) {
            #dim newpath As %String = $case(path,"":name,:path_isdirectory_name)
            #dim importedcnt As %Integer = 0
            d ..ExportRoutinesAux(newpath, isdirectory, level + 1)
        } else {
            #dim InternalName As %String = path_sep_name
            if (type = $$$CspFile) && ($E(InternalName) '= "/") {
                s InternalName = "/"_InternalName
            }
            s ec = ..ExportItem(InternalName)
        }
    }
    k rs
    Quit ec
}

ClassMethod ExportItem(InternalName As %String, expand As %Boolean = 1) As %Status
{
    #dim type = ..Type(InternalName)
    if type = "pkg" {
        $$$QuitOnError(..ExportRoutinesAux(..NameWithoutExtension(InternalName), "."))
    }elseif type = "prj" && expand {
	    //No handling for .prj files required
#;        $$$QuitOnError(..ExportProject(..NameWithoutExtension(InternalName)))
#;        $$$QuitOnError(..ExportItem(InternalName, 0))
    }elseif type = "ptd" {
	    //No handling for .ptd files required
    }elseif (type = "csp") && ..IsCspFolder(InternalName) {
        $$$QuitOnError(..ExportRoutinesAux(InternalName , "/"))
    }else {
        w "Exporting ", InternalName, !
        #dim filename As %String = ..FullExternalName(InternalName)
        #;Do not include selectivity as it
        #; 1. is likely to come from a dev system which does not have representative data
        #; 2. may have elements that cannot be imported into earlier versions of Cache
        
   //Disable this for now...
        //We know the database version of the file is always the latest
        //However, our local git repo may not have the latest that is in the remote repo
        //Therefore, when export to our local repo, we may create a conflict because we don't have the latest from the remote repo
        //So, because we know that the database version is the latest, we can discard what is in our local repo,
        //get the latest that is in the remote repo, which may contain edits not in our local repo
        //And then we will export a new copy of the database version which will contain our new edits 
        //but will be an addition, not a conflict to what was in the remote repo.
        //s tSC = ..GitCommand("checkout",filename)
        //s tSC = ..GitCommand("pull")
        //$$$QuitOnError(tSC)
   //
        
        if ..#UseUDL,..CanExportExtensionUDL(type) {
			$$$QuitOnError($system.OBJ.ExportUDL(InternalName, filename, "-d/diffexport=1/exportselectivity=0"))
		} else {
			$$$QuitOnError($system.OBJ.Export(InternalName, filename,"-d/diffexport=1/exportselectivity=0"))	
		}
		
        $$$QuitOnError(..UpdateRoutineTSH(InternalName, $H))
        s tSC = ..GitCommand("add",filename)
        $$$QuitOnError(tSC)
		
    }
    Quit $$$OK
}

ClassMethod ExportProject(project As %String) As %Status
{
    #dim rs As %ResultSet = ##class(%ResultSet).%New("%Studio.Project:ProjectItemsList")
    $$$QuitOnError(rs.Execute(project))
    #dim typesWithoutExtension As %List = $LB("CLS", "PKG")
    while rs.Next() {
        #dim name = rs.Get("Name")
        if $LF(typesWithoutExtension, rs.Get("Type")) {
            s name = name _ "." _ rs.Get("Type")
        }
        #dim ec As %Status = ..ExportItem(name)
        Quit:'ec
    }
    k rs
    Quit $$$OK
}

ClassMethod ExportAll() As %Status
{
    #dim item As %String = ""
    #dim ec As %Status = $$$OK
    For  {
        s item = $O(@..InstallNamespaceStorage()@("items",item))
        Quit:item=""
        s ec = ..ExportItem(item)
        Quit:'ec       
    }
    Quit ec
}

/// returns true if directory was deleted
ClassMethod RemoveFolderIfEmpty(path As %String) As %Boolean
{
    #dim rs As %Status = ##class(%ResultSet).%New("%File:FileSet")
    #define DirsFirst 1
    $$$QuitOnError(rs.Execute(path,,,$$$DirsFirst))
    #dim fileCount As %Integer = 0
    while rs.Next() {
        #dim fullname As %String = rs.Get("Name")
        #dim type As %String = rs.Get("Type")
        #dim name As %String = rs.Get("ItemName")
        #define IsDirectory(%type) %type="D"
        
        s fileCount = fileCount + 1
        Quit:'$$$IsDirectory(type)
        continue:name=".git"
        if ..RemoveFolderIfEmpty(fullname) {
            s fileCount = fileCount - 1
        }
    }
    if fileCount = 0 {
        d ##class(%File).RemoveDirectory(path)
    }
    k rs
    Quit 'fileCount
}

/// 
/// Returns if an extension can 
ClassMethod CanExportExtensionUDL(extension As %String = "") As %Integer
{
	quit ($listfind(..#NOTUDLEXTENSIONS, extension)=0)
}

ClassMethod TestDialogue(pMenuCommand, pCommandValue = "")
{
	s tSettings(pMenuCommand)=pCommandValue
	s tSC = ..HandleDialogue(.tSettings,.tOutput)
	For i=1:1:tOutput {
		w !,tOutput(i)
	}
}

ClassMethod LoadSettings(pRepoBaseFolder, pUserName, pPersonName, pPersonEmail, pTeamBranch, pRepoURL = "", pRepoProtocol = "", pReleaseBranchBase = "", pInstallNamespace = "", pGitBinaryLocation="") As %Status
{
	
	Set tSettings("repoBaseFolder")=pRepoBaseFolder
	Set tSettings("userName")=pUserName
	Set tSettings("personName")=pPersonName
	Set tSettings("personEmail")=pPersonEmail
	Set tSettings("teamBranch")=pTeamBranch
	Set:pRepoURL'="" tSettings("repoURL")=pRepoURL
	Set:pRepoProtocol'="" tSettings("repoProtocol")=pRepoProtocol
	Set:pReleaseBranchBase'="" tSettings("releaseBranchBase")=pReleaseBranchBase
	Set:pInstallNamespace'="" tSettings("installNamespace")=pInstallNamespace
	zw pGitBinaryLocation
	if (pGitBinaryLocation'="") && (pGitBinaryLocation'="null")
	{
		set tSettings("gitBinaryLocation")=pGitBinaryLocation
	}
	else
	{
		set tSettings("gitBinaryLocation")="git"
	}
	Quit ##class(User.SourceControl.Git.Utils).UpdateSettings(.tSettings)
}

ClassMethod LoadBranchLocal(ByRef pOutput As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
		
		Set outputfile=##class(%File).TempFilename("load")
		
		OPEN outputfile:"WSN"
		USE outputfile
		
		s (tErrors,tLoaded)=""
		s tSC = $System.OBJ.ImportDir(..RepoFolder(),"*.xml","cbfk",.tErrors,1,.tLoaded)
		s tSC = $System.OBJ.ImportDir(..RepoFolder(),"*.xsl","cbfk",.tErrors,1,.tLoaded)
		s tSC = $System.OBJ.ImportDir(..RepoFolder(),"*.cls","cbfk",.tErrors,1,.tLoaded)
		s tSC = $System.OBJ.ImportDir(..RepoFolder(),"*.mac","cbfk",.tErrors,1,.tLoaded)
		s tSC = $System.OBJ.ImportDir(..RepoFolder(),"*.lut","cbfk",.tErrors,1,.tLoaded)
		s tSC = $System.OBJ.ImportDir(..RepoFolder(),"*.hl7","cbfk",.tErrors,1,.tLoaded)
		
		CLOSE outputfile
		
		s tFile=##class(%FileCharacterStream).%New()
		s tFile.Filename=outputfile
		
		s pOutput($I(pOutput))="Loading all classes in branch "_..CurrentBranch()_" to namespace "_$NAMESPACE_" on "_##class(%SYS.System).GetNodeName()_":"_##class(%SYS.System).GetInstanceName()_$C(10)
		
		While 'tFile.AtEnd {
			s pOutput($I(pOutput))=tFile.ReadLine()
		}
		
	} catch e {
		s tSC = e.AsStatus()
		s pOutput($I(pOutput))=$System.Status.GetErrorText(tSC)
	}
	Quit tSC
}

ClassMethod LoadBranch(pBranch, pPassword) As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
		
		w !,1,!
		//Set this flag at the start so that the Source Control Hooks will skip doing any source control actions during branch load
		Set @..InstallNamespaceStorage()@("%user",$USERNAME,"%loadBranchActive") = 1
		
		w !,2,!
		
		s tOutput=""
		
		if '..IsNamespaceInGit() {
			w !,"inside",!
			s tSettings("Clone Repository")=pPassword
			s tSC=..HandleDialogue(.tSettings,.tOutput)
			zw tOutput
			$$$ThrowOnError(tSC)
		}
		w !,3,!
		
		Kill tSettings
		s tSettings("Switch to Branch")=pBranch
		s tSC=..HandleDialogue(.tSettings,.tOutput)
		ZW tOutput
		$$$ThrowOnError(tSC)
		
		w !,4,!
		Kill tSettings
		s tSettings("Pull")=pBranch
		s tSC=..HandleDialogue(.tSettings,.tOutput)
		ZW tOutput
		$$$ThrowOnError(tSC)
		
		w !,5,!
		
		//LoadDir is .xml only - do we need to switch to ImportDir to handle csp files?
		s (tErrors,tLoaded)=""
		s tSC = $System.OBJ.ImportDir(..RepoFolder(),"*.cls","cbfk",.tErrors,1,.tLoaded) $$$ThrowOnError(tSC)
		s tSC = $System.OBJ.ImportDir(..RepoFolder(),"*.mac","cbfk",.tErrors,1,.tLoaded) $$$ThrowOnError(tSC)
		s tSC = $System.OBJ.ImportDir(..RepoFolder(),"*.lut","cbfk",.tErrors,1,.tLoaded) $$$ThrowOnError(tSC)
		s tSC = $System.OBJ.ImportDir(..RepoFolder(),"*.hl7","cbfk",.tErrors,1,.tLoaded) $$$ThrowOnError(tSC)
		s tSC = $System.OBJ.ImportDir(..RepoFolder(),"*.inc","cbfk",.tErrors,1,.tLoaded) $$$ThrowOnError(tSC)
		
		//Must add handling for CSP files!
		
		
	} catch e {
		s tSC = e.AsStatus()
		w !,e.DisplayString()
	}
	
	for i=1:1:tOutput {
		w tOutput(i)
	}
	
	Set @..InstallNamespaceStorage()@("%user",$USERNAME,"%loadBranchActive") = ""
	
	Quit tSC
}

ClassMethod BuildDeployment(pFilename, pEnvironmentBranch, pIntegrationBranch) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	#dim tStream As %Stream.Object
	#dim tDeployStatus As %Boolean = 1
	
	Try {

		
		Kill tSettings
		s tSettings("Switch to Branch")=pIntegrationBranch
		Kill tOutput
		s tSC=..HandleDialogue(.tSettings,.tOutput)
		w !
		zw tOutput
		w !
		$$$ThrowOnError(tSC)
		
		Kill tSettings
		s tSettings("Pull")=pIntegrationBranch
		Kill tOutput
		s tSC=..HandleDialogue(.tSettings,.tOutput)
		w !
		zw tOutput
		w !
		$$$ThrowOnError(tSC)

		//Switch to the integration branch in order to do the diff with the source branch
		Kill tSettings		
		s tSettings("Switch to Branch")=pEnvironmentBranch
		Kill tOutput
		s tSC=..HandleDialogue(.tSettings,.tOutput)
		w !
		zw tOutput
		w !
		$$$ThrowOnError(tSC)
		
		//Get the new/changed files in the diff between integration branch and source branch
		Kill tSettings
		s tSettings("ListDiff")=pIntegrationBranch
		Kill tOutput
		s tSC=..HandleDialogue(.tSettings,.tOutput)
		w !
		zw tOutput
		w !
		$$$ThrowOnError(tSC)
		
		Merge tImportList = tOutput
		
		//Now that we have the list, switch to the source branch and load the files, ensuring each compile
		Kill tSettings
		s tSettings("Switch to Branch")=pIntegrationBranch
		Kill tOutput
		s tSC=..HandleDialogue(.tSettings,.tOutput)
		w !
		zw tOutput
		w !
		$$$ThrowOnError(tSC)
		
		//Create a temp folder to temporarily hold the new files, so that they may be imported from that directory to VABUILD
		//An alternate approach would be to provide a comma delimited list of files, but since the list could exceed max size, the folder approach is implemented
		s tTempFileName = ##class(%File).TempFilename()
		s tTempName = $P(##class(%File).GetFilename(tTempFileName),".",1)
		s tTempDir = ##class(%File).GetDirectory(tTempFileName)_tTempName_"/"
		
		//Now, loop through the list of changes files and copy them from the Git repo folder to the Temp folder
		for i=1:1:tImportList {
			s tItem=tImportList(i)
			s tExtension = $P(tItem,".",$LENGTH(tItem,"."))
			s tFullFilename = ..RepoFolder()_tItem
			s tFilename = ##Class(%File).GetFilename(tFullFilename)
			
			// files that are imported and compiled will be copied to temp folder
			// csp files will be handled differently
			If $TR($ZCVT($E(tItem,1,4),"U"),"\","/")'="CSP/" {
				s tTargetFullFilename = tTempDir_i_tFilename  // include number to avoid file name collisions
			} else {
				//If the file path indicates it is a csp file, it is copied directly to the csp folder of the VABUILD instance
				s tTargetFullFilename = $System.Util.InstallDirectory()_tItem
			}

			//First verify the directory exists - if it is a csp folder it very well may not.  Also the first time a file is copied to the temp folder it will not exist
			if '##class(%File).DirectoryExists(##class(%File).GetDirectory(tTargetFullFilename)) {
				s tSC = ##class(%File).CreateDirectoryChain(##class(%File).GetDirectory(tTargetFullFilename),.tCreateDirOutput)
				if 'tSC $$$ThrowStatus($$$ERROR($$$GeneralError,"Could not create directory: "_tTempDir_" with error value: "_tCreateDirOutput))
			}
			
			//Now, copy the file
			s tSC = ##class(%File).CopyFile(tFullFilename,tTargetFullFilename,,.tCopyOutput)
			if 'tSC {
				$$$ThrowStatus($$$ERROR($$$GeneralError,"File copy from: "_tFullFilename_" to: "_tTargetFullFilename_" failed with value: "_tCopyOutput))
			}
			
			//s tLoadList = tLoadList_$S(tLoadList="":"",1:"*")_..RepoFolder()_tItem
			
			s tInternalName = tItem
			if $TR($ZCVT($E(tInternalName,1,4),"U"),"\","/")'="CSP/" {
				s tItemExtension = $P(tInternalName,".",$LENGTH(tInternalName,"."))
				s tInternalName = $REPLACE(tInternalName,"."_tItemExtension,"."_$ZCVT(tItemExtension,"U"))
				s tInternalName = $TR(tInternalName,"/",".")
			}
			if tInternalName="" Continue
			
			Set tContentsList(tInternalName)=""

		}
		
		//a load list is compiled here so that multiple files can be loaded at one so that class DependsOn statements can be honored
		//But concern is whether the tLoadList may become too large?
		//s tSC = $System.OBJ.Load(tLoadList,"cbfk") $$$ThrowOnError(tSC)
		
		If '$D(tContentsList) $$$ThrowStatus($$$ERROR($$$GeneralError,"No items were found for deployment."))
		
		//The changed files have been copied to a temp directory.
		//the csp files have already been copied to the target csp folders
		//Load the changed files from the temp directory here
		s (tErrors,tLoaded)=""
		
		s tSC = $System.OBJ.ImportDir(tTempDir,"*.inc","cbfk",.tErrors,1,.tLoaded) $$$ThrowOnError(tSC)
		
		s tSC = $System.OBJ.ImportDir(tTempDir,"*.cls","cbfk",.tErrors,1,.tLoaded) 
		zw tLoaded
		zw tErrors
		$$$ThrowOnError(tSC)
		s tSC = $System.OBJ.ImportDir(tTempDir,"*.mac","cbfk",.tErrors,1,.tLoaded) $$$ThrowOnError(tSC)
		s tSC = $System.OBJ.ImportDir(tTempDir,"*.lut","cbfk",.tErrors,1,.tLoaded) $$$ThrowOnError(tSC)
		s tSC = $System.OBJ.ImportDir(tTempDir,"*.hl7","cbfk",.tErrors,1,.tLoaded) $$$ThrowOnError(tSC)
		
		s tProjectName = $TR(pEnvironmentBranch,"/","")
		s tProductionName = ""
		//Set:(tItemName '[ "||") tItemName = tProductionName_"||"_tItemName
		
		Set tProductionClassIncluded = 0
		Set tComments = "Deploy Package created programatically."
		Set tSC =##class(Ens.Deployment.Utils).CreateExportPackageFromProjectList(tProjectName,.tContentsList,pFilename,tProductionName,tComments,tProductionClassIncluded)
		$$$ThrowOnError(tSC)

		w !, "Deploy Package built and exported to: "_pFilename
		
		//Now clean up the temp folder where the changed files were loaded from and remove the csp files
		s tSC = ##class(%File).Delete(tTempDir_"*",.tDeleteFilesOutput)
		if 'tSC $$$ThrowStatus($$$ERROR($$$GeneralError,"Could not delete files from: "_tTempDir_" with error value: "_tDeleteFilesOutput))
		s tSC = ##class(%File).RemoveDirectory(tTempDir,.tDeleteDirOutput)
		if 'tSC $$$ThrowStatus($$$ERROR($$$GeneralError,"Could not remove directory: "_tTempDir_" with error value: "_tDeleteDirOutput))
		
		//Now remove the csp files
		for i=1:1:tImportList {
			s tItem=tImportList(i)
			If $TR($ZCVT($E(tItem,1,4),"U"),"\","/")="CSP/" {
				s tTargetFullFilename = $System.Util.InstallDirectory()_tItem
				s tSC = ##class(%File).Delete(tTargetFullFilename,.tDeleteFilesOutput)
				//if 'tSC $$$ThrowStatus($$$ERROR($$$GeneralError,"Could not delete file: "_tTargetFullFilename_" with error value: "_tDeleteFilesOutput))
			} 
		}
		
	} catch e {
		s tSC = e.AsStatus()
		w !,"Error Building Deploy Package: "_e.DisplayString()
		w !,"Current ContentList:",!
		zw tContentsList
		s tDeployStatus = 0
	}
	Quit $C(10)_$CASE(tDeployStatus,1:"SUCCESS",0:"FAILURE",:"")
}

ClassMethod LoadDeployment(pFilename) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
		
		//C:\InterSystems\HealthShare\mgr\Temp\intdevelop20191202132903.xml
		
		Set outputfile=##class(%File).TempFilename("compile")
		OPEN outputfile:"WSN"
		USE outputfile

		
		
		if ##class(%File).Exists(pFilename) {
			s tProduction = "" //$G(^Ens.Configuration("csp","LastProduction"))
			Do ##class(Ens.Deployment.Utils).GenerateFileNames(pFilename,.tRollbackFile,.tLogFile,.tReportFile)
			Set tCreateRollBack = 1, tAllowDeployToSource = 1 ,tAutoRevert = 0, tWhereToLog = "LC"
			s tSC = ##class(Ens.Deployment.Deploy).DeployCode(pFilename,tProduction,tCreateRollBack,tRollbackFile,tWhereToLog,tLogFile,tAllowDeployToSource,tAutoRevert)
			$$$ThrowOnError(tSC)
		} else {
			$$$ThrowOnError($$$ERROR($$$GeneralError,"File name for deployment not found: "_pFilename))
		}

		
		
	} catch e {
		s tSC = e.AsStatus()
		w e.DisplayString()
	}
	
	CLOSE outputfile
	
	s tFile=##class(%FileCharacterStream).%New()
	s tFile.Filename=outputfile
	While 'tFile.AtEnd {
		w tFile.ReadLine()
	}	
	d tFile.Clear()
	
	Quit tSC
}

ClassMethod DeployRollback(pFilename As %String, pTargetHost As %String, pTargetPort As %String, pTargetNamespace As %String) As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	#dim tDeployStatus As %Boolean = 1
	
	Try {
		
		s tResponse="-------------------------------"_$C(10)
		s tResponse=tResponse_"Rollback of last deployment to "_pTargetHost_":"_pTargetPort_$C(10)
		s tResponse=tResponse_"-------------------------------"_$C(10)		
		
		s tImportRequest = ##class(User.SourceControl.Deploy.ImportRequest).%New()
		
		set ConfigScripts=..ConfigScriptsFromImportRequest(pFilename)
		set tImportRequest.ConfigScriptsJSON=ConfigScripts.%ToJSON()
		
		Set tServiceClient=##class(User.SourceControl.Deploy.ServiceClient).%New()
		Set tServiceClient.Location="http://"_pTargetHost_":"_pTargetPort_"/csp/healthshare/"_$ZCVT(pTargetNamespace,"L")_"/services/User.SourceControl.Deploy.Service.cls"
		//Set tServiceClient.SSLConfiguration = tConfig.SSLConfig
		Set tServiceClient.Timeout = 300
		Set tCredentials = ##class(Ens.Config.Credentials).%OpenId("HS_Credentials")  //Build installer sets this on initial setup
		Set tSC=tServiceClient.WSSecurityLogin(tCredentials.Username,tCredentials.Password) $$$ThrowOnError(tSC)

		Set tResponse = tServiceClient.Rollback(tImportRequest,.tDeployStatus)

	} catch e {
		if $ZERROR["<ZSOAP>" {
            Set tSC=%objlasterror
        } else {
            Set tSC = e.AsStatus()
        }
		s tResponse="-------------------------------"_$C(10)
		s tResponse=tResponse_"Error deploying to "_pTargetHost_":"_pTargetPort_" = "_$System.Status.GetErrorText(tSC)_$C(10)
		s tResponse=tResponse_"-------------------------------"_$C(10)
		
		s tDeployStatus = 0
	}

	for i=1:1:$L(tResponse,$C(10)) {
		w !,$P(tResponse,$C(10),i)
	}

	Quit $C(10)_$CASE(tDeployStatus,1:"SUCCESS",0:"FAILURE",:"")
}

ClassMethod ConfigScriptsFromImportRequest(pFilename As %String) As %DynamicArray
{
		//Identify the Configuration Script and set it to the ImportRequest
		s tSC = ##class(Ens.Deployment.Deploy).GeneratePackageXMLVDOC(pFilename,.tDeploymentVDOC)
		$$$ThrowOnError(tSC)
		
		s tSC = ##class(Ens.Deployment.Deploy).GetProjectContents(pFilename,tDeploymentVDOC,.pTargetProduction,.tDeployDetails)
		$$$ThrowOnError(tSC)
		
		s ConfigScripts=[]
		s tItemName = ""
		For { s tItemName = $O(tDeployDetails("Items",tItemName)) Q:tItemName=""
			if $G(tDeployDetails("Items",tItemName,"Type"))="MAC" {
				if $P(tItemName,".",1)="ConfigScripts" {
					do ConfigScripts.%Push($P(tItemName,".",1,$LENGTH(tItemName,".")-1))
					s tCallBack = "^"_$P(tItemName,".",1,*-1)
				}
			}
		}
		return ConfigScripts
}

ClassMethod Deploy(pFilename As %String, pTargetHost As %String, pTargetPort As %String, pTargetNamespace As %String, pHSEnvironment As %String = "") As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	#dim tDeployStatus As %Boolean = 1
	
	Try{
		Set tCredentials = ##class(Ens.Config.Credentials).%OpenId("HS_Credentials")  //Build installer sets this on initial setup
	
		//Compile latest service and run projection on server
		set atelierBaseEndpoint="http://"_pTargetHost_":"_pTargetPort_"/api/atelier"
		set tSC = ##class(User.SourceControl.Deploy.Bootstrap).CompileUsingAtelierEndpoint(atelierBaseEndpoint,"User.SourceControl.Deploy.EnsDeploy.cls","HSCUSTOM",tCredentials.Username,tCredentials.Password)
		$$$ThrowOnError(tSC)
		set tSC = ##class(User.SourceControl.Deploy.Bootstrap).CompileUsingAtelierEndpoint(atelierBaseEndpoint,"User.SourceControl.Deploy.ImportObject.cls","HSCUSTOM",tCredentials.Username,tCredentials.Password)
		$$$ThrowOnError(tSC)
		set tSC = ##class(User.SourceControl.Deploy.Bootstrap).CompileUsingAtelierEndpoint(atelierBaseEndpoint,"User.SourceControl.Deploy.ImportRequest.cls","HSCUSTOM",tCredentials.Username,tCredentials.Password)
		$$$ThrowOnError(tSC)
		set tSC = ##class(User.SourceControl.Deploy.Bootstrap).CompileUsingAtelierEndpoint(atelierBaseEndpoint,"User.SourceControl.Deploy.Service.cls","HSCUSTOM",tCredentials.Username,tCredentials.Password)
		$$$ThrowOnError(tSC)
		set tSC = ##class(User.SourceControl.Deploy.Bootstrap).CompileUsingAtelierEndpoint(atelierBaseEndpoint,"User.SourceControl.Deploy.Projection.cls","HSCUSTOM",tCredentials.Username,tCredentials.Password)
		$$$ThrowOnError(tSC)
		
		s tImportRequest = ##class(User.SourceControl.Deploy.ImportRequest).%New()
		
		s tResponse="-------------------------------"_$C(10)
		s tResponse=tResponse_"Beginning deployment to "_pTargetHost_":"_pTargetPort_$C(10)
		s tResponse=tResponse_"-------------------------------"_$C(10)
		
		set ConfigScripts=..ConfigScriptsFromImportRequest(pFilename)
		set tImportRequest.ConfigScriptsJSON=ConfigScripts.%ToJSON()
 		
		//Create the Import Request and add one ImportObject to it.  The import object will be the deploy file.
		s tDeployStream = ##class(%FileCharacterStream).%New()
		s tDeployStream.Filename = pFilename
		
		
		s tImportObject = ##class(User.SourceControl.Deploy.ImportObject).%New()
		s tSC = tImportObject.ObjectStream.CopyFrom(tDeployStream) $$$ThrowOnError(tSC)
		s tImportObject.Name = ##class(%File).GetFilename(pFilename)
		s tSC = tImportRequest.Objects.Insert(tImportObject) $$$ThrowOnError(tSC)
		
		Set tServiceClient=##class(User.SourceControl.Deploy.ServiceClient).%New()
		Set tServiceClient.Location="http://"_pTargetHost_":"_pTargetPort_"/csp/healthshare/"_$ZCVT(pTargetNamespace,"L")_"/services/User.SourceControl.Deploy.Service.cls"
		//Set tServiceClient.SSLConfiguration = tConfig.SSLConfig
		Set tServiceClient.Timeout = 300
		Set tSC=tServiceClient.WSSecurityLogin(tCredentials.Username,tCredentials.Password) $$$ThrowOnError(tSC)


		Set tResponse = tServiceClient.Deploy(pHSEnvironment,tImportRequest,.tDeployStatus)
		
	} catch e {
		if $ZERROR["<ZSOAP>" {
            Set tSC=%objlasterror
        } else {
            Set tSC = e.AsStatus()
        }
		s tResponse="-------------------------------"_$C(10)
		s tResponse=tResponse_"Error deploying to "_pTargetHost_":"_pTargetPort_" = "_$System.Status.GetErrorText(tSC)_$C(10)
		s tResponse=tResponse_"-------------------------------"_$C(10)
		
		s tDeployStatus = 0
	}

	for i=1:1:$L(tResponse,$C(10)) {
		w !,$P(tResponse,$C(10),i)
	}
	
	
	//test reutrn value - this returns an error on every other deploy
#;	w !,$I(^MS("count"))
#;	if ^MS("count")#2 = 0 s tDeployStatus = 0
	

	Quit $C(10)_$CASE(tDeployStatus,1:"SUCCESS",0:"FAILURE",:"")
}

/// Pull Request Type may be: FeatureMerge, TeamMerge, BugFixMerge
/// Depending on the type of merge, the base and head brances will be determined as follows:
/// FeatureMerge:  base will be the team branch and head will be the current branch
/// TeamMerge: base will be develop and head will be the team branch
/// BugFixMerge: base will be the release branch the bugfix belongs to and head will be the current branch
ClassMethod CreatePullRequest(pPullRequestType As %String, ByRef pOutput As %String) As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
		
		set pOutput=$G(pOutput)+0 //This is to initialize the variable if it doesn't exist, but not increment it if it does exist
		s pOutput($I(pOutput))=""
		s pOutput($I(pOutput))="-------------------------------"
		s pOutput($I(pOutput))=""
		
		Set (tHead, tBase) = ""
		
		if pPullRequestType="FeatureMerge" {
			Set tHead = ..CurrentBranch()
			Set tBase = $P($REPLACE(tHead,"feature/","team-dev/"),"/",1,2)
		} elseif pPullRequestType="TeamMerge" {
			Set tHead = ..TeamBranch()
			Set tBase = "int/dev"
		} elseif pPullRequestType="BugFixMerge" {
			Set tHead = ..CurrentBranch()
			Set tBase = $P($REPLACE(tHead,"bugfix/","release/"),"/",1,2)
		} else {
			$$$ThrowOnError($$$ERROR($$$GeneralError,"Unrecognized pull request type: "_pPullRequestType))
		}
		
		s pOutput($I(pOutput))="Creating Pull Request to merge "_tHead_" to "_tBase

		
		//Get personal access token from git config
		s tCommand = ..GitCmdPrefix()_" config remote.origin.url"
		s tSC = ..RunCmd(tCommand,.tOutput,0) $$$ThrowOnError(tSC)
		s tPersonalAccessToken = $P($P(tOutput(1),"@",1),":",3)
		
		
		Set tHTTPRequest = ##class(%Net.HttpRequest).%New()
		set tHTTPRequest.Https=1
		Set tHTTPRequest.SSLConfiguration="AnySSL"
		set tHTTPRequest.ContentType="application/json"
		do tHTTPRequest.SetHeader("Authorization","Bearer "_tPersonalAccessToken)
	
		//Create payload as object, and then export to json
		Set tBody={}
		do tBody.%Set("title","Merge Request From: "_tHead)
		do tBody.%Set("head",tHead)
		do tBody.%Set("base",tBase)
	
		//Load request with payload
		Set tSC = tHTTPRequest.EntityBody.Write(tBody.%ToJSON()) $$$ThrowOnError(tSC)
		
		Set tAPIURL = ..RepoProtocol()_"://"_..RepoAPI()_"pulls"
 		
		Set tSC = tHTTPRequest.Post(tAPIURL) $$$ThrowOnError(tSC)
		Set tHttpResponse = tHTTPRequest.HttpResponse
		Set tStatusCode = tHttpResponse.StatusCode
		If 'tStatusCode?1"2"2N {
			$$$ThrowOnError($$$ERROR($$$GeneralError,"PullRequest failed with HTTP code: "_tStatusCode))
		}

		Set tResponseString = tHttpResponse.Data.Read()
		Set tResponseData=##class(%DynamicObject).%FromJSON(tResponseString)
		
		Set tPullRequestNumber = tResponseData.%Get("number")
		
		Set tPullRequestURI = ..RepoProtocol()_"://"_$REPLACE(..RepoURL(),".git","")_"/pull/"_tPullRequestNumber
		
		s pOutput($I(pOutput))=""
		s pOutput($I(pOutput))="Pull Request may be accessed at: <a href='"_tPullRequestURI_"' target='_blank'>"_tPullRequestURI_"</a>"
		s pOutput($I(pOutput))=""
		s pOutput($I(pOutput))="-------------------------------"
		
		//The following is an attempt to set an assignee or reviewer on the Pull request - but is not functional yet
		/*
		//This needs to be a setting
		Set tAssignees=[]
		Do tAssignees.%Push("AdamSalwen")
		
		Set tBody={}
		do tBody.%Set("assignees",tAssignees)
		
		Set tHTTPRequest = ##class(%Net.HttpRequest).%New()
		set tHTTPRequest.Https=1
		Set tHTTPRequest.SSLConfiguration="AnySSL"
		set tHTTPRequest.ContentType="application/json"
		//do tHTTPRequest.SetHeader("Authorization","Basic "_tPersonalAccessToken)
		Set tSC = tHTTPRequest.EntityBody.Write(tBody.%ToJSON()) $$$ThrowOnError(tSC)
		
		Set tAPIURL = ..RepoProtocol()_"://"_..RepoAPI()_"issues/"_tPullRequestNumber
		
		Set tSC = tHTTPRequest.Post(tAPIURL) $$$ThrowOnError(tSC)
		Set tHttpResponse = tHTTPRequest.HttpResponse
		Set tStatusCode = tHttpResponse.StatusCode
		If 'tStatusCode?1"2"2N {
			$$$ThrowOnError($$$ERROR($$$GeneralError,"PullRequest failed with HTTP code: "_tStatusCode))
		}

		Set tResponseString = tHttpResponse.Data.Read()
		Set tResponseData=##class(%DynamicObject).%FromJSON(tResponseString)
		
		w !,tResponseString
		
		*/
		
	} catch e {
		s tSC = e.AsStatus()
		Set pOutput($increment(pOutput))=e.DisplayString()
	}
	Quit tSC
}

}

