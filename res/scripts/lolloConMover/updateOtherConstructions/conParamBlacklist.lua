-- constructions will be blacklisted if they contain a parameter key matching the following
return {
    '(snowball_fences_)', -- these require fences, which tampers with result overriding updateFn() so they cannot be updated
}
