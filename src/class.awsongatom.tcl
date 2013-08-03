package provide AWSongAtom 1.0

package require Tcl 8.4
package require Itcl


# <<<<<<<<<<<<<<<<<<<< >>>>>>>>>>>>>>>>>>>> #
# <<                                     >> #
# <<      AWSongAtom Definition BEGIN    >> #
# <<                                     >> #
# <<<<<<<<<<<<<<<<<<<< >>>>>>>>>>>>>>>>>>>> #
itcl::class AWSongAtom {
    public variable id 0
    public variable parent {}
    public variable name {}
    public variable pointer 0
    public variable type {}
    
    method id {args}
    method parent {args}
    method name {args}
    method pointer {args}
    method type {args}
}

# id()
#   get/set the object id value.
#   PARAMS
#       set: a number
#   RETURNS:
#       on success, a number
#       on failure, NULL ("")
itcl::body AWSongAtom::id {args} {
    if {$args != ""} {
        set id [lindex $args 0]
    }
    return $id
}

# type()
#   get/set the object type value.
#   PARAMS
#       an object type (AW4416|AW2816|AW16G)
#   RETURNS:
#       on success, a string
#       on failure, NULL ("")
itcl::body AWSongAtom::type {args} {
    if {$args != ""} {
        set type [lindex $args 0]
    }
    return $type
}

# parent()
#   get/set the object's parent object.
#   PARAMS
#       set: an object name
#   RETURNS:
#       on success, an object name
#       on failure, NULL ("")
itcl::body AWSongAtom::parent {args} {
    if {$args != ""} {
        set parent [lindex $args 0]
    }
    return $parent
}

# name()
#   get/set the object name.
#   PARAMS
#       set: a name string
#   RETURNS:
#       on success, a string
#       on failure, NULL ("")
itcl::body AWSongAtom::name {args} {
    if {$args != ""} {
        set name [lindex $args 0]
    }
    return $name
}

# pointer()
#   get/set the value of the first track/region/frame pointer
#   that this object needs to fetch from.
#   PARAMS
#       set: a number
#   RETURNS:
#       on success, a number
#       on failure, NULL ("")
itcl::body AWSongAtom::pointer {args} {
    if {$args != ""} {
        set pointer [lindex $args 0]
    }
    return $pointer
}

####  AWSongAtom Definition END  ####
