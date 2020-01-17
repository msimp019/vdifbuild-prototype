Include Ensemble

/// <a href="http://www.readycomputing.com/">
/// <img src="http://www.readycomputing.com/images/header/headerLogo.png" alt="Ready Computing" >
/// </a>
/// <br>
Class User.SourceControl.Git.Hooks Extends %Studio.Extension.Base
{

// RC: Add Name="%Separator" for all separators

XData Menu
{
<MenuBase>
<Menu Name="Source Control Context Menu" Type="0">
<MenuItem Name="Add To"/>
<MenuItem Name="Add To Release"/>
<MenuItem Name="Remove From"/>
</Menu>
<Menu Name="%SourceMenuContext" Type="1">
<MenuItem Name="Add To"/>
<MenuItem Name="Add To Release"/>
<MenuItem Name="Remove From"/>
</Menu>
<Menu Name="Source Control Main Menu" Type="0">
<MenuItem Name="Settings" />
<MenuItem Name="Clone Repository" Save = "001"/>
<MenuItem Name="%Separator" Separator="true"/>
<MenuItem Name="Current Branch" Save = "001"/>
<MenuItem Name="Switch to Branch" Save = "001"/>
<MenuItem Name="Status" Save = "001"/>
<MenuItem Name="%Separator" Separator="true"/>
<MenuItem Name="Commit" Save = "001"/>
<MenuItem Name="Pull" Save = "001"/>
<MenuItem Name="Push" Save = "001"/>
<MenuItem Name="%Separator" Separator="true"/>
<MenuItem Name="Create Feature Branch" Save = "001"/>
<MenuItem Name="Create Release Branch" Save = "001"/>
<MenuItem Name="Re-create Team Branch" Save = "001"/>
<MenuItem Name="Create Bugfix Branch" Save = "001"/>
<MenuItem Name="%Separator" Separator="true"/>
<MenuItem Name="Pull from Develop" Save = "001"/>
<MenuItem Name="Pull from Team" Save = "001"/>
<MenuItem Name="Diff with Team" Save = "001"/>
<MenuItem Name="%Separator" Separator="true"/>
<MenuItem Name="Merge to Team and Delete" Save = "001"/>
<MenuItem Name="Merge to Release and Delete" Save = "001"/>
<MenuItem Name="%Separator" Separator="true"/>
<!--<MenuItem Name="Resolve Merge Conflicts" Save = "001"/>-->
<MenuItem Name="Load Branch" Save = "001"/>
</Menu>

</MenuBase>
}

Method UserAction(Type As %Integer, Name As %String, InternalName As %String, SelectedText As %String, ByRef Action As %String, ByRef Target As %String, ByRef Msg As %String, ByRef Reload As %Boolean) As %Status
{
	
	#dim ec As %Status = $$$OK
	#dim menu As %Status = $Piece(Name, ",", 1)
	if menu '= "Source Control Context Menu",menu '= "Source Control Main Menu", menu'="%SourceMenuContext" {
		Quit $$$OK
	}
	s ec = ##class(User.SourceControl.Git.Utils).UserAction(InternalName, Name, .Target, .Action, .Reload)
	Quit ec
}

