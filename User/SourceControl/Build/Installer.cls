Include %occInclude

Class User.SourceControl.Build.Installer
{

/// Application Definition
XData VABUILD [ XMLNamespace = INSTALLER ]
{
<Manifest>
<!-- Do some setup -->
<Var Name="NAMESPACE" Value="VABUILD"/>
<Var Name="DBRESOURCE" Value="%DB_VABUILD"/>

<!-- Create the namespace, yes it's Ensemble enabled for VABUILD -->
<Namespace Name="${NAMESPACE}"
          Create="yes"
          Code="${NAMESPACE}"
          Data="${NAMESPACE}"
          Ensemble="1"
		  >

<Configuration>

<!-- Create a "data" database -->
<Database Name="${NAMESPACE}"
		 Dir="${MGRDIR}/${NAMESPACE}"
		 Create="overwrite"
		 Resource="${DBRESOURCE}"
		 PublicPermissions=""/>

<ClassMapping Package="HS.Local.VA"    				From="${NAMESPACE}"/>
<ClassMapping Package="User.SourceControl.Git"    	From="${NAMESPACE}"/>
<ClassMapping Package="User.SourceControl.Deploy"  	From="${NAMESPACE}"/>
<ClassMapping Package="HS"    						From="HSLIB"/>

</Configuration>

</Namespace>

<Namespace Name="%SYS"
          Create="no">

<Invoke Class="User.SourceControl.Build.Installer" Method="CreateCSPApplications" CheckStatus="1" Return="tSC"> 
</Invoke>

<Invoke Class="User.SourceControl.Build.Installer" Method="SetProductionName" CheckStatus="1" Return="tSC"> 
</Invoke>

</Namespace>
</Manifest>
}

ClassMethod setup(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]
{
    #; Let our XGL document generate code for this method. 
    Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "VABUILD")
}

ClassMethod SetProductionName() As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
		
		zn "VABUILD"
		
		s ^Ens.Configuration("csp","LastProduction") = "HSCUSTOMPKG.Production "
		
		zn "%SYS"
		
		
	} catch e {
		s tSC = e.AsStatus()
	}
	Quit tSC
}

ClassMethod CreateCSPApplications() As %Status
{
	
	#dim tSC As %Status = $$$OK
	#dim e As %Exception.AbstractException
	
	Try {
		
		//For the build namespace, mount the hscustom csp apps to VABUILD temporarily (they will get mapped back to HSCUSTOM by the bootstrap step of the deploy
		s tBuildNamespace = "VABUILD"
		
		//Ensure HSCUSTOM html and services csp applications exist, create if not
		Kill tCSPProp
		s tCSPApp="/csp/healthshare/hscustom/services"
		s tExists=##class(Security.Applications).Exists(tCSPApp)
		if 'tExists {
			d ##class(%File).CreateDirectoryChain($System.Util.InstallDirectory()_"csp/healthshare/hscustom")
			s tSC=##class(Security.Applications).Copy("/csp/healthshare/ensemble/services",tCSPApp,"HealthShare HSCUSTOM Services")
			w !,tSC
		}
		s tCSPProp("NameSpace")=tBuildNamespace
		s tCSPProp("Path")=##class(%File).NormalizeDirectory($System.Util.InstallDirectory()_"csp/healthshare/hscustom/")
		s tSC=##class(Security.Applications).Modify(tCSPApp,.tCSPProp)
		$$$ThrowOnError(tSC)
		
		Kill tCSPProp
		s tCSPApp="/csp/healthshare/hscustom"
		s tExists=##class(Security.Applications).Exists(tCSPApp)
		if 'tExists {
			s tSC=##class(Security.Applications).Copy("/csp/healthshare/ensemble",tCSPApp,"HealthShare HSCUSTOM")
			w !,tSC
		}
		s tCSPProp("NameSpace")=tBuildNamespace
		s tCSPProp("Path")=##class(%File).NormalizeDirectory($System.Util.InstallDirectory()_"csp/healthshare/hscustom/")
		s tSC=##class(Security.Applications).Modify(tCSPApp,.tCSPProp)
		$$$ThrowOnError(tSC)
		
		//Ensure /csp/xslt csp application exists, create if not
		Kill tCSPProp
		s tCSPApp="/csp/xslt"
		s tExists=##class(Security.Applications).Exists(tCSPApp)
		if 'tExists {
			s tSC=##class(Security.Applications).Copy("/csp/healthshare/ensemble",tCSPApp,"xslt files")
			w !,tSC
		}
		//modify /csp/xslt to namespace HSCUSTOM always
		s tCSPProp("NameSpace")=tBuildNamespace
		s tCSPProp("Path")=##class(%File).NormalizeDirectory($System.Util.InstallDirectory()_"csp/xslt/")
		s tCSPProp("InbndWebServicesEnabled")=1
		s tSC=##class(Security.Applications).Modify(tCSPApp,.tCSPProp)
		$$$ThrowOnError(tSC)
		
		
		
		
	} catch e {
		s tSC = e.AsStatus()
	}
	Quit tSC
}

}

