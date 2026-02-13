local old
local DeviceToSpoof = "Gamepad" -- Devices are: Mobile, Gamepad (Xbox), Keyboard

old = hookmetamethod(game,"__namecall",function(self,...)
   local args = {...}
   local method = getnamecallmethod()
   if method == "FireServer" then
       if tostring(self) == "deviceEvent" then
           args[1] = DeviceToSpoof
           return self.FireServer(self,unpack(args))
       end
   end
   return old(self,...)
end)