Method OnSourceMenuItem(name As %String, ByRef Enabled As %String, ByRef DisplayName As %String) As %Status
{
	//RC: Adding separator
	if name = "%Separator" {
		s DisplayName = ""
		s Enabled = 0
		Quit $$$OK
	}
	//RC:
	if name = "Settings" {
		// We always show Settings
		Quit $$$OK
	} 
	
	if ##class(User.SourceControl.Git.Utils).NeedSettings() {
		s Enabled = -1
		Quit $$$OK
	} 
	
	s tCurrentBranch = ##class(User.SourceControl.Git.Utils).CurrentBranch()
	s Enabled = 0
	if ##class(User.SourceControl.Git.Utils).IsNamespaceInGit() {
		if name = "Clone Repository" {
			s Enabled = 0
		} elseif name = "Current Branch" {
			s DisplayName = "Current Branch: "_##class(User.SourceControl.Git.Utils).CurrentBranch()
			s Enabled = 0
		} elseif name = "Resolve Merge Conflicts" {
			s Enabled = 1
		} elseif (##class(User.SourceControl.Git.Utils).IsDevelopMenuGitCommand(name))&&($F($ZCVT(tCurrentBranch,"U"),"DEVELOP")>0) {
			s Enabled = 1
		} elseif (##class(User.SourceControl.Git.Utils).IsFeatureMenuGitCommand(name))&&($F($ZCVT(tCurrentBranch,"U"),"FEATURE/")>0) {
			s Enabled = 1
		} elseif (##class(User.SourceControl.Git.Utils).IsReleaseMenuGitCommand(name))&&($F($ZCVT(tCurrentBranch,"U"),"RELEASE/")>0) {
			s Enabled = 1
		} elseif (##class(User.SourceControl.Git.Utils).IsBugfixMenuGitCommand(name))&&($F($ZCVT(tCurrentBranch,"U"),"BUGFIX/")>0) {
			s Enabled = 1
		} elseif (##class(User.SourceControl.Git.Utils).IsTeamMenuGitCommand(name))&&(tCurrentBranch=##class(User.SourceControl.Git.Utils).TeamBranch()) {
			s Enabled = 1
		} elseif ##class(User.SourceControl.Git.Utils).IsMenuGitCommand(name) {
			//This else should be last to allow for special handling of menugitcommands as needed
			s Enabled = 1
		} 
#;		else {
#;			s Enabled = -1
#;		}
	} else { 
		if name '= "Clone Repository" {
			s Enabled = -1
		} else {
			s Enabled = 1
		}
	}
	Quit $$$OK
}

Method OnSourceMenuContextItem(itemName As %String, menuItemName As %String, ByRef Enabled As %String, ByRef DisplayName As %String) As %Status
{
	if (itemName = "") 
	|| '##class(User.SourceControl.Git.Utils).IsNamespaceInGit() 
	|| (##class(User.SourceControl.Git.Utils).Type(itemName)="pkg") {
		s Enabled = -1
		Quit $$$OK
	}
	
	s tCurrentBranch = ##class(User.SourceControl.Git.Utils).CurrentBranch()
	s Enabled = 0
	if (menuItemName="Add To Release") && ($F($ZCVT(tCurrentBranch,"U"),"RELEASE/")>0) {
		 Set Enabled = 1
	} elseif ($F($ZCVT(tCurrentBranch,"U"),"FEATURE/")>0) {
	
		if ##class(User.SourceControl.Git.Utils).IsInSourceControl(itemName) {
			If menuItemName="Remove From" Set Enabled = 1
		} else {
			if menuItemName="Add To" Set Enabled = 1
		}
	
	}
		
	Quit $$$OK
}

/// This is called for every menu item returned to Studio to allow the menu to be enabled/disabled without
/// having to write a custom query for <query>MenuItems</query>. The <var>DisplayName</var> of this menu is
/// also passed by reference and this may be modified to change the appearance of this menu item. The <var>MenuName</var>
/// is the main menu name then the submenu name separated by a ','. If <var>Enabled</var> is set to -1 then it will remove
/// this menu item from the list totally, 0 will gray the menu item out and the default 1 will display the menu item as normal.
Method OnMenuItem(MenuName As %String, InternalName As %String, SelectedText As %String, ByRef Enabled As %Boolean, ByRef DisplayName As %String) As %Status
{
	#dim menu As %String= $piece(MenuName,",")
	#dim name As %String = $piece(MenuName,",",2)
	
#;	s tTime=$H
#;	s tInt=$I(^MS(tTime))
#;	s ^MS(tTime,tInt,"MenuName")=MenuName
#;	s ^MS(tTime,tInt,"InternalName")=InternalName
#;	s ^MS(tTime,tInt,"SelectedText")=SelectedText
#;	s ^MS(tTime,tInt,"Enabled")=Enabled
#;	s ^MS(tTime,tInt,"DisplayName")=DisplayName
#;	s ^MS(tTime,tInt,"this")=$THIS
#;	s ^MS(tTime,tInt,"StudioVersion")=$THIS.StudioVersion
	
	if menu = "%SourceMenuContext", name = "" {
		s DisplayName = "&SourceControl"
	}
	if menu = "Source Control Main Menu", name = "" {
		s DisplayName = "&SourceControl"
	}
	if menu = "Source Control Context Menu" {
		if $THIS.StudioVersion'="" {
			s Enabled=0
			s DisplayName=""
		} else {
			if name '= "" {
				s ec = ..OnSourceMenuContextItem(InternalName, name, .Enabled, .DisplayName)
			}
		}
	}
	#dim ec As %Status = $$$OK

	if menu = "Source Control Main Menu" {
		s ec = ..OnSourceMenuItem(name, .Enabled, .DisplayName)
	}elseif menu = "%SourceMenuContext" {
		s ec = ..OnSourceMenuContextItem(InternalName, name, .Enabled, .DisplayName)
	}
	Quit ec
}

