Include HS.Common

/// <a href="http://www.readycomputing.com/">
/// <img src="http://www.readycomputing.com/images/header/headerLogo.png" alt="Ready Computing" >
/// </a>
/// <br/>
/// Source control settings page
Class User.SourceControl.Git.MergeConflicts Extends (HS.UI.Template, User.SourceControl.Git.Utils) [ DependsOn = (HS.UI.Custom.tablePane, HS.UI.Custom.tabGroup) ]
{

/// Security requirement
Parameter RESOURCE = "AH_SourceControl";

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

<html id="Output" hidden="false" OnDrawContent="DrawOutput"/>
<html id="gitOutput" hidden="true"/>

</pane>
}

Method DrawOutput(seed As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
		
		s tCommand = ..GitCmdPrefix()
		s tCommand = tCommand_" status"
		s tSC = ..RunCmd(tCommand,.tOutput,0) $$$ThrowOnError(tSC)

		Set ..%GetComponentById("Output").hidden=0
		
		s tMergeConflict=0
		for i=1:1:tOutput {
			s tOutputLine = tOutput(i)
			if $ZCVT(tOutputLine,"L") [ "unmerged" s tMergeConflict = 1
			&html<
				#(tOutputLine)#
				<br>
			>
		}
		
		Kill tOutput
		s tCommand = ..GitCmdPrefix()
		s tCommand = tCommand_" status -s"
		s tSC = ..RunCmd(tCommand,.tOutput,0) $$$ThrowOnError(tSC)
		&html<
			<br>
			Unmerged Files:
			<br>
		>
		for i=1:1:tOutput {
			s tOutputLine = tOutput(i)
			if $E(tOutputLine,1,2) [ "U" {
				
			}
			&html<
				#(tOutputLine)#
				<br>
			>
		}
		
		
		
	} catch e {
		s tSC = e.AsStatus()
	}
	Quit tSC
}

/// This callback is called after the server-side page 
/// object and all of its children are created.<br/>
/// Subclasses can override this to add, remove, or modify 
/// items within the page object model, or to provide values
/// for controls.
Method %OnAfterCreatePage() As %Status
{
	
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
