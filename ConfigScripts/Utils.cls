/// This class gets compiled within every HSCUSTOM namespace of each environment, and should be called within the configuration scripts.<p>
Class ConfigScripts.Utils
{

/// This prevents IP addresses being stored on github.  
/// environment should be one of the following strings: "develop", "sqa2", "sqa1", "preprod", "production"
/// label: (required) Can be any unique identifier, must be unique across all of vdif. recommend including teamname within identifier.
/// In order to set the intended value for an environment, go to the management portal for the Registry Instance ->
/// HealthShare -> HSREGISTRY -> Registry Management -> Configuration Registry -> Add Value. Set Key = "\Jenkins\IPLabels\Your.Label.Here" and
/// your desired IP for value and Save
ClassMethod GetIPFromLabel(label As %String) As %String
{
	set configRegistryKey="\Jenkins\IPLabels\"_label
	set ipAddress= ##class(HS.Registry.Config).GetKeyValue(configRegistryKey)	
	if (ipAddress ="") {$$$ThrowOnError($$$ERROR(500,"key("_configRegistryKey_") not defined in the configuration registry"))}
	return ipAddress
}

/// Many actions should only occur in a specified namespace such as HSREGISTRY<br>
/// Use this method to see if the namespace exists on the current instance<br>
/// For example, if the script is being executed on an Edge Gateway, but the action is intended for HSREGISTRY<br>
/// the script can exit, taking no action, if the HSREGISTRY namespace doesn't exist on this instance.
ClassMethod NamespaceExists(pNamespace) As %Boolean
{
	s tNS = $NAMESPACE
	zn "%SYS"
	
	s tExists=##class(Config.Namespaces).Exists(pNamespace)
	
	zn tNH
	
	Quit tExists
}

/// Any action that writes to a HealthShare database can only be written on either a non-mirrored system, or the Primary node of a mirrored system<br>
/// Use this method to check if the current system is a backup member, if it is not, it may be non-mirrorer, or the primary, but in either case, the db write can occur
ClassMethod IsBackupMirror() As %Boolean [ CodeMode = expression ]
{
$System.Mirror.IsBackup()
}

/// Use this to determine which environment the script is currently executing in.<br>
/// This allows the configuration script to have different settings or actions per environment<br>
/// For example, a service registry entry may have the same name in all environments, but pointed to a different host name in SQA1C vs. Prod<p>
/// The Environment names are as follows:<br>
/// <table border="1"><tr><th>Logical Name</th><th>Physical Name</th></tr>
/// <tr><td>prod</td><td>Prod</td></tr>
/// <tr><td>preProd</td><td>PreProd</td></tr>
/// <tr><td>gold</td><td>SQA1C</td></tr>
/// <tr><td>silver</td><td>SQA2C</td></tr>
/// <tr><td>bronze</td><td>DEV</td></tr></table><p>
/// The value that is returned is the Logical Name of the environment
ClassMethod GetEnvironment() As %String
{
	s tNS = $Namespace
	ZN "HSCUSTOM"
	s tEnvironment = $G(^SourceControlEnvironment)
	ZN tNS
	Quit tEnvironment
}

/// Use this method to get a list of HealthShare namespaces on an instance<br>
/// The list that is returned is an array of namespaces names<br>
/// Use $ORDER to loop through the array or use $Data to check for a specific namespace name<p>
/// Call this method as follows:<br>
/// set tSC = ##class(ConfigScripts.Utils).GetNamespacesList(.tNamespaces)<br>
/// 
ClassMethod GetNamespacesList(ByRef pNamespaces = "") As %Status
{
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	s tNS = $Namespace
	
	Try {
		
		ZN "%SYS"
		
		s tIgnoreList=$LB("ENSDEMO","ENSEMBLE")
	
		s tNamespace=""
		For { s tNamespace = $O(^%SYS("HealthShare","Instances",tNamespace)) Q:tNamespace=""
			IF $LF(tIgnoreList,tNamespace) CONTINUE
			s pNamespaces(tNamespace)=""
		}		
		

	} catch e {
		w e.DisplayString()
		s tSC = e.AsStatus()
	}
	
	zn tNS
	
	Quit tSC
}

/// Use this method to save a system default to the Namespace indicated by input parameter<p>
/// To utilize this method, create a DefaultSetting object and pass it to this method as follows:<br>
/// s tTargetNamespace = "EGADTALERTS"
/// 	s tDefault = ##class(Ens.Config.DefaultSettings).%New()<br>
/// 	s tDefault.ProductionName = "EGADTALERTSPKG.EdgeGatewayProduction"	<br>
/// 	s tDefault.ItemName = "Source.HL7.File.Service"<br>
/// 	s tDefault.SettingName = "AlertOnError"<br>
/// 	s tDefault.SettingValue = "1"<br>
/// 	s tDefault.Deployable = 1<br>
/// 	set tSC = ##class(ConfigScripts.Utils).SaveSystemDefault(tTargetNamespace,tDefault)<br>
/// 
ClassMethod SaveSystemDefault(pTargetNamespace As %String, pDefault As Ens.Config.DefaultSettings) As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	s tNS = $Namespace
	
	Try {
		
		if ..IsBackupMirror() || '..NamespaceExists(pTargetNamespace) Quit
		
		ZN pTargetNamespace
		
		If ##class(Ens.Config.DefaultSettings).%ExistsId(pDefault.ProductionName_"||"_pDefault.ItemName_"||"_pDefault.HostClassName_"||"_pDefault.SettingName) {
			// modify
			Set tExistingItem = ##class(Ens.Config.DefaultSettings).%OpenId(pDefault.ProductionName_"||"_pDefault.ItemName_"||"_pDefault.HostClassName_"||"_pDefault.SettingName)
			Set tDifferent = 0
			Set tDifferent = ((tExistingItem.Deployable '= pDefault.Deployable)||(tExistingItem.Description '= pDefault.Description)||(tExistingItem.SettingValue '= pDefault.SettingValue))
			If tDifferent {
				Set tExistingItem.Deployable = pDefault.Deployable
				Set tExistingItem.Description = pDefault.Description
				Set tExistingItem.SettingValue = pDefault.SettingValue
				Set tSC = tExistingItem.%Save()
			}
			#; Remember ID of existing whether changes or not
			Set tID = tExistingItem.%Id()
		} Else {
			Set tSC = pDefault.%Save() $$$ThrowOnError(tSC)
			Set tID = pDefault.%Id()
		}
		
		s tSC = ##class(Ens.Director).UpdateProduction()
		$$$ThrowOnError(tSC)
		
		
	} catch e {
		w e.DisplayString()
		s tSC = e.AsStatus()
	}
	
	zn tNS
	
	Quit tSC
}

/// Use this method to add or edit SOAP service registry entires of any type<p>
/// To utilize this method, pass settings as import parameters similar to this example:<br>
/// s tName	="eHX.ITPPatientManager.PD"<br>
/// s tDeviceFunction = "PD"<br>
/// s tHost = "validation.sequoiaproject.org"<br>
/// s tPort = "14430"<br>
/// s tURL = "/PAMSimulator-ejb/RespondingGateway_Service/RespondingGateway_PortType"<br>
/// s tMTOM = 0<br>
/// s tCheckId = 1<br>
/// kill tOIDMap<br>
/// s tOIDMap("Device")="ITPPatientManager"<br>
/// s tOIDMap("HomeCommunity")="eHXHub"<br>
/// s tOIDMap("AssigningAuthority")="eHXHub"<br>
/// s tSC = ##class(CONNECTPKG.Util).CreateServiceRegistry(tName,tDeviceFunction,tHost,tPort,tURL,tMTOM,"eHEXClient","eHXXUA",,"HS.IHE.Common.Security.eHealth",tCheckId,.tOIDMap)<br>
/// 
ClassMethod CreateServiceRegistrySOAP(pName, pDeviceFunction, pHost, pPort, pURL, pMTOM, pSSLConfig, pXUAConfig, pSendSAML = 2, pSecurityClass, pCheckId = 1, ByRef pOIDMap = "") As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	s tNS = $Namespace
	
	Try {
		
		if ..IsBackupMirror() || '..NamespaceExists("HSREGISTRY") Quit
		
		ZN "HSREGISTRY"

		s tService=##class(HS.Hub.HSWS.WebServices.Containers.Service).%New()
		s tService.Type = "SOAP"
		
		s tService.Name	=pName
		s tService.DeviceFunction = pDeviceFunction
		s tService.Host = pHost
		s tService.Port = pPort
		s tService.URL = pURL
		s tService.MTOM = pMTOM
		s tService.SSLConfig = pSSLConfig
		s tService.SSLCheckServerIdentity = pCheckId
		s tXUAId = ""
		&sql(select ID into :tXUAId from HS_IHE_XUA.Config where Name = :pXUAConfig)
		s tXUA = ##class(HS.IHE.XUA.Config).%OpenId(tXUAId)
		s tService.XUAConfiguration = tXUA
		s tService.SendSAMLAssertion = pSendSAML
		s tService.SecurityClass = pSecurityClass
	

		s tOID=""
		For { s tOID=$O(pOIDMap(tOID)) q:tOID=""
			d tService.OIDMapCode.SetAt(pOIDMap(tOID),tOID)
		}
		
		s tSC = ##class(HS.Hub.HSWS.WebServices.API.HubService).AddEditService(tService)
		$$$ThrowOnError(tSC)
		
	} catch e {
		s tSC = e.AsStatus()
	}
	
	zn tNS
	
	Quit tSC
}