/// Return true if this item should be marked as read only.
/// This is called when Studio opens a document. It is set to indicate
/// that the user checked the 'read only' checkbox in the open
/// dialog in Studio.
Method IsReadOnly(InternalName As %String) As %Boolean
{
	//w !,"isreadonly: "_InternalName
	
	#dim tReadOnly As %Boolean = 1
	
	s tCurrentBranch = ##class(User.SourceControl.Git.Utils).CurrentBranch()
	if $F($ZCVT(tCurrentBranch,"U"),"FEATURE/")>0 Set tReadOnly = 0
	if $F($ZCVT(tCurrentBranch,"U"),"BUGFIX/")>0 Set tReadOnly = 0
	if (InternalName[^Git("IgnorePackage")) set tReadOnly = 0
	Quit tReadOnly
}

/// This is called before the actual load of data to give the chance
/// to load the item from an external format.
Method OnBeforeLoad(InternalName As %String) As %Status
{
	#dim tSC As %Status = $$$OK
	
	//w !,"onbeforeload: "_InternalName
	Quit tSC
}

/// Called before the item is saved to the Cache database it is passed
/// a reference to the current temporary storage of this item so that it
/// can be modified before the save completes. If you quit with an error
/// value then it will abort the save.
Method OnBeforeSave(InternalName As %String, Location As %String = "", Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	//w !,"onbeforesave: "_InternalName
	#dim tSC As %Status = $$$OK
	Quit tSC
}

/// This is called after the item has been saved to the database.
/// It may be passed a reference to the object representing the item
/// just saved. It can be use to export this documement to an external form for example.
Method OnAfterSave(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	return $$$OK
	if ##class(User.SourceControl.Git.Utils).IsNamespaceInGit() && '##class(User.SourceControl.Git.Utils).IsLoadBranchActive() && '(InternalName[^Git("IgnorePackage")){
		If '##class(User.SourceControl.Git.Utils).IsInSourceControl(InternalName) {
			//Always add new files to source control by default
			s tSC = ##class(User.SourceControl.Git.Utils).AddToSourceControl(InternalName)
			Quit tSC
		} else {
			$$$QuitOnError(##class(User.SourceControl.Git.Utils).RemoveRoutineTSH(InternalName))
			s tSC = ##class(User.SourceControl.Git.Utils).ExportItem(InternalName)
			Q:$$$ISERR(tSC) tSC
			s tSC = ##class(User.SourceControl.Git.Utils).CheckOutItem(InternalName)
			Quit tSC
		}
	} else {
		Quit $$$OK
	}
}

Method AddToSourceControl(InternalName, pInfo) As %Status
{
	//the Ens.Deployment.Utils calls this method on the Hooks class by default
	//By quitting $$$OK we do not take action when the deployment util is used
	//Instead, we rely on the hooks - onaftersave, etc as per normal
	Quit $$$OK
}

/// Called after an item is deleted.
Method OnAfterDelete(InternalName As %String) As %Status
{
	if ##class(User.SourceControl.Git.Utils).IsInSourceControl(InternalName) {
		Quit ##class(User.SourceControl.Git.Utils).DeleteExternalFile(InternalName)
	}
	Quit $$$OK
}

}

