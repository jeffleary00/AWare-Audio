package require Tcl 8.4
package require Itcl


# <<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>> #
# <<                                      >> #
# <<       AWFile Definition BEGIN        >> #
# <<                                      >> #
# <<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>> #

itcl::class AWFile {
    public variable path
    public variable index
    public variable type
    public variable bytes
    public variable max_frames 5621
    public variable offset_frames
    public variable previous_frames
    public variable song_count 0
    
    method path {}
    method index {}
    method type {}
    method bytes {}
    method max_frames {}
    method offset_frames {}
    method previous_frames {}
    method song_count {}
    
    constructor {args} {
        if {$args != ""} {
            eval configure $args
        }
    }
    destructor {
	    
    }
}

# path()
#   return the path to the file
#   PARAMS
#       none
#   RETURNS:
#       a path file name
itcl::body AWFile::path {} { 
    return $path
}

# index()
#   return the index id of the file
#   PARAMS
#       none
#   RETURNS:
#       a number
itcl::body AWFile::index {} { 
    return $index
}

# type()
#   return the backup type of the file
#   PARAMS
#       none
#   RETURNS:
#       AW4416, AW2816, or AW16G
itcl::body AWFile::type {} { 
    return $type
}

# bytes()
#   return the size of the backup file
#   PARAMS
#       none
#   RETURNS:
#       a number
itcl::body AWFile::bytes {} { 
    return $bytes
}

# max_frames()
#   return the max audio frames of the file
#   PARAMS
#       none
#   RETURNS:
#       a number
itcl::body AWFile::max_frames {} { 
    return $max_frames
}

# offset_frames()
#   return the offset audio frames of the file
#   PARAMS
#       none
#   RETURNS:
#       a number
itcl::body AWFile::offset_frames {} { 
    return $offset_frames
}

# previous_frames()
#   return the previous audio frames of the file
#   PARAMS
#       none
#   RETURNS:
#       a number
itcl::body AWFile::previous_frames {} { 
    return $previous_frames
}

# song count()
#   return the number of songs found in a backup file
#   PARAMS
#       none
#   RETURNS:
#       a number
itcl::body AWFile::song_count {} { 
    return $song_count
}
####  AWFile Definition END  ####

