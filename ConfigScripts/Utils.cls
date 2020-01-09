/// This class gets compiled within every HSCUSTOM namespace of each environment, and should be called within the configuration scripts.
/// This prevents IP addresses being stored on github.  
Class ConfigScripts.Utils
{

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

}

