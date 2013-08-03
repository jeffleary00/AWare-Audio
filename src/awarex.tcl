#!/usr/bin/tclsh

# ############################################################################
#
# AWAREX 
# The AWare Audio Extractor (Part of the AWare Audio package)
#
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

# CHANGE HISTORY
#
#   Sep-2012    3.0     --Jeff
#               Converted the old C program to this new Tcl version.
#               This will be (hopefully) better for multiple OS', and 32-bit
#               and 64-bit platforms.
#
# ############################################################################


package require Tcl 8.4
package require Itcl


## GLOBAL SETUP ##
array set ::Properties [list \
    product_name        "AWAREX" \
    product_version     "3.0.1" \
    product_author      "Jeff Leary" \
    product_date        "2012" \
    product_description "AWare Audio Extractor. Extracts audio tracks from backup disks created by Yamaha AW Professional Audio Workstations." \
    product_copyright   "Copyright 2007-2012 Jeffrey Leary. All rights reserved. Released under BSD License. See full license details included with this software." \
    product_disclaimer  "SillyMonkey Software is not affiliated with Yamaha in any way. Yamaha does not endorse, acknowledge, approve, or support this software. AW4416, AW2816, AW16G, AW2400, and AW1600 are all registered trademarks of the Yamaha Corporation." \
    vendor_name         "SillyMonkey Software" \
    vendor_url          "www.sillymonkeysoftware.com" \
    vendor_support      "sillymonkeysoftware@gmail.com" \
]

# source additional files
set ::sourcedir [pwd]
if {[info exists starkit::topdir]} {
    set ::sourcedir [file join $starkit::topdir lib]
}
foreach srcfile [list awnamespace.tcl class.awfile.tcl class.awsongatom.tcl class.awsong.tcl class.awtrack.tcl class.awregion.tcl class.awcontroller.tcl class.awexporter.tcl] {
    source [file join $::sourcedir $srcfile]
}

set ::debug 0
set ::tmpdir [pwd]
set ::tmpfh {}
set ::sessionlog {}




