SuperStrict
Framework BRL.Blitz
Import BRL.Max2D
Import BRL.Map
Import BRL.Timer
Import sidesign.minib3d

Include "config.bmx"
Include "util.bmx"

Type TStation
	Field Entity:TEntity
	Field Population:Int
	Field Interest:Int
	Field DestinationLinks:TList
	
	Method New()
		Self.DestinationLinks = New TList
	EndMethod
	
EndType

Type TDestLink
	Field Origin:TStation
	Field Target:TStation
	Field Interest:Int
EndType

Type TTown
	Field x:Int
	Field y:Int
	Field Population:Int
	Field Reputation:Int	' in %
EndType

Type TBlimp
	Field Entity:TEntity

	Field Speed:Float
	Field Reliability:Int
	Field Profit:Int
	
	Field Template:TBlimpTemplate
	
	Field Target:TStation
	Field Origin:TStation
	
	Field Orders:TList
	Field CurrentOrder:TOrder
	Field RepeatOrders:Byte
	
	Field Cargo:TList
	
	Method New()
		Self.Orders = New TList
		Self.Cargo = New TList
	EndMethod
	
	Method MoveToTarget()
		RotateEntity( Self.Entity, DeltaPitch(Self.Entity, Target.Entity), DeltaYaw(Self.Entity, Target.Entity), 0)
		MoveEntity( Self.Entity, 0, 0, Self.Speed )
	EndMethod
	
	Method Update()
		If Self.Target <> Null Then
			Local distance:Float = EntityDistance( Self.Entity, Target.Entity )
			Self.Speed = Min( Self.Speed + 1.0 / Self.Template.MaxSpeed * Self.Template.AccelFactor, Self.Template.MaxSpeed )
			MoveToTarget()
			If distance < 0.3
				DebugLog( "Arrived!" )
				CurrentOrder.Execute( Self )
				GetNextOrderInQueue()
			EndIf
		EndIf
	EndMethod
	
	Method GetNextOrderInQueue()
		If Self.CurrentOrder <> Self.Orders.Last()
			Self.CurrentOrder = TOrder(Self.Orders.FindLink(Self.CurrentOrder).NextLink().Value())
			Self.Target = CurrentOrder.Target
		ElseIf Self.RepeatOrders = True
			Self.CurrentOrder = TOrder(Self.Orders.First())
			Self.Target = CurrentOrder.Target
		Else
			Self.CurrentOrder = Null
			Self.Target = Null
		EndIf
	EndMethod
	
	Function Create:TBlimp( Template:TBlimpTemplate, x:Double, z:Double )
		Local b:TBlimp = New TBlimp
		b.Template = Template
		b.Entity = CopyEntity(Template.Entity)
		ShowEntity(b.Entity)
		PositionEntity( b.Entity, x, 0, z )
		Return b
	EndFunction
EndType

Type TCargo
	Const TYPE_PASSENGER:Int	= 1
	Const TYPE_UNICORN:Int		= 2
	
	Field Origin:TStation
	Field Target:TStation
	Field CargoType:Int
	Field Value:Int
	
	Function Create:TCargo( Target:TStation, CargoType:Int, Value:Int, Origin:TStation = Null )
		Local c:TCargo = New TCargo
		c.Target = Target
		c.CargoType = CargoType
		c.Value = Value
		c.Origin = Origin
		Return c
	EndFunction
	
	Method SellCargo( Blimp:TBlimp )
		Blimp.Cargo.Remove(Self)
		Blimp.Profit :+ Self.Value
		Moneez :+ Self.Value
		DebugLog("Sold Cargo for " + Self.Value)
	EndMethod
EndType

Type TOrder
	Const TASK_GOTO:Int 			= 1
	Const TASK_MAINTENANCE:Int 		= 2
	Const TASK_GOTO_AND_UNLOAD:Int 	= 3
	Const TASK_GOTO_AND_LOAD:Int 	= 4
	Const TASK_GOTO_AND_DOSHIT:Int	= 5
	
	Field Target:TStation
	Field Task:Int
	
	Function Create:TOrder( Target:TStation, Task:Int )
		Local o:TOrder
		o:TOrder = New TOrder
		o.Target = Target
		o.Task = Task
		Return o
	EndFunction
	
	Method Execute( Blimp:TBlimp )
		Select Self.Task
			Case TASK_GOTO_AND_DOSHIT
				If Blimp.Cargo.Count() > 0
					Local totalprofit:Int
					
					For Local c:TCargo = EachIn Blimp.Cargo
						If c.Target = Blimp.Target Then
							'Sell dat shit!
							TotalProfit :+ c.Value
							c.SellCargo( Blimp )
						EndIf
					Next
					
					CameraProject( CamCon.Camera, EntityX(blimp.Entity), EntityY(blimp.Entity), EntityZ(blimp.Entity) )
					TProfitText.Create( Currency + totalprofit, blimp.Entity, 0, 255, 0)
				EndIf
			Default
				DebugLog( "lolwat. Wtf is " + Self.Task + "?!" )
		EndSelect
	EndMethod
