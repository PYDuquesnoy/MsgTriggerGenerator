/// A Context SuperClass to Delete Complex Persistent Objects Added to the Context
/// A SuperClass for Messages where the Persistent Properties get Deleted In cascade
Class Emporsis.Context.DeleteRelated Extends Ens.BP.Context
{

Trigger DeleteRelated [ CodeMode = objectgenerator, Event = DELETE, Foreach = row/object ]
{
	
 //###TODO: NEW Variables to Protect them (not Procedureblock)
 //###TODO: Add NEW in generated code as well.
 set tPropList=""
 for tI=1:1:%class.Properties.Count() {
	 set tProp=%class.Properties.GetAt(tI)
	 ///For Each Property, Verify if the Datatype is of type persistent
	 set tTypeDef=##class(%Dictionary.ClassDefinition).%OpenId(tProp.Type)
	 if ($isObject(tTypeDef)) {
	 	if ((tTypeDef.ClassType="persistent")||tTypeDef.%IsA("%Persistent")) {
			//This Property references a Persistent Class, we need to delete it
		 	set tPropList=tPropList_$lb(tProp.Name_";"_tProp.Type_";"_$s(tProp.Collection'="":1,tProp.Relationship=1:1,1:0))
	 	}
}
 }
 

 if (tPropList'="") {
	 //We have some properties referencing persistent classes, they require a Delete Operation
	 do %code.WriteLine($c(9)_"n oref ") //FFC Fem un new perque el codi original no funcionava amb missatges anidats
 	 do %code.WriteLine($c(9)_"Set oref=..%OpenId({%%ID},,.sc) If $$$ISERR(sc) set %ok=0,%msg=$System.Status.GetErrorText(sc) Quit")	
 	 do %code.WriteLine($c(9)_"n tPropList ") //FFC Fem un new perque el codi original no funcionava amb missatges anidats
 	 do %code.WriteLine($c(9)_"set tPropList="""_$ListToString(tPropList,",")_"""")
 	 //
 	 do %code.WriteLine($c(9)_"n tI ") //FFC Fem un new perque el codi original no funcionava amb missatges anidats
 	 do %code.WriteLine($c(9)_"for tI=1:1:$length(tPropList,"","") { ")
 	 do %code.WriteLine($c(9)_"n tElt ") //FFC Fem un new perque el codi original no funcionava amb missatges anidats
 	 do %code.WriteLine($c(9,9)_"set tElt=$piece(tPropList,"","",tI) //(name;Type;isCollection)")
 	 do %code.WriteLine($c(9,9)_"if ($p(tElt,"";"",3)=1) {")
 	 //Collection: Loop over elements
 	 do %code.WriteLine($c(9,9,9)_"//Collection: list, Array or Relationship")
 	 do %code.WriteLine($c(9,9,9)_"set tP=$property(oref,$p(tElt,"";"",1))")
 	 do %code.WriteLine($c(9,9,9)_"set key="""",tD=$method(tP,""GetNext"",.key)")
 	 do %code.WriteLine($c(9,9,9)_"while key'="""" {")
	 //PYD20210916: Do not Call Delete on NULL OID			
 	 do %code.WriteLine($c(9,9,9,9)_"do:((tD'="""")&&(tD.%Oid()'="""")) $classmethod($p(tElt,"";"",2),""%Delete"",tD.%Oid())")
 	 do %code.WriteLine($c(9,9,9,9)_"set tD=$method(tP,""GetNext"",.key)   //Next Element")
 	 do %code.WriteLine($c(9,9,9)_"}  //while key")
 	 do %code.WriteLine($c(9,9)_"} else {  //Not a collection ")
 	 //Single Value
 	 do %code.WriteLine($c(9,9,9)_"set tD=$property(oref,$p(tElt,"";"",1)) ")
	 do %code.WriteLine($c(9,9,9)_"if ((tD'="""")&&(tD.%Oid()'="""")) { set sc=$classmethod($piece(tElt,"";"",2),""%Delete"",tD.%Oid()) If $$$ISERR(sc) set %ok=0,%msg=$System.Status.GetErrorText(sc) Quit  } ")
 	 do %code.WriteLine($c(9,9)_"}  //if connection on single value")
 	 do %code.WriteLine($c(9)_"} //for tI...all properties")
 }
 	do %code.WriteLine($c(9)_"quit $$$OK")
 
 quit $$$OK
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
