package require Tcl 8.4
package require Itcl



# <<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>> #
# <<                                      >> #
# <<     AWController Definition BEGIN    >> #
# <<                                      >> #
# <<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>> #

itcl::class AWController {
    variable _songs;     # list of song objects
    variable _files;     # list of file objects
    variable _current;   # name of current file object
    variable _fh;        # file handle of open channel       
    variable _ftype;     # backup type/format (AW4416|AW2816|AW16G)
    variable _progress 0;
   
    public variable logfh;
    public variable debug 0;
    
    
    # PUBLIC methods
    method init_with_file {fname}
    method print_song_data {}
    method type {}
    method songs {}
    method current_file_object {}
    method current_handle {}
    method get_file_for_frame {frame}
    method log_msg {str}
    method export {song_id track_id fname}
    method set_progress {val}
    
    # *PRIVATE methods for disk/file management and mining
    private method dump_object {obj {chan stderr}}
    private method clean_c_string {str}
    private method new_awfile_from_file {fname}
    private method file_type_from_channel {fh}
    private method file_index_from_channel {fh type}
    private method file_songcount_from_channel {fh type} 
    private method file_maxframes_from_channel {fh type}
    private method file_offsetframes_from_channel {fh type}
    private method file_previousframes_from_channel {fh type}
         
    # *PRIVATE methods for mining for song info
    private method song_at_index {index}
    private method tracks_for_song {song}
    private method regions_for_track {track song}
    private method frames_for_region {region song}
    private method fetch_region {id song}
    private method is_valid_region {region}
    private method add_song {obj}
    private method add_file {obj}
    
       
    ## constructor
    constructor {args} {
        if {$args != ""} {
            eval configure $args
        }
    }
    
    
    ## destructor
    destructor {
        if {[info exists _fh] && $_fh != ""} {
            close $_fh
        }
        if {[info exists _files] && $_files != ""} {
            foreach $f {$_files} {
                itcl::delete object $f
            }
        }
        if {[info exists _songs] && $_songs != ""} {
            foreach $s {$_songs} {
                itcl::delete object $s 
            }    
        }
    }
}




# ############################################ #
#                                              #
# PUBLIC methods                               #
#                                              #
# ############################################ #


# init_with_file()
#   open aw backup file, validate, and start a new session.
#
#   PARAMETERS
#       a file name
#   RETURNS 
#       0 on success, non-zero on failure
itcl::body AWController::init_with_file {fname} {
    
    set ext [file extension $fname]
    set err {}
    
    if {$ext ne ".CFS" && $ext ne ".16G"} {
        set err "ERROR: Not a valid AW Backup file extension: $ext"
        log_msg $err
        puts $err
        flush stdout
        return -1
    }
    
    # clean up previous session information
    if {[info exists _fh] && $_fh != ""} {
        log_msg "Closing previous open file channel."
        close $_fh
        set _fh ""
    }
    if {[info exists _songs] && [llength $_songs] > 0} {
        foreach s $_songs {
            log_msg  "Deleting song object $s."
            itcl::delete object $s    
        } 
        set _songs {}   
    }
    if {[info exists _files] && [llength $_files] > 0} {
        foreach f $_files {
            log_msg  "Deleting file object $f."
            itcl::delete object $f  
        }  
        set _files {}
        set _ftype {}  
    }
    
    
    # gather data from current disk/file and store it
    set disk [new_awfile_from_file $fname]
    if {[$disk index] != 0} {
        set err = "ERROR: Backup file [$disk index] is not the first one in sequence."
        puts $err
        flush stdout
        log_msg $err
        itcl::delete object $disk
        return -1    
    }
    
    dump_object $disk
    add_file $disk
    set _ftype [$disk type]
    
    
    # go mining for song objects, and add to session	
	for {set i 0} {$i < [$disk song_count]} {incr i} {
		set song [song_at_index $i]
		if {$song == ""} {
    		log_msg "MESSAGE: Song index $i returned empty. No more songs?"
    		break
		}
		
		if {[llength [$song tracks]] < 1} {
    		set err "MESSAGE: Song at index $i ([$song name]) contains no tracks."
    	    log_msg $err
    	    puts $err 
    	    flush stdout
		} else {
		    add_song [$song info variable this -value]
		    dump_object $song
		}
	}
	
	if {! [info exists _songs] || [llength $_songs] < 1} {
        set err "MESSAGE: Backup file contains no valid songs."
        log_msg $err
    	puts $err 
        flush stdout	
    	return -1	
	}
	
	print_song_data
    return 0        
}


