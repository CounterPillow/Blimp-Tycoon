Type TBlimpTemplate
	Global List:TList = New TList
	Field MaxSpeed:Float
	Field MaxCapacity:Int
	Field Price:Int
	Field AccelFactor:Float
	Field Entity:TEntity
	Field Name:String
	
	Function Create:TBlimpTemplate( MaxSpeed:Float, MaxCapacity:Int, Price:Int, AccelFactor:Float, Entity:TEntity )
		Local bt:TBlimpTemplate = New TBlimpTemplate
		bt.MaxSpeed = MaxSpeed
		bt.MaxCapacity = MaxCapacity
		bt.Price = Price
		bt.AccelFactor = AccelFactor
		bt.Entity = Entity
		HideEntity bt.Entity
		Return bt
	EndFunction
EndType

Function LoadBlimpTemplates()
	Local dir:String[] = LoadDir("data/blimps/")
	For Local f:String = EachIn dir
		If f.EndsWith(".bt")
			TBlimpTemplate.List.AddLast(LoadTemplate(f))
		EndIf
	Next
EndFunction

Function LoadTemplate:TBlimpTemplate(file:String)
	Local map:TMap = ParseConfig( file )
	Local bt:TBlimpTemplate = New TBlimpTemplate
	bt.MaxSpeed = Float(String(map.ValueForKey("maxspeed")))
	bt.MaxCapacity = Int(String(map.ValueForKey("maxcapacity")))
	bt.Name = String(map.ValueForKey("name"))
	bt.Price = Int(String(map.ValueForKey("price")))
	bt.AccelFactor = Float(String(map.ValueForKey("accelfactor")))
	bt.Entity = LoadMesh(String(map.ValueForKey("mesh")))
	HideEntity(bt.Entity)
	Return bt
EndFunction
