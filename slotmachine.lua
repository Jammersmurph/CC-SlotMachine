-- CC-SlotMachine
-- Trigger: redstone input on right
-- Win output: redstone pulse on left

local INPUT_SIDE = "right"
local OUTPUT_SIDES = { "left", "top", "bottom" }

local SPIN_TIME = 2.5
local REEL_DELAY = 0.5
local WIN_DISPLAY_TIME = 10.0
local WIN_PULSE_TIME = 1.0

local symbols = {
    {symbol = "7", color = colors.red},
    {symbol = "$", color = colors.lime},
    {symbol = "*", color = colors.yellow},
    {symbol = "O", color = colors.orange},
    {symbol = "#", color = colors.cyan}
}

local lossMessages = {
    "Better luck next time!",
    "So close!",
    "Try again!",
    "Not this time!",
    "Almost had it!",
    "Maybe next spin!",
    "No jackpot today!",
    "The reels say no!",
    "Give it another shot!",
    "Close, but no prize!",
    "Lady Luck says nope!",
    "You'll get 'em next time!",
    "The house wins this one!",
    "One more spin?",
    "Ouch! So close!",
    "No luck this round!",
    "Better luck on the next one!",
    "Jackpot narrowly escaped!",
    "The jackpot lives another day!",
    "Nice try!",
    "Not quite!",
    "Maybe the next one's lucky!",
    "Fortune favors the next spin...",
    "Those reels were not feeling it.",
    "Denied by the reels!",
    "Your jackpot is in another machine!",
    "Three matching symbols? Apparently not.",
    "The machine remains undefeated.",
    "Luck.exe has stopped responding.",
    "Skill issue. Probably.",
    "The reels have spoken.",
    "No dice! Well... no slots.",
    "Jackpot says: maybe later.",
    "A valiant attempt!",
    "The odds strike again!",
    "Back to the button!",
    "Missed it by that much!",
    "Fortune took the day off.",
    "The jackpot dodged you!",
    "Next spin could be the one!"
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
        -- Keep the winning reels and WINNER message visible for 10 seconds
        -- before sending the payout signal.
        drawMachine(reels, "*** WINNER! ***", colors.lime)
        sleep(WIN_DISPLAY_TIME)

        for _, side in ipairs(OUTPUT_SIDES) do redstone.setOutput(side, true) end
        sleep(WIN_PULSE_TIME)
        for _, side in ipairs(OUTPUT_SIDES) do redstone.setOutput(side, false) end
    else
        local lossMessage = lossMessages[math.random(1, #lossMessages)]
        drawMachine(reels, lossMessage, colors.red)
        sleep(2)
    end
end

local function readyScreen()
    local reels = { symbols[1], symbols[2], symbols[3] }
    drawMachine(reels, "Press Button to play!", colors.lime)
end

math.randomseed(os.epoch("utc"))
for _, side in ipairs(OUTPUT_SIDES) do redstone.setOutput(side, false) end
readyScreen()

while true do
    while not redstone.getInput(INPUT_SIDE) do
        os.pullEvent("redstone")
    end

    spin()

    -- Do not allow the same held signal to trigger another round.
    while redstone.getInput(INPUT_SIDE) do
        os.pullEvent("redstone")
    end

    readyScreen()
end
