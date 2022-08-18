On Error Resume Next

Const ForReading = 1
Const ForAppending = 8
Set ws=createobject("wscript.shell")
Set FSO = CreateObject("Scripting.FileSystemObject")
Set environmentVars = WScript.CreateObject("WScript.Shell").Environment("Process")
tempFolder = environmentVars("TEMP")&"\clotho"	'��ʱ�ļ���
responseFolder = tempFolder & "\response\"		'������Ŀ¼
websocket = tempFolder & "\websocket"			'websocket�ļ�
logs = tempFolder & "\log"						'��־�ļ�
sysProtocol="https://"
sysHost="api.i996.me"
messageKey="ClothoMsg"
messageRequest="ClothoHTTPRequest"
dim websocketPid,requestPid,mainPid,keepalivePid
'��֤token
token=WScript.Arguments(0)
If Err.Number <> 0 Then 
	WSH.Echo "["&now&"] - "&"��ָ��Token����!(curl -s win.i996.me/token | cmd)"
	wscript.quit
end if
WSH.Echo "["&now&"] - "&"��֤Token��..."
'������´�����ʱ�ļ�
deleteTempFiles
createTempFiles

ctCode=checkToken(token)
If ctCode=2 Then
	WSH.Echo "["&now&"] - "&"��Ǹ,������������ʱ���˵�����!���Ժ��ٳ��ԡ�"
	wscript.quit
ElseIf ctCode = 1 Then
	WSH.Echo "["&now&"] - "&"Token��֤ʧ��!���ע""�ô���˹��""���ںŻ�ȡToken!(���)"
	wscript.quit
End If
WSH.Echo "["&now&"] - "&"Token��֤ͨ��,����׼����..."

mainPid = CurrProcessId()

WSH.Echo "["&now&"] - "&"������..."

WScript.sleep 500
'����websocket
Set exeRs = ws.Exec("cscript "&tempFolder&"\websocket.vbs")
' Set exeRs = ws.Exec("cscript websocket.vbs")
websocketPid = exeRs.ProcessID
WScript.sleep 2000
'����request
Set exeRs = ws.Exec("cscript "&tempFolder&"\request.vbs")
' Set exeRs = ws.Exec("cscript request.vbs")
requestPid = exeRs.ProcessID
'�����������
Set exeRs = ws.Exec("cscript "&tempFolder&"\keepAlive.vbs "&mainPid&" "&websocketPid&" "&requestPid)
' Set exeRs = ws.Exec("cscript keepAlive.vbs "&mainPid&" "&websocketPid&" "&requestPid)
keepalivePid = exeRs.ProcessID
WScript.sleep 1000

'WSH.Echo mainPid&" "&websocketPid&" "&requestPid&" "&keepalivePid


If checkActive() Then
	WSH.Echo "["&now&"] - "&"������͸�����ɹ���!"
	Set logFile = FSO.OpenTextFile(logs, ForReading)
	Do 
		If logFile.AtEndOfStream = 0 Then
			Do While logFile.AtEndOfStream = 0
				strComputer = logFile.ReadLine()
				WSH.Echo strComputer
			Loop
		End If
		WScript.sleep 100
	Loop
Else
	WSH.Echo "["&now&"] - "&"����ʧ�ܣ�������"
End If

killProcess
WScript.sleep 1000
deleteTempFiles

'ɱ�����н���
Sub killProcess ()
	cmd = "cmd /c taskkill /t /f /pid "&websocketPid&" /pid "&requestPid&" /pid "&keepalivePid
  	Set exeRs = ws.Exec(cmd)
End Sub

' ���״̬
Function checkActive ()
	cmd = "cmd /c tasklist /fi ""imagename eq cscript.exe"" /fo list | findstr /i ""pid"""
	Set exeRs = ws.Exec(cmd)
	stdMsg = exeRs.StdOut.ReadAll()
	If InStr(stdMsg,websocketPid)>0 and InStr(stdMsg,requestPid)>0 and InStr(stdMsg,keepalivePid)>0 Then
		checkActive = true
	Else
		checkActive = false
	End If
End Function

