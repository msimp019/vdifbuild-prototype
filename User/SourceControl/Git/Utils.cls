Include %occStatus

/// <a href="http://www.readycomputing.com/">
/// <img src="http://www.readycomputing.com/images/header/headerLogo.png" alt="Ready Computing" >
/// </a> 
/// <br/>
Class User.SourceControl.Git.Utils [ Abstract, ProcedureBlock ]
{

Parameter Storage = "^Git";

Parameter UseUDL = 1;

/// Extensions that can not be exported as UDL. XML will always be used.
Parameter NOTUDLEXTENSIONS = {$lb("hl7","dfi","lut")};

Parameter InstallNamespace = "HSCUSTOM";

/// If equals to 0 all tortoise-git calls are asynchronous<br/>
/// Otherwise calls are synchronous and import is automatically executed after git calls.
Parameter IsSYNC = 0;

/// Git menu commands
Parameter GitMenuItems = ",Pull,Clone Repository,Status,Switch to Branch,Load Branch,";

/// Menu Items that show, but are only enabled when on a Feature branch.
Parameter GitFeatureMenuItems = ",Commit,Push,Pull,Pull from Develop,Pull from Team,Diff with Team,Merge to Team and Delete,";

/// Menu Items that show, but are only enabled when on a Team branch.
Parameter GitTeamMenuItems = ",Pull,Pull from Develop,Create Feature Branch,";

/// Menu Items that show, but are only enabled when on a Team branch.
Parameter GitReleaseMenuItems = ",Commit,Push,Pull,";

/// RC: Removed %Blame,
Parameter GitContextMenuItems = ",";

ClassMethod InstallNamespaceStorage() As %String [ CodeMode = expression ]
{
$Replace(..#Storage,"^","^["""_..#InstallNamespace_"""]")
}

/// Returns root temp folder
ClassMethod RepoFolder() As %String [ CodeMode = expression ]
{
$G(@..InstallNamespaceStorage()@("%user",$USERNAME,"%repositoryFolder"))
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
$G(@..InstallNamespaceStorage()@("%repoURL"))
}

/// Returns root temp folder
ClassMethod RepoBaseFolder() As %String [ CodeMode = expression ]
{
$G(@..InstallNamespaceStorage()@("%repoBaseFolder"))
}

/// Returns root temp folder
ClassMethod RepoName() As %String [ CodeMode = expression ]
{
$G(@..InstallNamespaceStorage()@("%repoName"))
}

/// Returns root temp folder
ClassMethod RepoProtocol() As %String [ CodeMode = expression ]
{
$G(@..InstallNamespaceStorage()@("%repoProtocol"))
}

/// Returns default git command prefix
ClassMethod GitCmdPrefix() As %String [ CodeMode = expression ]
{
"git -C "_..RepoFolder()
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
..#InstallNamespace
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
	//Always include develop and team brances
	s tTeamBranch = ..TeamBranch()
	s tBranchList=",develop,"_tTeamBranch
	
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
				
				//I don't recall what this code is supposed to be doing
				//However, you shouldn't be able to switch to feature branch that is not from your team branc
				//So perhaps this code needs to be reworked a bit to accomplish that?
#;				kill tOutputCheckout
#;				s tCommand = ..GitCmdPrefix()_" checkout "_tBranch
#;				s tSC = ..RunCmd(tCommand,.tOutputCheckout,tDisplay)
#;				if $$$ISERR(tSC) Quit
#;				
#;				kill tOutputInitialCommit
#;				s tCommand = ..GitCmdPrefix()_" log --grep=""Initial commit"" --oneline --decorate"
#;				s tSC = ..RunCmd(tCommand,.tOutputInitialCommit,tDisplay)
#;				if $$$ISERR(tSC) Quit
#;				
#;				s tInitialCommit = $G(tOutputInitialCommit(1))
#;				if tInitialCommit [ tTeamBranch {
					s tBranchList=tBranchList_","_tBranch
#;				}
			}
		}
	}
	if $$$ISERR(tSC) Quit "error"
	Quit tBranchList
}

