Class SourceControl.Util Extends %RegisteredObject
{

// Sample Entry 

// Do ##class(SourceControl.Util).ExtractAndPush($LISTBUILD("DR1", "USER"), $LISTBUILD(".cls", ".inc", ".mac"),"C:\Mater")

/// IRIS Databases - File export and git push 
/// Edit - 1 to check gitHub 
/// Edit -2  to check gitHub 
ClassMethod ExtractAndPush(dbList As %List, extList As %List, workDir As %String) As %Status
{
    set st = $$$OK
    set i = 0
    set p = 0
    set ns = $namespace
    try {
    //Loop through each Database(s) 
    while $LISTNEXT(dbList, i, db) {
        write "Processing Database: "_db, !
        zn "%SYS"
        set dbObj = ##class(SYS.Database).%OpenId(db)
        set dbDir = dbObj.Directory
        // Construct the namespace dynamically
        set nsPath = "^^"_dbDir
		
		//Loop though each file extension（s） within each database
        while $LISTNEXT(extList, p, ext) {
	        if ext = ".cls"
	        {
		    	zn nsPath
		    	set nsName = $PIECE($PIECE($Namespace, "\", *-1), "\", *)
		    	set objRS=##class(%ResultSet).%New()
				set objRS.ClassName="%Dictionary.ClassDefinitionQuery"
				set objRS.QueryName="ClassIndex"
				do objRS.Execute()
				while objRS.Next() {
					set tClassName=objRS.GetData(2)
					//Exclude system classfiles start with "%"
					if $EXTRACT(tClassName, 1) = "%" {
        				continue
    				}
					set dynamicPath = ""
        			set index = 1
        			set part = $Piece(tClassName, ".", index)
        			while part'="" {
            			set dynamicPath = dynamicPath _ $Select(index=1:"", 1:"\") _ part
            			set index = index + 1
            			set part = $Piece(tClassName, ".", index)
        	}
        		set extPath = $PIECE(ext, ".",2)
        		set targetDir = workDir_"\src\"_nsName_"\"_extPath_"\"_ dynamicPath _ext
				Set status = ##class(%SYSTEM.OBJ).ExportUDL(tClassName_".cls", targetDir)
				}
				Write "Query completed for: "_ext_" successfully.", !	    
		    }
            else{
	            zn nsPath
	 			set nsName = $PIECE($PIECE($Namespace, "\", *-1), "\", *)
            	SET tStatement = ##class(%SQL.Statement).%New()
				DO tStatement.%PrepareClassQuery("%Routine", "RoutineList")
				SET rs = tStatement.%Execute(ext,,0)
				WHILE rs.%Next() {
					set tClassName = $Piece(rs.%Get("Name"), ".", 1, *-1)
					set dynamicPath = ""
					set index = 1
    				set part = $Piece(tClassName, ".", index)
        			while part'="" {
            			set dynamicPath = dynamicPath _ $Select(index=1:"", 1:"\") _ part
            			set index = index + 1
            			set part = $Piece(tClassName, ".", index)
        			}
        			set extPath = $PIECE(ext, ".",2)
        			set targetDir = workDir_"\src\"_nsName_"\"_extPath_"\"_ dynamicPath _ext
					Set status = ##class(%SYSTEM.OBJ).ExportUDL(tClassName _ext, targetDir)
					}
					Write "Query completed for: "_ext_" successfully.", !
            	}
            zn ns
        }
        	Write "complete export DataBase: "_db_" successfully.", !
		}
         	write "All files exported !", !
         	//perform Git operation
            set currentTime = $ZDATETIME($H,3)  // Format: DD/MM/YYYY HH:MM AM/PM
            set timePart = $PIECE(currentTime, " ", 2)
            set datePart = $PIECE(currentTime, " ", 1)
            set commitMsg = "Auto commit from InterSystems IRIS at "_timePart_" on "_datePart
            set pushResult = 0
            set pushResult = $ZF(-100,"/shell",
            "cd", ""_workDir_"", "&&",
             "git", "add",".", "&&", 
             "git", "commit", "-m", ""_commitMsg_"", "&&",
             "git", "push", "-u", "origin", "main")
            if pushResult = 0 {
                write "Git Push done! Process finished!", !
            } else {
	            write "ERROR Git Push Failed!", !
            }
		}catch ex {
		        // Error Handling
		        set st = ex.AsStatus()
		        write "An error occurred: ", ex.DisplayString(), !
		    }
		 quit st
}

}

