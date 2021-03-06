/// User.SourceControl.Deploy.Service
Class User.SourceControl.Deploy.Service Extends %SOAP.WebService [ ProcedureBlock ]
{

/// Name of the WebService.
Parameter SERVICENAME = "ZRCDeploy";

/// TODO: change this to actual SOAP namespace.
/// SOAP Namespace for the WebService
Parameter NAMESPACE = "http://ZRC.org";

/// Namespaces of referenced classes will be used in the WSDL.
Parameter USECLASSNAMESPACES = 1;

/// Use xsi:type attribute for literal types.
Parameter OUTPUTTYPEATTRIBUTE = 1;

Method Deploy(pHSEnvironment As %String = "", pRequest As User.SourceControl.Deploy.ImportRequest, Output pDeployStatus As %Boolean) As %String [ WebMethod ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	#dim tImportObject As User.SourceControl.Deploy.ImportObject
	s tReturn = ""
	s pDeployStatus = 1
	
	try {
		
		s ^SourceControlEnvironment = pHSEnvironment
		
		Set outputfile=##class(%File).TempFilename("compile")
		
		OPEN outputfile:"WSN"
		USE outputfile
		
		s tBusinessItems = 0
		
		For i=1:1:pRequest.Objects.Count() {
			s tImportObject=pRequest.Objects.GetAt(i)
			
			if tImportObject.Name [ "DeployPackage" {
				s tDeployFilename = ##class(%File).TempFilename("deploy")
				s tDeployFile = ##class(%FileCharacterStream).%New()
				s tDeployFile.Filename = tDeployFilename
				s tSC = tDeployFile.CopyFromAndSave(tImportObject.ObjectStream) $$$ThrowOnError(tSC)
				
				s tProduction = $G(^Ens.Configuration("csp","LastProduction"))
				s:tProduction="" tProduction = "NoProduction"
				Do ##class(Ens.Deployment.Utils).GenerateFileNames(tDeployFilename,.tRollbackFile,.tLogFile,.tReportFile)
				Set tCreateRollBack = 1, tAllowDeployToSource = 1 ,tAutoRevert = 1, tWhereToLog = "LC"
				s tSC = ##class(Ens.Deployment.Deploy).DeployCode(tDeployFilename,tProduction,tCreateRollBack,tRollbackFile,tWhereToLog,tLogFile,tAllowDeployToSource,tAutoRevert)
				//Don't throw error here so that we can continue to log output to file and then log file to return - check for error in tSC later
				
				
			} elseif $P(tImportObject.Name,"/",5) = "businessitems" {
				//If the imported item is a deployment package for a business item, do the import to the appropriate namespace after importing all the classes
				s tBusinessItems($I(tBusinessItems))=tImportObject.Name
			}
		}
		
		For i=1:1:tBusinessItems {
			s tDeployItemName = tBusinessItems(i)
			s tTargetNamespace = $ZCVT($P(tDeployItemName,"/",6),"U")
			//check to ensure the target namespace exists on this instance
			if ($D(^%SYS("Ensemble","InstalledNamespace",tTargetNamespace))=1) && ($System.Mirror.IsPrimary() || '$System.Mirror.IsMember()) {
				s tNS = $NAMESPACE
				ZN tTargetNamespace
				
				s tFilename = $System.Util.InstallDirectory()_$E(tDeployItemName,2,*)
				if ##class(%File).Exists(tFilename) {
					s tProduction = $G(^Ens.Configuration("csp","LastProduction"))
					s tRollbackFilename = $System.Util.InstallDirectory()_"/mgr/Temp/"_##class(Ens.Util.Time).FormatDateTime("%Y%m%d%H%M%S%N")_"_"_$P(tDeployItemName,"/",7)
					s tSCDeploy = ##class(Ens.Deployment.Deploy).DeployCode(tFilename,tProduction,1,tRollbackFilename,"C")
					if $$$ISERR(tSCDeploy) s err($I(err))=$System.Status.GetErrorText(tSC)
				} else {
					s err($I(err))="File name for deployment not found: "_tFilename CONTINUE
				}
				ZN tNS
			}
		}
		
		set ConfigScripts={}.%FromJSON(pRequest.ConfigScriptsJSON)
		do ..RunConfigRoutinesByMethodName(ConfigScripts,"Deploy")
		
		CLOSE outputfile
		
		s tFile=##class(%FileCharacterStream).%New()
		s tFile.Filename=outputfile
		
		s tReturn="Loading import request to namespace "_$NAMESPACE_" on "_##class(%SYS.System).GetNodeName()_":"_##class(%SYS.System).GetInstanceName()_$C(10)
		
		While 'tFile.AtEnd {
			s tReturn=tReturn_tFile.ReadLine()_$C(10)
		}
		
		d tFile.Clear()
		
		//Not currently doing any loads that populate err
#;		s tErrorText=""
#;		For { s tErrorText=$O(err(tErrorText)) Q:tErrorText=""
#;			s tReturn=tReturn_err(tErrorText)_$C(10)
#;			s pDeployStatus = 0
#;		}

		if $$$ISERR(tSC) {
			s tReturn = tReturn_$System.Status.GetErrorText(tSC)_$C(10)
			s pDeployStatus = 0
		} 
	} catch e {
		if $ZERROR["<ZSOAP>" {
            Set tSC=%objlasterror
        } else {
            Set tSC = e.AsStatus()
        }
		s tReturn = tReturn_$System.Status.GetErrorText(tSC)
		s pDeployStatus = 0
	}
	Quit tReturn
}

ClassMethod RunConfigRoutinesByMethodName(ConfigScripts As %DynamicObject, pMethod As %String)
{
		write !,"Running the "_pMethod_" method for Configuration Scripts",!
		write ConfigScripts.%ToJSON(),!
		set iter=ConfigScripts.%GetIterator()
		while iter.%GetNext(.i,.script)
		{
			set command="do "_pMethod_"^"_script_"(""EnvironmentParams"")"
			write !!,"Executing script:"
			zw command
			XECUTE command
		}
}

Method Rollback(pRequest As User.SourceControl.Deploy.ImportRequest, Output pDeployStatus As %Boolean) As %String [ WebMethod ]
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	s tReturn = ""
	s pDeployStatus = 1
	
	try {
		Set outputfile=##class(%File).TempFilename("compile")
		
		OPEN outputfile:"WSN"
		USE outputfile
		
		set ConfigScripts={}.%FromJSON(pRequest.ConfigScriptsJSON)
		do ..RunConfigRoutinesByMethodName(ConfigScripts,"Revert")
		
		s tSC = ##class(Ens.Deployment.Deploy).RollbackLastDeployment(,,,"LC")
		//Don't throw error here, check for error in tSC later
		
		CLOSE outputfile
		
		s tFile=##class(%FileCharacterStream).%New()
		s tFile.Filename=outputfile
		
		s tReturn="Rollback last deployment in namespace "_$NAMESPACE_" on "_##class(%SYS.System).GetNodeName()_":"_##class(%SYS.System).GetInstanceName()_$C(10)
		
		While 'tFile.AtEnd {
			s tReturn=tReturn_tFile.ReadLine()_$C(10)
		}
		
		d tFile.Clear()
		
		if $$$ISERR(tSC) {
			s tReturn = tReturn_$System.Status.GetErrorText(tSC)_$C(10)
			s pDeployStatus = 0
		} 
	} catch e {
		if $ZERROR["<ZSOAP>" {
            Set tSC=%objlasterror
        } else {
            Set tSC = e.AsStatus()
        }
		s tReturn = tReturn_$System.Status.GetErrorText(tSC)
		s pDeployStatus = 0
	}
	Quit tReturn
}

