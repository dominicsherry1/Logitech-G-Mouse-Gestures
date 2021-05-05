;; DOC

;; Gestures: There are a number of ways mouse button interactions can be combined with mouse movements to trigger actions. Each method has false positives which need to be counteracted.

;; 1. Button press.
;; False positives are counteracted by ensuring the button presses are sufficiently short in duration (not exceeding g_btn_dur_thresh) and there is no significant mouse movement which occurs during the button press (mouse movement threshold variables g_m[x/y]_thresh are not exceeded)

;; 2. Flick. Sudden mouse movement in a specific direction.
;; False positives are avoided by ensuring a filter is employed when measuring the differential mouse movements, a flick threshold is met, and the direction of movement is unambiguous (close enough to a specific direction so as not to be confused with movement in a different direction).

;; 3. Slide. Sustained mouse movement in a specific direction.
;; False positives are avoided by ensuring there are no significant mouse movements in the orthogonal direction
;; 2 types of sliding gesture - quantised and continuous. Quantised sliding gestures repeatedly trigger an action every time mouse movements exceed a certain distance. Continuous sliding gestures always trigger an action, but the action taken depends on the speed of the mouse movement.
; E.g. for brightness or volume control, continuous sliding gestures are a good fit since the amount of change can depend on the mouse velocity. For switching between tabs quantised sliding gestures are a better fit since the number of tabs switched is quantised.

;;

; TODO: Flick triggers action multiple times, should only trigger once. [FIXED]
; TODO: Volume slider does not move proprtionally to the speed of the mouse. [FIXED]
; TODO: FF/RW doesn't work.
; TODO: Always on top window doesn't update to the current window. [FIXED]
; TODO: Maximise / restore gestures are switched. [FIXED]
; TODO: Some gestures are accidentally triggered when another gesture is made. [FIXED]

; Script settings
#SingleInstance, force
SetTitleMatchMode 2
DetectHiddenWindows, On

; Globals

global g_mod_ctrl, g_mod_shift, g_mod_none, g_filter_aggression, g_move_thresh, g_btn_press_flg, g_btn_dur_thresh, g_flick_left, g_flick_right, g_flick_up, g_flick_down, g_flick_thresh, g_mx_threshold_flg, g_mx_rollover_thresh, g_mx_rollover_flg, g_my_threshold_flg, g_my_rollover_thresh, g_my_rollover_flg, g_direction, _directions, g_m_sample_rate, _move_thresh_flg, _btn_press_time, _m_sidebutton_state, _m_sidebutton_state_prev, _mx_diff, _my_diff, _mx_prev, _my_prev, _mx, _my, _mx_filter, _my_filter, _mx_rollover, _my_rollover, _flick_en, g_slide_x, g_slide_y, g_slide_sens

; Tunable parameters - adjust to tune gesture sensitivity
; Maximum time in ms for button press to register
g_btn_dur_thresh := 250

; Time in ms between mouse position samples
g_m_sample_rate := 20

; Number of pixels moved between mouse position samples needed to unregister a button press gesture
g_move_thresh := 2

; Minimum number of pixels moved between mouse position samples needed to register a flick gesture. The movement must be sustained for a period of time determined by the mouse movement filter aggression parameter g_filter_aggression
g_flick_thresh := 50

; Continuous sliding gesture sensitivity - higher is more sensitive. A small value (<1) is recommended. A negative number inverts the sliding gesture direction
g_slide_sens := 0.05

; The number of pixels moved by the mouse until each new action is performed during a quantised sliding gesture. Reducing this number increases the number of actions trigger over a given distance. A negative number inverts the direction of sliding gestures. g_mx_rollover_thresh adjusts the sensitivity of left / right movements. g_my_rollover_thresh adjusts the sensitivity of up / down movements.
g_mx_rollover_thresh := 200
g_my_rollover_thresh := 200

; Mouse movement filter aggression parameter. Parameter should be between 0 and 1. Higher values mean more aggressive smoothing and higher latency in registering changes in mouse movement speed. A value of zero effectively disables the filter.
g_filter_aggression := 0.1

; Modifier key states
g_mod_ctrl := 0
g_mod_shift := 0
g_mod_none := 0

; Flags
_move_thresh_flg := 0
g_btn_press_flg := 0
g_flick_flg := 0
g_mx_rollover_flg := 0
g_my_rollover_flg := 0
g_direction := 0

; Timer variable for measuring duration
_btn_press_time := 0

