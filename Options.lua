local _, env = ...

ModularCore.defaults = {
    profile = {
        message = "Test",
    },
}

ModularCore.options = { 
	name = "NeebelCDM",
	handler = ModularCore,
	type = "group",
	args = {
        general= {
            type = "group",
            name = "General",
            order = 1,
            args = {
                msg = {
                    type = "input",
                    name = "Message",
                    desc = "The message to be displayed when you get home.",
                    usage = "<Your message>",
                    get = "GetMessage",
                    set = "SetMessage",
                },
            }
        },
	},
}

function ModularCore:GetMessage(info)
    return self.db.profile.message
end

function ModularCore:SetMessage(info, msg)
    self.db.profile.message = msg
end


function ModularCore:GetValue(info)
	return self.db.profile[info[#info]]
end

function ModularCore:SetValue(info, value)
	self.db.profile[info[#info]] = value
end