ClassMethod ConfigureHSCUSTOM() As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
		s tNS = $NAMESPACE
		zn "HSCUSTOM"
		
		s ^%SYS("HealthShare","Instances","HSCUSTOM","Type") ="Foundation"
		s ^Ens.Configuration("csp","LastProduction") = "HSCUSTOMPKG.Production "
		
		zn "%SYS"
		
		//Ensure HSCUSTOM html and services csp applications exist, create if not
		s tCSPApp="/csp/healthshare/hscustom/services"
		s tExists=##class(Security.Applications).Exists(tCSPApp)
		if 'tExists {
			d ##class(%File).CreateDirectoryChain($System.Util.InstallDirectory()_"csp/healthshare/hscustom")
			s tSC=##class(Security.Applications).Copy("/csp/healthshare/ensemble/services",tCSPApp,"HealthShare HSCUSTOM Services")
			w !,tSC
		}
		s tCSPProp("NameSpace")="HSCUSTOM"
		s tCSPProp("Path")=##class(%File).NormalizeDirectory($System.Util.InstallDirectory()_"csp/healthshare/hscustom/")
		s tSC=##class(Security.Applications).Modify(tCSPApp,.tCSPProp)
		$$$ThrowOnError(tSC)
		
		s tCSPApp="/csp/healthshare/hscustom"
		s tExists=##class(Security.Applications).Exists(tCSPApp)
		if 'tExists {
			s tSC=##class(Security.Applications).Copy("/csp/healthshare/ensemble",tCSPApp,"HealthShare HSCUSTOM")
			w !,tSC
		}
		s tCSPProp("NameSpace")="HSCUSTOM"
		s tCSPProp("Path")=##class(%File).NormalizeDirectory($System.Util.InstallDirectory()_"csp/healthshare/hscustom/")
		s tCSPProp("IsNameSpaceDefault")=1
		s tSC=##class(Security.Applications).Modify(tCSPApp,.tCSPProp)
		$$$ThrowOnError(tSC)
		
		//Ensure /csp/xslt csp application exists, create if not
		s tCSPApp="/csp/xslt"
		s tExists=##class(Security.Applications).Exists(tCSPApp)
		if 'tExists {
			s tSC=##class(Security.Applications).Copy("/csp/healthshare/ensemble",tCSPApp,"xslt files")
			w !,tSC
			s tCSPProp("Path")=##class(%File).NormalizeDirectory($System.Util.InstallDirectory()_"csp/xslt/")
			s tCSPProp("InbndWebServicesEnabled")=1
		}
		//modify /csp/xslt to namespace HSCUSTOM always
		s tCSPProp("NameSpace")="HSCUSTOM"
		s tSC=##class(Security.Applications).Modify(tCSPApp,.tCSPProp)
		$$$ThrowOnError(tSC)
		
		
		
		
	} catch e {
		s tSC = e.AsStatus()
	}
	
	zn tNS
	
	Quit tSC
}

/// TODO: add arguments and implementation.
/// Test
Method Test() As %String [ WebMethod ]
{
	Quit "Test"
}

/// Revision number of this class
Parameter SrcVer = 2;

}

