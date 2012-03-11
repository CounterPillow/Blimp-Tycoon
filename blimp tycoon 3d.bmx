SuperStrict
Import sidesign.minib3d

Include "config.bmx"

Type TStation
	Field Entity:TEntity
	Field Population:Int
	Field Interest:Int
	Field DestinationLinks:TList
	
	Method New()
		Self.DestinationLinks = New TList
	EndMethod
	
	Rem
	Method Draw()
		DrawRect( Self.x, Self.y, 10, 10 )
	EndMethod
	EndRem
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
		RotateEntity( Self.Entity, 0, DeltaYaw(Self.Entity, Target.Entity), 0)
		MoveEntity( Self.Entity, 0, 0, Self.Speed )
	EndMethod
	
	Method Update()
		If Self.Target <> Null Then
			Local distance:Float = EntityDistance( Self.Entity, Target.Entity )
			Self.Speed = Min( Self.Speed + 1.0 / Self.Template.MaxSpeed * Self.Template.AccelFactor, Self.Template.MaxSpeed )
			MoveToTarget()
			If distance < 0.1
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
					ProfitTexts.AddLast(TProfitText.Create( Currency + totalprofit, blimp.Entity, 0, 255, 0))
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

Type TProfitText	'FIXME - transition from 2d to 3d. :o
	Field Caption:String
	Field x:Int
	Field y:Int
	Field yoff:Int
	Field Emitter:TEntity
	Field Alpha:Float = 1.0
	Field FramesDone:Int = 0
	Field r:Int
	Field g:Int
	Field b:Int
	
	Function Create:TProfitText( Caption:String, Emitter:TEntity, r:Int, g:Int, b:Int )
		Local p:TProfitText = New TProfitText
		p.Emitter = Emitter
		p.Caption = Caption
		p.r = r
		p.g = g
		p.b = b
		Return p
	EndFunction
	
	Method Update()
		CameraProject( CamCon.Camera, EntityX(Self.Emitter), EntityY(Self.Emitter), EntityZ(Self.Emitter) )
		Self.x = ProjectedX()
		Self.y = ProjectedY()
		SetAlpha( Self.Alpha )
		SetColor( Self.r, Self.g, Self.b )
		DrawText( Self.Caption, Self.x, Self.y + Self.yoff )
		Self.yoff :- 1
		Self.Alpha = Self.Alpha * 0.97
		Self.FramesDone :+ 1
		SetColor( 255, 255, 255 )
		SetAlpha( 1.0 )
	EndMethod
EndType

Type TIsland
	Field Entity:TEntity
	Field Towns:TList
	Field Population:Int[,]	' 2 dimensional arrays, right in ma butt!
	
	Method New()
		Self.Towns = New TList
	EndMethod
EndType

Type TCameraController
	Field Camera:TCamera
	Field xg:Float
	Field yg:Float
	Field zg:Float
	Field drag:Float	' I don't know if this is the right term for this, but I don't care either. ^-^
	
	Method New()
		Camera = CreateCamera()
	EndMethod
	
	Method UpdateControls()
		Local mdr:Int, mxs:Int, mys:Int, mx:Int, my:Int, mzs:Int, camheight:Float
		mdr = MouseDown(2)
		mxs = MouseXSpeed()
		mys = MouseYSpeed()
		mzs = MouseZSpeed()
		mx = MouseX()
		my = MouseY()
		camheight = EntityZ(Self.Camera)
		
		If mdr Then
			Local divisor:Float = Max((100.0 - Abs(camheight / 2.5)), 5.0)
			Self.xg :- mxs / divisor
			Self.yg :+ mys / divisor
		EndIf
		If mzs Then
			Self.zg :+ mzs / Abs(camheight / 20.0)
			DebugLog(camheight + "->" + Abs(camheight / 5.0))
		EndIf
		If Self.zg < 0 And camheight + Self.zg < -250 Then Self.zg = 0
		If Self.zg > 0 And camheight + Self.zg > -5 Then Self.zg = 0
	
	
		TranslateEntity( Camera,  Self.xg, Self.yg, 0)
		MoveEntity( Camera, 0, 0, Self.zg )
		
		Self.xg :* Self.drag
		Self.yg :* Self.drag
		Self.zg :* Self.drag
		
	EndMethod
	
	Function CreateCameraController:TCameraController( drag:Float )
		Local cc:TCameraController = New TCameraController
		cc.drag = drag
		Return cc
	EndFunction
