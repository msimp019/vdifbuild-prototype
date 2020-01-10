Class User.SourceControl.Deploy.Projection Extends %Projection.AbstractProjection
{

Projection Reference As User.SourceControl.Deploy.Projection;

/// Runs on Compile to setup worker app
ClassMethod CreateProjection(cls As %String, ByRef params) As %Status
{
	w $namespace
	w !!,"Doing some setup1",!!
	s ^XABS="test"
	set tSC= ##class(User.SourceControl.Deploy.Service).ConfigureHSCUSTOM()
	write "ConfigureHSCUSTOM output of: "_$SYSTEM.Status.GetErrorText(tSC)
	set tSC=$$$ERROR($$$GeneralError,"testing124")
	w "we are done"
	quit tSC
}

ClassMethod RemoveProjection(cls As %String, ByRef params, recompile As %Boolean) As %Status
{
	w !!,"removing projection",!!
	k ^XABS
	QUIT $$$OK
}

}

