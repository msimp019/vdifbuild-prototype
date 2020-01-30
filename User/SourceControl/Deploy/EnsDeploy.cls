Class User.SourceControl.Deploy.EnsDeploy Extends Ens.Deployment.Deploy
{

/// Go through XML file and record the locations in the array pDeployDetails
/// This will create pDeployDetails and also calculate extension based on type
/// and generate the unique ItemName.
ClassMethod RecordBasicContentsInfo(pDeploymentVDOC As %RegisteredObject, Output pDeployDetails) As %Status
{
	Set tSC = $$$OK, tRemoveLocation = ""
	Set tExtConversion("Class")="CLS"
	Set tExtConversion("Project")="PRJ"
	Set tExtConversion("INC")="INC"
	Set tExtConversion("MAC")="MAC"
	Set tExtConversion("INT")="INT"
	Kill pDeployDetails
	Try {
		Set tExportCount = pDeploymentVDOC.GetValueAt("/Export/*")
		For tCount = 1:1:tExportCount {
			Set tItemExportName = pDeploymentVDOC.GetValueAt("/Export/"_tCount_"/@name")
			Set tItemType = pDeploymentVDOC.GetValueAt("/Export/"_tCount_"/@type")
			Set tItemDescription =  pDeploymentVDOC.GetValueAt("/Export/"_tCount_"/Description")
			/* Type attribute can be used to add extension or xml name() Need to look up to see if defined. */
			Set tExportNodeName = pDeploymentVDOC.GetValueAt("/Export/"_tCount_"/name()")
			Set:(tItemType = "") tItemType = tExportNodeName
			
			Set tItemCalculatedExtension = $G(tExtConversion(tItemType))
			If tItemCalculatedExtension '= "" {
				Set tItemName = tItemExportName_"."_tItemCalculatedExtension
			} Else { /* Extension already in the name */ 
				Set tItemName = tItemExportName
			}
			If tItemType = "CSP" {
				//****Modification to base class:
				//The base class sets the csp application as the namespace default, but /csp/xslt files that is not the correct application
				//Get it from the import file instead
				Set tCSPApplication = pDeploymentVDOC.GetValueAt("/Export/"_tCount_"/@application")
				Set:tCSPApplication="" tCSPApplication = $system.CSP.GetDefaultApp($NAMESPACE)
				//***Modification end
				Set:$E(tCSPApplication,1,1)="/" tCSPApplication = $E(tCSPApplication,2,*)
				//***Modification to ensure that item name doesn't start with / so that the concat with / doesn't duplicate
				Set:$E(tItemName,1,1)="/" tItemName = $E(tItemName,2,*)
				//***Modification end
				Set tItemName = tCSPApplication_"/"_tItemName
			}
			If ((tItemType="Document") && ($P(tItemName,":")="Settings")) {
				Try {Set tItemName = $ZCVT(tItemName,"I","XML")} Catch {}
			}
			If tItemName = "" {
				/* Need to check for those exports that have no name */
				If tExportNodeName = "Global" {
					Set tItemCalculatedExtension = "GBL"
					/* e.g. ^Ens.LookupTable(&quot;Patient&quot;).GBL */
					Set tItemName = pDeploymentVDOC.GetValueAt("/Export/"_tCount_"/Node/Sub")_"."_tItemCalculatedExtension
					/* Any subscript quotes will have been escaped when exported originally. */
					Set tItemName = $ZCVT(tItemName,"I","XML")
					Set tItemExportName = tItemName /* leave leading ^ */
					Set:($E(tItemName)="^") tItemName = $E(tItemName,2,*)
				}	
				Quit:(tItemName = "") /* skip if can't identify */
			}
			
			/* Used in UI */
			Set pDeployDetails("Items",tItemName,"ExportFileLocation") = tCount
			Set pDeployDetails("Items",tItemName,"ExportName") = tItemExportName
			Set pDeployDetails("Items",tItemName,"ExportType") = tItemType
			Set pDeployDetails("Items",tItemName,"Description") = tItemDescription		}
	} Catch ex {
		Set tSC = ex.AsStatus()
	}
	Quit tSC
}

}

