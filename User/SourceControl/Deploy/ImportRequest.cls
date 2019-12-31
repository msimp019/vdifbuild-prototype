Class User.SourceControl.Deploy.ImportRequest Extends (%Persistent, %XML.Adaptor)
{

Property Objects As list Of User.SourceControl.Deploy.ImportObject;

Property CallBackMethod As %String(MAXLEN = 512);

Property ConfigScripts As list Of %String(MAXLEN = 512);

/// Revision number of this class
Parameter SrcVer = 2;

Storage Default
{
<Data name="ImportRequestDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Objects</Value>
</Value>
<Value name="3">
<Value>CallBackMethod</Value>
</Value>
<Value name="4">
<Value>ConfigScripts</Value>
</Value>
<Value name="5">
<Value>ConfigScriptsMacs</Value>
</Value>
</Data>
<DataLocation>^User.SourceCF138.ImportRequestD</DataLocation>
<DefaultData>ImportRequestDefaultData</DefaultData>
<IdLocation>^User.SourceCF138.ImportRequestD</IdLocation>
<IndexLocation>^User.SourceCF138.ImportRequestI</IndexLocation>
<StreamLocation>^User.SourceCF138.ImportRequestS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