; Enable flick gesture. Only one flick action should be performed per button press, so after performing that action, the flick gesture should be disabled until the next button press
_flick_en := 0

; Distance between mouse sample positions, in pixels
_mx_diff := 0
_my_diff := 0

; Last saved mouse coordinates
_mx_prev := 0
_my_prev := 0

; Current mouse coordinates
_mx := 0
_my := 0

; Distance between mouse sample positions, in pixels, with smoothing applied
_mx_filter := 0
_my_filter := 0

; Accumulated mouse movement distance. Resets to zero after exceeding the rollover threshold value in either a positive or negative direction.
_mx_rollover := 0
_my_rollover := 0

; Functions
UpdateGestures() {

	; Modifier key states
	g_mod_ctrl := GetKeyState("Ctrl", "P")
	g_mod_shift := GetKeyState("Shift", "P")
	g_mod_none := !(g_mod_ctrl Or g_mod_shift)

	; Get mouse coordinates
	MouseGetPos, _mx, _my

	; ToolTip % _mx ", " _my ", " _mx_prev ", " _my_prev ", " _mx_diff ", " _my_diff ", " _mx_filter ", " _my_filter
	; Distance between mouse sample positions, in pixels
	_mx_diff := _mx - _mx_prev
	_my_diff := _my_prev - _my

	; Set previous mouse coordinates to current
	_mx_prev := _mx
	_my_prev := _my

	; Smoothing for differential movements
	_mx_filter := ((_mx_filter * g_filter_aggression) + (_mx_diff * (1.0 - g_filter_aggression)))
	_my_filter := ((_my_filter * g_filter_aggression) + (_my_diff * (1.0 - g_filter_aggression)))

	; Determine if movement threshold is exceeded
	_move_thresh_flg := ((Abs(_mx_diff) > g_move_thresh) Or (Abs(_my_diff) > g_move_thresh)) 

	; Gestures - Button press
	g_btn_press_flg := (!_move_thresh_flg And ((A_TickCount - _btn_press_time) < g_btn_dur_thresh))

	; Gestures - Flick
	g_flick_left := (_flick_en And (_mx_filter < (-5 * (Abs(_my_filter)))) And (Abs(_mx_filter) > g_flick_thresh))
	g_flick_right := (_flick_en And (_mx_filter > (5 * (Abs(_my_filter)))) And (Abs(_mx_filter) > g_flick_thresh))
	g_flick_up := (_flick_en And (_my_filter > (5 * (Abs(_mx_filter)))) And (Abs(_my_filter) > g_flick_thresh))
	g_flick_down := (_flick_en And (_my_filter < (-5 * (Abs(_mx_filter)))) And (Abs(_my_filter) > g_flick_thresh))
	; Disable flick gesture from triggering again after first action
	_flick_en := _flick_en And !(g_flick_left Or g_flick_right Or g_flick_up Or g_flick_down)
	
	; Gestures - Slide
	g_slide_x := ((Abs(_mx_filter) > (5 * (Abs(_my_filter)))) * _mx_diff)
	g_slide_y := ((Abs(_my_filter) > (5 * (Abs(_mx_filter)))) * _my_diff)

	; Rollover values for sliding gestures
	_mx_rollover += _mx_diff
	_my_rollover += _my_diff

	g_mx_rollover_flg := 0
	if (_mx_rollover >= g_mx_rollover_thresh) {
		g_mx_rollover_flg := 1
	} else if (_mx_rollover <= -g_mx_rollover_thresh) {
		g_mx_rollover_flg := -1
	}

	g_my_rollover_flg := 0
	if (_my_rollover >= g_my_rollover_thresh) {
		g_my_rollover_flg := 1
	} else if (_my_rollover <= -g_my_rollover_thresh) {
		g_my_rollover_flg := -1
	}

	_mx_rollover := Mod(_mx_rollover, g_mx_rollover_thresh)
	_my_rollover := Mod(_my_rollover, g_my_rollover_thresh)

}

SideButtonEntry() {
	; Set previous coordinates to current coordinates to prevent errors in filtered coordinates
	MouseGetPos, _mx_prev, _my_prev

	UpdateGestures()

	; Update button press time on rising edge
	_btn_press_time := A_TickCount

	; Enable flick gesture
	_flick_en := 1
}

; Gestures

; G4 button - Desktop Management
; No modifiers - Window switching
; Ctrl key - Desktop switching
; Shift key - Windows gesture shortcuts
*f13::