/// Use this method to save an OID to the registry<br>
/// The code and the OID must be unique values and form the IDKey in the registry so if the desire is to modify an existing code or OID, the existing entry may need to be deleted first - there is no "change"<p>
/// To utilize this method, pass the parameters as follows:<br>
/// set tSC = ##class(ConfigScripts.Utils).CreateOID("VHAUSA","VA HIE","1.2.3.4","HomeCommunity","AssigningAuthority,Device,Repository")<br>
/// 
ClassMethod CreateOID(pCode, pDescription = "", pOID, pPrimaryType, pAdditionalTypes = "") As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	s tNS = $Namespace
	
	Try {
		
		if ..IsBackupMirror() || '..NamespaceExists("HSREGISTRY") Quit
		
		ZN "HSREGISTRY"
		
		s tSC = ##class(HS.Data.OIDMap).FileOID(pCode,pPrimaryType,pOID,pDescription,pAdditionalTypes,"")
		$$$ThrowOnError(tSC)

	} catch e {
		w e.DisplayString()
		s tSC = e.AsStatus()
	}
	
	zn tNS
	
	Quit tSC
}

/// Use this method to import a file containing system default settings<br>
/// Sometimes it is more effective to import a file rather than save a single setting - particularly when adding a lot of settings at once.<p>
/// To utilize this method, pass the parameters as follows:<br>
/// set tSC = ##class(ConfigScripts.Utils).ImportSystemDefaults("EGPBX",$System.Util.InstallDirectory()_"csp/healthshare/hscustom/SystemDefaults.xml")<br>
/// 
ClassMethod ImportSystemDefaults(pTargetNamespace, pFileName) As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	s tNS = $Namespace
	
	Try {
		
		if ..IsBackupMirror() || '..NamespaceExists(pTargetNamespace) Quit
		
		ZN pTargetNamespace
		
		s tSC = ##class(Ens.Config.DefaultSettings).%Import(pFileName)
		$$$ThrowOnError(tSC)

	} catch e {
		w e.DisplayString()
		s tSC = e.AsStatus()
	}
	
	zn tNS
	
	Quit tSC
}

