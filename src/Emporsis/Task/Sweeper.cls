/// Keeps A Registry of Global Sizes on a given Date, and Allows to Delete any Data older than "DaysToKeep" Days
/// this Task should only be used in Interoperability Namespaces that are not storing any persistent Data, except for messages and related elements.
/// Any data elements older tat DaysToKeep are expected to be messages or items that can be deleted.
/// So if you used any table or element for Metadata or other definitions, these elements might get deleted after DaysToKeep!
/// 
/// This is unsupported code: use art your own risk
/// 
Class Emporsis.Task.Sweeper Extends %SYS.Task.Definition
{

Parameter TaskName = "Sweep Lost Data";

/// Number of Days of Data to keep
Property DaysToKeep As %Integer [ InitialExpression = 20 ];

/// Verbose Output to a file?
Property Verbose As %Boolean [ InitialExpression = 1 ];

/// ClassesToSkip: Comma Separated List of Clases or Package Names that should *not* be incuded in the Purge
Property ClassesToSkip As %String(MAXLEN = 512) [ InitialExpression = "Emporsis" ];

/// This method is responsible for executing the task.<br>
/// At the scheduled time, the Task Manager creates an instance of this object,
/// sets any property values using the stored "Settings" for the task, and then
/// invokes this method to execute the task.<br>
Method OnTask() As %Status
{
	#DIM tSC as %Status=$$$OK
	#DIM errObj as %Exception.AbstractException
	try {
		Write:..Verbose !,"=============================================",!
		Write:..Verbose !,"Sweep Task Started at "_$ZDT($H,3),!,!
		$$$THROWONERROR(tSC,..ScanAllTables(..Verbose,..ClassesToSkip))
		Write:..Verbose !,"Clean Started",!,!
		$$$THROWONERROR(tSC,..Clean(..DaysToKeep,..Verbose))
		$$$THROWONERROR(tSC,..Purge(..DaysToKeep,..Verbose))
		Write:..Verbose !,"=============================================",!
	}catch (errObj) {
		set tSC=errObj.AsStatus()
	}
	quit tSC
}

/// Goes through All Persistent tables in the 
ClassMethod ScanAllTables(pVerbose As %Boolean = 0, pClassesToSkip As %String = "") As %Status
{
	#DIM tSC as %Status=$$$OK
	#DIM errObj as %Exception.AbstractException
	#DIM tStmt as %SQL.Statement
	#DIM tRS as %SQL.StatementResult
	try {
		
		set tScanDate=$ZD($H,3)
		
		set tStmt=##class(%SQL.Statement).%New()
		set tSC = tStmt.%PrepareClassQuery("%Dictionary.ClassDefinitionQuery","SubclassOf") 
		$$$ThrowOnError(tSC)
		set tRS= tStmt.%Execute("%Persistent")  //All Root Packages
	
  		while (tRS.%Next()) {
	  		set tCName=tRS.%GetData(1)
	  		//Skip Some Classes
	  		if $extract(tCName,1)="%" continue
	  		if (",HS,HSFHIR,HSMOD,SchemaMap,INFORMATION,"[(","_$piece(tCName,".",1)_",")) continue
	  		if $piece(tCName,".",1)="Ens" && ((",Ens.MessageBody,Ens.GenericObject,Ens.BP.Context,Ens.BP.Thread,Ens.Rule.Action,Ens.Rule.Log,Ens.Rule.RuleLog,Ens.StreamContainer,Ens.StringContainer,Ens.Util.IOLog,Ens.Util.Log,"'[tCName)) continue
	  		if $piece(tCName,".",1)="EnsLib"  continue
	  		if $classname()=tCName continue
	  		if ("Emporsis.Task.Sweeper.Record"=tCName) continue   //this is where we Store our Data!
	  		if (","_pClassesToSkip_",")[(","_tCName_",") continue //ClassName Specified in list to Skip
	  		if (","_pClassesToSkip_",")[(","_$piece(tCName,".",1)_",") continue //Exact Package Name Specified in list to Skip
	  		
	  		
	  		
	  		//Open Class, Get Global and StreamGlobal
	  		set tClass=##class(%Dictionary.ClassDefinition).%OpenId(tCName)
	  		if (tClass.Storages.Count()=1) {
		  		//Write:pVerbose tRS.%GetData(1),!
		  		
		  		#DIM tStore as %Dictionary.StorageDefinition
		  		set tStore=tClass.Storages.GetAt(1)
		  		set tGloDat=tStore.DataLocation
		  		set tGloStream=tStore.StreamLocation
		  		if ($e(tGloDat,1)="^") {
		  			set tGloDatIx=$order(@tGloDat@(""),-1)
		  			$$$THROWONERROR(tSC,..Store(tScanDate,tCName,tGloDat,tGloDatIx))
		  			
		  			Write:(pVerbose&&(tGloDatIx'="")) $c(9),tCName," : ",tGloDat,"->",tGloDatIx,!
		  		}
		  		if ($e(tGloStream,1)="^") {
		  			set tGloStreamIx=$order(@tGloStream@(""),-1)  		
		  			$$$THROWONERROR(tSC,..Store(tScanDate,tCName,tGloStream,tGloStreamIx))
		  			
		  			Write:(pVerbose&&(tGloStreamIx'="")) $c(9),tCName," : ",tGloStream,"->",tGloStreamIx,!
		  		}
		  		
	  		}elseif (tClass.Storages.Count()>0) {
		  		Write:pVerbose "Class "_tCName_" has multiple Storages...so I got lost...skipping",!
	  		}
  		}
  		do ..Store(tScanDate,tCName,"^CacheStream",$o(^CacheStream(""),-1))
  		
	}catch (errObj) {
		set tSC=errObj.AsStatus()
		Write "CATCH",errObj.DisplayString(),!
	}
	quit tSC
}

ClassMethod Store(pScanDate As %Date, pClassName As %String, pGlo As %String, pGloIx As %String) As %Status
{
	#DIM tSC as %Status=$$$OK
	#DIM errObj as %Exception.AbstractException
	try {
		 #sqlcompile select=ODBC
		&sql( insert into Emporsis_Task_Sweeper.Record(ScanDate, ClassName, GlobalName, GlobalIndex) values (:pScanDate,:pClassName,:pGlo,:pGloIx))
		if (SQLCODE<0) { 
			$$$ThrowOnError($$$ERROR($$$GeneralError,%msg))
		}
	}catch (errObj) {
		set tSC=errObj.AsStatus()
	}
	quit tSC
}

/// Purge the Cleanup table at tDays2Keep*2
ClassMethod Purge(tDays2Keep As %Integer, pVerbose = 0) As %Status
{
	#DIM tSC as %Status=$$$OK
	#DIM errObj as %Exception.AbstractException
	try {
		set tSql="Delete from Emporsis_Task_Sweeper.Record where DATEDIFF('D',ScanDate,NOW())>?"
		set tStmt=##class(%SQL.Statement).%New()
		$$$THROWONERROR(tSC,tStmt.%Prepare(tSql))
		set tRS=tStmt.%Execute(tDays2Keep*2)
		
	} catch (errObj) {
		set tSC=errObj.AsStatus()
	}
	quit tSC
}

// Perform the Cleanup of Stale leftover Data

ClassMethod Clean(tDays2Keep As %Integer, pVerbose As %Boolean = 0) As %Status
{
	#DIM tSC as %Status=$$$OK
	#DIM errObj as %Exception.AbstractException
	try {
		//Disable Journalling for this process.
		DO DISABLE^%NOJRN
		
		//For each Class+Globals, find the Highest Index that is at least tDays2Keep Old.
		set tSql="Select ClassName, GlobalName, Max(GlobalIndex) from Emporsis_Task_Sweeper.Record where DATEDIFF('D',ScanDate,NOW())>? group by %Exact(ClassName), %Exact(GlobalName)"  //  order by ScanDate desc
		set tStmt=##class(%SQL.Statement).%New()
		$$$THROWONERROR(tSC,tStmt.%Prepare(tSql))
		set tRS=tStmt.%Execute(tDays2Keep)
		set tIsFound=0
		while (tRS.%Next()) {
			set tIsFound=1
			//Write:pVerbose tRS.%GetData(1)_" -> ",tRS.%GetData(2)," : ",tRS.%GetData(3),!
			//
			set tGlo=tRS.%GetData(2),tLowIndex=tRS.%GetData(3)
			set tIx=tLowIndex
			set tCount=0
			while (tIx'="") {
				kill @tGlo@(tIx)
				//Write "index:",tIx
				set tIx=$Order(@tGlo@(tIx),-1)
				set tCount=tCount+1	
			}
			Write:pVerbose $c(9),tRS.%GetData(1)_"  ;  "_tGlo," -> Deleted ",tCount,"; tLowIndex= ",tLowIndex,"; tMaxIndex=",$order(@tGlo@(""),-1),!
		}
		if ('tIsFound) { Write:pVerbose $c(9),"No Data to Clean",! }

		//Go Back tDays2Keep and find the list of Globals and their Index
		//Kill everything below, register how many cleaned
	}catch (errObj) {
		set tSC=errObj.AsStatus()
	}
	//Enable Journalling again fro this process
	DO ENABLE^%NOJRN
	
	quit tSC
}

/// Only Run this in a Test Environment. It purges the History stored in this table.
/// Creates some Fake Tables, Inserts Data, Runs ScanAllTables, Change Dates, Inserts more Data, Calls Clean, and review Results
ClassMethod Test(tDays2Keep = 1) As %Status
{
	#DIM tSC as %Status=$$$OK
	#DIM errObj as %Exception.AbstractException
	try {
		//Clean Slab
		Write "Cleanup...",!
		do ##class(Emporsis.Task.Sweeper.Record).%DeleteExtent()
		do ##class(AA.CleanTest).%KillExtent(1)
		&sql(Drop table AA.CleanTest)
		
		Write "Creating test Data...",!
		//Some Test Data
		&sql(Create Table AA.CleanTest(one integer primary key, two varchar(20)))
		for i=1:1:50 {
			&sql(insert into AA.CleanTest(one,two) values (:i,'This is some content'))
		}
		Write "Scanning...",!
		$$$THROWONERROR(tSC,..ScanAllTables(1))
		
		//Change Dates
		Write "Changind Dates for testing...",!
		#sqlcompile select=ODBC
		&sql(Update Emporsis_Task_Sweeper.Record set ScanDate=TO_DATE(DATEADD('D',-(:tDays2Keep+1),ScanDate),'YYYY-MM-DD'))
		
		//Insert more Data
		Write "More Data...",!
		for i=100:1:150 {
			&sql(insert into AA.CleanTest(one,two) values (:i,'More content'))
		}
		Break
		
		//Test Clean
		Write "Trying to clean Old Entries...",!
		$$$THROWONERROR(tSC,..Clean(tDays2Keep,1))
		
	}catch (errObj) {
		set tSC=errObj.AsStatus()
		Write "CATCH: ",errObj.DisplayString(),!
	}
	quit tSC
}

}