# log_msg()
#   pring message to logfile
#
#   PARAMS
#       a string
#   RETURNS:
#       null
itcl::body AWController::log_msg {str} {
    if {! [catch {puts $logfh [format "\[%s\] %s" [clock format [clock seconds] -format "%m-%d-%Y %H:%M:%S"] $str]}]} {
        flush $logfh
    }
}


# set_progress()
#   pring message to logfile
#
#   PARAMS
#       a value <on|off>
#   RETURNS:
#       null
itcl::body AWController::set_progress {val} {
    if {[regexp -nocase {on} $val] || $val == 1} {
        set _progress 1
    } else {
        set _progress 0
    }
    log_msg "Progress set to $_progress"
}


# print_song_data()
#   print text information extracted from file.
#   information is in the following format:
#		song_id,
#       song_type,
#		song_name,
#		song_rate,
#		song_bits,
#		song_date,
#		track_id,
#		track_name,
#       track_start_time,
#       track_total_time
#
#   PARAMS
#       nothing
#   RETURNS:
#       0 on success, non-zero on failure
itcl::body AWController::print_song_data {} {
    foreach song $_songs {
        foreach track [$song tracks] {
            set str "DATA: "
            append str [join [list \
                [$song id] \
                $_ftype \
                "{[$song name]}" \
                [$song bits] \
                [$song rate] \
                "{[$song date]}" \
                [$track id] \
                "{[$track name]}" \
                [$track start_time] \
                [$track total_time] \
                ] " "]
            log_msg $str
            puts $str
            flush stdout
        }
    } 
    puts "DONE:"
    flush stdout
    return 0   
}


# export()
#   export a track to named file
#
#   PARAMS
#       song_id, track_id, export_type, output_filename
#   RETURNS:
#       0 on success, non-zero on fail
itcl::body AWController::export {songid trackid fname} {
    set obj {}
    set type "aif"
    
    if {[regexp -nocase {wav} [file extension $fname]]} {
        set type "wav"
    }
    
    if {! [info exists _songs] || $_songs == ""} {
        set err "MESSAGE: No songs loaded yet."
        log_msg $err
        puts $err
        flush stdout
        return -1
    }
    
    # iterate song/track objects to find one we want
    foreach song $_songs {
        if {[$song id] != $songid} { continue }
        foreach track [$song tracks] {
            if {[$track id] == $trackid} {
                set obj $track
                break
            }
        }
    }
    
    if {$obj == ""} {
        set err "MESSAGE: Track object ($songid,$trackid) not found."
        log_msg $err
        puts $err
        flush stdout
        return -1    
    }
    
    set exporter [AWExporter #auto \
                                -track $obj \
                                -type $type \
                                -output $fname \
                                -parent $this \
                                -progress $_progress ]
    
    set result [$exporter export]
    itcl::delete object $exporter
    
    if {$result != 0} {
        log_msg "MESSAGE: $result"
        puts "MESSAGE: $result"
        flush stdout
        
        # remove files that did not complete normally
        catch { file delete $fname }
        return -1
    }
    
    log_msg "Track ($songid, $trackid) completed normally."                       
    puts "DONE:"
    flush stdout

    return 0
}