EndType

Type TBlimpTemplate
	Field MaxSpeed:Float
	Field MaxCapacity:Int
	Field Price:Int
	Field AccelFactor:Float
	Field Entity:TEntity
	
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


Type TIsland
	Field Mesh:TMesh
	Field Towns:TList
	Field Terrain:Int[,]	' 2 dimensional arrays, right in ma butt!
	
	Method New()
		Self.Towns = New TList
	EndMethod
	
	Method BuildGeometry()
		Self.Mesh = CreateMesh()
		Local surf:TSurface = CreateSurface( Self.Mesh )
		Local x:Int, y:Int
		For x = 0 To Self.Terrain.Dimensions()[0] - 1
			For y = 0 To Self.Terrain.Dimensions()[1] - 1
				If Self.Terrain[x, y] > -1
					Local v0:Int, v1:Int, v2:Int, v3:Int
					v0 = AddVertex(surf, -1 + x * 2	, Self.Terrain[x, y] / 5.0	, -1 + y * 2, 0, 0)	'upper left
					v1 = AddVertex(surf, 1 + x * 2	, Self.Terrain[x, y] / 5.0	, -1 + y * 2, 1, 0)	'upper right
					v2 = AddVertex(surf, -1 + x * 2	, Self.Terrain[x, y] / 5.0	, 1 + y * 2	, 0, 1)	'lower left
					v3 = AddVertex(surf, 1 + x * 2	, Self.Terrain[x, y] / 5.0	, 1 + y * 2	, 1, 1)	'lower right
					AddTriangle(surf, v2, v1, v0)
					AddTriangle(surf, v1, v2, v3)
				EndIf
			Next
		Next
		EntityColor(Self.Mesh, 0, 255, 0)
		UpdateNormals(Self.Mesh)
	EndMethod
	
	Method ReadTerrainData(stream:TStream)
		Local width:Int = Int(ReadLine(stream))
		Local height:Int = Int(ReadLine(stream))
		Local x:Int, y:Int
		Local line:String[]
		
		For y = 0 To height - 1
			line = ReadLine(stream).Split(",")
			For x = 0 To width - 1
				Terrain[x, y] = Int(line[x])
			Next
		Next
		CloseStream(stream)
	EndMethod
	
	Function Create:TIsland(w:Int, h:Int)
		Local is:TIsland = New TIsland
		is.Terrain = New Int[w, h]
		For Local x:Int = 0 To w - 1
			For Local y:Int = 0 To h - 1
				is.Terrain[x, y] = -1
			Next
		Next
		Return is
	EndFunction
EndType


Global Config:TMap = ParseConfig("conf/game.cfg")

InitiateGraphics()

'Purely test code
Local town1:TStation = New TStation
town1.Entity = CreateCube()
PositionEntity town1.Entity, 4, 0, 3

Local blimpcone:TMesh = CreateCone()
RotateMesh blimpcone, 90, 0, 0
Local myblimp:TBlimpTemplate = TBlimpTemplate.Create( 0.25, 20, 200, 0.05, blimpcone)

Local blimp:TBlimp = TBlimp.Create( myblimp, -15, -15 )
blimp.Target = town1
blimp.CurrentOrder = TOrder.Create( town1, TOrder.TASK_GOTO_AND_DOSHIT )
blimp.Orders.AddLast(blimp.CurrentOrder)
Local c:TCargo = TCargo.Create( blimp.Target, TCargo.TYPE_PASSENGER, 30 )
blimp.Cargo.AddLast(c)

Global Moneez:Int = 0
Global Currency:String = String(Config.ValueForKey("currency"))
If Currency = "" Then Currency = "$"

