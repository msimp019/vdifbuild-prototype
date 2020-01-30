Include HS.Common

/// <a href="http://www.readycomputing.com/">
/// <img src="http://www.readycomputing.com/images/header/headerLogo.png" alt="Ready Computing" >
/// </a>
/// <br/>
/// Source control settings page
Class User.SourceControl.Git.Setting Extends HS.UI.Template [ DependsOn = (HS.UI.Custom.tablePane, HS.UI.Custom.tabGroup) ]
{

/// Page title
Property PageTitle As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Source Control Settings")} ];

/// This Style block contains page-specific CSS style definitions.
XData Style
{
<style type="text/css">
	
	a.link:visited {
		color: black;
		font-family: tahoma,arial,verdana;
    	font-size: 12px;
    	text-decoration: none;
	}
	a.link:hover {
		background-color: LightGray;
	}
	a.link {
		color: black;
		font-family: tahoma,arial,verdana;
    	font-size: 12px;
    	text-decoration: none;
	}
	
	.linkDisabled {
		color: gray;
		font-family: tahoma,arial,verdana;
    	font-size: 12px;
    	text-decoration: none;
	}

</style>
}

/// This XML block defines the contents of this page.
XData detailPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" title="Settings">
<fieldSet legend="Settings">
<form labelPosition="left" OnSubmitForm="SubmitForm">
<spacer height="20"/>
<text id="userName" name="userName" label="Repository username:" title="BitBucket or other Repo username" required="true" size="100"/>
<text id="personName" name="personName" label="Your Name:" title="Your Name" required="true" size="100"/>
<text id="personEmail" name="personEmail" label="Your Email:" title="you@example.com" required="true" size="100"/>
<text id="teamBranch" name="teamBranch" label="Team Branch:" title="example: team-dev/teamA" required="true" size="100"/>
<text id="repoBaseFolder" name="repoBaseFolder" label="Base path for all user's repositories:" title="(e.g. c:\temp)" required="true" size="100"/>
<submit caption="Save"/>
</form>
</fieldSet>
<spacer height="20"/>
<fieldSet legend="Actions" hidden="true">
<spacer height="20"/>
<link id="CloneLink" href="User.SourceControl.Git.Dialogue.cls?UserAction=Clone Repository" disabled="true" caption="Clone Repository" target="_self" />
<link id="StatusLink" href="User.SourceControl.Git.Dialogue.cls?UserAction=Status" disabled="true" caption="Status" target="_self" />
<link id="CommitLink" href="User.SourceControl.Git.Dialogue.cls?UserAction=Commit" disabled="true" caption="Commit" target="_self" />
<spacer height="20"/>
</fieldSet>
<fieldSet id="fsGit" hidden="true" legend="Git">
<combobox id="cmbGitUsers" label="User" size="35" disabled="false" editable="false" >
</combobox>
<text id="gitCommand" name="gitComand" label="Git Command" size="100" hint="(Enter git command without 'git'.  example: 'status')"/>
<button id="btnGitCommand" name="btnGitCommand" caption="Run" onclick="zenPage.runGitCommand();" />
<link caption="Git Documentation" href="https://git-scm.com/docs" target="_blank" style="color: blue;"/>
<html id="gitOutput"/>
</fieldSet>
</pane>
}

/// Callback to process values submitted for form.
ClassMethod SubmitForm(pSubmit As %ZEN.Submit) As %Status
{
	
	#dim tSettings As %String
	Set tSettings("repoBaseFolder")=pSubmit.%GetValue("repoBaseFolder")
	Set tSettings("userName")=pSubmit.%GetValue("userName")
	Set tSettings("personName")=pSubmit.%GetValue("personName")
	Set tSettings("personEmail")=pSubmit.%GetValue("personEmail")
	Set tSettings("teamBranch")=pSubmit.%GetValue("teamBranch")
	d ##class(User.SourceControl.Git.Utils).UpdateSettings(.tSettings)
	QUIT $$$OK
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	//Set tCtrl=..%GetComponentById("gitBinPath")
	//Set tCtrl.value=##class(User.SourceControl.Git.Utils).GitBinPath()

	Set tCtrl=..%GetComponentById("repoBaseFolder")
	Set tCtrl.value=##class(User.SourceControl.Git.Utils).RepoBaseFolder()
	
	Set tCtrl=..%GetComponentById("userName")
	Set tCtrl.value=##class(User.SourceControl.Git.Utils).UserName()
	
	Set tCtrl=..%GetComponentById("personName")
	Set tCtrl.value=##class(User.SourceControl.Git.Utils).PersonName()
	
	Set tCtrl=..%GetComponentById("personEmail")
	Set tCtrl.value=##class(User.SourceControl.Git.Utils).PersonEmail()
	
	Set tCtrl=..%GetComponentById("teamBranch")
	Set tCtrl.value=##class(User.SourceControl.Git.Utils).TeamBranch()
	
	
#;	if '##class(User.SourceControl.Git.Utils).NeedSettings() {
#;		if '##class(User.SourceControl.Git.Utils).IsNamespaceInGit() {
#;			Set tCtrl=..%GetComponentById("CloneLink")
#;			Set tCtrl.disabled = 0
#;		} else {
#;			Set tCtrl=..%GetComponentById("StatusLink")
#;			Set tCtrl.disabled = 0
#;			Set tCtrl=..%GetComponentById("CommitLink")
#;			Set tCtrl.disabled = 0
#;			
#;		}
#;	}
	
#;	if $System.Security.Check("AH_SourceControlAdmin","USE") {
#;		//This feature allows any admin to run any git command against any local repository!
#;		Set tFS=..%GetComponentById("fsGit")
#;		Set tFS.hidden = 0
#;		
#;		s tUserList=""
#;		s tUser=""
#;		For { s tUser = $O(^Git("%user",tUser)) Q:tUser=""
#;			s tUserList = tUserList_","_tUser
#;		}
#;		Set tCombo=..%GetComponentById("cmbGitUsers")
#;		Set tCombo.displayList = tUserList
#;		Set tCombo.valueList = tUserList
#;		
#;	}
		
	Quit $$$OK
}

ClientMethod runGitCommand() [ Language = javascript ]
{
	var User = zenPage.getComponentById('cmbGitUsers').getValue();
	var Command = zenPage.getComponentById('gitCommand').getValue();
	
	var ok = this.HandleGitCommand(User,Command);
}

ClassMethod HandleGitCommand(pUser, pCommand) As %String [ ZenMethod ]
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	#dim tReturn As %String = 1
	
	Try {
		s tGitCommand = "git -C "_^Git("%user",pUser,"%repositoryFolder")_" "
		s tGitCommand = tGitCommand_pCommand
		s tSC = ##class(User.SourceControl.Git.Utils).RunCmd(tGitCommand,.tOutput,0)
		s tHTML="<br/>"
		if tSC {
			for i=1:1:tOutput {
				s tHTML = tHTML_tOutput(i) _"<br/>"
			}
		} else {
			s tHTML=$System.Status.GetErrorText(tSC)
		}

		&js< zenPage.getComponentById('gitOutput').setProperty('content','#($ZCVT(tHTML,"O","JS"))#');>
		
	} catch e {
		s tReturn = e.DisplayString()
	}
	Quit tReturn
}

/// Revision number of this class
Parameter SrcVer = 2;

}

