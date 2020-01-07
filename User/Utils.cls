/// This class gets compiled within every HSCUSTOM namespace of each environment, and should be called within the configuration scripts.
/// This prevents IP addresses being stored on github.  
Class ConfigScripts.Utils
{

/// environment should be one of the following strings: "develop", "sqa2", "sqa1", "preprod", "production"
/// label: (required) Can be any unique identifier, must be unique across all of vdif. recommend including teamname within identifier.
/// environment: (optional) when called within vdif, this should be left blank, to utilize the jenkins deploy logic
/// ipDictonaryUR:
ClassMethod GetIPFromLabel(label As %String, environment As %String = "", ipDictionaryURL As %String = "http://10.0.2.2:57772/csp/user/ipdictionary.json") As %String
{
	set:(environment="") environment=..GetEnvironmentName()
	set request=##class(%Net.HttpRequest).%New()
	set sc=request.Get(ipDictionaryURL)
	if ('sc) {$$$ThrowOnError(sc)}
	set response=request.HttpResponse
	if (response.StatusCode '="200") $$$ThrowOnError($$$ERROR(500,"Bad Status Code"_response.StatusCode))
	try 
	{
		set json={}.%FromJSON(response.Data)
	}
	catch
	{
		$$$ThrowOnError($$$ERROR(500,"document stored is not valid json: "_ipDictionaryURL))
	}
	set ipAddressGrp= json.%Get(label)
	if (ipAddressGrp ="") {$$$ThrowOnError($$$ERROR(500,"label not defined"_label))}
	set ipAddress= ipAddressGrp.%Get(environment)
	if (ipAddress ="") {$$$ThrowOnError($$$ERROR(500,"environment ("_environment_") not defined for label("_label_")"))}
	return ipAddress
}

ClassMethod GetEnvironmentName() As %String
{
	return ^["VABUILD"]VDIF("environment")
}

}