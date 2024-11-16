; main.pb | Easyjot
EnableExplicit
IncludePath "includes"
XIncludeFile "main_screen.pbf"

#File_Types = "Text (*.txt;*.ini;*.csv;*.log)|*.txt;*.ini;*.csv;*.log|All files (*.*)|*.*"
#File_Default_Name = "untitled.txt"
#Menu_Main = 0
#Program_Title = "Easyjot"
#Program_URL = "https://github.com/vivid-pixel/pure-note"
#Program_Version = "0.95"

Structure File
  file_source.i
  file_with_path.s
  file_path_only.s
  file_name.s
  is_new.b
  is_unsaved.b
EndStructure

Define Text.File
Define.b user_quits = #False

Declare SetDefaults()
Declare UpdateTitleBar()
Declare UpdateFileStructure(temp_file, temp_path.s)
Declare Quit()
Declare WindowSizeHandler()


Procedure About(event)
  Define.s title = "About " + #Program_Title
  Define.s contents = "Version " + #Program_Version + " Copyright © 2022 - 2024" + 
                      ~"\n------------------------------------------------\n" +
                      ~"Coded in PureBasic! Repository link:\n" + #Program_URL
  MessageRequester(title, contents, #PB_MessageRequester_Info)
  ProcedureReturn #True
EndProcedure


Procedure AppMain()
  Shared Text.File
  Shared user_quits
  Define event
  
  OpenWindow_Main()
  SetDefaults()
  
  BindEvent(#PB_Event_SizeWindow, @WindowSizeHandler())
  ;BindEvent(#PB_Event_CloseWindow, @Quit(), this_window_id, #MenuBtn_Quit)
  
  While user_quits = #False
    event = Window_Main_Events(WaitWindowEvent())
    Select event
      Case #False: Quit()
    EndSelect
  Wend
EndProcedure


Procedure LoadFile(event)
  Shared Text.File
  Define.s temp_path
  Define temp_file
  
  ; Prompt for the text file so we can read it into the program
  temp_path = OpenFileRequester("Load Note", "", #File_Types, 0)
  
  If temp_path <> ""
    temp_file = OpenFile(#PB_Any, temp_path)
  Else
    ProcedureReturn #False
  EndIf
  
  If IsFile(temp_file)
    ; Read in the source_file contents line by line, until end-of-file
    Define.s file_source_contents = ReadString(temp_file, #PB_File_IgnoreEOL)
    
    ; Load text area up with source file's contents
    SetGadgetText(Editor_Main, file_source_contents)
    
    ; We're good to store the file in Text.File
    UpdateFileStructure(temp_file, temp_path)
    UpdateTitleBar()
    
    ProcedureReturn #True
  Else
    MessageRequester("Error loading file", 
                     "File was invalid or for some reason could not be loaded.",
                     #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf
EndProcedure


Procedure Quit()
  ;#MenuBtn_Quit
  
  Shared Text.File
  Shared user_quits
  Define user_confirm
  
  If Text.File\is_unsaved
    user_confirm = MessageRequester("Unsaved file!", 
                                    "Are you sure you want to quit WITHOUT saving?",
                                    #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning)
  EndIf
  
  Select user_confirm
    Case #PB_MessageRequester_No
      If SaveFile(0)
        user_quits = #True
      EndIf
    Case #PB_MessageRequester_Yes : user_quits = #True
    Default : user_quits = #False
  EndSelect
  
EndProcedure


Procedure SaveFile(event)
  Shared Text.File
  Define temp_file
  Define.s temp_path
  Define.s temp_name
  Define.b user_canceled = #False
  
  If Text.File\is_new
    ; Set the filename to default
    temp_name = #File_Default_Name
  Else
    ; Pre-populate the save window with the existing filename and extension
    temp_name = Text.File\file_name
  EndIf
  
  temp_path = SaveFileRequester("Save as", temp_name, #File_Types, 0)

  If temp_path <> ""
    ; File path should be valid. We'll store it in Text.File later
    temp_file = OpenFile(#PB_Any, temp_path, #PB_UTF8)
  Else
    ; The user cancelled the requestor
    user_canceled = #True
    MessageRequester("Save Canceled", 
                     "The save dialog was canceled without selecting a save location." +
                     " The file will not be saved.", #PB_MessageRequester_Error)
  EndIf
  
  ; Now we should have a file.
  If IsFile(temp_file) And Not user_canceled
    If WriteString(temp_file, GetGadgetText(Editor_Main))
      MessageRequester("Save complete", "The file has been saved.")
      
      ; Make it official and update things
      UpdateFileStructure(temp_file, temp_path)
      UpdateTitleBar()
      
    Else
      ; For some reason the file did not save, so let the user know
      MessageRequester("Save incomplete", 
                       "Failed to write to file. Possible permission issue.", 
                       #PB_MessageRequester_Error)
    EndIf
    
    CloseFile(temp_file)
  EndIf
EndProcedure


Procedure SaveFileAs(event)  
  ; D.R.Y.
  If SaveFile(event)
    ProcedureReturn #True
  EndIf
  
  ProcedureReturn #False
EndProcedure


Procedure SetDefaults()
  Shared Text.File
  
  ; Set boolean for brand new file
  Text.File\is_new = #True
  ; It's also unsaved
  Text.File\is_unsaved = #True
  ; Set file name for the new file
  Text.File\file_name = #File_Default_Name
  ; Check off Word Wrap in the menu
  SetMenuItemState(#Menu_Main, #MenuBtn_WordWrap, #True)
  ; Prevent window from becoming too small when resizing
  WindowBounds(Window_Main, 320, 240, #PB_Ignore, #PB_Ignore)
  ; Add file name to the title bar
  UpdateTitleBar()
  
  CompilerIf #PB_Compiler_OS = #PB_OS_MacOS
    ; MacOS UI customizations
    XIncludeFile "main_screen_mac.pbi"
  CompilerEndIf
  
  ProcedureReturn #True
EndProcedure  


Procedure ToggleWordWrap(event)
  Define word_wrap = GetGadgetAttribute(Editor_Main, #PB_Editor_WordWrap)
  
  If word_wrap
    ; Turn off word wrap and remove check mark from menu
    SetGadgetAttribute(Editor_Main, #PB_Editor_WordWrap, #False)
    SetMenuItemState(#Menu_Main, #MenuBtn_WordWrap, #False)
  Else
    ; Turn on word wrap and add check mark to menu
    SetGadgetAttribute(Editor_Main, #PB_Editor_WordWrap, #True)
    SetMenuItemState(#Menu_Main, #MenuBtn_WordWrap, #True)
  EndIf
  
  ProcedureReturn #True
EndProcedure


; Display the current file name in the program title bar
Procedure UpdateTitleBar()
  Shared Text.File
  Define.s full_title
  
  If Text.File\is_unsaved
    full_title = "*" + Text.File\file_name + " (unsaved) | " + #Program_Title
  Else
    Text.File\file_name = GetFilePart(Text.File\file_with_path)
    full_title = Text.File\file_name + " | " + #Program_Title
  EndIf
  
  SetWindowTitle(Window_Main, full_title)
EndProcedure


Procedure UpdateFileStructure(temp_file, temp_path.s)
  Shared Text.File
  
  Text.File\file_source = temp_file
  Text.File\file_with_path = temp_path
  Text.File\file_path_only = GetPathPart(Text.File\file_with_path)
  Text.File\file_name = GetFilePart(Text.File\file_with_path)
  Text.File\is_new = #False
  Text.File\is_unsaved = #False
EndProcedure


Procedure WindowSizeHandler()
  ResizeGadget(Editor_Main, #PB_Ignore, #PB_Ignore, 
               WindowWidth(Window_Main), WindowHeight(Window_Main) - MenuHeight())
EndProcedure


AppMain()
