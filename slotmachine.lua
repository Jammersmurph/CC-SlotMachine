-- CC-SlotMachine
-- Trigger: redstone input on right
-- Win output: redstone pulse on left

local INPUT_SIDE = "right"
local OUTPUT_SIDES = { "left", "top" }
local BUSY_SIDE = "bottom"

local SPIN_TIME = 2.5
local REEL_DELAY = 0.5
local WIN_DISPLAY_TIME = 3.0
local WIN_PULSE_ON_TIME = 0.5
local WIN_PULSE_OFF_TIME = 0.5

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

-- Speaker is optional. The slot machine works normally without one.
local speaker = peripheral.find("speaker")

local function playNote(instrument, volume, pitch)
    if speaker then
        speaker.playNote(instrument, volume, pitch)
    end
end

local function playSpinTick()
    playNote("hat", 0.5, math.random(8, 16))
end

local function playReelStop(reel)
    playNote("basedrum", 1.0, 6 + (reel * 2))
end

local function playLossSound()
    if not speaker then return end
    playNote("bass", 1.0, 10)
    sleep(0.15)
    playNote("bass", 1.0, 7)
    sleep(0.15)
    playNote("bass", 1.0, 4)
end

local function playJackpotFanfare()
    if not speaker then return end
    local notes = { 8, 12, 15, 20, 15, 20, 24 }
    for _, pitch in ipairs(notes) do
        playNote("bell", 1.5, pitch)
        sleep(0.16)
    end
end

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

local function pulsePayout(count)
    for pulse = 1, count do
        for _, side in ipairs(OUTPUT_SIDES) do
            redstone.setOutput(side, true)
        end
        sleep(WIN_PULSE_ON_TIME)

        for _, side in ipairs(OUTPUT_SIDES) do
            redstone.setOutput(side, false)
        end

        if pulse < count then
            sleep(WIN_PULSE_OFF_TIME)
        end
    end
end

