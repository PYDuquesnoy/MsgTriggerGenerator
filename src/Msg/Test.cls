/// A Persistent Test message
Class Msg.Test Extends (Ens.Request, Msg.Super) [ StorageStrategy = "" ]
{

// Test the Alt.Msg.Super Trigger Generator

ClassMethod Test() As %Status
{
	#DIM tSC as %Status=$$$OK
	#DIM errObj as %Exception.AbstractException
	try {
		///---Start Clean
		do ..%KillExtent()
		do ..Insert(1,"One","Pic:This is One","One StringRequest","Response1a,Response1b,Response1c")
		do ..Insert(2,"Two","Pic:This is Row Two","Two StringRequest","Response2a,Response2b,Response2c")
		do ..Insert(3,"Three","Pic:This is Row Three","Three StringRequest","Response3a,Response3b,Response3c")
		
		
		
	}catch (errObj) {
		Write "CATCH:"
		if ($SYSTEM.Status.IsError(tSC)) { 
			do $System.Status.DisplayError(tSC) 
		} else { 
			write errObj.DisplayString() 
			set tSC=errObj.AsStatus()
		}
		Write !
	}
	quit tSC
}

// Inserts a new Row

ClassMethod Insert(
	tOne,
	tTwo,
	tMyPic,
	tMyContentRequest,
	tList) As %Status
{
	#DIM tSC=$$$OK
	set tObj=..%New()
	set tObj.One=tOne
	set tObj.Two=tTwo
	set tObj.MyPic=##class(Ens.StreamContainer).%New()
	set tObj.MyPic.Stream=##class(%Stream.GlobalBinary).%New()
	do tObj.MyPic.Stream.Write(tMyPic)
	set tObj.MyContentRequest=##class(Ens.StringRequest).%New()
	set tObj.MyContentRequest.StringValue=tMyContentRequest
	for i=1:1:$length(tList,",") {
		set tR=##class(Ens.StringResponse).%New()
		set tR.StringValue=$piece(tList,",",i)
		do tObj.MyContentResponses.Insert(tR)
		do tObj.MyArraysReponses.SetAt(tR,i)
		set tM=##class(Alt.Msg.TestMany).%New()
		set tM.Name=$piece(tList,",",i)
		set tM.TheOne=i
	}
	
	$$$THROWONERROR(tSC,tObj.%Save(1))
	Write "Inserted:",tObj.%Id(),!
}

Property One As %Integer;

Property Two As %String(MAXLEN = 255);

Property MyPic As Ens.StreamContainer;

Property MyContentRequest As Ens.StringRequest;

Property MyContentResponses As list Of Ens.StringResponse;

Property MyArraysReponses As array Of Ens.StringResponse;

Relationship MyMany As Alt.Msg.TestMany [ Cardinality = many, Inverse = TheOne ];

Storage Default
{
<Data name="MyArraysReponses">
<Attribute>MyArraysReponses</Attribute>
<Structure>subnode</Structure>
<Subscript>"Msg.Test.MyArraysReponses"</Subscript>
</Data>
<Data name="TestDefaultData">
<Subscript>"Test"</Subscript>
<Value name="1">
<Value>One</Value>
</Value>
<Value name="2">
<Value>Two</Value>
</Value>
<Value name="3">
<Value>MyPic</Value>
</Value>
<Value name="4">
<Value>MyContentRequest</Value>
</Value>
<Value name="5">
<Value>MyContentResponses</Value>
</Value>
</Data>
<DefaultData>TestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
