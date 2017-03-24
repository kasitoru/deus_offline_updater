﻿InitNetwork()

; Список файлов, из которых состоит прошивка
Structure FirmwareFile
  File.s      ; Имя файла прошивки
  Required.b  ; Этот файл обязателен или нет
EndStructure
Global NewList FirmwareFiles.FirmwareFile()
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "md5sums.txt"          : FirmwareFiles()\Required = #False
; Casque
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "C01.txt"              : FirmwareFiles()\Required = #True
; Disques
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "004.txt"              : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "104.txt"              : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "104_7.txt"            : FirmwareFiles()\Required = #False ; V4 only
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "R_004.txt"            : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "R_104.txt"            : FirmwareFiles()\Required = #True
; Telecommande
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "Restaure20130108.txt" : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T01.txt"              : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T02.txt"              : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T03.txt"              : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T04.txt"              : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T05.txt"              : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T06.txt"              : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T07.txt"              : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T08.txt"              : FirmwareFiles()\Required = #False ; VIP
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T09.txt"              : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T15.txt"              : FirmwareFiles()\Required = #False ; V4 only
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T0A.txt"              : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T0B.txt"              : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T0C.txt"              : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T0D.txt"              : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T0E.txt"              : FirmwareFiles()\Required = #True
AddElement(FirmwareFiles()) : FirmwareFiles()\File = "T0F.txt"              : FirmwareFiles()\Required = #True

