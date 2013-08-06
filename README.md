AWare-Audio
===========

AWare Audio extracts audio tracks from Yamaha AW audio workstation backup files.


1. INTRODUCTION
    
    AWare Audio retrieves the audio tracks from backup CDs created on Yamaha AW-series Professional Audio Workstations 
    (AW4416, AW2816, AW16G).


2. SYSTEM REQUIREMENTS
    
    Version 3.0 of AWare Audio is written entirely in Tcl/Tk, which means it can be run on any system with Tcl 8.5 or
    higher. Additionally, pre-compiled binaries are available for several systems, including Linux, Mac OSX, and 
    Windows.


3. INSTALLATION
    
    PRE-COMPILED BINARIES:
    Windows:
        There is no installation program to run. Simply unzip the file and place the folder anywhere you want, on your
        Desktop, C: drive, wherever. Double-click on the AWARE.EXE program. The AWAREX.EXE program must ALWAYS remain in the
        same folder as AWARE.EXE
        
    Linux:
        Unzip the file.
        Copy "aware" and "awarex" to a place where your binaries are typically found (/usr/local/bin)
        
        $> cp ./aware* /usr/local/bin


        Launch AWare Audio.
        
          $> aware


        Change permissions on "aware" and "awarex" programs, only if necessary.
          
          $> chmod 755 /usr/local/bin/aware*
          

  SOURCE CODE:
    There is no installation required to use just the raw Tcl scripts.
    
    
4. RUNNING AWARE AUDIO
    
    WINDOWS: Double-click on the AWARE.EXE application.
    LINUX: From command-line, simply run "aware"
    MAC: Double-click on AWareAudio3.0

    FROM SOURCE: If your machine already has Tcl/Tk8.5 (or higher) and the Incr-Tcl package installed, you can
    run AWare by simply; tclsh ./aware.tcl
    
    
5. OPENING BACKUP FILES
  
    To open a backup file, choose "File -> Open..." from the AWare Audio menu. Browse to the CD you inserted, and 
    select the backup file.
      1. For AW4416 and AW2816 backups, the file is named A00000_0.CFS
      2. For AW16G backups, the file will be named AW_00000.16G

    Once a song is loaded, it's tracks will appear in the track table. You must select (or highlight) tracks before 
    they can be exported.
      1. To select ALL tracks for export, go to the "Edit" menu and choose "Select All".
      2. To select a multiple tracks, hold down the CTRL Key while clicking on tracks.

    Press the "Extract" button.
    You will be prompted to select a location for the output files. AWare will automatically create a folder with the 
    same name as the song. All tracks will be exported to this folder.


6. EXPORT FORMATS

    AWare Audio will always default to exporting tracks as AIFF files, as they are much, much faster to export*. If you
    really must have WAV files, you can change the export type in the Options menu.

    *The audio data in the AW backup file is stored Big-Endian. AIFF format is also Big-Endian, so there is no byte
    conversion required. Because WAV is a Little-Endian format, each audio byte-sample must be flipped. This takes a lot
    longer!
