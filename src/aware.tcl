#!/usr/bin/tclsh

# ############################################################################
# Copyright 2007-2012 Jeffrey Leary. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
#
#   1. Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#
#   2. Redistributions in binary form must reproduce the above copyright notice, 
#       this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY JEFFREY LEARY 'AS IS' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO 
# EVENT SHALL JEFFREY LEARY OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# The views and conclusions contained in the software and documentation are 
# those of the authors and should not be interpreted as representing official 
# policies, either expressed or implied, of Jeffrey Leary.
# ############################################################################

package require Tcl 8.5
package require Tk 8.5



proc main {} {
    init_variables
    init_gui
    init_awarex
}


proc init_variables {} {
#
#   Prototype and load all our global variables
#
    set ::export_type "aif"
    set ::eventflag {}
    
    set ::awarex [dict create \
        version {} \
        location {} \
        pid {} \
        pipe {} \
        sessionlog {} \
    ]
    
    set ::interface [dict create \
        track_tree {} \
        song_tree {} \
        song_bits {} \
        song_rate {} \
        song_date {} \
        song_type {} \
        progress_bar {} \
        extract_button {} \
        menu_bar {} \
    ]   
   
    set ::product [dict create \
        name        {AWare Audio} \
        version     3.0.1 \
        vendor      {SillyMonkey Software} \
        author      {Jeffrey Leary} \
        url         {www.sillymonkeysoftware.com} \
        support     {sillymonkeysoftware@gmail.com} \
        date        {2013} \
        description {Extracts audio tracks from backup disks created by Yamaha AW Professional Audio Workstations.} \
        disclaimer  {SillyMonkey Software is not affiliated with Yamaha in any way. Yamaha does not endorse, acknowledge, approve, or support this software. AW4416, AW2816, AW16G, AW2400, and AW1600 are all registered trademarks of the Yamaha Corporation.} \
    ]
}


proc clean_exit {} {
#
# ensure the spawned awarex program gets shut down
# before exit
#
#   parameters
#       none
#   
#   returns 
#       none

    if {[dict get $::awarex pipe] != ""} {
        puts [dict get $::awarex pipe] "exit"
        flush [dict get $::awarex pipe]
        catch {close [dict get $::awarex pipe]}
    }
    exit
}


proc about_this_program {} {
#
# display application information.
#
#   parameters
#       none
#   
#   returns 
#       null
#

    set txt "[dict get $::product name] version [dict get $::product version]\n"
    append txt "(awarex version [dict get $::awarex version])\n"
    append txt "\n[dict get $::product description]\n\n"
    append txt "[dict get $::awarex sessionlog]\n\n"
    append txt "[dict get $::product vendor]\n"
    append txt "[dict get $::product url] \n"
    
    tk_messageBox -title "About" -message "$txt" -parent .
    return
}


proc tkAboutDialog {} {
#
# This is a redirect, to override the Wish built in 'About This Program...'
#
    about_this_program
}


proc select_file {} {
#
# open an AW backup file (.CFS or .16G)
#
#   parameters
#       none
#   
#   returns 
#       pathname to file
#
    set myfile [tk_getOpenFile \
                -multiple 0 \
                -title "Please select backup file..." \
                -filetypes {{"AW Backup" {.CFS .16G}}} \
                -parent . \
    ]
             
    return $myfile
}


proc choose_location {} {
#
# select a directory
#
#   parameters
#       none
#   
#   returns 
#       a path
#
    set file [tk_chooseDirectory \
                -title "Please select an output location..." \
                -parent . ]
    return $file
}


proc clear_tree {tree} {
#
# clear all elements from a gui tree widget.
#
#   parameters
#       a named tree widget
#   
#   returns 
#       null
#
    foreach i [$tree children {}] {
        $tree delete $i
    }
}


proc select_all_tracks {} {
#
# Select all tracks in the current track view tree.
#
#   parameters
#   
#   returns 
#       null
#
    [dict get $::interface track_tree] selection set [[dict get $::interface track_tree] children {}]
}


proc create_safe_dir {path name} {
#
# create a directory for our song name at a given path.
# append numbers to song name if required, to prevent
# clobbering any existing dirs with same name
#
#   parameters
#       1. a path
#       2. a song name
#
#   returns 
#       a path to the newly created directory
#
    set index 1
    set success 0
    set max 999
    set mystring [file join $path $name]
    
    while {! $success} {
        if {$index > $max} {
            # oh, just clobber it!
            break
        }
        
        if {[file exists $mystring]} {
            set mystring [file join $path "$name $index"]
        } else {
            set success 1
        }
        incr index
    }
    
    if {[file mkdir $mystring] eq ""} {
        return $mystring
    } else {
        return {}
    }
}


