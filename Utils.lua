local random = math.random

-- Generates a GUID based on: https://gist.github.com/jrus/3197011
---@return string guid
function GenerateGUID()
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    local guid, _ = string.gsub(template, "[xy]", function (c)
        local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
        return string.format("%x", v)
    end)
    return guid
end


QuestionMark = "Interface\\Icons\\INV_Misc_QuestionMark"
AddSign = 450907  --should be the + icon