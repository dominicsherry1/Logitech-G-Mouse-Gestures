function OnEvent(event, arg)
	if event == "MOUSE_BUTTON_PRESSED" and arg > 3 and arg < 14 then
		k = "f"..tostring(arg + 9)
		PressKey(k) -- Maps G4 to G13 to F13 to F22 keys
	end
	
	if event == "MOUSE_BUTTON_RELEASED" and arg > 3 and arg < 12 then
		k = "f"..tostring(arg + 9)	
		ReleaseKey(k) -- Maps G4 to G13 to F13 to F22 keys
	end
end