/// Use this method to set an entry into the HSREGISTRY configuration registry<p>
/// To utilize this method, pass the parameters as follows:<br>
/// set tSC = ##class(ConfigScripts.Utils).InsertUpdateConfigRegistryEntry("\key","value")<br>
/// 
ClassMethod CreateConfigRegistryEntry(pKey, pValue) As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	s tNS = $Namespace
	
	Try {
		
		if ..IsBackupMirror() || '..NamespaceExists("HSREGISTRY") Quit
		
		ZN "HSREGISTRY"
		
		$$$ThrowOnError(##class(HS.Registry.Config).AddNewKey(pKey,pValue))

	} catch e {
		w e.DisplayString()
		s tSC = e.AsStatus()
	}
	
	zn tNS
	
	Quit tSC
}

/// Use this method to create or edit a Facility in the Facility Registry<p>
/// To utilize this method, pass the parameters as follows:<br>
/// set tSC = ##class(ConfigScripts.Utils).CreateFacility("HospitalA",,,"HospitalA")<br>
/// 
ClassMethod CreateFacility(pCode, pName = "", pDescription = "", pGatewayName = "", pAssigningAuthority = 1) As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	s tNS = $Namespace
	
	Try {
		
		if ..IsBackupMirror() || '..NamespaceExists("HSREGISTRY") Quit
		
		ZN "HSREGISTRY"
		
		if pGatewayName'="" {
			s tGatewayName = "%"_pGatewayName
			s tGWId=""
			&sql(select Id into :tGWId from hs_gateway.config where Name like :tGatewayName)
			if SQLCODE '= 0 {
				$$$ThrowOnError($$$ERROR($$$GeneralError,"Gateway for "_pGatewayName_" not found: "_SQLCODE))
			}
			s tGateway=##class(HS.Gateway.Config).%OpenId(tGWId)
		}

		s tFacility =  ##class(HS.Facility.Config).%OpenId(pCode)
		if '$ISOBJECT(tFacility) {
			s tFacility = ##class(HS.Facility.Config).%New()
		}
		s tFacility.FacilityCode=pCode
		s tFacility.Name=$SELECT(pName="":pCode,1:pName)
		s tFacility.Description=pDescription
		s tFacility.Gateway=tGateway
		s tFacility.AssigningAuthority=pAssigningAuthority

		s tSC = tFacility.%Save()
		
		$$$ThrowOnError(tSC)

	} catch e {
		w e.DisplayString()
		s tSC = e.AsStatus()
	}
	
	zn tNS
	
	Quit tSC
}

/// Use this method to create an Ensemble Credential<p>
/// To utilize this method, pass the parameters as follows:<br>
/// set tSC = ##class(ConfigScripts.Utils)CreateCredential("HS_Services","HS_Services","password")<br>
/// 
ClassMethod CreateCredential(pTargetNamespace, pCredentialName, pUsername, pPassword) As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	s tNS = $Namespace
	
	Try {
		
		if ..IsBackupMirror() || '..NamespaceExists(pTargetNamespace) Quit
		
		ZN pTargetNamespace
		
		$$$ThrowOnError(##class(Ens.Config.Credentials).SetCredential(pCredentialName,pUsername,pPassword,1))

	} catch e {
		w e.DisplayString()
		s tSC = e.AsStatus()
	}
	
	zn tNS
	
	Quit tSC
}

}

