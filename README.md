# Logitech G Mouse Gestures
 An AutoHotKey script for performing actions based on mouse gestures combined with the side buttons on Logitech mice.
 Version 1.0

## Preamble
 The AutoHotKey code used here is incomplete, but functional. Excuse the terrible coding style.

## Purpose
 The scripting API Logitech builds into G Hub is limited in terms of its functionality. For example, there is no way to determine the state of the side buttons inside a loop.

This script is written to maximise the functionality of the extra buttons on Logitech G mice. Instead of using the default scripting language (Lua) which is built into the Logitech G Hub tool I am using [AutoHotKey](https://www.autohotkey.com) as the main scripting language.

This script is designed for use in Windows in combination with Logitech's G Hub software. In the future I may attempt to make the script work with other Operating Systems.

Since there is no way for AutoHotKey to interface with the side buttons on Logitech G mice, I'm first using a Lua script within the [Logitech G Hub](https://support.logi.com/hc/articles/360025298133) software to map the side buttons to the F13 to F22 function keys. These keys are most likely not present on your keyboard, but nevertheless AutoHotKey can see them.

## Mappings
 The mappings are as follows:

|Logitech mouse button|Function Key|
|---|---|
|G4|F13|
|G5|F14|
|G6|F15|
|G7|F16|
|G8|F17|
|G9|F18|
|DPI - button|F19|
|DPI + button|F20|
|Left scroll button|F21|
|Right scroll button|F22|

## Setup
 I recommend disabling all profiles except the default one within the Logitech G Hub software, so that the script which maps the side buttons to the keyboard function keys always remains active, no matter which application you are using.

I also recommend compiling the script `mouse_functions.ahk` using AutoHotKey and creating a shortcut to the resulting `mouse_functions.exe` file in the start menu folder within Windows.

In order to map the extra Logitech mouse buttons to the function keys as described, within Logitech G Hub, under the default profile click on the scripting button, create a new script, paste the following code snippet into the script, and save it.

```lua

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

```


## Gestures:
 There are a number of ways mouse button interactions can be combined with mouse movements to trigger actions. Each method has false positives which need to be counteracted.

1. Button press.
 False positives are counteracted by ensuring the button presses are sufficiently short in duration (not exceeding `g_btn_dur_thresh`) and there is no significant mouse movement which occurs during the button press (mouse movement threshold variables `g_m[x/y]_thresh` are not exceeded)

2. Flick. Sudden mouse movement in a specific direction.
 False positives are avoided by ensuring a filter is employed when measuring the differential mouse movements, a flick threshold is met, and the direction of movement is unambiguous (close enough to a specific direction so as not to be confused with movement in a different direction).

3. Slide. Sustained mouse movement in a specific direction.
 False positives are avoided by ensuring there are no significant mouse movements in the orthogonal direction

> 2 types of sliding gesture - quantised and continuous. Quantised sliding gestures repeatedly trigger an action every time mouse movements exceed a certain distance. Continuous sliding gestures always trigger an action, but the action taken depends on the speed of the mouse movement.
 E.g. for brightness or volume control, continuous sliding gestures are a good fit since the amount of change can depend on the mouse velocity. For switching between tabs quantised sliding gestures are a better fit since the number of tabs switched is quantised.

There are some gestures already configured in this script.

<table>
	<thead>
	<tr>
		<th>Mouse Button</th>
		<th>Purpose</th>
		<th>Modifier Key</th>
		<th>Gesture</th>
		<th>Action</th>
	</tr>
	</thead>
	<tbody>
	<tr>
		<td rowspan=9>G4</td>
		<td rowspan=9>Desktop Management</td>
		<td rowspan=3>LCtrl</td>
		<td>Flick Right</td>
		<td>Switch to left desktop</td>
	</tr>
	<tr>
		<td>Flick Left</td>
		<td>Switch to right desktop</td>
	</tr>
	<tr>
		<td>Button Press</td>
		<td>Toggle task view</td>
	</tr>
	<tr>
		<td rowspan=5>LShift</td>
		<td>Flick Left</td>
		<td>Show / hide quick actions bar</td>
	</tr>
	<tr>
		<td>Flick Right</td>
		<td>Show / hide start menu</td>
	</tr>
	<tr>
		<td>Flick Up</td>
		<td>Maximise highlighted window</td>
	</tr>
	<tr>
		<td>Flick Down</td>
		<td>Restore highlighted window</td>
	</tr>
	<tr>
		<td>Button Press</td>
		<td>Toggle always on top mode for highlighted window</td>
	</tr>
	<tr>
		<td>None</td>
		<td>Slide in any direction</td>
		<td>Navigate multitasking view</td>
	</tr>
	<tr>
		<td rowspan=4>G5</td>
		<td rowspan=4>Tab Management</td>
		<td rowspan=2>LShift</td>
		<td>Slide Right</td>
		<td>Move tab right</td>
	</tr>
	<tr>
		<td>Slide Left</td>
		<td>Move tab left</td>
	</tr>
	<tr>
		<td rowspan=2>None</td>
		<td>Slide Right</td>
		<td>Switch to right tab</td>
	</tr>
	<tr>
		<td>Slide Left</td>
		<td>Switch to left tab</td>
	</tr>
	<tr>
		<td rowspan=5>G8</td>
		<td rowspan=5>Media Management</td>
		<td rowspan=5>None</td>
		<td>Flick Right</td>
		<td>Next Track</td>
	</tr>
	<tr>
		<td>Flick Left</td>
		<td>Previous Track</td>
	</tr>
	<tr>
		<td>Slide Up</td>
		<td>Volume Up</td>
	</tr>
	<tr>
		<td>Slide Down</td>
		<td>Volume Down</td>
	</tr>
	<tr>
		<td>Button Press</td>
		<td>Play / Pause</td>
	</tr>
	</tbody>
</table>


## Parameters
 There are some parameters which can be fine tuned for each individual user.

|Global variable|Description|
|---|---|
|g_btn_dur_thresh|Maximum time in ms for button press to register|
|g_m_sample_rate|Time in ms between mouse position samples|
|g_move_thresh|Number of pixels moved between mouse position samples needed to unregister a button press gesture|
|g_flick_thresh|Minimum number of pixels moved between mouse position samples needed to register a flick gesture. The movement must be sustained for a period of time determined by the mouse movement filter aggression parameter `g_filter_aggression`|
|g_slide_sens|Continuous sliding gesture sensitivity - higher is more sensitive. A small value (<1) is recommended. A negative number inverts the sliding gesture direction|
|g_mx_rollover_thresh / g_my_rollover_thresh|The number of pixels moved by the mouse until each new action is performed during a quantised sliding gesture. Reducing this number increases the number of actions trigger over a given distance. A negative number inverts the direction of sliding gestures. `g_mx_rollover_thresh` adjusts the sensitivity of left / right movements. `g_my_rollover_thresh` adjusts the sensitivity of up / down movements.|
|g_filter_aggression|Mouse movement filter aggression parameter. Parameter should be between 0 and 1. Higher values mean more aggressive smoothing and higher latency in registering changes in mouse movement speed. A value of zero effectively disables the filter.|

## Emergency Exit
 To quit the AutoHotKey script at any time, use the keyboard combo `LCtrl-LShift-LWin-X`.