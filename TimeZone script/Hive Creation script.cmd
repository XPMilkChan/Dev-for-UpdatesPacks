::¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯::
::     ***** 5eraph's TimeZone Registry Hive Script *****     ::
::                                                            ::
::                    version:  2011-12_3                     ::
::                                                            ::
::¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯::
::  Script source post:                                       ::
::  http://www.ryanvm.net/forum/viewtopic.php?p=119697#119697 ::
::                                                            ::
::  Further information:                                      ::
::  http://www.ryanvm.net/forum/viewtopic.php?p=119625#119625 ::
::                                                            ::
::¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯::
::  Purpose:                                                  ::
::                                                            ::
::      Create a text-mode INF which applies all changes      ::
::      from the latest time zone DST update.                 ::
::                                                            ::
::  Directions for use:                                       ::
::                                                            ::
::      From a fresh Windows install WITHOUT updates, export  ::
::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones::
::      key from RegEdit.exe and place REG file in "Source    ::
::      Files" folder as your Base REG.  Then install the     ::
::      latest DST update package and export again, into      ::
::      the "Source Files" folder.  Finally, run this script. ::
::                                                            ::
::  Script's Procedure:                                       ::
::                                                            ::
::   1. Converts REG files in source directory to INFs.       ::
::   2. Creates a Patch file in the output folder showing ALL ::
::      changes between converted REG files for user refer-   ::
::      ence when complete.  See Notes.                       ::
::   3. Creates AddReg segment from added lines in Patch file.::
::      (lines starting with +)                               ::
::   4. Creates a temporary file containing removed entries   ::
::      (from lines starting with -) that do not appear in    ::
::      the AddReg segment.                                   ::
::   5. Finds removed keys by comparing removed entries with  ::
::      updated registry dump INF.                            ::
::   6. Merges added and removed entries into the output file.::
::   7. Cleans up temporary files in source and output        ::
::      folders.                                              ::
::                                                            ::
::  Notes:                                                    ::
::                                                            ::
::    * Base REG files for ENU XP x86 and x64 are included.   ::
::                                                            ::
::    * Latest exported ENU DST update REG files are included.::
::                                                            ::
::    * Executable files used by this script are included:    ::
::      Reg2Inf.exe and diff.exe                              ::
::                                                            ::
::    * Edit the "Constant Declarations" section below to     ::
::      change important file and folder names to be used.    ::
::                                                            ::
::    * Entries can be sorted alphabetically.  Change the     ::
::      value of b_SortEntries in "Constant Declarations" if  ::
::      desired.                                              ::
::                                                            ::
::    * Script now detects registry entries and keys that are ::
::      deleted.  However, no current DST update package      ::
::      removes base registry keys or entries.  Though I'm    ::
::      confident that the detection routines work, the user  ::
::      should manually check the Patch file for deleted      ::
::      lines that are not replaced or updated elsewhere in   ::
::      the Patch file.                                       ::
::                                                            ::
::    * Patch files are best viewed by a text editor with     ::
::      syntax highlighting capability, such as notepad2-mod  ::
::      found at:                                             ::
::      http://www.ryanvm.net/forum/viewtopic.php?t=9058      ::
::____________________________________________________________::

@ECHO OFF
TITLE TimeZone Script
SETLOCAL EnableDelayedExpansion

::Constant Declarations:
SET "s_BaseRegFileName=TZ.Base.XPx86.ENU.reg"
SET "s_NewRegFileName=TZ.KB2633952.XPx86.ENU.reg"
SET "s_OutputFileName=TimeZone.inf"
SET "s_SourceFolderName=Source Files"
SET "s_OutputFolderName=Output Files"
SET "s_ExecutablesFolderName=EXEs"
SET "b_SortEntries=No"