# get_file_for_frame()
#   Calculate which disk a particular audio frame exists on,
#   and then find (or request) that file.
#
#   PARAMS
#       a frame number
#   RETURNS:
#       0 on success, non-zero on fail
itcl::body AWController::get_file_for_frame {frame} {
    set desired_disk -1
    set origfile [$this current_file_object]
    set current_path [$origfile path]
    set new_path {}
    set err {}
    
    if {$desired_disk < 0} {
        if {$frame < [expr [$origfile offset_frames] * -1]} {
            set desired_disk [expr [$origfile index] - 1]
            if {$desired_disk < 0} {
                set desired_disk 0
            }
        } else {
            set desired_disk [expr [$origfile index] + 1]
        }
    }
    
    log_msg "Requesting disk index '$desired_disk' for frame $frame."
    
    # If disk already exists in our stored session/file, us it.
    # Or, see if it can be found without asking.
    if {[llength $_files] > $desired_disk} {
        set newfile [lindex $_files $desired_disk]
        set new_path [$newfile path]
    } else {
        set dirname [file dirname [$origfile path]]
        if {$_ftype == "AW16G"} {
            set new_path [file join $dirname [format "AW_%05d.16G" $desired_disk]]
    	} else {
    	    set new_path [file join $dirname [format "A%05d_0.CFS" $desired_disk]]
    	}
    }
    
    while {1} {
        log_msg "Entering while-loop to search for new file path '$new_path'."
        if {$new_path == "" || ! [file exists $new_path]} {
            # No other choice but to ask user to insert/identify it?
            log_msg "Asking user to insert disk/file."
            puts "INSERT DISK: $desired_disk (enter full path name):"
            flush stdout
            puts -nonewline "OK> "
            flush stdout
            gets stdin new_path
            set new_path [regsub -all -nocase {OK> } $new_path ""]
            
            if {[regexp {exit|quit} $new_path]} {
                log_msg "Export quit requested."
                return -1
            }
            if {! [file exists $new_path]} {
                set err "MESSAGE: File $new_path not found."
                log_msg $err
                puts $err 
                flush stdout
            }
        } else {
            log_msg "New file for use found at $new_path"
            close $_fh
            set newfile [new_awfile_from_file $new_path]
            if {[$newfile index] != $desired_disk} {
                set err "MESSAGE: File index does not match index that was requested."
                log_msg $err
                puts $err
                flush stdout
                
                itcl::delete object $newfile
                set new_path {}
                
                # reopen our original file before returning.
                add_file $origfile
            } else {
                add_file $newfile
                break
            }
        }    
    }
    
    return 0
}



# ############################################ #
#                                              #
# PRIVATE methods                              #
#                                              #
# ############################################ #


# dump_object()
#   print an objects details.
#   useful for debugging.
#
#   PARAMETERS
#       an AW* Object name
#       [a channel] (stdout, stderr(default), filehandle)
#   RETURNS 
#       null
itcl::body AWController::dump_object {obj {chan stderr}} {
    set msg {}
    append msg "*Object Name: $obj\n"
    append msg "*Object Class: "
    append msg [$obj info class]
    append msg "\n"
    append msg "*Object Details:\n"
    foreach myvar [lsort [$obj info variable]] {
        set varname [lindex [split $myvar "::"] end]
        append msg "*  $varname = "
        append msg [$obj info variable $varname -value]
        append msg "\n"
    }
    log_msg $msg
}


# clean_c_string()
#
#   removes from a string any characters that 
#   will cause us problems later on.
#
#   parameters
#       1. a string
#   
#   returns 
#       a new string
#
# ###############################################
itcl::body AWController::clean_c_string {str} {	
	set size [string length $str]
	set clean {}
	
	for {set i 0} {$i < $size} {incr i}  {
		set ch [string index $str $i]	
		if {[string is control $ch] || $ch eq "\0"} {
			break
		} else {
			append clean $ch
		}
	}
	
	set clean [regsub -all {[[:space:]]+} $clean " "]
	set clean [regsub -all {_+} $clean "_"]
	set clean [regsub -all {[^[:alnum:] _-]} $clean "-"]
	set clean [regsub -all {[^[:alnum:]]*$} $clean ""]
	set clean [string trim $clean]
	
	return $clean
}


# new_awfile_from_file()
#   populate an AWFile object from information at path.
#
#   PARAMETERS
#       a file name
#   RETURNS 
#       an AWFile object on success
itcl::body AWController::new_awfile_from_file {fname} {
    
    set type {}
    set ext [file extension $fname]
    
    if {$ext eq ".16G"} {
        set type "AW16G"
    }
    
    set fh [open $fname r]
    fconfigure $fh -translation binary
    
    if {$type ne "AW16G"} {
        set type [file_type_from_channel $fh] 
    }
    set index [file_index_from_channel $fh $type]
    set max [file_maxframes_from_channel $fh $type]
    set offset [file_offsetframes_from_channel $fh $type]
    set prev [file_previousframes_from_channel $fh $type] 
    set count [file_songcount_from_channel $fh $type]
    close $fh 

    set awfile [AWFile #auto \
                        -path $fname \
                        -type $type \
                        -index $index \
                        -song_count $count \
                        -bytes [file size $fname] \
                        -max_frames $max \
                        -offset_frames $offset \
                        -previous_frames $prev ]
                   
    return $awfile
}


