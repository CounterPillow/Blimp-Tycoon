Import BRL.Event

Type TGUIGadget
	Field x:Int
	Field y:Int
	Field width:Int
	Field height:Int
	
	Field enabled:Int
	
	Field parent:TGUIGadget
EndType

Type TGUIWindow Extends TGUIGadget
	Field title:String
EndType

Type TGUIText Extends TGUIGadget
	Field value:String
EndType

Type TGUIButton Extends TGUIGadget
	Const SPECIAL_HOVER:Int = 1
	Const SPECIAL_PRESSED:Int = 2
	Const SPECIAL_LOCKED:Int = 3
	
	Field caption:String
	Field special:Int	' 1 for hover, 2 for press, 3 for deactivated
	
	Method Update()
		If Self.enabled
			If PointInRect( gui_mx, gui_my, Self.x, Self.y, Self.width, Self.height )
				Self.special = SPECIAL_HOVER
				If md[0] Then
					Self.special = SPECIAL_PRESSED
					Self.SendEvent(EVENT_FGUI_BUTTON_PRESSED)
				EndIf
				If mh[0] Then
					Self.SendEvent(EVENT_FGUI_BUTTON_RELEASED)
				EndIf
			Else
				Self.special = 0
			EndIf
		EndIf
	EndMethod
	
	Method SendEvent( id:Int )
		Local e:TEvent = CreateEvent( id, Object(Self) )
		EmitEvent(e)
	EndMethod
	
	Method Draw()	' placeholder
		Select Self.special
			Case SPECIAL_HOVER
				SetColor(230, 230, 230)
			Case SPECIAL_PRESSED
				SetColor(150, 150, 150)
			Case SPECIAL_LOCKED
				SetColor(100, 100, 100)
			Default
				SetColor(200, 200, 200)
		EndSelect
		DrawRect(Self.x, Self.y, Self.width, Self.height)
		SetColor(255, 255, 255)
	EndMethod
EndType

Global EVENT_FGUI_BUTTON_PRESSED:Int = AllocUserEventId("ButtonPressed")
Global EVENT_FGUI_BUTTON_RELEASED:Int = AllocUserEventId("ButtonReleased")

Global gui_mx:Int, gui_my:Int
Global gui_mh:Int[3]
Global gui_md:Int[3]

Function UpdateGUIInput( mx:Int, my:Int, mh:Int[3], md:Int[3] )
	gui_mx = mx
	gui_my = my
	gui_mh = mh
	gui_md = md
EndFunction

Function PointInRect:Int( x:Int, y:Int, rx:Int, ry:Int, w:Int, h:Int )
	If x > rx And x < rx + w And y > ry And y < ry + h Then Return True
EndFunction