::When using this script as a module we need to check the current and working
::directories and change when necessary.
::For parameter usage, see:  http://www.msfn.org/board/index.php?act=findpost&pid=967978
SET "s_CalledFromFolder=%CD%"
SET "s_CommandLineFolder=%~dp0"
SET "s_CommandLineFolder=!s_CommandLineFolder:~0,-1!"
IF /I "%s_CalledFromFolder%"=="!s_CommandLineFolder!" (
::Set smallest descriptive CMD window.
  MODE CON COLS=29 LINES=3
  ECHO.
  ECHO.         WORKING...
) ELSE (
  ChDir "!s_CommandLineFolder!"
  SET s_NewRegFileName=%1
  SET s_NewRegFileName=!s_NewRegFileName:"=!
)

::Convert source REGs to INFs.
"%s_ExecutablesFolderName%\Reg2Inf.exe" "%s_SourceFolderName%\%s_BaseRegFileName%" /linesonly /longflags >"%s_SourceFolderName%\%s_BaseRegFileName:~0,-4%.inf"
"%s_ExecutablesFolderName%\Reg2Inf.exe" "%s_SourceFolderName%\!s_NewRegFileName!" /linesonly /longflags >"%s_SourceFolderName%\!s_NewRegFileName:~0,-4!.inf"

::Create Patch file from the INFs created above.
IF NOT EXIST "%s_OutputFolderName%" (MkDir "%s_OutputFolderName%")
"%s_ExecutablesFolderName%\diff.exe" -u8 "%s_SourceFolderName%\%s_BaseRegFileName:~0,-4%.inf" "%s_SourceFolderName%\!s_NewRegFileName:~0,-4!.inf" >"%s_OutputFolderName%\!s_NewRegFileName:~0,-4!.patch"

::Create AddReg output file part.  This step must be complete before starting
::the next step.
FOR /F "usebackq skip=2 delims=" %%G IN ("%s_OutputFolderName%\!s_NewRegFileName:~0,-4!.patch") DO (
  SET "s_LineToParse=%%G"
  IF "!s_LineToParse:~0,1!"=="+" (ECHO>>"%s_OutputFolderName%\AddRegEntries.inf" !s_LineToParse:~1!)
)

::Find removed entries which have not been moved or updated in the Patch file
::and put them in DelRegValues.inf.
FOR /F "usebackq skip=2 delims=" %%G IN ("%s_OutputFolderName%\!s_NewRegFileName:~0,-4!.patch") DO (
  SET "s_LineToParse=%%G"
  IF "!s_LineToParse:~0,1!"=="-" (
    FOR /F "tokens=2-3 delims=," %%H IN ("!s_LineToParse!") DO (
      SET "s_DelRegLine=HKLM,%%H,%%I"
      SET "b_EntryDeleted=True"
      FOR /F "usebackq tokens=2-3 delims=," %%J IN ("%s_OutputFolderName%\AddRegEntries.inf") DO (IF /I "%%H"=="%%J" (IF /I "%%I"=="%%K" (SET "b_EntryDeleted=False")))
    )
    IF /I "!b_EntryDeleted!"=="True" (ECHO>>"%s_OutputFolderName%\DelRegValues.inf" !s_DelRegLine!)
) )