EndType

Global Config:TMap = ParseConfig("conf/game.cfg")

InitiateGraphics()

'Purely test code
Local town1:TStation = New TStation
town1.Entity = CreateCube()
PositionEntity town1.Entity, 4, 0, 3

Local myblimp:TBlimpTemplate = TBlimpTemplate.Create( 0.25, 20, 200, 0.05, CreateSphere())

Local blimp:TBlimp = TBlimp.Create( myblimp, -15, -15 )
blimp.Target = town1
blimp.CurrentOrder = TOrder.Create( town1, TOrder.TASK_GOTO_AND_DOSHIT )
blimp.Orders.AddLast(blimp.CurrentOrder)
Local c:TCargo = TCargo.Create( blimp.Target, TCargo.TYPE_PASSENGER, 30 )
blimp.Cargo.AddLast(c)

Global Moneez:Int = 0
Global Currency:String = "$"

Global CamCon:TCameraController = TCameraController.CreateCameraController( 0.8 )
PositionEntity( CamCon.Camera, 0, -30, -20 )
RotateEntity( CamCon.Camera, -45, 0, 0 )
CameraClsColor(CamCon.Camera, 125, 200, 255)

Local CloudPlane:TMesh = CreateMesh()
Local CloudSurf:TSurface = CreateSurface(CloudPlane)
Local CloudV:Int[4]
CloudV[0] = AddVertex(CloudSurf, -1, -1, 0, 0, 0)
CloudV[1] = AddVertex(CloudSurf, 1, -1, 0, 1, 0)
CloudV[2] = AddVertex(CloudSurf, -1, 1, 0, 0, 1)
CloudV[3] = AddVertex(CloudSurf, 1, 1, 0, 1, 1)
AddTriangle(CloudSurf, 2, 1, 0)
AddTriangle(CloudSurf, 1, 2, 3)
UpdateNormals(CloudPlane)
ScaleMesh(CloudPlane, 100, 100, 1)
Local CloudTexture:TTexture = LoadTexture("GFX/tex/clooouuud.png", 2)
ScaleTexture CloudTexture, 0.5, 0.5
EntityTexture(CloudPlane, CloudTexture)
PositionEntity CloudPlane, 0, 0, 10

Local Light:TLight = CreateLight()
RotateEntity(Light, -45, 45, 0)

Local FrameTimer:TTimer = CreateTimer(60)

Global ProfitTexts:TList = New TList

Repeat
	CamCon.UpdateControls()
	blimp.Update()
	
	UpdateWorld()
	RenderWorld()
	
	BeginMax2D()
	
	For Local p:TProfitText = EachIn ProfitTexts
		p.Update()
		If p.FramesDone > 120 Then
			DebugLog("STFU TEXT")
			ProfitTexts.Remove(p)
		EndIf
	Next
	
	'Super Advanced HUD
	DrawText "MoneyFoods: " + Moneez, 0, 0
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
				galias = 8
				gdepth = DesktopDepth()
				gmode = 1
				ghertz = DesktopHertz()
				DebugLog( gwidth + ", " + gheight + ", " + gdepth + ", " + ghertz)
			Else
				Throw "Desktop resolution not supported. Thefuck?"
			EndIf
		EndIf
	Catch e:String
		Print e
		gwidth = 800
		gheight = 600
		galias = 0
		gmode = 0
	EndTry
	
	AppTitle = "CounterPillow wins for all eternity."
	Print gmode
	Graphics3D gwidth, gheight, gdepth, gmode, ghertz
	SetBlend(AlphaBlend)
	AntiAlias(galias)
EndFunction