Function ParseConfig:TMap( path:String )
	Local FileStream:TStream = ReadFile( path )
	Local Map:TMap = CreateMap()
	If FileStream = Null Then Return Map
	Local Line:String
	While Not Eof( FileStream )
		Line = FileStream.ReadLine()
		
		'Find the comments
		Local CommentPos:Int = Line.Find( ";" )
		If (CommentPos > Line.Find( "#" ) And Line.Find( "#" ) > -1) Or CommentPos = -1 Then
			CommentPos = Line.Find( "#" )
		EndIf
		If CommentPos > -1 Then
			Line = Line[..CommentPos]
		EndIf
		
		'Separate Value and Key
		Local EqPos:Int 	= Line.Find( "=" )
		Local Key:String 	= Line[..EqPos].ToLower().Trim()
		Local Value:String 	= Line[(EqPos + 1)..].Trim()
		
		If Key <> ""
			DebugLog( Key + "=" + Value )
			MapInsert( Map, Key, Value )
		EndIf
		
	Wend
	CloseFile( FileStream )
	Return Map
EndFunction

Function SaveConfig( path:String, Map:TMap )
	Local FileStream:TStream = WriteFile( path )
	Local Key:String
	
	For Key = EachIn MapKeys( Map )
		Local Line:String = String(Key) + " = " + String(Map.ValueForKey( Key ))
		WriteLine( FileStream, Line )
	Next
	CloseFile( FileStream )
EndFunction

Function IsInConfig:Int( Keys:Object[], Map:TMap )
	For Local o:Object = EachIn Keys
		If Not Map.Contains(o) Then Return False
	Next
	Return True
EndFunction