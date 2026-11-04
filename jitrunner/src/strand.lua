-- Strand player programs (LuaJIT / editor-host dialect), shared verbatim.
local S = {}
S.stub = [=[
-- Strand repair: slug(s)
-- Trim s (the host's vim.trim), lower it, turn each space into a dash.
function slug(s)
    return s
end
]=]
S.solution = [=[
function slug(s)
    local t = vim.trim(s)
    t = t:lower()
    t = t:gsub(" ", "-")
    return t
end
]=]
S.runaway = [=[
function slug(s)
    return s
end
while true do
end
]=]
return S
