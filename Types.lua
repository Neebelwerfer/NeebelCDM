---@class Color
---@field r number
---@field g number
---@field b number
---@field a number

-- Normalized Color
---@param r number -- 0-1
---@param g number -- 0-1
---@param b number -- 0-1
---@param a? number -- 0-1
---@return Color
function Color(r, g, b, a)
    return {
        r = r,
        g = g,
        b = b,
        a = a or 1
    }
end

---@enum DataTypes
DataTypes = {
    Spell = 1,
    Item = 2,
    Aura = 3,
    Resource = 4,
    Unit = 5
}

---@enum GroupAxis
GroupAxis = {
    Vertical = 1,
    Horizontal = 2
}

---@enum GroupAnchorMode
GroupAnchorMode = {
    Leading = 1,
    Centered = 2,
    Trailing = 3
}