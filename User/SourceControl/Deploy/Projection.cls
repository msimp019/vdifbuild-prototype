Class User.SourceControl.Deploy.Projection Extends %Projection.AbstractProjection
{

Projection Reference As User.SourceControl.Deploy.Projection;

/// Runs on Compile to setup worker app
ClassMethod CreateProjection(cls As %String, ByRef params) As %Status
{
	w $namespace
	w !!,"Doing some setup1",!!
	s ^XABS=7777
	quit $$$OK
}

ClassMethod RemoveProjection(cls As %String, ByRef params, recompile As %Boolean) As %Status
{
	w !!,"removing projection",!!
	k ^XABS
	QUIT $$$OK
}

ClassMethod test()
{
	w 1
}
}

