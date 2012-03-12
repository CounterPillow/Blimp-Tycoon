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
		camheight = EntityY(Self.Camera)
		
		If mdr Then
			Local divisor:Float = Max((100.0 - Abs(camheight / 2.5)), 5.0)
			Self.xg :- mxs / divisor
			Self.zg :+ mys / divisor
		EndIf
		
		If mzs Then
			Self.yg :+ mzs * (camheight / 50.0)
		EndIf
		If Self.yg < 0 And camheight > 250 Then Self.yg = 0
		If Self.yg > 0 And camheight < 5 Then Self.yg = 0
	
		TranslateEntity( Camera,  Self.xg, 0, Self.zg)
		MoveEntity( Camera, 0, 0, Self.yg )
		
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

Type TProfitText
	Global List:TList = New TList
	
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
		TProfitText.List.AddLast(p)
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

Function CreateClooouuud:TEntity()
	Local CloudPlane:TMesh = CreateMesh()
	Local CloudSurf:TSurface = CreateSurface(CloudPlane)
	
	AddVertex(CloudSurf, -1, 0, -1, 0, 0)	'upper left
	AddVertex(CloudSurf, 1, 0, -1, 1, 0)	'upper right
	AddVertex(CloudSurf, -1, 0, 1, 0, 1)	'lower left
	AddVertex(CloudSurf, 1, 0, 1, 1, 1)		'lower right
	AddTriangle(CloudSurf, 2, 1, 0)	' lower left to upper right to upper left
	AddTriangle(CloudSurf, 1, 2, 3)	' upper right to lower left to lower right
	UpdateNormals(CloudPlane)
	
	ScaleMesh(CloudPlane, 100, 1, 100)
	
	Local CloudTexture:TTexture = LoadTexture("GFX/tex/clooouuud.png", 2)
	ScaleTexture CloudTexture, 0.5, 0.5
	EntityTexture(CloudPlane, CloudTexture)
	
	Return TEntity(CloudPlane)
EndFunction