proc find_safe_filename {path name ext} {
#
# create a safe file name. append numbers to name
# if required, to prevent clobbering any existing 
# files with same name.
#
#   parameters
#       1. a path
#       2. a file name
#        3. a file extension (minus the '.')
#
#   returns 
#       full pathname that is safe to use.
#
    set index 1
    set success 0
    set max 999
    set mystring [file join $path "$name.$ext"]
    
    while {! $success} {
        if {$index > $max} {
            # oh, just clobber it!
            break
        }
        
        if {[file exists $mystring]} {
            set mystring [file join $path "$name $index.$ext"]
        } else {
            set success 1
        }
        incr index
    }
    
    return $mystring
}


proc update_gui_with_song {index} {
#
# update gui info when user clicks on a song element.
#
#   parameters
#       1. a song index number
#   
#   returns 
#       1 on success
#       0 on failure
#
    
    # clear trees
    clear_tree [dict get $::interface track_tree]
    
    # assign new song details
    [dict get $::interface song_type] configure -text [dict get $::session type]
    [dict get $::interface song_bits] configure -text [dict get $::session songs $index bits]
    [dict get $::interface song_rate] configure -text [dict get $::session songs $index rate]
    # [dict get $::interface song_date] configure -text [dict get $::session songs $index date]
    
    # add new track elements
    dict for {i ptr} [dict get $::session songs $index tracks] {
        [dict get $::interface track_tree] insert {} end -id $i -values [list \
            [dict get $ptr name] \
            [dict get $ptr start_time] \
            [dict get $ptr total_time] \
        ]
    }
    
    return 1
}


proc toggle_button {} {
# 
# toggle the export button from its current state
#
 
    set b [dict get $::interface extract_button]
    
    if {[$b cget -text] eq "Extract"} {
        $b configure -text "Cancel" -command [list set ::eventflag -2]    
    } else {
        $b configure -text "Extract" -command export_tracks        
    }
}


proc request_disk {index} {
#
# find a specified backup disk number.
#
#   parameters
#       1. a number
#   
#   returns 
#       a path to the file
#
    set fmt1 [format "AW_%05d.16G" $index]
    set fmt2 [format "A%05d_0.CFS" $index]
    
    # ask user to eject disk and insert new one.
    if {[tk_messageBox -icon question -message "Next audio block is in file with index $index (probably named like '$fmt1' or '$fmt2').\nIf reading from CD, please eject current disk and insert next CD.\nIn the next step you will need to select the next file.\nPress OK to continue, CANCEL to quit the export."] eq "cancel"} {
        return {}
    }    
    
    set myfile [select_file]
    return $myfile
}


proc locate_awarex {} {
#
# Find the awarex executable.
# Look in our starting dir, and all other reasonable path locations.
#
#   parameters
#       none
#   
#   returns 
#       path to awarex, or null if not found
    
    set searchpaths [list ./ [pwd] [file dirname [info script]]]
    
    # add starkit dirs if we are running in a starkit
    if {[info exists starkit::topdir]} {
        lappend searchpaths $starkit::topdir
        lappend searchpaths [file join $starkit::topdir lib]
    }

    # add standard *nix bin directories on *nix systems
    if {[tk windowingsystem] ne "win32"} {
        lappend searchpaths /usr/bin /usr/local/bin/ /bin
    }

    # iterate through directories and look for some form of awarex
    foreach name [list awarex awarex.exe awarex.tcl] {       
        foreach path $searchpaths {
            set fname [file join $path $name]

            # clean the paths depending on which OS
            set fname [file nativename [file normalize $fname]]
            
            # if {[tk windowingsystem] eq "win32"} {
            #    set fname [file attribute $fname -shortname]
            # }

            if {[file exists "$fname"]} {
                # add additional quotes to improve cross-platform compatibility
                return "\"$fname\""
            }
        }
    }

    return ""
}


