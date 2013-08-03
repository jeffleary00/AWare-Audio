package require Tcl 8.4
package require Itcl
package require AWSongAtom


# <<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>> #
# <<                                      >> #
# <<       AWTrack Definition BEGIN       >> #
# <<                                      >> #
# <<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>> #
itcl::class AWTrack {
    inherit AWSongAtom
    
    public variable start_sample -1
    public variable total_samples 0
    variable regions {}
    
    method start_sample {}
    method total_samples {}
    method start_time {}
    method total_time {}
    method add_region {obj}
    method region_count {}
    method regions {}
    private method time_from_samples {samples rate}
    
    constructor {args} {
        if {$args != ""} {
            eval configure $args
        }
    }
}

# start_sample()
#   get the starting sample value
#   PARAMS
#       none
#   RETURNS:
#       a number
itcl::body AWTrack::start_sample {} {
    return $start_sample
}

# total_samples()
#   get the total track samples
#   PARAMS
#       none
#   RETURNS:
#       a number
itcl::body AWTrack::total_samples {} {
    return $total_samples
}

# start_time()
#   get the starting sample time
#   PARAMS
#       none
#   RETURNS:
#       a formatted string
itcl::body AWTrack::start_time {} {
    return [time_from_samples $start_sample [$parent rate]]
}

# total_time()
#   get the total sample time
#   PARAMS
#       none
#   RETURNS:
#       a formatted string
itcl::body AWTrack::total_time {} {
    return [time_from_samples $total_samples [$parent rate]]
}

# time_from_samples()
#   returns a formatted HH:MM:SS time
#   PARAMS
#       number of samples
#       sample rate
#   RETURNS:
#       a formatted string
itcl::body AWTrack::time_from_samples {samples rate} {
    set seconds [expr ($samples/$rate)]
	set minutes 0
	set hours 0
					
	if {[expr ($seconds/3600)] >= 1} {
		set hours [expr ($seconds/3600)]
		set seconds [expr ($seconds % 3600)]
    }
    
	if {[expr ($seconds/60)] >= 1} {
		set minutes [expr ($seconds/60)]
		set seconds [expr ($seconds % 60)]
    }

	return [format "%02d:%02d:%02d" $hours $minutes $seconds]
}

# add_region()
#   add an AWRegion object to the track
#   PARAMS
#       an object name
#   RETURNS:
#       on success, 0
#       on failure, non-zero
itcl::body AWTrack::add_region {obj} {
    if {[$obj parent $this] == ""} {
        puts stderr "Failure adding parent to track. aborting."
        return -1
    }
    
    # recalculate the track samples based
    # on the contents of the region.
    if {$start_sample == -1} {
        set start_sample [$obj start_sample]    
    }
    set total_samples [expr ([$obj start_sample] - ($start_sample + $total_samples)) + [$obj total_samples]]
    lappend regions $obj
    
    return 0
}

# region_count()
#   number of AWRegion objects belonging to the track
#   PARAMS
#       none
#   RETURNS:
#       a number
itcl::body AWTrack::region_count {} {
   return [llength $regions]
}

# regions()
#   get list of region objects belonging to this track
#   PARAMS
#       none
#   RETURNS:
#       a list
itcl::body AWTrack::regions {} {
    return $regions
}

####  AWTrack Definition END  ####
