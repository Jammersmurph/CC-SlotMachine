-- CC-SlotMachine
-- Trigger: redstone input on right
-- Win output: redstone pulse on left

local INPUT_SIDE = "right"
local OUTPUT_SIDE = "left"

local SPIN_TIME = 2.5
local REEL_DELAY = 0.5
local WIN_PULSE_TIME = 1.0

local symbols = {
    {symbol = "7", color = colors.red},
    {symbol = "$", color = colors.lime},
    {symbol = "*", color = colors.yellow},
    {symbol = "O", color = colors.orange},
    {symbol = "#", color = colors.cyan}
}

local monitor = peripheral.find("monitor")
if not monitor then error("No monitor attached") end

monitor.setTextScale(1)
monitor.setBackgroundColor(colors.black)
monitor.clear()

local width, height = monitor.getSize()

local function centerText(y, text, textColor, backgroundColor)
    textColor = textColor or colors.white
    backgroundColor = backgroundColor or colors.black
    monitor.setTextColor(textColor)
    monitor.setBackgroundColor(backgroundColor)
    local x = math.floor((width - #text) / 2) + 1
    if x < 1 then x = 1 end
    monitor.setCursorPos(x, y)
    monitor.write(text)
end

local function fill(x, y, w, h, bg)
    monitor.setBackgroundColor(bg)
    for row = y, y + h - 1 do
        monitor.setCursorPos(x, row)
        monitor.write(string.rep(" ", w))
    end
end

local function drawMachine(reels, message, messageColor)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    centerText(2, "LUCKY SLOTS", colors.yellow)

    local reelWidth = 7
    local reelHeight = 5
    local spacing = 2
    local totalWidth = (reelWidth * 3) + (spacing * 2)
    local startX = math.floor((width - totalWidth) / 2) + 1
    local reelY = math.floor(height / 2) - 2

    for i = 1, 3 do
        local x = startX + ((i - 1) * (reelWidth + spacing))
        fill(x, reelY, reelWidth, reelHeight, colors.white)

        local s = reels[i]
        monitor.setBackgroundColor(colors.white)
        monitor.setTextColor(s.color)
        local sx = x + math.floor(reelWidth / 2)
        local sy = reelY + math.floor(reelHeight / 2)
        monitor.setCursorPos(sx, sy)
        monitor.write(s.symbol)
    end

    if message then
        centerText(height - 2, message, messageColor or colors.white)
    end
    monitor.setBackgroundColor(colors.black)
end

local function randomSymbol()
    return symbols[math.random(1, #symbols)]
end

local function spin()
    local reels = { randomSymbol(), randomSymbol(), randomSymbol() }

    local startTime = os.clock()
    while os.clock() - startTime < SPIN_TIME do
        reels[1] = randomSymbol()
        reels[2] = randomSymbol()
        reels[3] = randomSymbol()
        drawMachine(reels, "SPINNING...", colors.yellow)
        sleep(0.08)
    end

    reels[1] = randomSymbol()

    local stopTime = os.clock()
    while os.clock() - stopTime < REEL_DELAY do
        reels[2] = randomSymbol()
        reels[3] = randomSymbol()
        drawMachine(reels, "SPINNING...", colors.yellow)
        sleep(0.08)
    end

    reels[2] = randomSymbol()

    stopTime = os.clock()
    while os.clock() - stopTime < REEL_DELAY do
        reels[3] = randomSymbol()
        drawMachine(reels, "SPINNING...", colors.yellow)
        sleep(0.08)
    end

    reels[3] = randomSymbol()

    local win = reels[1].symbol == reels[2].symbol and reels[2].symbol == reels[3].symbol

    if win then
        drawMachine(reels, "*** WINNER! ***", colors.lime)
        redstone.setOutput(OUTPUT_SIDE, true)
        sleep(WIN_PULSE_TIME)
        redstone.setOutput(OUTPUT_SIDE, false)
    else
        drawMachine(reels, "BETTER LUCK NEXT TIME", colors.red)
    end
end

local function readyScreen()
    local reels = { symbols[1], symbols[1], symbols[1] }
    drawMachine(reels, "READY TO PLAY", colors.lime)
end

math.randomseed(os.epoch("utc"))
redstone.setOutput(OUTPUT_SIDE, false)
readyScreen()

while true do
    while not redstone.getInput(INPUT_SIDE) do
        os.pullEvent("redstone")
    end

    spin()

    while redstone.getInput(INPUT_SIDE) do
        os.pullEvent("redstone")
    end

    readyScreen()
end