Global CamCon:TCameraController = TCameraController.CreateCameraController( 0.8 )
PositionEntity( CamCon.Camera, 0, 20, -30 )
RotateEntity( CamCon.Camera, 45, 0, 0 )
CameraClsColor(CamCon.Camera, 125, 200, 255)

Local CloudPlane:TEntity = CreateClooouuud()
PositionEntity CloudPlane, 0, -10, 0

Local Light:TLight = CreateLight()
RotateEntity(Light, 45, 45, 0)

Local FrameTimer:TTimer = CreateTimer(60)

Local xcone:TEntity = CreateCone()
EntityColor xcone, 255, 0, 0
RotateEntity xcone, 90, 90, 0
PositionEntity xcone, -2, 0, 0

Local ycone:TEntity = CreateCone()
EntityColor ycone, 0, 255, 0
RotateEntity ycone, 0, 0, 0
PositionEntity ycone, 0, 2, 0

Local zcone:TEntity = CreateCone()
EntityColor zcone, 0, 0, 255
RotateEntity zcone, 90, 0, 0
PositionEntity zcone, 0, 0, 2

Local TestIsland:TIsland = TIsland.Create(10, 10)
TestIsland.ReadTerrainData(ReadFile("testisland.txt"))
TestIsland.BuildGeometry()

Local wfon:Int

Repeat
	CamCon.UpdateControls()
	blimp.Update()
	If KeyHit(KEY_W) Then wfon = 1 - wfon
	Wireframe(wfon)
	
	UpdateWorld()
	RenderWorld()
	
	BeginMax2D()
	SetBlend(AlphaBlend)
	
	For Local p:TProfitText = EachIn TProfitText.List
		p.Update()
		If p.FramesDone > 120 Then
			DebugLog("STFU TEXT")
			TProfitText.List.Remove(p)
		EndIf
	Next
	
	'Super Advanced HUD
	DrawText "MoneyFoods: " + Currency + " " + Moneez, 0, 0
	DrawText "Camera Coords: " + EntityX(CamCon.Camera) + ", " + EntityY(CamCon.Camera) + ", " + EntityZ(CamCon.Camera), 0, 12
	DrawText "Camera G: " + CamCon.xg + ", " + CamCon.yg + ", " + CamCon.zg, 0, 24
	EndMax2D()
	Flip 1
	Cls
	WaitTimer(FrameTimer)
Until KeyHit( KEY_ESCAPE )

Function InitiateGraphics()
	SetGraphicsDriver GLMax2DDriver()
	Local gwidth:Int, gheight:Int, gdepth:Int, gmode:Int, ghertz:Int, galias:Int
	Try
		gwidth = Int(String(Config.ValueForKey("graphicswidth")))
		gheight = Int(String(Config.ValueForKey("graphicsheight")))
		gdepth = Int(String(Config.ValueForKey("graphicsdepth")))
		'gmode = Max((Int(String(Config.ValueForKey("fullscreen"))) = 0) * 2, 1)	'lol hack. fuck you maintainability. I'll never touch this again
		gmode = Int(String(Config.ValueForKey("windowed"))) + 1	'simpler.
		ghertz = Int(String(Config.ValueForKey("refreshrate")))
		galias = Int(String(Config.ValueForKey("antialiasing")))
		If ghertz = 0 Then ghertz = 60
		If gdepth = 0 Then gdepth = 32
		If Not GraphicsModeExists( gwidth, gheight, gdepth, ghertz ) Then Throw "Invalid graphics settings in config. :/"
		
		If Not IsInConfig(["graphicswidth", "graphicsheight"], Config)
			'First launch without configuration
			If GraphicsModeExists( DesktopWidth(), DesktopHeight(), DesktopDepth(), DesktopHertz() )
				gwidth = DesktopWidth()
				gheight = DesktopHeight()
				galias = 0
				gdepth = DesktopDepth()
				gmode = 1
				ghertz = DesktopHertz()
				DebugLog( gwidth + ", " + gheight + ", " + gdepth + ", " + ghertz)
			Else
				Throw "Desktop resolution not supported. Thefuck?"
			EndIf
		EndIf
	Catch e:String
		WriteStderr(e)
		gwidth = 800
		gheight = 600
		galias = 0
		gmode = 0
	EndTry
	
	AppTitle = "BlimpTycoon v0.0001. Your face."
	Graphics3D gwidth, gheight, gdepth, gmode, ghertz
	AntiAlias(galias)
EndFunction

