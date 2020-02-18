Class User.SourceControl.Deploy.EnsDeploy Extends Ens.Deployment.Deploy
{

/// Go through XML file and record the locations in the array pDeployDetails
/// This will create pDeployDetails and also calculate extension based on type
/// and generate the unique ItemName.
ClassMethod RecordBasicContentsInfo(pDeploymentVDOC As %RegisteredObject, Output pDeployDetails) As %Status
{
	s ^XABS("")=$i(^XABS(""))
	s ^XABS("ens")=1
	Set tSC = $$$OK, tRemoveLocation = ""
	Set tExtConversion("Class")="CLS"
	Set tExtConversion("Project")="PRJ"
	Set tExtConversion("INC")="INC"
	Set tExtConversion("MAC")="MAC"
	Set tExtConversion("INT")="INT"
	Kill pDeployDetails
	s ^XABS("ens")=2
	Try {
		Set tExportCount = pDeploymentVDOC.GetValueAt("/Export/*")
		s ^XABS("ens")=3
		For tCount = 1:1:tExportCount {
			s ^XABS("ens")=4_"a"_tCount
			Set tItemExportName = pDeploymentVDOC.GetValueAt("/Export/"_tCount_"/@name")
			Set tItemType = pDeploymentVDOC.GetValueAt("/Export/"_tCount_"/@type")
			Set tItemDescription =  pDeploymentVDOC.GetValueAt("/Export/"_tCount_"/Description")
			/* Type attribute can be used to add extension or xml name() Need to look up to see if defined. */
			Set tExportNodeName = pDeploymentVDOC.GetValueAt("/Export/"_tCount_"/name()")
			Set:(tItemType = "") tItemType = tExportNodeName
			s ^XABS("ens")=4_"b"_tCount
			Set tItemCalculatedExtension = $G(tExtConversion(tItemType))
			If tItemCalculatedExtension '= "" {
				Set tItemName = tItemExportName_"."_tItemCalculatedExtension
			} Else { /* Extension already in the name */ 
				Set tItemName = tItemExportName
			}
			s ^XABS("ens")=4_"c"_tCount
			If tItemType = "CSP" {
				s ^XABS("ens")=4_"d"_tCount
				//****Modification to base class:
				//The base class sets the csp application as the namespace default, but /csp/xslt files that is not the correct application
				//Get it from the import file instead
				Set tCSPApplication = pDeploymentVDOC.GetValueAt("/Export/"_tCount_"/@application")
				Set:tCSPApplication="" tCSPApplication = $system.CSP.GetDefaultApp($NAMESPACE)
				//***Modification end
				Set:$E(tCSPApplication,1,1)="/" tCSPApplication = $E(tCSPApplication,2,*)
				//***Modification to ensure that tCSPApplication name doesn't end with / so that the concat with / doesn't duplicate
				Set:$E(tCSPApplication,*,*)="/" tCSPApplication = $E(tCSPApplication,1,*-1)
				//***Modification end
				Set tItemName = tCSPApplication_"/"_tItemName
			}
			s ^XABS("ens")=4_"e"_tCount
			If ((tItemType="Document") && ($P(tItemName,":")="Settings")) {
				s ^XABS("ens")=4_"f"_tCount
				Try {Set tItemName = $ZCVT(tItemName,"I","XML")} Catch {}
			}
			s ^XABS("ens")=4_"g"_tCount
			If tItemName = "" {
				/* Need to check for those exports that have no name */
				s ^XABS("ens")=4_"h"_tCount
				If tExportNodeName = "Global" {
					s ^XABS("ens")=4_"i"_tCount
					Set tItemCalculatedExtension = "GBL"
					/* e.g. ^Ens.LookupTable(&quot;Patient&quot;).GBL */
					Set tItemName = pDeploymentVDOC.GetValueAt("/Export/"_tCount_"/Node/Sub")_"."_tItemCalculatedExtension
					/* Any subscript quotes will have been escaped when exported originally. */
					Set tItemName = $ZCVT(tItemName,"I","XML")
					Set tItemExportName = tItemName /* leave leading ^ */
					Set:($E(tItemName)="^") tItemName = $E(tItemName,2,*)
				}	
				s ^XABS("ens")=4_"j"_tCount
				Quit:(tItemName = "") /* skip if can't identify */
			}
			s ^XABS("ens")=4_"k"_tCount
			/* Used in UI */
			Set pDeployDetails("Items",tItemName,"ExportFileLocation") = tCount
			Set pDeployDetails("Items",tItemName,"ExportName") = tItemExportName
			Set pDeployDetails("Items",tItemName,"ExportType") = tItemType
			Set pDeployDetails("Items",tItemName,"Description") = tItemDescription		
			s ^XABS("ens")=4_"l"_tCount
	}
	} Catch ex {
		s ^XABS("ens")=4_"m"_tCount
		Set tSC = ex.AsStatus()
	}
	s ^XABS("","ensst")=tSC 
	Quit tSC
}

}