; Функция подсчета количества строк в файле
Procedure.l CountFileStrings(FileName.s)
  File.l = ReadFile(#PB_Any, FileName)
  If File
    Count.l = 0
    While Eof(File) = 0
      ReadString(File)
      Count + 1
    Wend
    CloseFile(File)
    ProcedureReturn Count
  Else
    ProcedureReturn -1
  EndIf
EndProcedure

; Процедура записи сообщения в лог файл
Procedure.l AddToLogFile(Message.s, DateTime.b=#True, NewLine.b=#True, Enable.b=#True)
  If Enable
    LogFile.l = OpenFile(#PB_Any, "updater.log", #PB_File_Append)
    If LogFile
      DateString$ = ""
      If DateTime
        Date.l = Date()
        Hour$ = LSet(Str(Hour(Date)), 2, "0")
        Minute$ = LSet(Str(Minute(Date)), 2, "0")
        Second$ = LSet(Str(Second(Date)), 2, "0")
        Day$ = LSet(Str(Day(Date)), 2, "0")
        Month$ = LSet(Str(Month(Date)), 2, "0")
        Year$ = LSet(Str(Year(Date)), 4)
        DateString$ = "["+Hour$+":"+Minute$+":"+Second$+" "+Day$+"/"+Month$+"/"+Year$+"]: "
      EndIf
      If NewLine
        WriteStringN(LogFile, DateString$+Message)
      Else
        WriteString(LogFile, DateString$+Message)
      EndIf
      CloseFile(LogFile)
      ProcedureReturn #True
    Else
      ProcedureReturn #False
    EndIf
  Else
    ProcedureReturn -1
  EndIf
EndProcedure

; Получаем версию программы
Global ProgramFilename$ = ProgramFilename()
Global CurrentUpdaterVersion$ = GetFileVersion(ProgramFilename$, #GFVI_FileVersion, #False)

; Читаем настройки из файла
Global system_debug.l = 0 ; Режим отладки
cache_updates.l = 1 ; Обновлять кеш с сервера
cache_hidden.l = 0  ; Загружать скрытые обновления
If OpenPreferences("config.cfg", #PB_Preference_GroupSeparator)
  PreferenceGroup("system")
  system_debug = ReadPreferenceLong("debug", system_debug)
  PreferenceGroup("cache")
  cache_updates = ReadPreferenceLong("updates", cache_updates)
  cache_hidden = ReadPreferenceLong("hidden", cache_hidden)
  ClosePreferences()
  AddToLogFile("Updater started (version "+CurrentUpdaterVersion$+").", #True, #True, system_debug)
Else
  AddToLogFile("Updater started (version "+CurrentUpdaterVersion$+").", #True, #True, system_debug)
  AddToLogFile("Can`t open config file! Will be used default settings.", #True, #True, system_debug)
  DisclaimerTitle$ = #NULL$ : DisclaimerText$ = #NULL$
  If GetUserLanguage()="Russian"
    DisclaimerTitle$ = "Внимание!"
    DisclaimerText$ + "Данная программа обновления НЕ ЯВЛЯЕТСЯ ОФИЦИАЛЬНОЙ и предназначена для использования исключительно в ознакомительных целях." + Chr(13)
    DisclaimerText$ + Chr(13)
    DisclaimerText$ + "Автор не несет ответственности за любой вред (материальный или моральный), причененный вам или третьим лицам, в результате использования данного программного обеспечения." + Chr(13)
    DisclaimerText$ + Chr(13)
    DisclaimerText$ + "Все действия вы производите на свой страх и риск!" + Chr(13)
  Else
    DisclaimerTitle$ = "Warning!"
    DisclaimerText$ + "This program update IS NOT OFFICIAL and is intended for use solely for informational purposes." + Chr(13)
    DisclaimerText$ + Chr(13)
    DisclaimerText$ + "The author is not responsible for any damage (material or moral) caused to you or third parties resulting from the use of this software." + Chr(13)
    DisclaimerText$ + Chr(13)
    DisclaimerText$ + "All the steps you are at your own risk!" + Chr(13)
  EndIf
  MessageRequester(DisclaimerTitle$, DisclaimerText$, #MB_ICONWARNING)
EndIf
AddToLogFile("Current settings:", #True, #True, system_debug)
AddToLogFile(LSet(#NULL$, 3, Chr(9))+"system_debug = "+Str(system_debug)+";", #False, #True, system_debug)
AddToLogFile(LSet(#NULL$, 3, Chr(9))+"cache_updates = "+Str(cache_updates)+";", #False, #True, system_debug)
AddToLogFile(LSet(#NULL$, 3, Chr(9))+"cache_hidden = "+Str(cache_hidden)+";", #False, #True, system_debug)

; Создаем дирректории
If FileSize("updates")=-1
  AddToLogFile("The directory "+Chr(34)+"updates"+Chr(34)+" does not exist! Create it... ", #True, #False, system_debug)
  If CreateDirectory("updates")
    AddToLogFile("DONE!", #False, #True, system_debug)
  Else
    AddToLogFile("ERROR!", #False, #True, system_debug)
  EndIf
EndIf
If FileSize("updates/cache_updates")=-1
  AddToLogFile("The directory "+Chr(34)+"updates/cache_updates"+Chr(34)+" does not exist! Create it... ", #True, #False, system_debug)
  If CreateDirectory("updates/cache_updates")
    AddToLogFile("DONE!", #False, #True, system_debug)
  Else
    AddToLogFile("ERROR!", #False, #True, system_debug)
  EndIf
EndIf
If FileSize("updates/cache_updates/DEUS_V4")=-1
  AddToLogFile("The directory "+Chr(34)+"updates/cache_updates/DEUS_V4"+Chr(34)+" does not exist! Create it... ", #True, #False, system_debug)
  If CreateDirectory("updates/cache_updates/DEUS_V4")
    AddToLogFile("DONE!", #False, #True, system_debug)
  Else
    AddToLogFile("ERROR!", #False, #True, system_debug)
  EndIf
EndIf

; Сравнивает два номера версий программ и возвращает True, если последняя новее
Procedure CompareProgramsVersions(CurrentVersion.s, LatestVersion.s)
  CVC.l = CountString(CurrentVersion, ".")
  LVC.l = CountString(LatestVersion, ".")
  If CVC>LVC : DVC.l = CVC : Else : DVC.l = LVC : EndIf
  For i=1 To DVC+1
    CVF$ = StringField(CurrentVersion, i, ".")
    LVF$ = StringField(LatestVersion, i, ".")
    If Val(LVF$)>Val(CVF$)
      ProcedureReturn #True
    ElseIf Val(LVF$)<Val(CVF$)
      ProcedureReturn #False
    EndIf
  Next i
  ProcedureReturn #False
EndProcedure

; Обновление программы и прошивок
Global VersionsFileName$ = "4_0_01" ;- FIXME: определить алгоритм формирования имени файла
Global UpdateSuccess.b = #False
Procedure CheckForNewUpdates(hidden)
  ; Обновление самой программы
  AddToLogFile("Checking the program update...", #True, #True, system_debug)
  ; Получаем информацию о последней версии
  AddToLogFile("Download file "+Chr(34)+"http://deus.lipkop.club/Update/dou.php"+Chr(34)+"... ", #True, #False, system_debug)
  LastUpdaterVersion$ = CurrentUpdaterVersion$
  If ReceiveHTTPFile("http://deus.lipkop.club/Update/dou.php", "updates/dou.txt")
    AddToLogFile("DONE!", #False, #True, system_debug)
    AddToLogFile("Read last program version from file "+Chr(34)+"updates/dou.txt"+Chr(34)+"... ", #True, #False, system_debug)
    If ReadFile(0, "updates/dou.txt")
      LastUpdaterVersion$ = #NULL$
      AddToLogFile("DONE!", #False, #True, system_debug)
      While Eof(0) = 0
        LastUpdaterVersion$ + ReadString(0)
      Wend
      LastUpdaterVersion$ = Trim(LastUpdaterVersion$)
      CloseFile(0)
    Else
      AddToLogFile("ERROR!", #False, #True, system_debug)
    EndIf
  Else
    AddToLogFile("ERROR!", #False, #True, system_debug)
  EndIf
  ; Если есть новая версия программы
  If CompareProgramsVersions(CurrentUpdaterVersion$, LastUpdaterVersion$)
    AddToLogFile("A new version "+LastUpdaterVersion$+" of the program is available.", #True, #True, system_debug)
    ;- TODO: Установка новой версии из SFX архива
    AddToLogFile("Download file "+Chr(34)+"http://deus.lipkop.club/Update/deus_offline_updater.zip"+Chr(34)+"... ", #True, #False, system_debug)
    If ReceiveHTTPFile("http://deus.lipkop.club/Update/deus_offline_updater.zip", "updates/deus_offline_updater.zip")
      AddToLogFile("DONE!", #False, #True, system_debug)
      ;- TODO: Избавиться от внешнего 7z.exe
      sZIP.l = RunProgram("7z.exe", "e -aoa -o./ -i!unzipper.exe -y updates/deus_offline_updater.zip", GetPathPart(ProgramFilename$), #PB_Program_Open|#PB_Program_Hide)
      If sZIP
        Repeat
          Delay(100)
        Until Not ProgramRunning(sZIP)
        AddToLogFile("DONE!", #False, #True, system_debug)
        AddToLogFile("Execute file "+Chr(34)+"unzipper.exe"+Chr(34)+"... ", #True, #False, system_debug)
        If RunProgram("unzipper.exe")
          AddToLogFile("DONE!", #False, #True, system_debug)
          End
        Else
          AddToLogFile("ERROR!", #False, #True, system_debug)
        EndIf
      Else
        AddToLogFile("ERROR!", #False, #True, system_debug)
      EndIf
    Else
      AddToLogFile("ERROR!", #False, #True, system_debug)
    EndIf
  Else ; Если новой версии нет, то проверим, возможно мы только что обновились и надо подчистить за собой
    AddToLogFile("There are no updates available.", #True, #True, system_debug)
    If FileSize("updates/deus_offline_updater.zip")<>-1
      AddToLogFile("Delete file "+Chr(34)+"updates/deus_offline_updater.zip"+Chr(34)+"... ", #True, #False, system_debug)
      If DeleteFile("updates/deus_offline_updater.zip", #PB_FileSystem_Force)
        AddToLogFile("DONE!", #False, #True, system_debug)
      Else
        AddToLogFile("ERROR!", #False, #True, system_debug)
      EndIf
      AddToLogFile("Software update finished.", #True, #True, system_debug)
    EndIf
  EndIf
  AddToLogFile("Delete file "+Chr(34)+"updates/dou.txt"+Chr(34)+"... ", #True, #False, system_debug)
  If DeleteFile("updates/dou.txt", #PB_FileSystem_Force)
    AddToLogFile("DONE!", #False, #True, system_debug)
  Else
    AddToLogFile("ERROR!", #False, #True, system_debug)
  EndIf
  ; Обновление прошивок в локальном каталоге
  ;- TODO: Обновление отдельных файлов по MD5 хешу
  ;- TODO: Сократить пути на сервере обновлений
  HideGadget(1, #True) : HideGadget(0, #False)
  AddToLogFile("Checking the firmware update ...", #True, #True, system_debug)
  If hidden>0
    versions_url$ = "http://deus.lipkop.club/Update/deus_updates/DEUS_V4/Versions_"+VersionsFileName$+".php?show=all"
  Else
    versions_url$ = "http://deus.lipkop.club/Update/deus_updates/DEUS_V4/Versions_"+VersionsFileName$+".php"
  EndIf
  AddToLogFile("Download file "+Chr(34)+versions_url$+Chr(34)+"... ", #True, #False, system_debug)
  If ReceiveHTTPFile(versions_url$, "updates/cache_updates/Versions_"+VersionsFileName$+".txt")
    AddToLogFile("DONE!", #False, #True, system_debug)
    Count.l = CountFileStrings("updates/cache_updates/Versions_"+VersionsFileName$+".txt")
    If Count>0 And ReadFile(0, "updates/cache_updates/Versions_"+VersionsFileName$+".txt")
      SetGadgetAttribute(0, #PB_ProgressBar_Maximum, Count*ListSize(FirmwareFiles()))
      While Eof(0) = 0
        version$ = Trim(ReadString(0))
        If Len(version$)>0
          If FileSize("updates/cache_updates/DEUS_V4/"+version$) = -1 ; Если в локальном кеше такой прошивки нету
            AddToLogFile("Get firmware "+Chr(34)+version$+Chr(34)+"...", #True, #True, system_debug)
            ; Качаем ее во временный каталог
            DownloadOfSuccessful.b = #True
            AddToLogFile("Create directory "+Chr(34)+"updates/cache_updates/"+version$+Chr(34)+"... ", #True, #False, system_debug)
            If CreateDirectory("updates/cache_updates/"+version$)
              AddToLogFile("DONE!", #False, #True, system_debug)
            Else
              AddToLogFile("ERROR!", #False, #True, system_debug)
            EndIf
            ResetList(FirmwareFiles())
            While NextElement(FirmwareFiles())
              AddToLogFile("Download file "+Chr(34)+"http://deus.lipkop.club/Update/deus_updates/DEUS_V4/"+version$+"/"+FirmwareFiles()\File+Chr(34)+"... ", #True, #False, system_debug)
              If Not ReceiveHTTPFile("http://deus.lipkop.club/Update/deus_updates/DEUS_V4/"+version$+"/"+FirmwareFiles()\File, "updates/cache_updates/"+version$+"/"+FirmwareFiles()\File) And FirmwareFiles()\Required = #True
                DownloadOfSuccessful.b = #False
                SetGadgetState(0, GetGadgetState(0)+ListSize(FirmwareFiles())-ListIndex(FirmwareFiles()))
                AddToLogFile("ERROR!", #False, #True, system_debug)
                Break 1
              Else
                SetGadgetState(0, GetGadgetState(0)+1)
                AddToLogFile("DONE!", #False, #True, system_debug)
              EndIf
            Wend
            If DownloadOfSuccessful ; Если прошивка скачалась успешно
              AddToLogFile("Copy directory "+Chr(34)+"updates/cache_updates/"+version$+Chr(34)+" to "+Chr(34)+"updates/cache_updates/DEUS_V4/"+version$+Chr(34)+"... ", #True, #False, system_debug)
              If CopyDirectory("updates/cache_updates/"+version$, "updates/cache_updates/DEUS_V4/"+version$, "", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
                AddToLogFile("DONE!", #False, #True, system_debug)
              Else
                AddToLogFile("ERROR!", #False, #True, system_debug)
              EndIf
            EndIf
            AddToLogFile("Delete directory "+Chr(34)+"updates/cache_updates/"+version$+Chr(34)+"... ", #True, #False, system_debug)
            If DeleteDirectory("updates/cache_updates/"+version$, "", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
              AddToLogFile("DONE!", #False, #True, system_debug)
            Else
              AddToLogFile("ERROR!", #False, #True, system_debug)
            EndIf
          Else
            SetGadgetState(0, GetGadgetState(0)+ListSize(FirmwareFiles()))
          EndIf
        EndIf
      Wend
      CloseFile(0)
    Else
      SetGadgetState(0, 1)
      AddToLogFile("Can`t open file "+Chr(34)+"updates/cache_updates/Versions_"+VersionsFileName$+".txt"+Chr(34)+"!", #True, #True, system_debug)
    EndIf
    AddToLogFile("Delete file "+Chr(34)+"updates/cache_updates/Versions_"+VersionsFileName$+".txt"+Chr(34)+"... ", #True, #False, system_debug)
    If DeleteFile("updates/cache_updates/Versions_"+VersionsFileName$+".txt", #PB_FileSystem_Force)
      AddToLogFile("DONE!", #False, #True, system_debug)
    Else
      AddToLogFile("ERROR!", #False, #True, system_debug)
    EndIf
  Else
    AddToLogFile("ERROR!", #False, #True, system_debug)
  EndIf
  UpdateSuccess = #True
  AddToLogFile("Update finished.", #True, #True, system_debug)
EndProcedure

; Если интернет доступен
If cache_updates>0
  If CheckInternetConnection()
    Exit.b = #False
    OpenWindow(0, #PB_Any, #PB_Any, 300, 35, "Updating", #PB_Window_ScreenCentered)
    ProgressBarGadget(0, 5, 5, 290, 25, 0, 1) : HideGadget(0, #True)
    TextGadget(1, 5, 10, 290, 25, "Please, wait...", #PB_Text_Center) : HideGadget(1, #False)
    AddToLogFile("Check for new updates...", #True, #True, system_debug)
    CreateThread(@CheckForNewUpdates(), cache_hidden)
    Repeat
      WaitWindowEvent(100)
    Until UpdateSuccess
    CloseWindow(0)
  Else
    AddToLogFile("Updating the cache is impossible: no network connection.", #True, #True, system_debug)
  EndIf
Else
  AddToLogFile("Updating the cache is disabled in settings.", #True, #True, system_debug)
EndIf

; Обновление versions.txt
AddToLogFile("Updating file "+Chr(34)+"updates/cache_updates/DEUS_V4/Versions_"+VersionsFileName$+".txt"+Chr(34)+"...", #True, #True, system_debug)
If OpenFile(1, "updates/cache_updates/DEUS_V4/Versions_"+VersionsFileName$+".txt") Or CreateFile(1, "updates/cache_updates/DEUS_V4/Versions_"+VersionsFileName$+".txt")
  TruncateFile(1)
  If ExamineDirectory(0, "updates/cache_updates/DEUS_V4/", "")
    While NextDirectoryEntry(0)
      If DirectoryEntryType(0) = #PB_DirectoryEntry_Directory
        DirectoryName$ = DirectoryEntryName(0)
        If DirectoryName$<>"." And DirectoryName$<>".."
          WriteStringN(1, DirectoryName$)
          AddToLogFile(LSet(#NULL$, 3, Chr(9))+"Add version string "+Chr(34)+DirectoryName$+Chr(34)+";", #False, #True, system_debug)
        EndIf
      EndIf
    Wend
    FinishDirectory(0)
  Else
    AddToLogFile("Can`t examine directory "+Chr(34)+"updates/cache_updates/DEUS_V4/"+Chr(34)+"!", #True, #True, system_debug)
  EndIf
  CloseFile(1)
Else
  AddToLogFile("Can`t open file "+Chr(34)+"updates/cache_updates/DEUS_V4/Versions_"+VersionsFileName$+".txt"+Chr(34)+"!", #True, #True, system_debug)
EndIf

; Процедура обработки запроса для HTTP сервера
Procedure RequestProcess(ClientID.l)
  *Memory = AllocateMemory(1024)
  MemorySize.l = ReceiveNetworkData(ClientID, *Memory, MemorySize(*Memory))
  ClientRequest$ = PeekS(*Memory, MemorySize, #PB_UTF8)
  If Len(Trim(ClientRequest$))=0 : ProcedureReturn #False : EndIf
  FreeMemory(*Memory) : RequestFile$ = Chr(32)
  For i=1 To CountString(ClientRequest$, #LF$)
    RequestLine$ = Trim(StringField(ClientRequest$, i, #LF$))
    If Left(RequestLine$, 3) = "GET"
      RequestFile$ = Trim(StringField(RequestLine$, 2, " "))
      AddToLogFile("HTTP/GET file "+Chr(34)+RequestFile$+Chr(34)+"... ", #True, #False, system_debug)
    EndIf
  Next i
  ; Читаем запрошенный файл с диска
  If Len(Trim(RequestFile$))>0
    RequestFile$ = Mid(RequestFile$, 2)
    File.l = ReadFile(#PB_Any, RequestFile$)
    If File
      FileSize.l = Lof(File)
      *Memory = AllocateMemory(FileSize)
      ReadData(File, *Memory, FileSize)
      CloseFile(File)
      SendNetworkString(ClientID, "HTTP/1.1 200 OK"+#CR$+#LF$)
      SendNetworkString(ClientID, "Content-Length: "+Str(FileSize)+#CR$+#LF$)
      SendNetworkString(ClientID, "Content-Type: application/octet-stream"+#CR$+#LF$)
      SendNetworkString(ClientID, "Connection: close"+#CR$+#LF$)
      SendNetworkString(ClientID, #CR$+#LF$)
      SendNetworkData(ClientID, *Memory, FileSize)
      FreeMemory(*Memory)
      AddToLogFile("OK-200 ("+Str(FileSize)+" bytes)!", #False, #True, system_debug)
    Else ; Ошибка 404
      If Len(RequestFile$)>0
        AddToLogFile("ERROR-404!", #False, #True, system_debug)
        Answer$ = #NULL$
        Answer$ + "<!DOCTYPE HTML PUBLIC "+Chr(34)+"-//IETF//DTD HTML 2.0//EN"+Chr(34)+">"+#CR$+#LF$
        Answer$ + "<html><head>"+#CR$+#LF$
        Answer$ + "<title>404 Not Found</title>"+#CR$+#LF$
        Answer$ + "</head><body>"+#CR$+#LF$
        Answer$ + "<h1>Not Found</h1>"+#CR$+#LF$
        Answer$ + "<p>The requested URL /"+RequestFile$+" was not found on this server.</p>"+#CR$+#LF$
        Answer$ + "<p>Additionally, a 404 Not Found error was encountered while trying to use an ErrorDocument to handle the request.</p>"+#CR$+#LF$
        Answer$ + "</body></html>"+#CR$+#LF$
        SendNetworkString(ClientID, "HTTP/1.1 404 Not Found"+#CR$+#LF$)
        SendNetworkString(ClientID, "Content-Length: "+Len(Answer$)+#CR$+#LF$)
        SendNetworkString(ClientID, "Content-Type: text/html"+#CR$+#LF$)
        SendNetworkString(ClientID, "Connection: close"+#CR$+#LF$)
        SendNetworkString(ClientID, #CR$+#LF$)
        SendNetworkString(ClientID, Answer$)
      Else
        AddToLogFile("ERROR-404 (header location http://deus.lipkop.club/Update/)!", #False, #True, system_debug)
        SendNetworkString(ClientID, "HTTP/1.1 302 Moved Temporarily"+#CR$+#LF$)
        SendNetworkString(ClientID, "Location: http://deus.lipkop.club/Update/"+#CR$+#LF$)
        SendNetworkString(ClientID, "Content-Length: 0"+#CR$+#LF$)
        SendNetworkString(ClientID, "Content-Type: text/html"+#CR$+#LF$)
        SendNetworkString(ClientID, "Connection: close"+#CR$+#LF$)
        SendNetworkString(ClientID, #CR$+#LF$)
        SendNetworkString(ClientID, Answer$)
      EndIf
    EndIf
  Else ; Ошибка 400
    If RequestFile$=Chr(32)
      AddToLogFile("HTTP/UNKNOWN request... ", #True, #False, system_debug)
    EndIf
    AddToLogFile("ERROR-400!", #False, #True, system_debug)
    Answer$ = #NULL$
    Answer$ + "<!DOCTYPE HTML PUBLIC "+Chr(34)+"-//IETF//DTD HTML 2.0//EN"+Chr(34)+">"+#CR$+#LF$
    Answer$ + "<html><head>"+#CR$+#LF$
    Answer$ + "<title>400 Bad Request</title>"+#CR$+#LF$
    Answer$ + "</head><body>"+#CR$+#LF$
    Answer$ + "<h1>Bad Request</h1>"+#CR$+#LF$
    Answer$ + "<p>Your browser sent a request that this server could not understand.</p>"+#CR$+#LF$
    Answer$ + "<p>Additionally, a 400 Bad Request error was encountered while trying to use an ErrorDocument to handle the request.</p>"+#CR$+#LF$
    Answer$ + "</body></html>"+#CR$+#LF$
    SendNetworkString(ClientID, "HTTP/1.1 400 Bad Request"+#CR$+#LF$)
    SendNetworkString(ClientID, "Content-Length: "+Len(Answer$)+#CR$+#LF$)
    SendNetworkString(ClientID, "Content-Type: text/html"+#CR$+#LF$)
    SendNetworkString(ClientID, "Connection: close"+#CR$+#LF$)
    SendNetworkString(ClientID, #CR$+#LF$)
    SendNetworkString(ClientID, Answer$)
  EndIf
EndProcedure

; Запускаем HTTP сервер
If CreateNetworkServer(0, 8080, #PB_Network_TCP)
  ; Запускаем DEUS UPDATE
  DeusUpdate.l = RunProgram("DEUS_UPDATE.exe", "", "", #PB_Program_Open)
  If DeusUpdate
    Repeat
      Select NetworkServerEvent()
        Case #PB_NetworkEvent_Data
          ClientID.l = EventClient()
          CreateThread(@RequestProcess(), ClientID)
      EndSelect
    Until Not ProgramRunning(DeusUpdate)
  Else
    AddToLogFile("Can`t execute the DEUS_UPDATE.exe file!", #True, #True, system_debug)
    MessageRequester("Error", "Can`t execute the DEUS_UPDATE.exe file!", #MB_ICONERROR)
  EndIf
Else
  AddToLogFile("Can`t create the http server on port 8080!", #True, #True, system_debug)
  MessageRequester("Error", "Can`t create the http server on port 8080!", #MB_ICONERROR)
EndIf

; Сохраняем настройки в файл
If Not OpenPreferences("config.cfg", #PB_Preference_GroupSeparator)
  AddToLogFile("Can`t open config file! Try to create it...", #True, #True, system_debug)
  If Not CreatePreferences("config.cfg", #PB_Preference_GroupSeparator)
    AddToLogFile("Can`t create config file! The current settings will be lost.", #True, #True, system_debug)
    AddToLogFile(LSet(#NULL$, 64, Chr(45)), #False, #True, system_debug)
    AddToLogFile(#NULL$, #False, #True, system_debug)
    End
  EndIf
EndIf
PreferenceGroup("system")
WritePreferenceLong("debug", system_debug)
PreferenceGroup("cache")
WritePreferenceLong("updates", cache_updates)
WritePreferenceLong("hidden", cache_hidden)
ClosePreferences()
AddToLogFile("ALL DONE.", #True, #True, system_debug)
AddToLogFile(LSet(#NULL$, 64, Chr(45)), #False, #True, system_debug)
AddToLogFile(#NULL$, #False, #True, system_debug)

End

; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 28
; Folding = -
; EnableUnicode
; EnableThread
; EnableXP
; EnableAdmin
; UseIcon = dou.ico
; Executable = dou.exe
; EnableCompileCount = 30
; EnableBuildCount = 17
; IncludeVersionInfo
; VersionField0 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField1 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField2 = LipKop.club
; VersionField3 = Updater
; VersionField4 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField5 = 1.0.%BUILDCOUNT.%COMPILECOUNT
; VersionField6 = Unofficial XP Deus updater
; VersionField7 = deus_offline_updater
; VersionField8 = %EXECUTABLE
; VersionField9 = SoulTaker
; VersionField13 = thesoultaker48@gmail.com
; VersionField14 = http://deus.lipkop.club
; VersionField15 = VOS_NT_WINDOWS32
; VersionField16 = VFT_APP