# file_type_from_channel()
#   fetch backup file format. 
#   valid only for 4416/2816 backups.
#
#   PARAMETERS
#       an open file channel
#   RETURNS 
#       AW4416 or AW2816 or ???
itcl::body AWController::file_type_from_channel {fh} {
    set location $::aw::diskformat_location
    set size $::aw::diskformat_size
    
    seek $fh $location start
    set val [read $fh $size]
    
    if {$val == 2816} {
        return "AW2816"
    }
    
    return "AW4416"
}


# file_index_from_channel()
#   fetch the file index/sequence number
#
#   PARAMETERS
#       an open file channel.
#       a file format (AW4416, AW2816, AW16G).
#   RETURNS 
#       a number
itcl::body AWController::file_index_from_channel {fh type} {
    set location $::aw::diskinfo_location
    set offset $::aw::diskinfo_disknum_offset
    set size 1
    
    if {$type eq "AW16G"} {
        set location $::awg::diskinfo_location
        set offset $::awg::diskinfo_disknum_offset 
    }
    
    seek $fh [expr $location + $offset] start
    binary scan [read $fh $size] c val
    return $val
}


# file_songcount_from_channel()
#   read number of songs contained in the backup
#
#   PARAMETERS
#       an open file channel.
#       a file format (AW4416, AW2816, AW16G).
#   RETURNS 
#       on success, a number. on failure, ""
itcl::body AWController::file_songcount_from_channel {fh type} {
    set location $::aw::diskinfo_location
    set offset $::aw::diskinfo_songcount_offset
    set size 2
    
    if {$type eq "AW16G"} {
        set location $::awg::diskinfo_location
        set offset $::awg::diskinfo_songcount_offset 
    }
    
    seek $fh [expr $location + $offset] start
    binary scan [read $fh $size] S* val
    return $val
}


# file_maxframes_from_channel()
#   read number of audio frames in backup file
#
#   PARAMETERS
#       an open file channel.
#       a file format (AW4416, AW2816, AW16G).
#   RETURNS 
#       a number
itcl::body AWController::file_maxframes_from_channel {fh type} {
    set location $::aw::diskinfo_location
    set offset $::aw::diskinfo_audio_offset
    set size 2
    
    if {$type eq "AW16G"} {
        set location $::awg::diskinfo_location
        set offset $::awg::diskinfo_audio_offset
    }
    
    seek $fh [expr $location + $offset] start
    binary scan [read $fh $size] S* val
    return $val
}


# file_offsetframes_from_channel()
#   read number of audio offset frames in backup file
#
#   PARAMETERS
#       an open file channel.
#       a file format (AW4416, AW2816, AW16G).
#   RETURNS 
#       a number
itcl::body AWController::file_offsetframes_from_channel {fh type} {
    set location $::aw::diskinfo_location
    set offset $::aw::diskinfo_offset_offset
    set size 2
    
    if {$type eq "AW16G"} {
        set location $::awg::diskinfo_location
        set offset $::awg::diskinfo_offset_offset
    }
    
    seek $fh [expr $location + $offset] start
    binary scan [read $fh $size] S* val
    return $val
}


# file_previousframes_from_channel()
#   read number of audio previous frames in backup file
#
#   PARAMETERS
#       an open file channel.
#       a file format (AW4416, AW2816, AW16G).
#   RETURNS 
#       a number
itcl::body AWController::file_previousframes_from_channel {fh type} {
    set location $::aw::diskinfo_location
    set offset $::aw::diskinfo_previous_offset
    set size 2
    
    if {$type eq "AW16G"} {
        set location $::awg::diskinfo_location
        set offset $::awg::diskinfo_previous_offset
    }
    
    seek $fh [expr $location + $offset] start
    binary scan [read $fh $size] S* val
    return $val
}


