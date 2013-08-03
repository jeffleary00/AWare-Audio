package require Tcl 8.4
package require Itcl
package require AWSongAtom


# <<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>> #
# <<                                      >> #
# <<        AWSong Definition BEGIN       >> #
# <<                                      >> #
# <<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>> #
itcl::class AWSong {
    inherit AWSongAtom
    
    public variable location 0
    public variable offset 0
    public variable bits 16
    public variable rate 44100
    public variable date 0
    public variable description "None"
    variable tracks {}
    
    method bits {args}
    method rate {args}
    method location {args}
    method offset {args}
    method add_track {obj}
    method track_count {}
    method tracks {}    
    method date {args}
    method description {args}
    constructor {args} {
        if {$args != ""} {
            eval configure $args
        }
        if {$bits != 16 && $bits != 24} {
            error "invalid bit depth: $bits"
        }
        if {$rate != 44100 && $rate != 48000} {
            error "invalid sample rate: $rate"
        }
    }
}


# bits()
#   get/set the song bit-depth (16 or 24).
#   PARAMS
#       set: a number
#   RETURNS:
#       on success, a number
#       on failure, NULL ("")
itcl::body AWSong::bits {args} {
    if {$args != ""} {
        set val [lindex $args 0]
        if {$val == 16 || $val == 24} {
            set bits $val
        } else {
            error "invalid bit depth: $val"
            return ""
        }
    }
    return $bits
}


# rate()
#   get/set the song sample rate (44100 or 48000).
#   PARAMS
#       set: a number
#   RETURNS:
#       on success, a number
#       on failure, NULL ("")
itcl::body AWSong::rate {args} {
    if {$args != ""} {
        set val [lindex $args 0]
        if {$val == 44100 || $val == 48000} {
            set rate $val
        } else {
            error "invalid sample rate: $val"
        }
    }
    return $rate
}


# location()
#   get/set the song location.
#   PARAMS
#       set: a number
#   RETURNS:
#       on success, a number
#       on failure, NULL ("")
itcl::body AWSong::location {args} {
    if {$args != ""} {
        set location [lindex $args 0]
    }
    return $location
}


# offset()
#   get/set the song offset value.
#   PARAMS
#       set: a number
#   RETURNS:
#       on success, a number
#       on failure, NULL ("")
itcl::body AWSong::offset {args} {
    if {$args != ""} {
        set offset [lindex $args 0]
    }
    return $offset
}


# date()
#   get/set the song save-date.
#   only valid for 4416/2816 backups.
#   PARAMS
#       set: a date string
#   RETURNS:
#       on success, a string
#       on failure, NULL ("")
itcl::body AWSong::date {args} {
    if {$args != ""} {
        set date [lindex $args 0]
    }
    return $date
}


# description()
#   get/set the song description.
#   only valid for 4416/2816 backups.
#   PARAMS
#       set: a string
#   RETURNS:
#       on success, a string
#       on failure, NULL ("")
itcl::body AWSong::description {args} {
    if {$args != ""} {
        set description [lindex $args 0]
    }
    return $description
}


# add_track()
#   add an Track object to the song.
#   PARAMS
#       set: an object name
#   RETURNS:
#       on success, 0
#       on failure, non-zero
itcl::body AWSong::add_track {obj} {
    if {[$obj parent $this] == ""} {
        return -1
    }
    lappend tracks $obj
    return 0
}


# tracks()
#   return the list of track objects belonging to
#   this song.
#   PARAMS
#       none
#   RETURNS:
#       a list
itcl::body AWSong::tracks {} {
    return $tracks
}


# track_count()
#   return the number of track objects belonging to
#   this song.
#   PARAMS
#       none
#   RETURNS:
#       a number
itcl::body AWSong::track_count {} {
    return [llength $tracks]
}

####  AWSong Definition END  ####