ClassMethod UpdateSettings(ByRef settings) As %Status
{
  
    // set user properties - username and password to start with.
    s @..InstallNamespaceStorage()@("%user",$USERNAME,"%userName") = settings("userName")
    s @..InstallNamespaceStorage()@("%user",$USERNAME,"%personName") = settings("personName")
    s @..InstallNamespaceStorage()@("%user",$USERNAME,"%personEmail") = settings("personEmail")
    s @..InstallNamespaceStorage()@("%user",$USERNAME,"%teamBranch") = $G(settings("teamBranch"))
    s @..InstallNamespaceStorage()@("%user",$USERNAME,"%releaseBranchBase") = $G(settings("releaseBranchBase"))
    
    If $System.Security.Check("AH_SourceControlAdmin","USE") {    
	    // set Repository url - example: bitbucket.org/readycomputinginc/alohr.git
	    s @..InstallNamespaceStorage()@("%repoURL") = settings("repoURL")
	    s @..InstallNamespaceStorage()@("%repoProtocol") = settings("repoProtocol")
	    s @..InstallNamespaceStorage()@("%repoName") = $P($P(settings("repoURL"),"/",$L(settings("repoURL"),"/")),".",1)
	    // set Repository url - example: bitbucket.org/readycomputinginc/alohr.git
	    s @..InstallNamespaceStorage()@("%repoBaseFolder") = ##class(%File).NormalizeDirectory(settings("repoBaseFolder"))
    }    
    //Build user's repo folder using the base folder, username, and repository name
    s tFolder = ##class(%File).NormalizeDirectory(..RepoBaseFolder()_$USERNAME_"\"_..RepoName())
    s @..InstallNamespaceStorage()@("%user",$USERNAME,"%repositoryFolder") = tFolder
}

