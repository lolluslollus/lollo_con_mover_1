-- gmatches of construction file names to be blacklisted
-- LOLLO NOTE If I prepend a slash such as '(/wk_ they will work at game start but fail during the game.
return {
    '(wk_[^(./)]+.con)', -- these require the models to be separated for some reason
    '(zzwk_tram_mast[^(./)]+.con)', -- don't know these, I was told they are incompatible
    '(nando_truck_set.con)', -- these are scripted
    '(snowball_fence[^(./)]+.con)', -- these tamper with result overriding updateFn() so they cannot be updated
}