; Ctrl-Alt-Tab shortcut keeps multitasking view frame active after modifier keys are released
if g_mod_none {
	SendEvent ^!{Tab}
}

SideButtonEntry()
while GetKeyState("f13", "p") {

	UpdateGestures()
	
	if g_mod_ctrl {
		; Quick flick right - Switch to desktop on left
		;if (g_flick_flg And (g_direction == ObjRawGet(_directions, "RIGHT"))) {
		if g_flick_right {
			SendEvent ^#{Left}
		}
		; Quick flick left - Switch to desktop on right
		else if g_flick_left {
			SendEvent ^#{Right}
		}
	} else if g_mod_shift {
		; Quick flick right - Start menu
		if g_flick_right {
			SendEvent ^{Escape}
		}
		; Quick flick left - Quick actions bar
		else if g_flick_left {
			SendEvent #a
		}
		; Quick flick up - Maximise window
		else if g_flick_up {
			WinMaximize A
		}
		; Quick flick down - Restore window
		else if g_flick_down {
			WinRestore A
		}
	} else if g_mod_none {
		; No modifier key - Navigate multitasking view
		; Slide right
		if (g_mx_rollover_flg == 1) {
			SendEvent {Right}
		}
		; Slide left
		else if (g_mx_rollover_flg == -1) {
			SendEvent {Left}
		}
		; Slide up
		else if (g_my_rollover_flg == -1) {
			SendEvent {Up}
		}
		; Slide left
		else if (g_my_rollover_flg == 1) {
			SendEvent {Down}
		}
	}

	; Mouse sample rate (ms)
	Sleep g_m_sample_rate
}
Return

*f13 up::
; Ctrl and short press - Toggle task view
if (g_mod_ctrl And g_btn_press_flg) {
	SendEvent #{Tab}
}
; Shift and Short press - Toggle always-on-top mode for active window
else if (g_mod_shift And g_btn_press_flg) {
	Winset, Alwaysontop, -1, A
}
; Release key - Select highlighted window
else if (g_mod_none And WinActive("ahk_class MultitaskingViewFrame")) {
	SendEvent {Enter}
}
Return

; G5 button - Tab switching and moving
*f14::
SideButtonEntry()

while GetKeyState("f14", "P") {
	UpdateGestures()

	; Shift key held down - move tabs
	if g_mod_shift {
		; Tab to the right
		if (g_mx_rollover_flg == 1) {
			SendEvent ^+{PgDn}
		}
		; Tab to the left
		else if (g_mx_rollover_flg == -1) {
			SendEvent ^+{PgUp}
		}
	}

	; Shift key not held down - Switch tabs
	else {
		; Tab to the right
		if (g_mx_rollover_flg == 1) {
			SendEvent ^{PgDn}
		}
		; Tab to the left
		else if (g_mx_rollover_flg == -1) {
			SendEvent ^{PgUp}
		}	
	}

	; Mouse sample rate (ms)
	Sleep g_m_sample_rate
}
Return

; G6 button - Desk Lamp Adjustments
; Left / right for colour temperature
; Up / down for brightness
; Short press for on / off

; G8 button - Multimedia Controls
*f17::
SideButtonEntry()

while GetKeyState("f17", "P") {
	UpdateGestures()

	; Shift and slide left / right to rewind / fastforward
	if g_mod_shift {
		if (g_mx_rollover_flg == -1) {
			ControlSend, ahk_parent, +{Left}, ahk_class SpotifyMainWindow
			;ControlSend, , !{Left}, VLC
		} else if (g_mx_rollover_flg == 1) {
			ControlSend, ahk_parent, +{Right}, ahk_class SpotifyMainWindow
			;ControlSend, , !{Right}, VLC
		}
	}
	else {
		; Next track - Quick flick to the right
		if g_flick_right {
			SendEvent {Media_Next}
		}
		; Previous track - Quick flick to the left
		else if g_flick_left {
			SendEvent {Media_Prev}
		}
		; Adjust volume - slide up / down
		else {
			SoundSet, +(g_slide_sens * g_slide_y)
		}
	}

	; Sample mouse movements at 20ms
	Sleep g_m_sample_rate
}
Return

*f17 up::
; Play / Pause - Short button press - ignore if significant mouse movement or button held for more than 250ms
if g_btn_press_flg { 
	SendEvent {Media_Play_Pause}
}

Return

; Exit Script - Ctrl-Shift-Win-X
^+#x::ExitApp