-- The chronicle as a file: one portable single file, canonical
-- serialization (keys sorted at every depth, so the same state is
-- the same bytes on every machine), a checksum line, and a loader
-- that trusts nothing — a save that does not verify is not a save,
-- and the game starts honestly blank rather than limping.
local Gate = require("gate")

local SAVE_MAX_BYTES = 1048576

local function escape_string(s)
    return string.format("%q", s)
end

local function serialize_value(v, out)
    local t = type(v)
    if t == "string" then
        out[#out + 1] = escape_string(v)
    elseif t == "number" then
        if math.type(v) == "integer" then
            out[#out + 1] = string.format("%d", v)
        else
            out[#out + 1] = tostring(v)
        end
    elseif t == "boolean" then
        out[#out + 1] = tostring(v)
    elseif t == "table" then
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        out[#out + 1] = "{"
        for _, k in ipairs(keys) do
            out[#out + 1] = "["
            serialize_value(k, out)
            out[#out + 1] = "]="
            serialize_value(v[k], out)
            out[#out + 1] = ","
        end
        out[#out + 1] = "}"
    else
        error("unsavable value of type " .. t, 0)
    end
end

local function serialize(state)
    local out = {}
    serialize_value(state, out)
    local body = "return " .. table.concat(out) .. "\n"
    return "VERSEMEND-SAVE 1\n" .. body
        .. "checksum " .. Gate.checksum(body) .. "\n"
end

local function parse(text)
    if type(text) ~= "string" then return nil, "no save" end
    if #text > SAVE_MAX_BYTES then return nil, "save too large" end
    local header, body, sum = text:match(
        "^(VERSEMEND%-SAVE 1)\n(.-)\nchecksum (%x+)\n$")
    if not header then return nil, "save shape not recognized" end
    local body_with_nl = body .. "\n"
    if Gate.checksum(body_with_nl) ~= sum then
        return nil, "save checksum mismatch"
    end
    local chunk = load(body_with_nl, "save", "t", {})
    if not chunk then return nil, "save does not load" end
    local ok, state = pcall(chunk)
    if not ok or type(state) ~= "table" then
        return nil, "save is not a chronicle"
    end
    if state.version ~= 1 then return nil, "save version unknown" end
    return state
end

local function fresh()
    return {
        version = 1,
        seen_arrival = false,
        motion_chosen = false,
        sealed = {},
        boss_act1 = false,
        boss_done = false,
        drafts = {},
        hints_used = {},
        settings = { motion = "full" },
    }
end

local M = {
    serialize = serialize,
    parse = parse,
    fresh = fresh,
    MAX_BYTES = SAVE_MAX_BYTES,
}
return M
