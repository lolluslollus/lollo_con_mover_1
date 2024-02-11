-- gmatches of construction file names to be blacklisted
return {
    '(/wk_[^(./)]+.con)', -- these require the models to be separated for some reason
    '(/nando_truck_set.con)', -- these are scripted
    '(/snowball_fence[^(./)]+.con)', -- these tamper with result overriding updateFn() so they cannot be updated
}