local function spin()
    local reels = { randomSymbol(), randomSymbol(), randomSymbol() }

    -- Decide the outcome independently of the animation:
    -- 1% Mega Jackpot, 5% regular Jackpot, 25% Redo/refund, 69% loss.
    local outcomeRoll = math.random(1, 100)
    local megaJackpot = outcomeRoll == 1
    local jackpot = outcomeRoll >= 2 and outcomeRoll <= 6
    local redo = outcomeRoll >= 7 and outcomeRoll <= 31

    local startTime = os.clock()
    while os.clock() - startTime < SPIN_TIME do
        reels[1] = randomSymbol()
        reels[2] = randomSymbol()
        reels[3] = randomSymbol()
        drawMachine(reels, "SPINNING...", colors.yellow)
        playSpinTick()
        sleep(0.08)
    end

    reels[1] = randomSymbol()
    playReelStop(1)

    local stopTime = os.clock()
    while os.clock() - stopTime < REEL_DELAY do
        reels[2] = randomSymbol()
        reels[3] = randomSymbol()
        drawMachine(reels, "SPINNING...", colors.yellow)
        playSpinTick()
        sleep(0.08)
    end

    reels[2] = randomSymbol()
    playReelStop(2)

    stopTime = os.clock()
    while os.clock() - stopTime < REEL_DELAY do
        reels[3] = randomSymbol()
        drawMachine(reels, "SPINNING...", colors.yellow)
        playSpinTick()
        sleep(0.08)
    end

    -- Force the displayed final reels to match the pre-selected outcome.
    if megaJackpot then
        reels = { symbols[1], symbols[1], symbols[1] } -- 777
    elseif jackpot then
        local winningSymbol = symbols[math.random(2, #symbols)]
        reels = { winningSymbol, winningSymbol, winningSymbol }
    elseif redo then
        -- Keep REDO visually distinct from a jackpot and from an accidental triple.
        repeat
            reels = { randomSymbol(), randomSymbol(), randomSymbol() }
        until not (reels[1].symbol == reels[2].symbol and reels[2].symbol == reels[3].symbol)
    else
        -- A loss must never accidentally display three matching symbols.
        repeat
            reels[3] = randomSymbol()
        until not (reels[1].symbol == reels[2].symbol and reels[2].symbol == reels[3].symbol)
    end
    playReelStop(3)

    if megaJackpot or jackpot then
        local payoutPulses = megaJackpot and 30 or 20

        if megaJackpot then
            drawMachine(reels, "*** MEGA JACKPOT! ***", colors.yellow)
        else
            drawMachine(reels, "*** WINNER! ***", colors.lime)
        end

        playJackpotFanfare()
        sleep(math.max(0, WIN_DISPLAY_TIME - 1.12))
        pulsePayout(payoutPulses)
    elseif redo then
        drawMachine(reels, "*** REDO! PLAY AGAIN! ***", colors.cyan)
        playNote("bell", 1.0, 12)
        sleep(0.15)
        playNote("bell", 1.0, 16)
        sleep(math.max(0, WIN_DISPLAY_TIME - 0.15))

        -- Refund the 5-pulse price to play.
        pulsePayout(5)
    else
        local lossMessage = lossMessages[math.random(1, #lossMessages)]
        drawMachine(reels, lossMessage, colors.red)
        playLossSound()
        sleep(1.55)
    end
end

local attractFrames = {
    { symbols[1], symbols[2], symbols[3] },
    { symbols[2], symbols[3], symbols[4] },
    { symbols[3], symbols[4], symbols[5] },
    { symbols[4], symbols[5], symbols[1] },
    { symbols[5], symbols[1], symbols[2] }
}

local function drawScreensaver(frame)
    local reels = attractFrames[((frame - 1) % #attractFrames) + 1]

    monitor.setBackgroundColor(colors.black)
    monitor.clear()

    -- Animated marquee border.
    local borderColors = { colors.yellow, colors.orange, colors.red, colors.lime, colors.cyan }
    local borderColor = borderColors[((frame - 1) % #borderColors) + 1]
    monitor.setBackgroundColor(borderColor)
    monitor.setTextColor(colors.black)
    monitor.setCursorPos(1, 1)
    monitor.write(string.rep(" ", width))
    monitor.setCursorPos(1, height)
    monitor.write(string.rep(" ", width))

    centerText(2, "*** LUCKY SLOTS ***", colors.yellow)
    centerText(3, "5 SPURS PER PLAY", colors.white)

    -- Main animated reels.
    local reelWidth = 7
    local reelHeight = 5
    local spacing = 2
    local totalWidth = (reelWidth * 3) + (spacing * 2)
    local startX = math.floor((width - totalWidth) / 2) + 1
    local reelY = math.max(5, math.floor(height / 2) - 2)

    for i = 1, 3 do
        local x = startX + ((i - 1) * (reelWidth + spacing))
        fill(x, reelY, reelWidth, reelHeight, colors.white)
        local s = reels[i]
        monitor.setBackgroundColor(colors.white)
        monitor.setTextColor(s.color)
        monitor.setCursorPos(x + math.floor(reelWidth / 2), reelY + math.floor(reelHeight / 2))
        monitor.write(s.symbol)
    end

    -- Prize information when there is enough vertical room.
    if height >= 17 then
        centerText(height - 6, "PRIZES & ODDS", colors.white)
        centerText(height - 5, "MEGA 1% - 30", colors.yellow)
        centerText(height - 4, "JACKPOT 5% - 20", colors.lime)
        centerText(height - 3, "REDO 25% - 5", colors.cyan)
    elseif height >= 16 then
        centerText(height - 5, "MEGA 1%/30  JACKPOT 5%/20", colors.yellow)
        centerText(height - 4, "REDO 25%/5", colors.cyan)
    end

    local blinkColor = (frame % 2 == 0) and colors.lime or colors.white
    centerText(height - 2, "Press Button to play!", blinkColor)
    monitor.setBackgroundColor(colors.black)
end

local function waitForPlay()
    local frame = 1

    while not redstone.getInput(INPUT_SIDE) do
        drawScreensaver(frame)
        frame = frame + 1

        local timer = os.startTimer(0.45)
        while true do
            local event, id = os.pullEvent()
            if event == "redstone" and redstone.getInput(INPUT_SIDE) then
                return
            elseif event == "timer" and id == timer then
                break
            end
        end
    end
end

math.randomseed(os.epoch("utc"))
for _, side in ipairs(OUTPUT_SIDES) do redstone.setOutput(side, false) end
redstone.setOutput(BUSY_SIDE, false)

while true do
    -- Animated attract mode runs until the play signal arrives.
    waitForPlay()

    -- Lock payment immediately when a valid play begins.
    -- Bottom remains continuously powered for the entire game,
    -- including the result screen and any payout pulses.
    redstone.setOutput(BUSY_SIDE, true)

    spin()

    -- Do not allow the same held signal to trigger another round.
    while redstone.getInput(INPUT_SIDE) do
        os.pullEvent("redstone")
    end

    -- The machine can accept payment again only after the round is fully over.
    redstone.setOutput(BUSY_SIDE, false)
end
