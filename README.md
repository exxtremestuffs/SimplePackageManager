# SimplePackage

A runtime package manager designed for compatible GitHub repositories.

```lua
local sp = loadstring(game:HttpGet("https://raw.githubusercontent.com/SimplePackageManager/master/init.lua"))()
    :setCurrentProject("exxtremestuffs/SimplePackage")

local packageName = sp:import("exxtremestuffs/packageName")

local privateModule = sp:require("moduleName")

...
```
