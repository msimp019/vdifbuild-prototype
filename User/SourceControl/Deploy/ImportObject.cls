Class User.SourceControl.Deploy.ImportObject Extends (%Persistent, %XML.Adaptor)
{

Property ObjectStream As %Stream.GlobalBinary;

Property Name As %String(MAXLEN = 512);

/// Revision number of this class
Parameter SrcVer = 2;

Storage Default
{
<Data name="ImportObjectDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ObjectStream</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
</Data>
<DataLocation>^User.SourceCoF138.ImportObjectD</DataLocation>
<DefaultData>ImportObjectDefaultData</DefaultData>
<IdLocation>^User.SourceCoF138.ImportObjectD</IdLocation>
<IndexLocation>^User.SourceCoF138.ImportObjectI</IndexLocation>
<StreamLocation>^User.SourceCoF138.ImportObjectS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}