proc init_awarex {} {
#
#   initialize bi-directional file handle to AWAREX and set up file
#   event monitoring and actions.
#
#   parameters
#       none
#   
#   returns 
#       0 on success
#       non-zero failure
#
    set location [locate_awarex]
    if {$location == ""} {
        tk_messageBox -type ok -message "Cannot find awarex executable. Please re-install AWare Audio"
        exit
    }

    # if awarex is a tcl script and not an executable, launch with another tclsh interpreter.
    # this is sketchy.
    if {[regexp -nocase {tcl} [file extension $location]]} {
        set location "tclsh $location"
    }

    dict set ::awarex location $location
    if {[catch {open "| $location" r+} pipe]} {
        tk_messageBox -type ok -message $pipe
        exit
    }
    fconfigure $pipe -blocking 0
    fileevent $pipe readable [list evaluate_response $pipe]
    
    dict set ::awarex pipe $pipe
    dict set ::awarex pid [pid $pipe]
    puts $pipe "progress on"
    flush $pipe
}


proc open_new_session {} {
#
# open an AW backup file (.CFS or .16G) and
# initialize a new session based on the disk info.
#
#   parameters
#       none
#   
#   returns 
#       0 on success
#       non-zero on failure
#

    # select a backup file for opening.
    set myfile [select_file]
    if {$myfile eq ""} {
        return -1
    }
    
    # re-initialize our master session.
    set ::session [dict create songs {} type {} ]
    
    # clear GUI elements of old data
    clear_tree [dict get $::interface track_tree]
    clear_tree [dict get $::interface song_tree]
    
    
    # send command to awarex and read resulting lines
    # ##################################################################
    
    unset -nocomplain ::eventflag
    puts [dict get $::awarex pipe] "open $myfile"
    flush [dict get $::awarex pipe]
    vwait ::eventflag
    
    # ##################################################################
    
    if {$::eventflag < 1} {
        return $::eventflag
    }
    
    if {[llength [dict get $::session songs]] < 1} {
        tk_messageBox -icon "warning" -message "No valid songs found in file."
        return -1
    }

    # update song tree with names.
    dict for {index ptr} [dict get $::session songs] {
        [dict get $::interface song_tree] insert {} end -id $index -values [list [dict get $ptr name]] -tags $index
        [dict get $::interface song_tree] tag bind $index <1> [list update_gui_with_song $index]
        [dict get $::interface song_tree] selection set $index
        update_gui_with_song $index
    }
    
    return 0    
}


