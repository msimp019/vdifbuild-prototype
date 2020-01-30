Class User.SourceControl.Deploy.Bootstrap
{
ClassMethod CompileUsingAtelierEndpoint(atelierBaseEndpoint As %String = "http://server:port/api/atelier", className As %String = "User.SourceControl.Deploy.Projection.cls", namespace As %String = "User", username As %String = "_system", password As %String = "SYS") As %Status
{
	set request=##class(%Net.HttpRequest).%New()
	set request.Username=username
	set request.Password=password

	set endpoint=atelierBaseEndpoint_"/v1/"_namespace_"/doc/"_className
	do request.Send("Delete",endpoint)

	set classArray=..GetUDLasArray(className)
	set body={}
	set body.enc= "false"
	set body.content= classArray
	do request.EntityBody.Write(body.%ToJSON())
	do request.SetHeader("Content-Type", "application/json") 
	set sc=request.Put(endpoint)

	set responseData={}.%FromJSON(request.HttpResponse.Data)
	if (responseData.status.errors.%Size()>0)
	{
		return $$$ERROR($$$GeneralError,responseData.status.errors.%Get(0))
	}

	set body=[(className)]
	set endpoint=atelierBaseEndpoint_"/v1/"_namespace_"/action/compile"
	do request.EntityBody.Clear()
	do request.EntityBody.Write(body.%ToJSON())
	do request.SetHeader("Content-Type", "application/json") 
	do request.Post(endpoint)

	set responseData={}.%FromJSON(request.HttpResponse.Data)
	
	set iter=responseData.console.%GetIterator()
	while iter.%GetNext(,.val)
	{
		write val,!
	}
	if (responseData.status.errors.%Size()>0)
	{
		return $$$ERROR($$$GeneralError,responseData.status.errors.%Get(0))
	}
	
	return $$$OK
}

ClassMethod GetUDLasArray(className As %String) As %Library.DynamicArray
{
	set array=[]
	set currentNamespace=$namespace
	do ##class(%Compiler.UDL.TextServices).GetTextAsArray(currentNamespace,className,.classAsGlobalArray)
	for i=1:1:classAsGlobalArray(0)
	{
		do array.%Push(classAsGlobalArray(i))
	}
	return array
}
}