# song_at_index()
#   decode and build Song object from song data at index
#
#   PARAMETERS
#       an index number
#   RETURNS 
#       on success, a Song object. on error, ""
itcl::body AWController::song_at_index {index} {
	
    set name {}
	set location 0
	set offset 0
	set bits 16
	set rate 44100
	set start 0
	set blocksz 0
	set bufsz 0
	set found 0
	set count 0
	set buffer {}
	
   	if {$_ftype eq "AW16G"} {
        set blocksz $::awg::songblock_size
        set start $::awg::songinfo_location
        set bufsz $::awg::songinfo_size
	} else {
        set blocksz $::aw::songblock_size
        set start $::aw::songinfo_location
        set bufsz $::aw::songinfo_size
	}
	
    log_msg "Fetching $_ftype song at index $index."
		
    if {$_ftype eq "AW16G"} {
	    # finding AW16G songs is a little tricky
	    
        for {set i 0} {$i < $::awg::songinfo_max_count} {incr i} {
	        set buffer {}
			set location [expr ($i * $bufsz) + $start]
			
			# This song header exists on another disk???
			# Current version of software is not capable of handling this.
			if {[expr $location + $::awg::songblock_size] > [$_current bytes]} {
			    set err "ERROR: Too many songs in backup file. Sorry"
                log_msg $err
				puts $err
				flush stdout
    		    return ""
			}
			
			# seek to song location, and pull in the info buffer
			seek $_fh $location start
			set buffer [read $_fh $bufsz]
			
		    # aw16g song offset number is very important in locating song data
			binary scan [string range $buffer 0x20 [expr 0x20 + 4]] I* offset
			
			# offset of 0x0000 indicates beginning of the valid song blocks
			if {$offset == 0} { incr found }
			
			if {$found} {
    			if {$count == $index} {
					# correct buffer found! update loction and offset values
        		    set location [expr ($offset * $::aw::block_size) + \
        		    					$::awg::songblock_location]
        		    					
        		    set name [clean_c_string [string range $buffer \
        		    				$::awg::songinfo_name_offset \
        							[expr $::awg::songinfo_name_offset + \
        							$::awg::songinfo_name_size] ]]					
            	    
        		    break	
    			}
				incr count
            }
        }
    } else {
        # finding aw4416/2816 song buffers is easy!
        set location [expr $start + ($index * $blocksz)]
        
        # This song header exists on another disk???
		# Current version of software is not capable of handling this.
		if {[expr $location + $::aw::songblock_size] > [$_current bytes]} {
			set err "ERROR: Too many songs in backup file. Sorry"
		    puts $err
		    flush stdout
			log_msg $err
		    return ""
		}
		
		# seek to song location, and pull in the info buffer	
		seek $_fh $location start
		set buffer [read $_fh $bufsz]
			
	    set name [clean_c_string [string range $buffer \
        		    				$::aw::songinfo_name_offset \
        							[expr $::aw::songinfo_name_offset + \
        							$::aw::songinfo_name_size] ]]
		
		# decode the sample rate
		binary scan [string range $buffer \
		                $::aw::songinfo_samplerate_offset \
		                $::aw::songinfo_samplerate_offset] c tmp
		if {$tmp != 1} { set rate 48000 }
		
		# decode the bit depth
		binary scan [string range $buffer \
		                $::aw::songinfo_bitdepth_offset \
		                $::aw::songinfo_bitdepth_offset] c tmp
		if {$tmp != 1} { set bits 24 }
    }
	
    # create the new song object with our gathered information
    set song [AWSong #auto \
                    -id $index \
                    -type $_ftype \
                    -name $name \
                    -location $location \
                    -offset $offset \
                    -bits $bits \
                    -rate $rate ] 
    
    
    if ([tracks_for_song $song]) {
        log_msg "Error fetching tracks for song!"
    }
    
    return $song	
}


# tracks_for_song()
#   fetch all track objects for a song
#
#   PARAMETERS
#       a Song object
#   RETURNS 
#       0 on success, non-zero on failure
itcl::body AWController::tracks_for_song {song} {
    set bufsz 0
    set location 0
    set offset 0
    set max 0 
    set no 0
	set	ns 0
	set	ro 0
    set buffer {}
    
    if {$_ftype eq "AW16G"} {
		set max     $::awg::trackinfo_max_count
		set offset  $::awg::trackinfo_offset	
		set bufsz   $::awg::trackinfo_size
		set no      $::awg::trackinfo_name_offset
		set ns      $::awg::trackinfo_name_size
		set ro      $::awg::trackinfo_region_offset
	} else {
	    set max     $::aw::trackinfo_max_count
		set offset  $::aw::trackinfo_offset	
		set bufsz   $::aw::trackinfo_size
		set no      $::aw::trackinfo_name_offset
		set ns      $::aw::trackinfo_name_size
		set ro      $::aw::trackinfo_region_offset
	}
	
    for {set i 0} {$i < $max} {incr i} {
        set region_ptr {}
        
        # seek to track info location, and pull in the info buffer	
        set location [expr [$song location] + $offset + ($i * $bufsz)]
        seek $_fh $location start
        set buffer [read $_fh $bufsz]
        
        # Value of (0xFFFF, unsigned 65535) means no region data.
        binary scan [string range $buffer $ro [expr $ro + 2]] S region_ptr
        set region_ptr [expr { $region_ptr & 0xFFFF }]; # convert to unsigned!
        
		if {$region_ptr < $::aw::block_term} {
        	log_msg "Fetching track at index $i (location $location)."
    		set name [clean_c_string [string range $buffer $no [expr $no + $ns]]]
    		set track [AWTrack #auto \
    		            -id $i \
    		            -name $name \
    		            -pointer $region_ptr ]
    		            
    	    if {! [regions_for_track $track $song]} {
    		    $song add_track [$track info variable this -value]
    		    dump_object $track
	        }
		}
    }
    
    # does our song now contain ANY valid tracks?
    if {[llength [$song tracks]] < 1} {
        # a warning?
        return -1
    }
    
    return 0        
}


