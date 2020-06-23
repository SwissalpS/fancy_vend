
function fancy_vend.bts(bool)
    if bool == false then
        return "false"
    elseif bool == true then
        return "true"
    else
        return bool
    end
end

function fancy_vend.stb(str)
    if str == "false" then
        return false
    elseif str == "true" then
        return true
    else
        return str
    end
end