proc export_tracks {} {
#
# iterate over selected tracks and send the off to be exported
#
#   parameters
#       none
#
#   returns 
#       0 on success, non-zero on failure
#

    # check if any tracks are selected
    if {[llength [[dict get $::interface track_tree] selection]] < 1} {
        tk_messageBox -icon "warning" -message "Please select at least one track to export."
        return -1
    }
    
    # choose output location
    set path [choose_location]
    if {$path eq ""} {
        return -1
    }
    
    # create safe directory name for this songs files
    set song_id [[dict get $::interface song_tree] selection]
    set song_name [dict get $::session songs $song_id name]
    set path [create_safe_dir $path $song_name]
    if {$path eq ""} {
        tk_messageBox -icon "warning" -message "Failed to create output folder $path."
        return -1
    }
    
    # change our "Extract" button to "Cancel" button
    toggle_button
    
    # iterate over selected tracks and export files
    foreach track_id [[dict get $::interface track_tree] selection] {
        
        set track_name [dict get $::session songs $song_id tracks $track_id name]
        set output [find_safe_filename $path $track_name $::export_type]
        
        if {$output eq ""} {
            tk_messageBox -icon "warning" -message "Failed to find a safe filename for track named $track_name."
            [dict get $::interface track_tree] set $track_id "status" "skipped"
            continue
        }
        
        # set up the progress bar and display it
        set max 100
        [dict get $::interface progress_bar] configure -value 1 -maximum $max
        grid [dict get $::interface progress_bar]
        
        
        # #############################################
        
        unset -nocomplain ::eventflag
        puts [dict get $::awarex pipe] "export $song_id $track_id $output"
        flush [dict get $::awarex pipe]
        vwait ::eventflag
        
        # #############################################
        
        
        # re-hide the progress bar and remove this track from selection
        grid remove [dict get $::interface progress_bar]
        
        # un-highlight the track currently that finished exported
        [dict get $::interface track_tree] selection remove $track_id
        
        if {$::eventflag > 0} {
            [dict get $::interface track_tree] set $track_id "status" "complete"
        } else {
            [dict get $::interface track_tree] set $track_id "status" "failed"
            
            # remove corrupt or invalid file
            if {[file exists $output]} {
                file delete $output
            }
            
            # -2 means user issued CANCEL command. Stop exporting tracks
            if {$::eventflag == -2} {
                break
            }
        }
    }
    
    # reset button and clear selected tracks
    toggle_button
    [dict get $::interface track_tree] selection remove [[dict get $::interface track_tree] selection]
    
    return 1
}

 
proc evaluate_response {pipe} {
#
# read text from a bidirectional pipe and take appropriate response.
# ::eventflag gets set under the following circumstances
#   ERROR from awarex (-1)
#   MESSAGE from awarex (null)
#   COMPLETE from awarex (2)
#   "OK>" promt from awarex (1)
#   INSERT DISK from awarex (null)
#   DATA info from awarex (null)
#
#   parameters
#       1. a channel
#   
#   returns 
#       void
#
    
    if {[catch {gets $pipe data} rval]} {
        tk_messageBox -type okcancel -message "Unknown pipe error"
        set ::eventflag -1
        return
    }
    if {[regexp -nocase {PROGRESS:\s+(\d+)} $data match str]} {
        # export progress information
        flush stdout
        [dict get $::interface progress_bar] configure -value $str
        return
    }
    if {[regexp -nocase {version\s+(\d+.+)} $data match str]} {
        # matched version info from awarex
        dict set ::awarex version $str   
        return
    }
    if {[regexp -nocase {(session log at .+)} $data match str]} {
        # matched log info from awarex
        dict set ::awarex sessionlog $str   
        return
    }
    if {[regexp -nocase {MESSAGE:\s+(.+)} $data match str]} {
        # a message from awarex?
        tk_messageBox -type ok -message $str
        return
    } 
    if {[regexp -nocase {ERROR:\s+(.+)} $data match str]} {
        # a critical error from awarex?
        tk_messageBox -type ok -message $str
        set ::eventflag -1
        return
    }
    if {[regexp -nocase {WARNING:\s+(.+)} $data match str]} {
        # a critical error from awarex?
        tk_messageBox -type ok -message $str
        return
    }
    if {[regexp -nocase {COMPLETE:|DONE:} $data]} {
        # file export completed
        set ::eventflag 2
        return
    }
    if {[regexp -nocase {INSERT DISK:\s+(\d+)} $data match str]} {
        # DEBUG MESSAGE
        puts $data
        
        # insert disk request
        set result [request_disk $str]
        if {$result eq ""} {
            set ::eventflag -1
        } else {
            puts $pipe "$result"
            flush $pipe 
        }
    } 
    if {[regexp -nocase {(DATA:.+)} $data match str]} {
        set mylist $str
        lassign $mylist junk songid type songname bits rate date trkid trkname stime ttime
        dict set ::session type $type
        dict set ::session songs $songid name $songname
        dict set ::session songs $songid date $date
        dict set ::session songs $songid bits $bits
        dict set ::session songs $songid rate $rate
        dict set ::session songs $songid tracks $trkid name $trkname
        dict set ::session songs $songid tracks $trkid start_time $stime
        dict set ::session songs $songid tracks $trkid total_time $ttime
        return
    }
    if {[regexp -nocase {OK>} $data]} {
        # very important that this check is the LAST in the list of every other
        # option. otherwise can cause false positives, and our script may start
        # issuing commands to awarex when it is really not ready to handle them.
        set ::eventflag 1
        return 
    }
}


