Class User.SourceControl.Deploy.ServiceClient Extends %SOAP.WebClient [ ProcedureBlock ]
{

/// This is the URL used to access the web service.
Parameter LOCATION = "http://localhost:57775/csp/public/hsregistry/User.SourceControl.Deploy.Service.cls";

/// This is the namespace used by the Service
Parameter NAMESPACE = "http://ZRC.org";

/// Use xsi:type attribute for literal types.
Parameter OUTPUTTYPEATTRIBUTE = 1;

/// Determines handling of Security header.
Parameter SECURITYIN = "ALLOW";

/// This is the name of the Service
Parameter SERVICENAME = "HDS";

/// This is the SOAP version supported by the service.
Parameter SOAPVERSION = 1.1;

Method Deploy(pRequest As User.SourceControl.Deploy.ImportRequest, Output pDeployStatus As %Boolean) As %String [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("ImportClass").Invoke($this,"http://ZRC.org/User.SourceControl.Deploy.Service.ImportClass",.pRequest,.pDeployStatus)
}

Method Rollback(pRequest As User.SourceControl.Deploy.ImportRequest, Output pDeployStatus As %Boolean) As %String [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("Rollback").Invoke($this,"http://ZRC.org/User.SourceControl.Deploy.Service.Rollback",.pRequest,.pDeployStatus)
}

Method Test() As %String [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 Quit ..WebMethod("Test").Invoke($this,"http://ZRC.org/User.SourceControl.Deploy.Service.Test")
}

/// Revision number of this class
Parameter SrcVer = 2;

}