'��ȡ��ǰ����pid
Function CurrProcessId()
    Dim oShell, sCmd, oWMI, oChldPrcs, oCols, lOut
    lOut = 0
    Set oShell  = CreateObject("WScript.Shell")
    Set oWMI    = GetObject(_
        "winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
    sCmd = "/K " & Left(CreateObject("Scriptlet.TypeLib").Guid, 38)
    oShell.Run "%comspec% " & sCmd, 0
    
    Set oChldPrcs = oWMI.ExecQuery("Select * From Win32_Process Where CommandLine Like '%" & sCmd & "'",,32)
    For Each oCols In oChldPrcs
        lOut = oCols.ParentProcessId
        oCols.Terminate
        Exit For
    Next
    CurrProcessId = lOut
End Function

' ���token�Ϸ��� ��ȷ����0
function checkToken(token)
	cmd = "curl -s --http1.1 -X POST "&sysProtocol&sysHost&"/sys-auth -H ""Authorization: "&token&""""
	Set exeRs = ws.Exec(cmd)
	stdMsg = exeRs.StdOut.ReadAll()
	If stdMsg = "" Then
		checkToken = 2
		exit Function
	End If
	message_broadcast="ClothoBroadcast"
	If instr(stdMsg,message_broadcast) = 0 Then
		checkToken = 1
		exit Function
	End If
	dim tmpstr,onlineUrl,localUrl
	tmpstr = right(stdMsg,len(stdMsg)-len(message_broadcast))
	onlineUrl = mid(tmpstr,1,instr(tmpstr,"|")-1)
	localUrl = mid(tmpstr,instr(tmpstr,"|")+1)
	Set logAppend = FSO.OpenTextFile(logs, ForAppending)
	logAppend.WriteLine("["&now&"] - "&"������ַ  : ===> https://"&onlineUrl)
	logAppend.WriteLine("["&now&"] - "&"..               http://"&onlineUrl)
	logAppend.WriteLine("["&now&"] - "&"������ַ  : ===> "&localUrl)
	logAppend.Close

	checkToken = 0
end function

'ɾ��������ʱ�ļ�'
Sub deleteTempFiles ()
	FSO.DeleteFolder tempFolder,true
End Sub

'���������ļ�'
Sub createTempFiles ()
	'������ʱ�ļ���'
	If not FSO.FolderExists(tempFolder) Then
	    FSO.CreateFolder(tempFolder)
	End If
	'����websocket�ļ�
	If not FSO.FileExists(websocket) Then
		FSO.CreateTextFile(websocket)
	End If
	'����log�ļ�
	If not FSO.FileExists(logs) Then
		FSO.CreateTextFile(logs)
	End If
	'����responseĿ¼
	If not FSO.FolderExists(responseFolder) Then
	    FSO.CreateFolder(responseFolder)
	End If
	'����websocket�ű�
	If not FSO.FileExists(tempFolder&"\websocket.vbs") Then
		FSO.CreateTextFile(tempFolder&"\websocket.vbs")
		Set vbsFile = FSO.OpenTextFile(tempFolder&"\websocket.vbs", ForAppending,true)
		vbsFile.WriteLine("On Error Resume Next")
		vbsFile.WriteLine("")
		vbsFile.WriteLine("Set ws=createobject(""wscript.shell"")")
		vbsFile.WriteLine("")
		vbsFile.WriteLine("curlPid = 99999")
		vbsFile.WriteLine("Do")
		vbsFile.WriteLine("	If not checkActive() Then")
		vbsFile.WriteLine("		cmd = ""curl -s --no-buffer --http1.1 -H """"Authorization: "&token&""""" -H """"Connection: keep-alive, Upgrade"""" -H """"Upgrade: websocket"""" -v -H """"Sec-WebSocket-Version: 13"""" -H """"Sec-WebSocket-Key: websocket"""" "&sysProtocol& sysHost&"/sys-ws ws -o "&websocket&"""")
		vbsFile.WriteLine("		Set exeRs = ws.Exec(cmd)")
		vbsFile.WriteLine("		curlPid = exeRs.ProcessID")
		vbsFile.WriteLine("	End If")
		vbsFile.WriteLine("	WScript.sleep 1000")
		vbsFile.WriteLine("Loop")
		vbsFile.WriteLine("Function checkActive ()")
		vbsFile.WriteLine("	checkCmd = ""cmd /c tasklist /fi """"imagename eq curl.exe"""" /fo list | findstr /i """"pid""""""")
		vbsFile.WriteLine("	Set exeRs = ws.Exec(checkCmd)")
		vbsFile.WriteLine("	stdMsg = exeRs.StdOut.ReadAll()")
		vbsFile.WriteLine("	If InStr(stdMsg,curlPid)>0 Then")
		vbsFile.WriteLine("		checkActive = true")
		vbsFile.WriteLine("	Else")
		vbsFile.WriteLine("		checkActive = false")
		vbsFile.WriteLine("	End If")
		vbsFile.WriteLine("End Function")
		vbsFile.Close
	End If
	'����response�ű�
	If not FSO.FileExists(tempFolder&"\response.vbs") Then
		FSO.CreateTextFile(tempFolder&"\response.vbs")
		Set vbsFile = FSO.OpenTextFile(tempFolder&"\response.vbs", ForAppending,true)
		vbsFile.WriteLine("On Error Resume Next")
		vbsFile.WriteLine("")
		vbsFile.WriteLine("Set FSO = CreateObject(""Scripting.FileSystemObject"")")
		vbsFile.WriteLine("Set ws=createobject(""wscript.shell"")")
		vbsFile.WriteLine("")

		vbsFile.WriteLine("Base64Url=WScript.Arguments(0)")
		vbsFile.WriteLine("url = jiemac(Base64Url)")
		vbsFile.WriteLine("url = replace(url,"""""""","""")")
		vbsFile.WriteLine("url = replace(url,""'"","""""""")")
		vbsFile.WriteLine("messageId = Mid(url,InStr(url,"""&messageKey&""")+Len("""&messageKey&""")+1) ")
		vbsFile.WriteLine("messageId = Trim(Mid(messageId,1,InStr(messageId,"""""""")-1))")
		vbsFile.WriteLine("localUrl = Left(url,len(url)-1)")
		vbsFile.WriteLine("localUrl = Mid(localUrl,InStrRev(localUrl,"""""""")+1)")
		vbsFile.WriteLine("reqTimer = timer")
		vbsFile.WriteLine("url = url & "" -o "&responseFolder&""" &messageId")
		vbsFile.WriteLine("Set logAppend = FSO.OpenTextFile("""&logs&""", "&ForAppending&")")
		vbsFile.WriteLine("logAppend.WriteLine(""[""&now&""] - ***""&right(messageId,6)&"" : ===> ""&localUrl)")
		vbsFile.WriteLine("Set exeRs = ws.Exec(url)")
		vbsFile.WriteLine("exeRs.StdOut.ReadAll()")
		vbsFile.WriteLine("cmd = ""curl -X POST --http1.1 -v "&sysProtocol&sysHost&"/sys-callback -H """"Authorization: "&token&""""" -H """"ClothoMsg: ""&messageId&"""""" --data-binary """"@"&responseFolder&"""&messageId&""""""""")
		vbsFile.WriteLine("Set exeRs = ws.Exec(cmd)")
		vbsFile.WriteLine("logAppend.WriteLine(""[""&now&""] - ***""&right(messageId,6)&"" : <=== ��ʱ ""&Round((timer-reqTimer)*1000)&""ms"")")
		vbsFile.WriteLine("logAppend.Close")
		vbsFile.WriteLine("stdMsg = exeRs.StdOut.ReadAll()")
		vbsFile.WriteLine("FSO.DeleteFile("""&responseFolder&"""&messageId)")
		vbsFile.WriteLine("")
		vbsFile.WriteLine("Function jiemac(ByVal jiemaString)")
		vbsFile.WriteLine("  Const jiema = ""ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/""")
		vbsFile.WriteLine("  Dim dataLength, sOut, groupBegin")
		vbsFile.WriteLine("  jiemaString = Replace(jiemaString, vbCrLf, """")")
		vbsFile.WriteLine("  jiemaString = Replace(jiemaString, vbTab, """")")
		vbsFile.WriteLine("  jiemaString = Replace(jiemaString, "" "", """")")
		vbsFile.WriteLine("  dataLength = Len(jiemaString)")
		vbsFile.WriteLine("  If dataLength Mod 4 <> 0 Then")
		vbsFile.WriteLine("    Err.Raise 1, ""jiemaDecode"", ""Bad jiema string.""")
		vbsFile.WriteLine("    Exit Function")
		vbsFile.WriteLine("  End If")
		vbsFile.WriteLine("  For groupBegin = 1 To dataLength Step 4")
		vbsFile.WriteLine("    Dim numDataBytes, CharCounter, thisChar, thisData, nGroup, pOut")
		vbsFile.WriteLine("    numDataBytes = 3")
		vbsFile.WriteLine("    nGroup = 0")
		vbsFile.WriteLine("    For CharCounter = 0 To 3")
		vbsFile.WriteLine("      thisChar = Mid(jiemaString, groupBegin + CharCounter, 1)")
		vbsFile.WriteLine("      If thisChar = ""="" Then")
		vbsFile.WriteLine("        numDataBytes = numDataBytes - 1")
		vbsFile.WriteLine("        thisData = 0")
		vbsFile.WriteLine("      Else")
		vbsFile.WriteLine("        thisData = InStr(1, jiema, thisChar, vbBinaryCompare) - 1")
		vbsFile.WriteLine("      End If")
		vbsFile.WriteLine("      If thisData = -1 Then")
		vbsFile.WriteLine("        Err.Raise 2, ""jiemaDecode"", ""Bad character In jiema string.""")
		vbsFile.WriteLine("        Exit Function")
		vbsFile.WriteLine("      End If")
		vbsFile.WriteLine("      nGroup = 64 * nGroup + thisData")
		vbsFile.WriteLine("    Next")
		vbsFile.WriteLine("    nGroup = Hex(nGroup)")
		vbsFile.WriteLine("    nGroup = String(6 - Len(nGroup), ""0"") & nGroup")
		vbsFile.WriteLine("    pOut = Chr(CByte(""&H"" & Mid(nGroup, 1, 2))) + _")
		vbsFile.WriteLine("      Chr(CByte(""&H"" & Mid(nGroup, 3, 2))) + _")
		vbsFile.WriteLine("      Chr(CByte(""&H"" & Mid(nGroup, 5, 2)))")
		vbsFile.WriteLine("    sOut = sOut & Left(pOut, numDataBytes)")
		vbsFile.WriteLine("  Next")
		vbsFile.WriteLine("  jiemac = sOut")
		vbsFile.WriteLine("End Function")
		vbsFile.Close
	End If
	'����request�ű�
	If not FSO.FileExists(tempFolder&"\request.vbs") Then
		FSO.CreateTextFile(tempFolder&"\request.vbs")
		Set vbsFile = FSO.OpenTextFile(tempFolder&"\request.vbs", ForAppending,true)
		vbsFile.WriteLine("On Error Resume Next")
		vbsFile.WriteLine("Set FSO = CreateObject(""Scripting.FileSystemObject"")")
		vbsFile.WriteLine("Set ws=createobject(""wscript.shell"")")
		vbsFile.WriteLine("")
		vbsFile.WriteLine("Set websocketFile = FSO.OpenTextFile("""&websocket&""", "&ForReading&")")
		vbsFile.WriteLine("Do ")
		vbsFile.WriteLine("	If websocketFile.AtEndOfStream = 0 Then")
		vbsFile.WriteLine("		Do While websocketFile.AtEndOfStream = 0")
		vbsFile.WriteLine("			strComputer = websocketFile.ReadLine()")
		vbsFile.WriteLine("			Base64Url = replace(strComputer,"""&messageRequest&""","""")")
		vbsFile.WriteLine("	    	ws.Exec(""cscript "&tempFolder&"\response.vbs ""&Base64Url)")
		vbsFile.WriteLine("		Loop")
		vbsFile.WriteLine("	End If")
		vbsFile.WriteLine("	WScript.sleep 100")
		vbsFile.WriteLine("Loop")
		vbsFile.WriteLine("websocketFile.Close")
		vbsFile.Close
	End If
	'����keepalive�ű�
	If not FSO.FileExists(tempFolder&"\keepAlive.vbs") Then
		FSO.CreateTextFile(tempFolder&"\keepAlive.vbs")
		Set vbsFile = FSO.OpenTextFile(tempFolder&"\keepAlive.vbs", ForAppending,true)
		vbsFile.WriteLine("On Error Resume Next")
		vbsFile.WriteLine("")
		vbsFile.WriteLine("Set FSO = CreateObject(""Scripting.FileSystemObject"")")
		vbsFile.WriteLine("Set ws=createobject(""wscript.shell"")")
		vbsFile.WriteLine("dim websocketPid,requestPid,mainPid")
		vbsFile.WriteLine("mainPid=WScript.Arguments(0)")
		vbsFile.WriteLine("websocketPid=WScript.Arguments(1)")
		vbsFile.WriteLine("requestPid=WScript.Arguments(2)")
		vbsFile.WriteLine("")
		vbsFile.WriteLine("Do")
		vbsFile.WriteLine("  WScript.sleep 2000")
		vbsFile.WriteLine("  stat = checkActive()")
		vbsFile.WriteLine("  If stat = 2 Then")
		vbsFile.WriteLine("    Exit Do")
		vbsFile.WriteLine("  ElseIf stat = 1 Then")
		vbsFile.WriteLine("    Set logAppend = FSO.OpenTextFile("""&logs&""", "&ForAppending&")")
		vbsFile.WriteLine("    logAppend.WriteLine(""[""&now&""] - ""&""�����쳣��������������"")")
		vbsFile.WriteLine("    logAppend.Close")
		vbsFile.WriteLine("    ")
		vbsFile.WriteLine("    killProcess")
		vbsFile.WriteLine("    WScript.sleep 500")
		vbsFile.WriteLine("    Set exeRs = ws.Exec(""cscript websocket.vbs"")")
		vbsFile.WriteLine("    websocketPid = exeRs.ProcessID")
		vbsFile.WriteLine("    WScript.sleep 2000")
		vbsFile.WriteLine("    Set exeRs = ws.Exec(""cscript request.vbs"")")
		vbsFile.WriteLine("    requestPid = exeRs.ProcessID")
		vbsFile.WriteLine("")
		vbsFile.WriteLine("    stat = checkActive()")
		vbsFile.WriteLine("    If stat = 0 Then")
		vbsFile.WriteLine("      Set logAppend = FSO.OpenTextFile("""&logs&""", "&ForAppending&")")
		vbsFile.WriteLine("      logAppend.WriteLine(""[""&now&""] - ""&""���������ɹ�"")")
		vbsFile.WriteLine("      logAppend.Close")
		vbsFile.WriteLine("    End If")
		vbsFile.WriteLine("  End If")
		vbsFile.WriteLine("Loop")
		vbsFile.WriteLine("")
		vbsFile.WriteLine("")
		vbsFile.WriteLine("killProcess")
		vbsFile.WriteLine("WScript.sleep 1000")
		vbsFile.WriteLine("deleteTempFiles")
		vbsFile.WriteLine("")
		vbsFile.WriteLine("Function checkActive ()")
		vbsFile.WriteLine("  cmd = ""cmd /c tasklist /fi """"imagename eq cscript.exe"""" /fo list | findstr /i """"pid""""""")
		vbsFile.WriteLine("  Set exeRs = ws.Exec(cmd)")
		vbsFile.WriteLine("  stdMsg = exeRs.StdOut.ReadAll()")
		vbsFile.WriteLine("  If InStr(stdMsg,mainPid)=0 Then")
		vbsFile.WriteLine("    checkActive = 2")
		vbsFile.WriteLine("  ElseIf InStr(stdMsg,websocketPid)=0 or InStr(stdMsg,requestPid)=0 Then")
		vbsFile.WriteLine("    checkActive = 1")
		vbsFile.WriteLine("  Else")
		vbsFile.WriteLine("    checkActive = 0")
		vbsFile.WriteLine("  End If")
		vbsFile.WriteLine("End Function")
		vbsFile.WriteLine("")
		vbsFile.WriteLine("Sub killProcess ()")
		vbsFile.WriteLine("  cmd = ""cmd /c taskkill /t /f /pid ""&websocketPid&"" /pid ""&requestPid")
		vbsFile.WriteLine("  Set exeRs = ws.Exec(cmd)")
		vbsFile.WriteLine("End Sub")
		vbsFile.WriteLine("")
		vbsFile.WriteLine("Sub createTempFiles ()")
		vbsFile.WriteLine("  If not FSO.FolderExists("""&tempFolder&""") Then")
		vbsFile.WriteLine("    FSO.CreateFolder("""&tempFolder&""")")
		vbsFile.WriteLine("  End If")
		vbsFile.WriteLine("  If not FSO.FileExists("""&websocket&""") Then")
		vbsFile.WriteLine("    FSO.CreateTextFile("""&websocket&""")")
		vbsFile.WriteLine("  End If")
		vbsFile.WriteLine("  If not FSO.FileExists("""&logs&""") Then")
		vbsFile.WriteLine("    FSO.CreateTextFile("""&logs&""")")
		vbsFile.WriteLine("  End If")
		vbsFile.WriteLine("  If not FSO.FolderExists("""&responseFolder&""") Then")
		vbsFile.WriteLine("    FSO.CreateFolder("""&responseFolder&""")")
		vbsFile.WriteLine("  End If")
		vbsFile.WriteLine("End Sub")
		vbsFile.WriteLine("Sub deleteTempFiles ()")
		vbsFile.WriteLine("  FSO.DeleteFolder """&responseFolder&""",true")
		vbsFile.WriteLine("End Sub")
		vbsFile.Close
	End If
End Sub