ClassMethod HandleDialogue(ByRef pSettings, ByRef pOutput) As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	w "HandleDialogue",!
	zw pSettings
	
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
			s tCommand = "git -C "_tFolder
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
			s tBranchName = pSettings(tCommandName)
			if '$FIND(tBranchName,"feature/") s tBranchName = "feature/"_tBranchName
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
			s tBranchName = pSettings(tCommandName)
			if '$FIND(tBranchName,"release/") s tBranchName = "release/"_tBranchName
			
			s tCreateBranchCommand = tCommand_" checkout -b "_tBranchName
			s tSC = ..RunCmd(tCreateBranchCommand,.pOutput) $$$ThrowOnError(tSC)
			
			s tCommand = tCommand_" push --set-upstream origin "_tBranchName
		} elseif tCommandName = "Pull from Develop" {

			//Pull just to ensure the release branch base is up to date locally before creating release branch
			s tPullCommand = tCommand_" pull --rebase"
			s tSC = ..RunCmd(tPullCommand,.pOutput) $$$ThrowOnError(tSC)

			s tCommand = tCommand_" merge origin/develop"
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

		} elseif tCommandName = "Merge to Team and Delete" {
			//First, get the current branch
			s tCurrentBranch = ..CurrentBranch()
			
			//Push the feature branch to remote
			s tPushCommand = tCommand_" push"
			s tSC = ..RunCmd(tPushCommand,.pOutput) $$$ThrowOnError(tSC)

			//Then check out the team branch to merge to
			s tCheckoutTargetBranch = tCommand_" checkout "_..TeamBranch()
			s tSC = ..RunCmd(tCheckoutTargetBranch,.pOutput) $$$ThrowOnError(tSC)
			
			//First Pull the team branch
			s tPullTeamCommand = tCommand_" pull --rebase"
			s tSC = ..RunCmd(tPullTeamCommand,.pOutput) $$$ThrowOnError(tSC)

			//Then do the merge
			s tMergeTeamCommand = tCommand_" merge --squash "_tCurrentBranch
			s tSC = ..RunCmd(tMergeTeamCommand,.pOutput) $$$ThrowOnError(tSC)
			
			s tMergeCommitCommand = tCommand_" commit -m ""merge commit from feature branch: "_tCurrentBranch_""""
			s tSC = ..RunCmd(tMergeCommitCommand,.pOutput) $$$ThrowOnError(tSC)
			
			//Push the merged team branch to remote
			s tTeamPushCommand = tCommand_" push"
			s tSC = ..RunCmd(tTeamPushCommand,.pOutput) $$$ThrowOnError(tSC)

			//Now checkout the feature branch to delete it
			s tCheckoutCurrentBranch = tCommand_" checkout "_tCurrentBranch
			s tSC = ..RunCmd(tCheckoutCurrentBranch,.pOutput) $$$ThrowOnError(tSC)

 			//Now delete the feature branch from remote
			s tRemoteDeleteCommand = tCommand_" push --delete origin "_tCurrentBranch
			s tSC = ..RunCmd(tRemoteDeleteCommand,.pOutput) $$$ThrowOnError(tSC)

			//Now checkout the team branch in order to delete the local feature branch
			s tSC = ..RunCmd(tCheckoutTargetBranch,.pOutput) $$$ThrowOnError(tSC)

			//Now delete the feature branch using -D to force the delete
			s tCommand = tCommand_" branch -D "_tCurrentBranch
			
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

ClassMethod IsFeatureMenuGitCommand(menuItemName As %String) As %Boolean [ CodeMode = expression ]
{
$F(..#GitFeatureMenuItems, ","_menuItemName_",") > 0
}

ClassMethod IsReleaseMenuGitCommand(menuItemName As %String) As %Boolean [ CodeMode = expression ]
{
$F(..#GitReleaseMenuItems, ","_menuItemName_",") > 0
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
            #dim defNamespace As %String = ..#InstallNamespace
            Set Target="/csp/healthshare/"_$ZCVT($NAMESPACE,"L")_"/User.SourceControl.Git.Setting.cls"
        } elseif ..IsMenuGitCommand(menuItemName) || ..IsFeatureMenuGitCommand(menuItemName) || ..IsReleaseMenuGitCommand(menuItemName) || ..IsTeamMenuGitCommand(menuItemName) {
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
    
    // lower case for extensions
    #dim extension As %String = $ZCVT($P(name,".",$L(name,".")),"L")
    s $P(name,".",$L(name,".")) = extension
    
    // we shall put classes in different folders
    //if extension = "cls" {
        s name = $TR( $P(name,".", 1, $L(name,".")-1), ".", tBackslash)_"."_extension
    //}
    
    // we shall delete csp-app from csp files
    if $E(name, 1) = tBackslash {
        s $E(name, 1) = ""
    }
    if $P(name, tBackslash, 1) = "csp" {
        s $P(name, tBackslash, 1, 2) = "csp"
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

ClassMethod LoadSettings(pRepoBaseFolder, pUserName, pRepoURL, pRepoProtocol, pPersonName, pPersonEmail) As %Status
{
	
	Set tSettings("repoBaseFolder")=pRepoBaseFolder
	Set tSettings("userName")=pUserName
	Set tSettings("repoURL")=pRepoURL
	Set tSettings("repoProtocol")=pRepoProtocol
	Set tSettings("personName")=pPersonName
	Set tSettings("personEmail")=pPersonEmail
	d ##class(User.SourceControl.Git.Utils).UpdateSettings(.tSettings)
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
		
		s tOutput=""
		
		if '..IsNamespaceInGit() {
			s tSettings("Clone Repository")=pPassword
			s tSC=..HandleDialogue(.tSettings,.tOutput)
			$$$ThrowOnError(tSC)
		}
		
		Kill tSettings
		s tSettings("Switch to Branch")=pBranch
		s tSC=..HandleDialogue(.tSettings,.tOutput)
		$$$ThrowOnError(tSC)
		
		Kill tSettings
		s tSettings("Pull")=pBranch
		s tSC=..HandleDialogue(.tSettings,.tOutput)
		$$$ThrowOnError(tSC)
		
		//LoadDir is .xml only - do we need to switch to ImportDir to handle csp files?
		s (tErrors,tLoaded)=""
		s tSC = $System.OBJ.ImportDir(..RepoFolder(),"*.xml","cbfk",.tErrors,1,.tLoaded)
		s tSC = $System.OBJ.ImportDir(..RepoFolder(),"*.xsl","cbfk",.tErrors,1,.tLoaded)
		s tSC = $System.OBJ.ImportDir(..RepoFolder(),"*.cls","cbfk",.tErrors,1,.tLoaded)
		s tSC = $System.OBJ.ImportDir(..RepoFolder(),"*.mac","cbfk",.tErrors,1,.tLoaded)
		s tSC = $System.OBJ.ImportDir(..RepoFolder(),"*.lut","cbfk",.tErrors,1,.tLoaded)
		s tSC = $System.OBJ.ImportDir(..RepoFolder(),"*.hl7","cbfk",.tErrors,1,.tLoaded)
		
		
	} catch e {
		//s tSC = e.AsStatus()
		//w !,e.DisplayString()
	}
	
	for i=1:1:tOutput {
		w tOutput(i)
	}
	
	Quit tSC
}

ClassMethod BuildDeployment(pFilename, pIntegrationBranch, pSourceBranch) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	#dim tStream As %Stream.Object
	
	Try {

		Kill tSettings
		s tSettings("Switch to Branch")=pSourceBranch
		Kill tOutput
		s tSC=..HandleDialogue(.tSettings,.tOutput)
		$$$ThrowOnError(tSC)
		
		Kill tSettings
		s tSettings("Pull")=pSourceBranch
		Kill tOutput
		s tSC=..HandleDialogue(.tSettings,.tOutput)
		$$$ThrowOnError(tSC)

		//Switch to the integration branch in order to do the diff with the source branch
		Kill tSettings		
		s tSettings("Switch to Branch")=pIntegrationBranch
		Kill tOutput
		s tSC=..HandleDialogue(.tSettings,.tOutput)
		$$$ThrowOnError(tSC)
		
		//Get the new/changed files in the diff between integration branch and source branch
		Kill tSettings
		s tSettings("ListDiff")=pSourceBranch
		Kill tOutput
		s tSC=..HandleDialogue(.tSettings,.tOutput)
		$$$ThrowOnError(tSC)
		
		w "This is the diff object",!
		zw tOutput
		w !
		Merge tImportList = tOutput
		zw tImportList
		w !
		//Now that we have the list, switch to the source branch and load the files, ensuring each compile
		Kill tSettings
		s tSettings("Switch to Branch")=pSourceBranch
		Kill tOutput
		s tSC=..HandleDialogue(.tSettings,.tOutput)
		$$$ThrowOnError(tSC)
		
		w " we got this"
		
		s tLoadList = ""
		for i=1:1:tImportList {
			w !,i_"looping"
			s tItem=tImportList(i)
			s tLoadList = tLoadList_$S(tLoadList="":"",1:"*")_..RepoFolder()_tItem
			s tExtension = $P(tItem,".",$LENGTH(tItem,"."))
			s tInternalName = tItem
			if tExtension = "xml" {
				s tInternalName = $REPLACE(tInternalName,".xml","")
			}
			s tItemExtension = $P(tInternalName,".",$LENGTH(tInternalName,"."))
			s tInternalName = $REPLACE(tInternalName,"."_tItemExtension,"."_$ZCVT(tItemExtension,"U"))
			s tInternalName = $TR(tInternalName,"/",".")
			if tInternalName="" Continue
			
			Set tContentsList(tInternalName)=""

		}
		
		w "Line 1306"
		//a load list is compiled here so that multiple files can be loaded at one so that class DependsOn statements can be honored
		//But concern is whether the tLoadList may become too large?
		s tSC = $System.OBJ.Load(tLoadList,"cbfk",,.loadedList) $$$ThrowOnError(tSC)
		
		k ^XABSMAC
		s ^XABSMAC=0
		zw loadedList
		set name=$O(loadedList(""))
		while name'=""
		{
			if $piece(name,".")="ConfigScripts"
			{
				s ^XABSMAC=^XABSMAC+1
				s ^XABSMAC(^XABSMAC)=$piece(name,".",1,*-1)
				set command="do ^"_^XABSMAC(^XABSMAC)
				zw command
				XECUTE command
			}
			set name=$O(loadedList(name))
		}
		
		s tProjectName = $TR(pIntegrationBranch,"/","")
		s tProductionName = ""
		//Set:(tItemName '[ "||") tItemName = tProductionName_"||"_tItemName
		
		w "line1315"
		Set tProductionClassIncluded = 0
		Set tComments = "Deploy Package created programatically."
		Set tSC =##class(Ens.Deployment.Utils).CreateExportPackageFromProjectList(tProjectName,.tContentsList,pFilename,tProductionName,tComments,tProductionClassIncluded)
		$$$ThrowOnError(tSC)

		w !, "Deploy Package built and exported to: "_pFilename
		
	} catch e {
		s tSC = e.AsStatus()
	}
	Quit tSC
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
			Set tCreateRollBack = 1, tAllowDeployToSource = 1 ,tAutoRevert = 1, tWhereToLog = "LC"
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
		s tImportRequest.CallBackMethod = "" //how do we determine the config script?
		
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

ClassMethod test123(X As %DynamicArray)
{
}

ClassMethod Deploy(pFilename As %String, pTargetHost As %String, pTargetPort As %String, pTargetNamespace As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	#dim tDeployStatus As %Boolean = 1
	zw pFilename
	zw pTargetHost
	zw pTargetPort
	zw pTargetNamespace
	
	Try{
		zw ^XABSMAC
		s tImportRequest = ##class(User.SourceControl.Deploy.ImportRequest).%New()
		
		s tResponse="-------------------------------"_$C(10)
		s tResponse=tResponse_"Beginning deployment to "_pTargetHost_":"_pTargetPort_$C(10)
		s tResponse=tResponse_"-------------------------------"_$C(10)
		
		//Identify the Configuration Script and set it to the ImportRequest
		s tSC = ##class(Ens.Deployment.Deploy).GeneratePackageXMLVDOC(pFilename,.tDeploymentVDOC)
		$$$ThrowOnError(tSC)
		
		s tSC = ##class(Ens.Deployment.Deploy).GetProjectContents(pFilename,tDeploymentVDOC,.pTargetProduction,.tDeployDetails)
		$$$ThrowOnError(tSC)
		
		zw tDeployDetails
		
		s (tItemName,tCallBack) = ""
		For { s tItemName = $O(tDeployDetails("Items",tItemName)) Q:tItemName=""
			if $G(tDeployDetails("Items",tItemName,"Type"))="MAC" {
				if $P(tItemName,".",1)="ConfigScripts" {
					s tCallBack = "^"_$P(tItemName,".",1,$LENGTH(tItemName,".")-1)
				}
			}
		}
		
		zw tCallBack
		s tImportRequest.CallBackMethod = tCallBack
		
		w !!
		s ConfigScripts=[]
		for i=1:1:^XABSMAC
		{
			do ConfigScripts.%Push(^XABSMAC(i))
		}
 //		set tImportRequest.ConfigScriptsJSON=ConfigScripts.%ToJSON()
		
		//Create the Import Request and add one ImportObject to it.  The import object will be the deploy file.
		s tDeployStream = ##class(%FileCharacterStream).%New()
		s tDeployStream.Filename = pFilename
		
		
		s tImportObject = ##class(User.SourceControl.Deploy.ImportObject).%New()
		s tSC = tImportObject.ObjectStream.CopyFrom(tDeployStream) $$$ThrowOnError(tSC)
		s tImportObject.Name = ##class(%File).GetFilename(pFilename)
		s tSC = tImportRequest.Objects.Insert(tImportObject) $$$ThrowOnError(tSC)
		
		zw tImportRequest
		
		
		Set tServiceClient=##class(User.SourceControl.Deploy.ServiceClient).%New()
		Set tServiceClient.Location="http://"_pTargetHost_":"_pTargetPort_"/csp/healthshare/"_$ZCVT(pTargetNamespace,"L")_"/services/User.SourceControl.Deploy.Service.cls"
		//Set tServiceClient.SSLConfiguration = tConfig.SSLConfig
		Set tServiceClient.Timeout = 300
		Set tCredentials = ##class(Ens.Config.Credentials).%OpenId("HS_Credentials")  //Build installer sets this on initial setup
		Set tSC=tServiceClient.WSSecurityLogin(tCredentials.Username,tCredentials.Password) $$$ThrowOnError(tSC)

		Set tResponse = tServiceClient.Deploy(tImportRequest,.tDeployStatus)
		
		
		
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
	
	
	//test reutrn value
#;	w !,$I(^MS("count"))
#;	if ^MS("count")#2 = 0 s tDeployStatus = 0
	

	Quit $C(10)_$CASE(tDeployStatus,1:"SUCCESS",0:"FAILURE",:"")
}

}

