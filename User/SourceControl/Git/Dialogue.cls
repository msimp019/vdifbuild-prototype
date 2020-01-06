Include HS.Common

/// <a href="http://www.readycomputing.com/">
/// <img src="http://www.readycomputing.com/images/header/headerLogo.png" alt="Ready Computing" >
/// </a>
/// <br>
/// Source control dialogue page
Class User.SourceControl.Git.Dialogue Extends HS.UI.Template [ DependsOn = (HS.UI.Custom.tablePane, HS.UI.Custom.tabGroup) ]
{

/// Security requirement
Parameter RESOURCE = "AH_SourceControl";

/// Page title
Property PageTitle As %ZEN.Datatype.caption [ InitialExpression = {$$$TextHTML("Source Control")} ];

Parameter NoDialogueActions = ",Status,Pull,Push,Add,Pull from Develop,Pull from Team,Diff with Team,Load Branch,";

/// This XML block defines the contents of this page.
XData detailPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen">
<form id="DialogueForm" method="post" labelPosition="left" OnSubmitForm="SubmitForm" hidden="true">
<text id="UserAction" hidden="true" name="UserAction" label="hidden field for storing user action" required="false" size="100"/>
<text id="NoDialogueActions" hidden="true" name="NoDialogueActions" label="hidden field for storing user action" required="false" size="100"/>
<text id="Commit" hidden="true" name="Commit" label="Commit Comment:" required="false" size="100"/>
<select id="Switch to Branch" hidden="true" name="Switch to Branch" showEmpty="false" width="100" label="Switch to Branch:" required="false"/>
<text id="Create Feature Branch" hidden="true" name="Create Feature Branch" label="Branch name: feature/" required="false" size="100"/>
<text id="Create Release Branch" hidden="true" name="Create Release Branch" label="Release name: release/" required="false" size="100"/>
<text id="Create Bugfix Branch" hidden="true" name="Create Bugfix Branch" label="Branch name: bugfix/" required="false" size="100"/>
<select id="Merge From Branch" hidden="true" name="Merge From Branch" showEmpty="false" width="100" label="Merge From Branch:" required="false"/>
<password id="Clone Repository" hidden="true" name="Clone Repository" label="Repository user account password:" required="false" size="100"/>
<html id="Merge to Team and Delete" hidden="true"/>
<submit caption="Submit"/>
</form>
<html id="Output" hidden="true" OnDrawContent="DrawOutput"/>
</pane>
}

Method DrawOutput(seed As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
		
		if $D(%session.Data("Output"))>0 {
			Set ..%GetComponentById("Output").hidden=0
			
			for i=1:1:%session.Data("Output") {
				s tOutputLine = %session.Data("Output",i)
				&html<
					#(tOutputLine)#
					<br>
				>
			}
			Kill %session.Data("Output")
			Kill %session.Data("UserAction")
		}
		
	} catch e {
		s tSC = e.AsStatus()
	}
	Quit tSC
}

/// Callback to process values submitted for form.
ClassMethod SubmitForm(pSubmit As %ZEN.Submit) As %Status
{
	#dim tSettings As %String
	
	Set tUserAction = pSubmit.%GetValue("UserAction")
	s ^XABS=tUserAction
	if $D(pSubmit.%Data(tUserAction))>0 {
		Set tSettings(tUserAction)=pSubmit.%GetValue(tUserAction)
		set ^XABS(tUserAction)=tSettings(tUserAction)
	} else {
		Set tSettings(tUserAction)=""
	}
	
	s tSC = ##class(User.SourceControl.Git.Utils).HandleDialogue(.tSettings,.tOutput)
	Q:$$$ISERR(tSC) tSC
	
	merge %session.Data("Output") = tOutput
	Set %session.Data("UserAction") = tUserAction
	
	QUIT $$$OK
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	Set tUserAction = $G(%request.Data("UserAction",1))
	Set ..%GetComponentById("UserAction").value = tUserAction
	Set ..%GetComponentById("NoDialogueActions").value = ..#NoDialogueActions
	
	if tUserAction'="" {
		
		if $F(..#NoDialogueActions, ","_tUserAction_",") > 0 {
			
		} else {
			Set ..%GetComponentById("DialogueForm").hidden=0
			Set ..%GetComponentById(tUserAction).hidden=0
			
			if tUserAction="Switch to Branch" || "Create Bugfix Branch" {
				Set ..%GetComponentById(tUserAction).valueList = ##class(User.SourceControl.Git.Utils).BranchList(1)
			} elseif tUserAction="Merge to Team and Delete" {
				Set ..%GetComponentById(tUserAction).content = "Please confirm:<br><br>Merge from: "_##class(User.SourceControl.Git.Utils).CurrentBranch()_"<br>Merge to: "_##class(User.SourceControl.Git.Utils).TeamBranch()_"<br><br>Once merge is completed, "_##class(User.SourceControl.Git.Utils).CurrentBranch()_" will be deleted.<br><br>"
			} 

			
		}
		
	} else {
		Set ..%GetComponentById("Output").hidden=0
	}
		
	Quit $$$OK
}

ClientMethod onloadHandler() [ Language = javascript ]
{
	var noDialogueActions = zenPage.getComponentById("NoDialogueActions").value
	var userAction = zenPage.getComponentById("UserAction").value
	var n = noDialogueActions.indexOf(userAction)
	if (n > 0) {
		zenPage.getComponentById("DialogueForm").submit();
	}
}

}

