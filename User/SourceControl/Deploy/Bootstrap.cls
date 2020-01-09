Class User.SourceControl.Deploy.Bootstrap
{
ClassMethod CompileUsingAtelierEndpoint(atelierBaseEndpoint As %String = "http://server:port/api/atelier", className As %String = "User.SourceControl.Deploy.Projection.cls", namespace As %String = "User", username As %String = "_system", password As %String = "SYS")
{
	set request=##class(%Net.HttpRequest).%New()
	set request.Username=username
	set request.Password=password
	w 1
	set endpoint=atelierBaseEndpoint_"/v1/"_namespace_"/doc/"_className
	do request.Send("Delete",endpoint)
	w 2
	set classArray=..GetUDLasArray(className)
	set body={}
	set body.enc= "false"
	set body.content= classArray
	do request.EntityBody.Write(body.%ToJSON())
	do request.SetHeader("Content-Type", "application/json") 
	do request.Put(endpoint)
	w 3
	set body=[(className)]
	set endpoint=atelierBaseEndpoint_"/v1/"_namespace_"/action/compile"
	do request.EntityBody.Clear()
	do request.EntityBody.Write(body.%ToJSON())
	do request.SetHeader("Content-Type", "application/json") 
	do request.Post(endpoint)
	w 4
	w !!,request.HttpResponse.Data.Read(),!!
	w 5
	set responseData={}.%FromJSON(request.HttpResponse.Data)
	w 6
	return responseData.status.errors.%Size()<1
}

ClassMethod GetUDLasArray(className As %String) As %Library.DynamicArray
{
	set array=[]
	set currentNamespace=$namespace
	do ##class(%Compiler.UDL.TextServices).GetTextAsArray(currentNamespace,className,.classAsGlobalArray)
	zw classname
	zw currentNamespace
	zw classAsGlobalArray
	for i=1:1:classAsGlobalArray(0)
	{
		do array.%Push(classAsGlobalArray(i))
	}
	return array
}
}