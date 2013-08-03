package require Tcl 8.4
package require Itcl
package require AWSongAtom


# <<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>> #
# <<                                      >> #
# <<       AWRegion Definition BEGIN      >> #
# <<                                      >> #
# <<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>> #
itcl::class AWRegion {
    inherit AWSongAtom
    
    public variable start_sample 0
    public variable total_samples 0
    public variable offset_samples 0
    public variable next_region 0
    variable frames {}
    
    method start_sample {args}
    method total_samples {args}
    method offset_samples {args}
    method add_frame {val}
    method frame_count {}
    method frames {}
    method next_region {}
    constructor {args} {
        if {$args != ""} {
            eval configure $args
        }
    }
}

# start_sample()
#   set/get the starting sample value
#   PARAMS
#       set: a starting sample
#   RETURNS:
#       on success, a number
#       on failure, NULL ("")
itcl::body AWRegion::start_sample {args} {
    if {$args != ""} {
        set start_sample [lindex $args 0]
    }
    return $start_sample
}

# total_samples()
#   set/get the total sample value
#   PARAMS
#       set: a number
#   RETURNS:
#       on success, a number
#       on failure, NULL ("")
itcl::body AWRegion::total_samples {args} {
    if {$args != ""} {
        set total_samples [lindex $args 0]
    }
    return $total_samples
}

# offset_samples()
#   set/get the offset sample value
#   PARAMS
#       set: a number
#   RETURNS:
#       on success, a number
#       on failure, NULL ("")
itcl::body AWRegion::offset_samples {args} {
    if {$args != ""} {
        set offset_samples [lindex $args 0]
    }
    return $offset_samples
}

# add_frame()
#   add a frame value to the AWRegion
#   PARAMS
#       set: a number
#   RETURNS:
#       on success 0
#       on failure non-zero
itcl::body AWRegion::add_frame {val} {
    lappend frames $val
    return 0
}

# frame_count()
#   number of frames belonging to this AWRegion
#   PARAMS
#       none
#   RETURNS:
#       a number
itcl::body AWRegion::frame_count {} {
    return [llength $frames]
}

# frames()
#   get list of frames owned by this AWRegion
#   PARAMS
#       none
#   RETURNS:
#       a list
itcl::body AWRegion::frames {} {
    return $frames
}

# next_region()
#   get pointer value to next AWRegion
#   PARAMS
#       none
#   RETURNS:
#       a number (-1 means no next AWRegion)
itcl::body AWRegion::next_region {} {
    return $next_region
}

####  AWRegion Definition END  ####
