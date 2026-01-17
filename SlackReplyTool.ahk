#Requires AutoHotkey v2.0
; Slack Reply Tool
; Made by LewdLeah on January 17, 2026
linkTimestamp := 0
rememberedLink := ""
TIMEOUT_SECONDS := 60
; Clipboard change handler
ClipChanged(Type) {
    global rememberedLink, linkTimestamp
    if ((Type != 1) || !ClipWait(0.1)) {
        return
    }
    clipboardContent := A_Clipboard
    ; Check if the clipboard contains a message link
    if (RegExMatch(clipboardContent, "i)^https://[^/]+\.slack\.com/archives/[A-Z0-9]+/p[0-9]+")) {
        rememberedLink := clipboardContent
        linkTimestamp := A_TickCount
        ToolTip("⮎ Link copied")
        SetTimer(() => ToolTip(), -1500)
    } else if (rememberedLink != "") {
        ; Text copied with a remembered link (paste will be formatted)
        ToolTip("⮎ Quote ready")
        SetTimer(() => ToolTip(), -1500)
    }
    return
}
OnClipboardChange(ClipChanged)
; Timeout check
CheckTimeout() {
    global rememberedLink, linkTimestamp, TIMEOUT_SECONDS
    if (
		(rememberedLink != "")
		&& (linkTimestamp != 0)
		&& (TIMEOUT_SECONDS <= ((A_TickCount - linkTimestamp) / 1000))
	) {
        rememberedLink := ""
        linkTimestamp := 0
        TrayTip("Slack Reply Tool", "Message link expired! (60s timeout)", 500)
    }
	return
}
SetTimer(CheckTimeout, 1000)
; Format and paste if there's a remembered link
$^v:: {
    global rememberedLink, linkTimestamp
    if (rememberedLink == "") {
        Send("^v")
        return
    }
    ; Format the clipboard content at paste time
    clipboardContent := A_Clipboard
    ; Don't reformat if already formatted or a message link
    if (
		InStr(clipboardContent, "> *[⮎ Reply](")
		|| RegExMatch(clipboardContent, "i)^https://[^/]+\.slack\.com/archives/")
	) {
        Send("^v")
        return
    }
    linkTimestamp := 0
    ; Quote each line
    lines := StrSplit(clipboardContent, "`n", "`r")
    quotedLines := ""
    for index, line in lines {
        quotedLines .= "> " . line . "`n"
    }
    ; Build formatted output and put in clipboard
    A_Clipboard := "> *[⮎ Reply](" . rememberedLink . ")*`n" . quotedLines . "`n"
	rememberedLink := ""
    ClipWait(1)
    ; Paste using Shift+Insert (avoids triggering the ^v hotkey)
    Send("+{Insert}")
	return
}