proc init_gui {} {
#
# create our gui.
#
#   parameters
#       none
#   
#   returns 
#       0 on success
#       non-zero on failure
#    

    # change treeview selection colors, due to wierdness with newer Windows OS
    # versions and Tk.
    ttk::style configure Treeview -background white
    
    set columnData {}
    set columnNames {}
    set borderSize {}
    
    if {[tk windowingsystem] eq "aqua"} {
        set borderSize 10
    } else {
        set borderSize 5
    }
    
    set columnData [dict create \
        0 [list name {Track Name} 180 center] \
        1 [list starttime "Start time" 100 center] \
        2 [list totaltime "Total time" 100 center] \
        3 [list status Status 100 center] \
    ]
    foreach id [lsort [dict keys $columnData]] {
        lappend columnNames [lindex [dict get $columnData $id] 0]
    }
    
    wm title . [dict get $::product name]
    wm minsize . 780 480
    
    if {[init_menu]} {
        return -1
    }
    
    # GUI APPLICATION FRAME LAYOUT
    #
    #  + f --------------------------------------+
    #  |                                         |
    #  | + f1 -+  + f3 ------------------------+ |
    #  | |     |  |                            | |
    #  | |     |  |                            | |
    #  | |     |  |                            | |
    #  | +-----+  |                            | |
    #  |          |                            | |
    #  | + f2 -+  |                            | |
    #  | |     |  |                            | |
    #  | |     |  |                            | |
    #  | |     |  |                            | |
    #  | +-----+  +----------------------------+ |
    #  |                                         |
    #  | + f4 ---------------+ + f5 -----------+ |
    #  | |      progress bar | |        button | |
    #  | +-------------------+ +---------------+ |
    #  +-----------------------------------------+
    
    # master frame
    grid [ttk::frame .f -padding "$borderSize $borderSize $borderSize $borderSize"] -column 0 -row 0 -sticky nwes 
    
    # sub frames
    grid [ttk::frame .f.f1] -column 0 -row 0 -sticky nwes -padx 10 -pady 10
    grid [ttk::labelframe .f.f2 -text "Song Details"] -column 0 -row 1 -sticky nwes -padx 10 -pady 10    
    grid [ttk::frame .f.f3] -column 1 -row 0 -sticky nwes -padx 10 -pady 10 -rowspan 2 -columnspan 2
    grid [ttk::frame .f.f4] -column 0 -row 2 -sticky nwes -padx 10 -pady 10 -columnspan 2
    grid [ttk::frame .f.f5] -column 2 -row 2 -sticky e -padx 10 -pady 10
    
    # configure master frames
    grid columnconfigure . 0 -weight 1
    grid columnconfigure .f 0 -weight 1
    grid columnconfigure .f 1 -weight 2
    grid columnconfigure .f 2 -weight 2
    grid rowconfigure . 0 -weight 1
    grid rowconfigure .f 0 -weight 1
    grid rowconfigure .f 1 -weight 0
    grid rowconfigure .f 2 -weight 0
    
    # configure the sub frames    
    grid columnconfigure .f.f1 0 -weight 1 -minsize 200
    grid columnconfigure .f.f2 0 -weight 0
    grid columnconfigure .f.f2 1 -weight 0
    grid columnconfigure .f.f3 0 -weight 1
    grid columnconfigure .f.f4 0 -weight 1 
    grid columnconfigure .f.f5 0 -weight 1
    grid rowconfigure .f.f1 0 -weight 1 -minsize 240
    grid rowconfigure .f.f2 0 -weight 1
    grid rowconfigure .f.f3 0 -weight 1
    grid rowconfigure .f.f4 0 -weight 1
    grid rowconfigure .f.f5 0 -weight 1
        
    # progress bar (hide until it is needed)
    dict set ::interface progress_bar [ttk::progressbar .f.f4.p -orient horizontal -mode determinate]
    grid [dict get $::interface progress_bar] -column 0 -row 0 -sticky nwes
    grid remove [dict get $::interface progress_bar]

    # extract button
    dict set ::interface extract_button [ttk::button .f.f5.b1 -text "Extract" -padding "15 2 15 2" -command export_tracks]
    grid [dict get $::interface extract_button] -column 0 -row 0 -sticky e
    
    # song detail labels
    grid [ttk::label .f.f2.l1 -text "Song Format:"] -column 0 -row 0 -sticky e -padx 5
    grid [ttk::label .f.f2.l2 -text "Bit Depth:"] -column 0 -row 1 -sticky e -padx 5
    grid [ttk::label .f.f2.l3 -text "Sample Rate:"] -column 0 -row 2 -sticky e -padx 5
     # grid [ttk::label .f.f2.l5 -text "Date:"] -column 0 -row 4 -sticky e -padx 5
    
    # song detail widgets
    dict set ::interface song_type [ttk::label .f.f2.l11]
    dict set ::interface song_bits [ttk::label .f.f2.l21]
    dict set ::interface song_rate [ttk::label .f.f2.l31]
     # dict set ::interface song_date [ttk::label .f.f2.l51]
    grid [dict get $::interface song_type] -column 1 -row 0 -sticky w
    grid [dict get $::interface song_bits] -column 1 -row 1 -sticky w
    grid [dict get $::interface song_rate] -column 1 -row 2 -sticky w 
     # grid [dict get $::interface song_date] -column 1 -row 4 -sticky w
    
    # song treeview
    dict set ::interface song_tree [ttk::treeview .f.f1.tree -selectmode browse -columns "songs"]
    grid [dict get $::interface song_tree] -column 0 -row 0 -sticky nsew
    [dict get $::interface song_tree] column songs -anchor w
    [dict get $::interface song_tree] heading songs -text "Songs" -anchor center
    [dict get $::interface song_tree] configure -displaycolumns "songs"
    [dict get $::interface song_tree] configure -show headings
    grid columnconfigure [dict get $::interface song_tree] 0 -weight 1
    grid columnconfigure [dict get $::interface song_tree] 1 -weight 0
    grid rowconfigure [dict get $::interface song_tree] 0 -weight 1
      
    # track treeview
    dict set ::interface track_tree [ttk::treeview .f.f3.tree]
    grid [dict get $::interface track_tree] -column 0 -row 0 -sticky nsew 
    [dict get $::interface track_tree] configure -columns $columnNames
    foreach id [lsort [dict keys $columnData]] {
        [dict get $::interface track_tree] column [lindex [dict get $columnData $id] 0] -width [lindex [dict get $columnData $id] 2] -anchor [lindex [dict get $columnData $id] 3]
        [dict get $::interface track_tree] heading [lindex [dict get $columnData $id] 0] -text [lindex [dict get $columnData $id] 1] -anchor [lindex [dict get $columnData $id] 3]
    }
    [dict get $::interface track_tree] configure -displaycolumns $columnNames
    [dict get $::interface track_tree] configure -show headings
    grid columnconfigure [dict get $::interface track_tree] 0 -weight 1 -minsize 520
    grid columnconfigure [dict get $::interface track_tree] 1 -weight 0
    grid rowconfigure [dict get $::interface track_tree] 0 -weight 1
    
    # scroller
    grid [ttk::scrollbar .f.f3.scroll -orient vertical -command ".f.f3.tree yview"] -column 1 -row 0 -sticky ns
    [dict get $::interface track_tree] configure -yscrollcommand ".f.f3.scroll set"
    grid columnconfigure .f.f3.scroll 4 -weight 1
    grid rowconfigure .f.f3.scroll 0 -weight 1
    
    # bind shortcut keys to actions
    if {[tk windowingsystem] eq "aqua"} {
        bind all <Command-a> select_all_tracks
        bind all <Command-A> select_all_tracks
    } else {
        bind all <Control-a> select_all_tracks
        bind all <Control-A> select_all_tracks
    }
    
    # finally, ensure that our spawned program is killed before gui exits
    wm protocol . WM_DELETE_WINDOW {clean_exit}
    
    return 0
}


