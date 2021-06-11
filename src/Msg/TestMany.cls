/// A Persistent Class that is in a one-many relationship
Class Msg.TestMany Extends (%Persistent, %XML.Adaptor)
{

Relationship TheOne As Msg.Test [ Cardinality = one, Inverse = MyMany ];

Property Name As %String;

Index TheOneIndex On TheOne;

Storage Default
{
<Data name="TestManyDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>TheOne</Value>
</Value>
<Value name="3">
<Value>Name</Value>
</Value>
</Data>
<DataLocation>^Msg.TestManyD</DataLocation>
<DefaultData>TestManyDefaultData</DefaultData>
<IdLocation>^Msg.TestManyD</IdLocation>
<IndexLocation>^Msg.TestManyI</IndexLocation>
<StreamLocation>^Msg.TestManyS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
