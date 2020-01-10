Class User.SourceControl.Deploy.Projection Extends %Projection.AbstractProjection
{

Projection Reference As User.SourceControl.Deploy.Projection;

/// Runs on Compile to setup worker app
ClassMethod CreateProjection(cls As %String, ByRef params) As %Status
{
	set tSC=$$$OK
	write !,"Inside Projection"
	set tSC= ##class(User.SourceControl.Deploy.Service).ConfigureHSCUSTOM()
	quit tSC
}

ClassMethod RemoveProjection(cls As %String, ByRef params, recompile As %Boolean) As %Status
{
	w !!,"removing projection",!!
	k ^XABS
	QUIT $$$OK
}

}

