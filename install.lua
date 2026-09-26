local url = "https://raw.githubusercontent.com/Jammersmurph/CC-SlotMachine/main/slotmachine.lua"

local response = http.get(url)
if not response then error("Failed to download slotmachine.lua") end

local data = response.readAll()
response.close()

local f = fs.open("startup.lua", "w")
f.write(data)
f.close()

print("CC-SlotMachine installed/updated successfully.")
print("Saved as startup.lua")
print("Reboot the computer to start it.")