# regions_for_track()
#   fetch all regions for a track/song object
#
#   PARAMETERS
#       1. a Track object
#       2. a Song object
#   RETURNS 
#       0 on success, non-zero on failure
itcl::body AWController::regions_for_track {track song} {  
	set next_region [$track pointer]
    
    while {$next_region != $::aw::block_term} {
    	set region [fetch_region $next_region $song]
		set next_region [$region next_region]
		
		if {[is_valid_region $region]} {
			if {! [frames_for_region $region $song]} {
				$track add_region [$region info variable this -value]
				dump_object $region
			} else {
				itcl::delete object $region
			}
		} else {
            log_msg "Invalid Region! Dumping object for investigation."
        	dump_object $region
			itcl::delete object $region
		}
	}
	
    if {[llength [$track regions]] < 1} {
        # a warning?
        return -1
    }
    return 0
}


# fetch_region()
#   fetch a region object from a defined song location
#
#   PARAMETERS
#       1. a region id
#       2. a Song object
#   RETURNS 
#       a Region object on success, a "" on failure
itcl::body AWController::fetch_region {id song} {
    set bufsz 0
    set location 0
    set total 0
    set start 0
    set offset 0
    set pointer 0
    set next_rgn 0
    set ro 0;   # region offset
    set so 0; 	# start offset
    set to 0; 	# total offset
    set oo 0;   # offset offset
    set mo 0;   # map offset
    set no 0;   # next region offset
    set buffer {}
	
    if {$_ftype eq "AW16G"} {
		set bufsz $::awg::regioninfo_size
		set ro $::awg::regioninfo_offset
		set so $::awg::regioninfo_start_offset
		set to $::awg::regioninfo_total_offset
		set oo $::awg::regioninfo_offset_offset
		set no $::awg::regioninfo_next_offset
		set mo $::awg::regioninfo_map_offset
	} else {
		set bufsz $::aw::regioninfo_size
		set ro $::aw::regioninfo_offset
		set so $::aw::regioninfo_start_offset
		set to $::aw::regioninfo_total_offset
		set oo $::aw::regioninfo_offset_offset
		set no $::aw::regioninfo_next_offset
		set mo $::aw::regioninfo_map_offset
	}
	
    set location [expr ($id * $bufsz) + [$song location] + $ro]
    log_msg "Fetching region at location $location."
        
    seek $_fh $location start
    set buffer [read $_fh $bufsz]

	binary scan [string range $buffer $so [expr $so + 4]] I start
	set start [expr { $start & 0xFFFFFFFF }]; # convert to unsigned
	
	binary scan [string range $buffer $to [expr $to + 4]] I total
	set total [expr { $total & 0xFFFFFFFF }]; # convert to unsigned
	
	binary scan [string range $buffer $oo [expr $oo + 4]] I offset
	set offset [expr { $offset & 0xFFFFFFFF }]; # convert to unsigned
	
	binary scan [string range $buffer $mo [expr $mo + 2]] S pointer
	set pointer [expr { $pointer & 0xFFFF }]; # convert to unsigned
	
	binary scan [string range $buffer $no [expr $no + 2]] S next_rgn
	set next_rgn [expr { $next_rgn & 0xFFFF }]; # convert to unsigned
	
	set region [AWRegion #auto \
	            -id $id \
	            -start_sample $start \
	            -total_samples $total \
	            -offset_samples $offset \
	            -pointer $pointer \
	            -next_region $next_rgn ]
    
    return $region 
}


