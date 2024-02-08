package.path = package.path .. ';res/scripts/?.lua'

local isFound = false
local fileName = 'aaa/wk_mrkx_delete_edges.con'
-- for match in string.gmatch(fileName, '(%/wk_[^(%.%/)]+%.con)') do
for match in string.gmatch(fileName, '(/wk_[^(./)]+.con)') do
    isFound = true
end

local ttt = 123