::Determine if entries in DelRegValues.inf correspond to a deleted key by
::checking the converted NewRegFile.  If so, add key to DelRegEntries.inf if it
::doesn't already exist there.  Otherwise, just add the line to DelRegEntries.inf.
IF EXIST "%s_OutputFolderName%\DelRegValues.inf" (
  FOR /F "usebackq tokens=1-3 delims=," %%G IN ("%s_OutputFolderName%\DelRegValues.inf") DO (
    SET "s_KeyToCheckFor=%%G,%%H"
    SET "b_KeyFoundInNewRegFile=False"
::Begin search loop through converted NewRegFile.
    FOR /F "usebackq skip=2 tokens=1-2 delims=," %%J IN ("%s_SourceFolderName%\!s_NewRegFileName:~0,-4!.inf") DO (
      SET "s_KeyToCheckAgainst=%%J,%%K"
      IF /I "!b_KeyFoundInNewRegFile!"=="False" (
        IF /I "!s_KeyToCheckFor!"=="!s_KeyToCheckAgainst!" (
          SET "b_KeyFoundInNewRegFile=True"
          ECHO>>"%s_OutputFolderName%\DelRegEntries.inf" %%G,%%H,%%I
    ) ) )
::Ended search loop through NewRegFile.  Start new loop through DelRegEntries.
    IF /I "!b_KeyFoundInNewRegFile!"=="False" (
      IF NOT EXIST "%s_OutputFolderName%\DelRegEntries.inf" (ECHO>"%s_OutputFolderName%\DelRegEntries.inf" !s_KeyToCheckFor!) ELSE (
        SET "b_KeyFoundInDelRegEntries=False"
        FOR /F "usebackq delims=" %%J IN ("%s_OutputFolderName%\DelRegEntries.inf") DO (IF /I "!s_KeyToCheckFor!"=="%%J" (SET "b_KeyFoundInDelRegEntries=True"))
        IF /I "!b_KeyFoundInDelRegEntries!"=="False" (ECHO>>"%s_OutputFolderName%\DelRegEntries.inf" !s_KeyToCheckFor!)
) ) ) )

::Create output file header.
ECHO.>"%s_OutputFolderName%\%s_OutputFileName%"
ECHO>>"%s_OutputFolderName%\%s_OutputFileName%" [Version]
ECHO>>"%s_OutputFolderName%\%s_OutputFileName%" Signature = "$Windows NT$"
ECHO>>"%s_OutputFolderName%\%s_OutputFileName%" ClassGUID={00000000-0000-0000-0000-000000000000}
ECHO>>"%s_OutputFolderName%\%s_OutputFileName%" DriverVer=10/01/2002,5.2.3790.3959
ECHO.>>"%s_OutputFolderName%\%s_OutputFileName%"

::Add [DelReg] section to output file if entries exist for it.
IF EXIST "%s_OutputFolderName%\DelRegEntries.inf" (
  ECHO>>"%s_OutputFolderName%\%s_OutputFileName%" [DelReg]
  IF /I NOT "!b_SortEntries!"=="No" (
    SORT "%s_OutputFolderName%\DelRegEntries.inf" >>"%s_OutputFolderName%\%s_OutputFileName%"
  ) ELSE (
    COPY /B "%s_OutputFolderName%\%s_OutputFileName%" + "%s_OutputFolderName%\DelRegEntries.inf" "%s_OutputFolderName%\%s_OutputFileName%" >NUL
  )
  ECHO.>>"%s_OutputFolderName%\%s_OutputFileName%"
)

::Add [AddReg] section to output file.
ECHO>>"%s_OutputFolderName%\%s_OutputFileName%" [AddReg]
IF /I NOT "!b_SortEntries!"=="No" (
  SORT "%s_OutputFolderName%\AddRegEntries.inf" >>"%s_OutputFolderName%\%s_OutputFileName%"
) ELSE (
  COPY /B "%s_OutputFolderName%\%s_OutputFileName%" + "%s_OutputFolderName%\AddRegEntries.inf" "%s_OutputFolderName%\%s_OutputFileName%" >NUL
)

::INF Cleanup
DEL "%s_SourceFolderName%\%s_BaseRegFileName:~0,-4%.inf" 2>NUL
DEL "%s_SourceFolderName%\!s_NewRegFileName:~0,-4!.inf" 2>NUL
DEL "%s_OutputFolderName%\AddRegEntries.inf" 2>NUL
DEL "%s_OutputFolderName%\DelRegValues.inf" 2>NUL
DEL "%s_OutputFolderName%\DelRegEntries.inf" 2>NUL

::When using this script as a module we need to check the current and working
::directories and change when necessary.
IF /I NOT "%s_CalledFromFolder%"=="!s_CommandLineFolder!" (ChDir "%s_CalledFromFolder%")

GOTO :eof