# frames_for_region()
#   fetch all frames for a region/song object
#
#   PARAMETERS
#       1. a Region object
#       2. a Song object
#   RETURNS 
#       0 on success, non-zero on failure
itcl::body AWController::frames_for_region {region song} {  
    set bufsz 0
    set location 0
    set pointer 0
    set offset 0
    set po 0; # 'previous' offset
    set no 2; # 'next' offset
    set mo 4; # 'map' offset
    set prev 0
    set next 0
	set buffer {}
	
    if {$_ftype eq "AW16G"} {
		set bufsz $::awg::mapinfo_size 
		set offset $::awg::mapinfo_offset 
	} else {
		set bufsz $::aw::mapinfo_size 
		set offset $::aw::mapinfo_offset 
	}
    
    set next [$region pointer]
    while {$next < $::aw::block_term} {
 		set location [expr ($next * $bufsz) + $offset + [$song location]]
 		
		seek $_fh $location start
        set buffer [read $_fh $bufsz]
		
		binary scan [string range $buffer $po [expr $po + 2]] S prev
	    set prev [expr { $prev & 0xFFFF }]; # convert to unsigned
	
		binary scan [string range $buffer $no [expr $no + 2]] S next
	    set next [expr { $next & 0xFFFF }]; # convert to unsigned
	    
	    binary scan [string range $buffer $mo [expr $mo + 4]] I pointer
	    set pointer [expr { $pointer & 0xFFFFFFFF }]; # convert to unsigned
		
	    $region add_frame $pointer
 	}
	
 	if {[llength [$region frames]] < 1} {
     	# a warning?
     	return -1
 	}
 	return 0
}


# is_valid_region()
#   check a region object for basic validity
#   PARAMS
#       a region object
#   RETURNS:
#       1 on true, 0 on false
itcl::body AWController::is_valid_region {region} {
    if {[$region total_samples] > 0 && [$region start_sample] >= 0} {
	    return 1
    }
    return 0  
}


# add_song()
#   add song object to this session
#   PARAMS
#       a song object
#   RETURNS:
#       0 on success, non-zero on failure
itcl::body AWController::add_song {obj} {
    if {[$obj parent $this] == ""} {
        return -1
    }
    lappend _songs $obj
    return 0
}


# songs()
#   get list of song objects belonging to this object
#   PARAMS
#       none
#   RETURNS:
#       on success, a list
itcl::body AWController::songs {} {
    return $_songs
}


# type()
#   AW backup type the session was initialized with
#   PARAMS
#       none
#   RETURNS:
#       AW4416, AW2816, or AW16G
itcl::body AWController::type {} {
    return $_ftype
}


# add_file()
#   add AWFile object to this session
#   PARAMS
#       an AWFile object
#   RETURNS:
#       0 on success, non-zero on failure
itcl::body AWController::add_file {obj} {
    set err {}
    
    if {! [info exists _files] || $_files == ""} {
        # first file added to our session
        if {[$obj index] != 0} {
            set err "MESSAGE: First backup file must be index 0"
            puts $err
            log_msg $err
            flush stdout
            return -1
        }
        set _current [$obj info variable this -value]
        lappend _files [$obj info variable this -value]  
        set _ftype [$obj type]
    } else {
        if {[$obj type] != $_ftype} {
            set err "MESSAGE: backup type is different from previous file"
            puts $err
            log_msg $err
            flush stdout
            return -1
        }
        
        # don't archive this obj if it's one we already know about.
        set _current {}
        foreach awfile $_files {
            if {[$obj index] == [$awfile index]} {
                # already exists!
                set _current $awfile
                itcl::delete object $obj
                break
            }        
        }
        if {$_current == ""} {
            set _current [$obj info variable this -value]
            lappend _files [$obj info variable this -value]
        }
    }  
    
    set _fh [open [$_current path] r]
    fconfigure $_fh -translation binary    
        
    return 0
}


# current_handle()
#   get the currently open filehandle (channel)
#   PARAMS
#       none
#   RETURNS:
#       an open channel name
itcl::body AWController::current_handle {} {
    return $_fh
}


# current_file_object()
#   get the currently in-use AWFile object
#   PARAMS
#       none
#   RETURNS:
#       an AWFile object
itcl::body AWController::current_file_object {} {
    return $_current
}



####  AWController Definition END  ####