proc main {} {
    
    # determine where /tmp is for this machine/environment
    if {[file exists "/tmp"] && [file isdirectory "/tmp"]} {
        set ::tmpdir "/tmp"
    } elseif {[file exists "C:/Temp"] && [file isdirectory "C:/Temp"]} {
        set ::tmpdir "C:/Temp"   
    } else {
        catch { set ::tmpdir $env(TMP) }   
        catch { set ::tmpdir $env(TEMP) }
    }
    
    # initate the temp session log
    set ::sessionlog [file join $::tmpdir "awarex.session.log"]
    if { [catch { open  $::sessionlog w } ::tmpfh] } {
        puts "MESSAGE: Failed to initiate a session log. System message: '$result'"    
    }
    
    # create the controller object and have it print session start info
    set ::Controller [AWController #auto -debug $::debug -logfh $::tmpfh]
    $::Controller log_msg "START"
    foreach {key val} [array get ::Properties] {
        set key [string toupper $key]
        $::Controller log_msg "$key : $val"
    }
    
    # show initial screen to user, and begin.
    print_usage
    while {1} {
        set result [get_user_input]
        if {[handle_user_input $result]} {
            # fatal error!
            exit
        }
    }
}


proc print_usage {} {
#
# Basic program header on startup
#
    
    puts "AWare Extractor"
    puts "Version $::Properties(product_version)"
    puts "Session log at $::sessionlog"
    puts "Enter 'help' for more."
    flush stdout
}

proc print_help {} {
#
# Show detailed help screen
#

    set single_line [string repeat "-" 79]
    set double_line [string repeat "=" 79]
    
    puts ""
    puts $single_line
    puts "$::Properties(product_name) (Version $::Properties(product_version))"
    puts ""
    puts "$::Properties(product_description)"
    puts ""
    puts "$::Properties(vendor_name)"
    puts "$::Properties(vendor_url)"
    puts $single_line
    puts ""
    puts "Command syntax:"
    puts "==============="
    puts "  help"
    puts "  open <filename>"
    puts "  print|show"
    puts "  progress <on|off>"
    puts "  export <song_id> <track_id> <output_filename>"
    puts "  exit"
    puts ""
    puts "Command details:"
    puts "================"
    puts "  help     = Display the help screen."
    puts "  open     = Open a named .CFS or .16G file for processing. Use only"
    puts "              full path names. Shell variables are not expanded."
    puts "  print    = Display song/track information from the open file."
    puts "  show     = Same as print. Song data colums printed are:"
    puts "                  song_id"
    puts "                  song_type"
    puts "                  song_name"
    puts "                  song_bitdepth"
    puts "                  song_samplerate"
    puts "                  song_savedate (AW4416 only, unused)"
    puts "                  track_id"
    puts "                  track_name"
    puts "                  track_start_time"
    puts "                  track_total_time"
    puts "  progress = Toggle progress (percent exported) during exports."
    puts "  export   = Export a Song/Track to a filename. Output format will be"
    puts "              automatically determined based on the file extension."
    puts "              Supported extensions are .wav or .aif only."
    puts "  exit     = Quit the program."
    puts ""
    puts "Example:"
    puts "========"
    puts "OK> open /media/cd/AW_00000.16G"
    puts "DATA: 0 AW16G {My Song} 16 44100 {0} 0 {guitar} 00:00:00 00:02:30"
    puts "DATA: 0 AW16G {My Song} 16 44100 {0} 8 {mandolin} 00:00:00 00:02:31"
    puts "DATA: 0 AW16G {My Song} 16 44100 {0} 16 {kazoo} 00:01:20 00:00:28"
    puts "OK> export 0 0 /home/user/Recordings/My Song/guitar.aif"
    puts "DONE:"
    puts "OK> export 0 16 /home/user/Recordings/My Song/kazoo_solo.wav"
    puts "DONE:"
    puts "OK> exit"
    puts ""
    
}


proc get_user_input {} {
#
# Present an entry prompt to the user, and read users input.
# Do some basic de-tainting of input.
#
#   Returns
#       A string
#

    set ans {}
    while {1} {
        puts -nonewline "OK> "
        flush stdout
        gets stdin ans
        
        # de-taint user info
        if {[regexp {\$|\{|\|} $ans]} {
            puts "MESSAGE: Tainted user input. Please avoid special characters."
            flush stdout 
        } else {
            break
        }
    }
    return $ans
}


proc handle_user_input {str} {
#
#   Param
#       A string from the user
#
#   Returns
#       0 on success, non-zero on failure
#   

    set atoms [split $str]
    set cmd [lindex $atoms 0]
    
    # exit
    if {[regexp -nocase {exit|bye|quit} $cmd]} {
        $::Controller log_msg "EXIT"
        exit
        
    # help    
    } elseif {[regexp -nocase {help} $cmd]} {
        print_help
        return 0
        
    # open        
    } elseif {[regexp -nocase {open} $cmd]} {
        set fname [join [lrange $atoms 1 end] " "]
        if {[file exists $fname]} {
            $::Controller log_msg "Initializing session with file $fname"
            # spaces are allowed in filenames, so re-join
            if {[$::Controller init_with_file $fname]} {
                set err "MESSAGE: Failed to read file $fname."
                $::Controller log_msg $err
                puts $err
                flush stdout
            }
            return 0   
        } else {
            set err "MESSAGE: File not found $fname."
            $::Controller log_msg $err
            puts $err
            flush stdout
            return 0     
        }
        
    # show
    } elseif {[regexp -nocase {show|print} $cmd]} {
        $::Controller print_song_data
        return 0
        
    # progress
    } elseif {[regexp -nocase {progress} $cmd]} {
        $::Controller set_progress [lindex $atoms 1]
        return 0
        
    # export
    } elseif {[regexp -nocase {export} $cmd]} {
        set songid [lindex $atoms 1]
        set trackid [lindex $atoms 2]
        set fname [concat [lrange $atoms 3 end]]
        $::Controller log_msg "Track export command: $songid $trackid '$fname'"
        return [$::Controller export $songid $trackid $fname]
    } else {
        puts "What? 'help' if you are confused."
        return 0
    }
}


main


