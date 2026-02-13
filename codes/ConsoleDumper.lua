local logHistory = game:GetService("LogService"):GetLogHistory()
local allMessages = ""

for _, logEntry in ipairs(logHistory) do
    local message = ""
    if logEntry.messageType == Enum.MessageType.MessageError then
        message = "- " .. logEntry.message
    elseif logEntry.messageType == Enum.MessageType.MessageWarning then
        message = "+ " .. logEntry.message
    else
        message = logEntry.message
    end
    if not table.find(previousMessages, message) then
        table.insert(previousMessages, message)
    end
        allMessages = allMessages .. message .. "\n"
end

writefile(identifyexecutor() .. ".txt", allMessages)