proc init_menu {} {
#
#   create our menus.
#
#   parameters
#       none
#   
#   returns 
#       0 on success
#       non-zero on failure
#    
    option add *tearOff 0
    menu .menubar
    . configure -menu .menubar
    
    set m .menubar
    menu $m.file
    menu $m.edit
    menu $m.options
    $m add cascade -menu $m.file -label File
    $m add cascade -menu $m.edit -label Edit
    $m add cascade -menu $m.options -label Options
    
    if {[tk windowingsystem] eq "aqua"} {
        $m add cascade -menu [menu $m.apple]
        $m.apple add command -label "About [dict get $::product name]"  -command about_this_program 
    } else {
        menu $m.help
        $m add cascade -menu $m.help -label Help
        $m.help add command -label "About..." -command about_this_program  
    }
    
    $m.file add command -label "Open..." -command open_new_session
    $m.file add command -label "Extract..." -command export_tracks
    
    if {[tk windowingsystem] eq "aqua"} {
        $m.edit add command -label "Select All" -command select_all_tracks -accelerator "Cmd-A"  
    } else {
        $m.edit add command -label "Select All" -command select_all_tracks -accelerator "Ctrl-A"  
    }
    
    $m.options add radiobutton -label "AIFF output" -variable ::export_type -value aif
    $m.options add radiobutton -label "WAV output" -variable ::export_type -value wav
    
    if {[tk windowingsystem] ne "aqua"} {
        $m.file add separator
        $m.file add command -label "Exit" -command {clean_exit}
    }
    
    return 0
}



## LAUNCH ##
main

