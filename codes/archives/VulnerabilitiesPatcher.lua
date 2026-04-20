getgenv().Vuln_Patcher = {
    Print = false,
    Writefile = false,
    Readfile = false,
    Error = false,
    Warn = false,
    Loadfile = false
}

local xx = getgenv().Vuln_Patcher

local function antiPrint(...)
    local info = debug.getinfo(2)
    if info and info.what == 'Lua' and info.func == print then
        return
    end
end

if xx.Print then
    print = antiPrint
end

if xx.Writefile then
    writefile = antiPrint
end

if xx.Readfile then
    readfile = antiPrint
end

if xx.Loadfile then
    loadfile = antiPrint
end

if xx.Error then
    error = antiPrint
end

if xx.Warn then
    warn = antiPrint
end