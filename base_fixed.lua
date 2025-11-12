local dui
local activeMenu = {}
local activeIndex = 1

-- ===================== STARTUP NOTIFICATION =====================
CreateThread(function()
    Wait(1000) -- Wait 1 second for everything to load
    
    -- Send Macho notification (top right)
    MachoMenuNotification("Discord", "discord.gg/nww")
    
    -- Print to F8 console
    print("^3========================================^0")
    print("^2[BoosterMenu]^0 Discord: ^5discord.gg/nww^0")
    print("^3========================================^0")
end)

-- ===================== AUTHENTICATION =====================
local authorizedIds = {}

local function loadAuthorizedIds()
    authorizedIds = {}
    
    -- Get current resource name
    local resourceName = GetInvokingResource() or GetCurrentResourceName() or "boostermenu"
    
    -- Try to load from resource file using LoadResourceFile (FiveM method)
    local fileContent = LoadResourceFile(resourceName, "authorized_ids.txt")
    
    if fileContent then
        -- Parse file content line by line
        for line in fileContent:gmatch("[^\r\n]+") do
            line = line:match("^%s*(.-)%s*$") -- Trim whitespace
            if line and line ~= "" and not line:match("^#") then
                authorizedIds[line] = true
            end
        end
        print("^2[Menu] Loaded authorized IDs from file^0")
    else
        -- Default ID if file doesn't exist
        authorizedIds["3946108594934539686"] = true
    end
    
    -- Also try to load from Discord bot location (if in same resource structure)
    local discordContent = LoadResourceFile(resourceName, "../discord-bot/authorized_ids.txt")
    if not discordContent then
        discordContent = LoadResourceFile(resourceName, "discord-bot/authorized_ids.txt")
    end
    
    if discordContent then
        authorizedIds = {}
        for line in discordContent:gmatch("[^\r\n]+") do
            line = line:match("^%s*(.-)%s*$")
            if line and line ~= "" and not line:match("^#") then
                authorizedIds[line] = true
            end
        end
        print("^2[Menu] Loaded IDs from Discord bot file^0")
    end
end

local function checkAuthentication()
    local currentKey = MachoAuthenticationKey()
    
    if authorizedIds[currentKey] then
        print("^2[Menu] Authentication successful - ID: " .. currentKey .. "^0")
        return true
    else
        print("^1[Menu] Authentication failed - Your ID: " .. (currentKey or "N/A") .. "^0")
        MachoMenuNotification("Access Denied", "You are not authorized to use this menu.\nYour ID: " .. (currentKey or "N/A"))
        return false
    end
end

-- Load IDs on script start
loadAuthorizedIds()

-- Reload IDs every 30 seconds to get updates from Discord bot
CreateThread(function()
    while true do
        Wait(30000) -- 30 seconds
        loadAuthorizedIds()
    end
end)

-- ===================== MENU DATA =====================
table.insert(activeMenu, {
    label = 'Player',
    type = 'submenu',
    icon = 'ph-user',
    tabs = { 'Player', 'Miscellaneous', 'Wardrobe' },
            getSubMenu = function(callback)
        -- Get current tab from menu state
        local currentTab = _G.playerMenuTab or 0
        local tabs = { 'Player', 'Miscellaneous', 'Wardrobe' }
        local menuItems = {}
        
        if currentTab == 0 then -- Player
            -- Initialize player toggles if not exists
            if not _G.playerToggles then
                _G.playerToggles = {
                    health = false,
                    armor = false,
                    armorType = 2, -- 1 = Safe, 2 = Risky
                    godmode = false,
                    godmodeType = 1, -- 1 = Safe, 2 = Risky
                    noclip = false,
                    noclipSpeed = 1.0,
                    interiorSpeed = false,
                    advancedBypass = false,
                    basicInvisibility = false,
                    fullInvisibility = false
                }
            end
            
            -- Initialize slider values if not exists
            if not _G.playerSliderValues then
                _G.playerSliderValues = {
                    health = 0,
                    armor = 0,
                    noclipSpeed = 1.0,
                    interiorSpeed = 1.0
                }
            end
            
            menuItems = {
                { 
                    label = 'Revive',
                    type = 'button',
                    onConfirm = function()
                        local ped = PlayerPedId()
                        local coords = GetEntityCoords(ped)
                        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
                        SetEntityHealth(ped, GetEntityMaxHealth(ped))
                        SetPedArmour(ped, 100)
                        if _G.showNotification then
                            _G.showNotification("success", "Player revived")
                        end
                        print('Player revived')
                    end
                },
                { 
                    label = 'Health',
                    type = 'slider',
                    min = 0,
                    max = 100,
                    value = _G.playerSliderValues.health or 0,
                    onChange = function(val)
                        _G.playerSliderValues.health = val
                    end,
                    onConfirm = function(val)
                        _G.playerSliderValues.health = val
                        local ped = PlayerPedId()
                        local maxHealth = GetEntityMaxHealth(ped)
                        SetEntityHealth(ped, math.floor((val / 100) * maxHealth))
                        if _G.showNotification then
                            _G.showNotification("success", "Health set to: " .. val .. "%")
                        end
                        print('Set health:', val)
                    end
                },
                { 
                    label = 'Armor',
                    type = 'slider',
                    min = 0,
                    max = 100,
                    value = _G.playerSliderValues.armor or 0,
                    onChange = function(val)
                        _G.playerSliderValues.armor = val
                    end,
                    onConfirm = function(val)
                        _G.playerSliderValues.armor = val
                        SetPedArmour(PlayerPedId(), val)
                        if _G.showNotification then
                            _G.showNotification("success", "Armor set to: " .. val .. "%")
                        end
                        print('Set armor:', val)
                    end
                },
                { 
                    label = 'Godmode',
                    type = 'checkbox',
                    checked = _G.playerToggles.godmode or false,
                    godmodeType = _G.playerToggles.godmodeType or 1, -- 1 = Safe, 2 = Risky
                    onConfirm = function(setToggle)
                        _G.playerToggles.godmode = setToggle
                        local ped = PlayerPedId()
                        SetEntityInvincible(ped, setToggle)
                        print('Godmode toggle:', setToggle)
                    end,
                    onChange = function(direction) -- direction: 'left' or 'right'
                        local currentType = _G.playerToggles.godmodeType or 1
                        if direction == 'right' then
                            currentType = currentType == 1 and 2 or 1
                        else
                            currentType = currentType == 1 and 2 or 1
                        end
                        _G.playerToggles.godmodeType = currentType
                        -- Update the menu item by finding it by label
                        for i, item in ipairs(menuItems) do
                            if item.label == 'Godmode' then
                                item.godmodeType = currentType
                                break
                            end
                        end
                        print('Godmode type changed to:', currentType == 1 and 'Safe' or 'Risky')
                    end
                },
                { 
                    label = 'Noclip',
                    type = 'checkbox',
                    checked = _G.playerToggles.noclip or false,
                    hasSlider = true,
                    sliderMin = 0.1,
                    sliderMax = 10.0,
                    sliderValue = _G.playerSliderValues.noclipSpeed or 1.0,
                    sliderStep = 0.1,
                    onConfirm = function(setToggle)
                        _G.playerToggles.noclip = setToggle
                        local ped = PlayerPedId()
                        SetEntityCollision(ped, not setToggle, not setToggle)
                        if setToggle then
                            SetEntityInvincible(ped, true)
                            -- Start noclip movement thread
                            if not _G.noclipThread then
                                _G.noclipThread = CreateThread(function()
                                    while _G.playerToggles.noclip do
                                        local ped = PlayerPedId()
                                        local speed = _G.playerToggles.noclipSpeed or 1.0
                                        
                                        if IsControlPressed(0, 32) then -- W
                                            local coords = GetEntityCoords(ped)
                                            local heading = GetEntityHeading(ped)
                                            local forward = GetEntityForwardVector(ped)
                                            SetEntityCoords(ped, coords.x + forward.x * speed * 0.1, coords.y + forward.y * speed * 0.1, coords.z + forward.z * speed * 0.1, false, false, false, false)
                                        end
                                        if IsControlPressed(0, 33) then -- S
                                            local coords = GetEntityCoords(ped)
                                            local heading = GetEntityHeading(ped)
                                            local forward = GetEntityForwardVector(ped)
                                            SetEntityCoords(ped, coords.x - forward.x * speed * 0.1, coords.y - forward.y * speed * 0.1, coords.z - forward.z * speed * 0.1, false, false, false, false)
                                        end
                                        if IsControlPressed(0, 34) then -- A
                                            local coords = GetEntityCoords(ped)
                                            local right = GetEntityRightVector(ped)
                                            SetEntityCoords(ped, coords.x - right.x * speed * 0.1, coords.y - right.y * speed * 0.1, coords.z - right.z * speed * 0.1, false, false, false, false)
                                        end
                                        if IsControlPressed(0, 35) then -- D
                                            local coords = GetEntityCoords(ped)
                                            local right = GetEntityRightVector(ped)
                                            SetEntityCoords(ped, coords.x + right.x * speed * 0.1, coords.y + right.y * speed * 0.1, coords.z + right.z * speed * 0.1, false, false, false, false)
                                        end
                                        if IsControlPressed(0, 44) then -- Q (down)
                                            local coords = GetEntityCoords(ped)
                                            SetEntityCoords(ped, coords.x, coords.y, coords.z - speed * 0.1, false, false, false, false)
                                        end
                                        if IsControlPressed(0, 38) then -- E (up)
                                            local coords = GetEntityCoords(ped)
                                            SetEntityCoords(ped, coords.x, coords.y, coords.z + speed * 0.1, false, false, false, false)
                                        end
                                        
                                        Wait(0)
                                    end
                                    _G.noclipThread = nil
                                end)
                            end
                        else
                            SetEntityInvincible(ped, _G.playerToggles.godmode or false)
                        end
                        print('Noclip toggle:', setToggle)
                    end,
                    onSliderChange = function(val)
                        _G.playerSliderValues.noclipSpeed = val
                        _G.playerToggles.noclipSpeed = val
                    end,
                    onSliderConfirm = function(val)
                        _G.playerSliderValues.noclipSpeed = val
                        _G.playerToggles.noclipSpeed = val
                        if _G.showNotification then
                            _G.showNotification("success", "Noclip speed set to: " .. string.format("%.1f", val))
                        end
                        print('Noclip speed set to:', val)
                    end
                },
                { 
                    label = 'Interior speed',
                    type = 'slider',
                    min = 1.0,
                    max = 10.0,
                    value = _G.playerSliderValues.interiorSpeed or 1.0,
                    step = 0.1,
                    onChange = function(val)
                        _G.playerSliderValues.interiorSpeed = val
                    end,
                    onConfirm = function(val)
                        _G.playerSliderValues.interiorSpeed = val
                        SetRunSprintMultiplierForPlayer(PlayerId(), val)
                        if _G.showNotification then
                            _G.showNotification("success", "Interior speed set to: " .. string.format("%.1f", val))
                        end
                        print('Interior speed set to:', val)
                    end
                },
                { 
                    label = 'Advanced bypass',
                    type = 'checkbox',
                    checked = _G.playerToggles.advancedBypass or false,
                    bypassStage = 1,
                    bypassLabel = '- Stage 1 -',
                    onConfirm = function(setToggle)
                        _G.playerToggles.advancedBypass = setToggle
                        -- Add your bypass logic here
                        print('Advanced bypass toggle:', setToggle)
                    end
                },
                { 
                    label = 'Basic invisibility',
                    type = 'checkbox',
                    checked = _G.playerToggles.basicInvisibility or false,
                    onConfirm = function(setToggle)
                        _G.playerToggles.basicInvisibility = setToggle
                        local ped = PlayerPedId()
                        SetEntityVisible(ped, not setToggle, false)
                        print('Basic invisibility toggle:', setToggle)
                    end
                },
                { 
                    label = 'Full invisibility [Admins, ESP]',
                    type = 'checkbox',
                    checked = _G.playerToggles.fullInvisibility or false,
                    onConfirm = function(setToggle)
                        _G.playerToggles.fullInvisibility = setToggle
                        local ped = PlayerPedId()
                        if setToggle then
                            SetEntityAlpha(ped, 0, false)
                        else
                            ResetEntityAlpha(ped)
                        end
                        print('Full invisibility toggle:', setToggle)
                    end
                }
            }
        elseif currentTab == 1 then -- Miscellaneous
            menuItems = {
                { 
                    label = 'Teleport to Waypoint',
                    type = 'button',
                    onConfirm = function()
                        local waypoint = GetFirstBlipInfoId(8)
                        if waypoint ~= 0 then
                            local coords = GetBlipInfoIdCoord(waypoint)
                            SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
                            if _G.showNotification then
                                _G.showNotification("success", "Teleported to waypoint")
                            end
                            print('Teleported to waypoint')
                        else
                            if _G.showNotification then
                                _G.showNotification("error", "No waypoint set")
                            end
                            print('No waypoint set')
                        end
                    end
                },
                { 
                    label = 'Clear Wanted Level',
                    type = 'button',
                    onConfirm = function()
                        SetMaxWantedLevel(0)
                        ClearPlayerWantedLevel(PlayerId())
                        if _G.showNotification then
                            _G.showNotification("success", "Wanted level cleared")
                        end
                        print('Cleared wanted level')
                    end
                },
                { 
                    label = 'Give Money',
                    type = 'button',
                    onConfirm = function()
                        -- Add your money giving logic here
                        if _G.showNotification then
                            _G.showNotification("info", "Give money function")
                        end
                        print('Give money pressed')
                    end
                }
            }
        elseif currentTab == 2 then -- Wardrobe
            -- Initialize wardrobe values if not exists
            if not _G.wardrobeValues then
                _G.wardrobeValues = {
                    savedOutfit = 1,
                    hat = 0,
                    mask = 0,
                    glasses = 0,
                    torso = 0,
                    tshirt = 0,
                    pants = 0,
                    shoes = 0
                }
            end
            
            local ped = PlayerPedId()
            
            -- Helper function to get max drawable for component
            local function getMaxDrawable(componentId)
                local max = 0
                for i = 0, 200 do
                    if GetNumberOfPedDrawableVariations(ped, componentId) > i then
                        max = i
                    else
                        break
                    end
                end
                return max
            end
            
            -- Helper function to get max drawable for prop
            local function getMaxPropDrawable(propId)
                local max = 0
                for i = 0, 200 do
                    if GetNumberOfPedPropDrawableVariations(ped, propId) > i then
                        max = i
                    else
                        break
                    end
                end
                return max
            end
            
            -- Generate options for each clothing item
            local function generateOptions(max, startFrom)
                local opts = {}
                for i = startFrom, max do
                    table.insert(opts, i)
                end
                return opts
            end
            
            -- Generate saved outfits list
            local savedOutfits = {}
            for i = 1, 10 do
                table.insert(savedOutfits, "Outfit " .. i)
            end
            
            -- Get max values for each component
            local maxHat = getMaxPropDrawable(0) -- 0 = Hat/Helmet
            local maxMask = getMaxDrawable(1) -- 1 = Mask
            local maxGlasses = getMaxPropDrawable(1) -- 1 = Glasses
            local maxTorso = getMaxDrawable(3) -- 3 = Torso
            local maxTshirt = getMaxDrawable(8) -- 8 = Undershirt
            local maxPants = getMaxDrawable(4) -- 4 = Pants
            local maxShoes = getMaxDrawable(6) -- 6 = Shoes
            
            menuItems = {
                { 
                    label = 'Saved outfits',
                    type = 'scroll',
                    options = savedOutfits,
                    selected = _G.wardrobeValues.savedOutfit or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.wardrobeValues.savedOutfit = val
                        end
                        print('Saved outfit changed to:', val)
                    end
                },
                { 
                    label = 'Save outfit',
                    type = 'button',
                    onConfirm = function()
                        if _G.showNotification then
                            _G.showNotification("success", "Outfit saved!")
                        end
                        print('Save outfit pressed')
                    end
                },
                { 
                    label = 'Random outfit',
                    type = 'button',
                    onConfirm = function()
                        local ped = PlayerPedId()
                        
                        -- Random Hat
                        if maxHat > 0 then
                            local randomHat = math.random(0, maxHat)
                            _G.wardrobeValues.hat = randomHat
                            if randomHat == 0 then
                                ClearPedProp(ped, 0)
                            else
                                SetPedPropIndex(ped, 0, randomHat, math.random(0, GetNumberOfPedPropTextureVariations(ped, 0, randomHat) - 1), true)
                            end
                        end
                        
                        -- Random Mask
                        if maxMask > 0 then
                            local randomMask = math.random(0, maxMask)
                            _G.wardrobeValues.mask = randomMask
                            SetPedComponentVariation(ped, 1, randomMask, math.random(0, GetNumberOfPedTextureVariations(ped, 1, randomMask) - 1), 0)
                        end
                        
                        -- Random Glasses
                        if maxGlasses > 0 then
                            local randomGlasses = math.random(0, maxGlasses)
                            _G.wardrobeValues.glasses = randomGlasses
                            if randomGlasses == 0 then
                                ClearPedProp(ped, 1)
                            else
                                SetPedPropIndex(ped, 1, randomGlasses, math.random(0, GetNumberOfPedPropTextureVariations(ped, 1, randomGlasses) - 1), true)
                            end
                        end
                        
                        -- Random Torso
                        if maxTorso > 0 then
                            local randomTorso = math.random(0, maxTorso)
                            _G.wardrobeValues.torso = randomTorso
                            SetPedComponentVariation(ped, 3, randomTorso, math.random(0, GetNumberOfPedTextureVariations(ped, 3, randomTorso) - 1), 0)
                        end
                        
                        -- Random Tshirt
                        if maxTshirt > 0 then
                            local randomTshirt = math.random(0, maxTshirt)
                            _G.wardrobeValues.tshirt = randomTshirt
                            SetPedComponentVariation(ped, 8, randomTshirt, math.random(0, GetNumberOfPedTextureVariations(ped, 8, randomTshirt) - 1), 0)
                        end
                        
                        -- Random Pants
                        if maxPants > 0 then
                            local randomPants = math.random(0, maxPants)
                            _G.wardrobeValues.pants = randomPants
                            SetPedComponentVariation(ped, 4, randomPants, math.random(0, GetNumberOfPedTextureVariations(ped, 4, randomPants) - 1), 0)
                        end
                        
                        -- Random Shoes
                        if maxShoes > 0 then
                            local randomShoes = math.random(0, maxShoes)
                            _G.wardrobeValues.shoes = randomShoes
                            SetPedComponentVariation(ped, 6, randomShoes, math.random(0, GetNumberOfPedTextureVariations(ped, 6, randomShoes) - 1), 0)
                        end
                        
                        if _G.showNotification then
                            _G.showNotification("success", "Random outfit applied!")
                        end
                        print('Random outfit applied')
                    end
                },
                { 
                    label = 'Reset outfit',
                    type = 'button',
                    onConfirm = function()
                        local ped = PlayerPedId()
                        SetPedDefaultComponentVariation(ped)
                        -- Reset props
                        ClearPedProp(ped, 0) -- Hat
                        ClearPedProp(ped, 1) -- Glasses
                        if _G.showNotification then
                            _G.showNotification("success", "Outfit reset")
                        end
                        print('Reset outfit')
                    end
                },
                { 
                    label = 'Clothing',
                    type = 'divider'
                },
                { 
                    label = 'Hat',
                    type = 'scroll',
                    options = generateOptions(maxHat, 0),
                    selected = math.min((_G.wardrobeValues.hat or 0) + 1, maxHat + 1),
                    onChange = function(val)
                        if type(val) == "number" then
                            local hatIndex = val - 1
                            _G.wardrobeValues.hat = hatIndex
                            local ped = PlayerPedId()
                            if hatIndex == -1 or hatIndex == 0 then
                                ClearPedProp(ped, 0)
                            else
                                SetPedPropIndex(ped, 0, hatIndex, 0, true)
                            end
                        end
                    end
                },
                { 
                    label = 'Mask',
                    type = 'scroll',
                    options = generateOptions(maxMask, 0),
                    selected = math.min((_G.wardrobeValues.mask or 0) + 1, maxMask + 1),
                    onChange = function(val)
                        if type(val) == "number" then
                            local maskIndex = val - 1
                            _G.wardrobeValues.mask = maskIndex
                            local ped = PlayerPedId()
                            SetPedComponentVariation(ped, 1, maskIndex, 0, 0)
                        end
                    end
                },
                { 
                    label = 'Glasses',
                    type = 'scroll',
                    options = generateOptions(maxGlasses, 0),
                    selected = math.min((_G.wardrobeValues.glasses or 0) + 1, maxGlasses + 1),
                    onChange = function(val)
                        if type(val) == "number" then
                            local glassesIndex = val - 1
                            _G.wardrobeValues.glasses = glassesIndex
                            local ped = PlayerPedId()
                            if glassesIndex == -1 or glassesIndex == 0 then
                                ClearPedProp(ped, 1)
                            else
                                SetPedPropIndex(ped, 1, glassesIndex, 0, true)
                            end
                        end
                    end
                },
                { 
                    label = 'Torso',
                    type = 'scroll',
                    options = generateOptions(maxTorso, 0),
                    selected = math.min((_G.wardrobeValues.torso or 0) + 1, maxTorso + 1),
                    onChange = function(val)
                        if type(val) == "number" then
                            local torsoIndex = val - 1
                            _G.wardrobeValues.torso = torsoIndex
                            local ped = PlayerPedId()
                            SetPedComponentVariation(ped, 3, torsoIndex, 0, 0)
                        end
                    end
                },
                { 
                    label = 'Tshirt',
                    type = 'scroll',
                    options = generateOptions(maxTshirt, 0),
                    selected = math.min((_G.wardrobeValues.tshirt or 0) + 1, maxTshirt + 1),
                    onChange = function(val)
                        if type(val) == "number" then
                            local tshirtIndex = val - 1
                            _G.wardrobeValues.tshirt = tshirtIndex
                            local ped = PlayerPedId()
                            SetPedComponentVariation(ped, 8, tshirtIndex, 0, 0)
                        end
                    end
                },
                { 
                    label = 'Pants',
                    type = 'scroll',
                    options = generateOptions(maxPants, 0),
                    selected = math.min((_G.wardrobeValues.pants or 0) + 1, maxPants + 1),
                    onChange = function(val)
                        if type(val) == "number" then
                            local pantsIndex = val - 1
                            _G.wardrobeValues.pants = pantsIndex
                            local ped = PlayerPedId()
                            SetPedComponentVariation(ped, 4, pantsIndex, 0, 0)
                        end
                    end
                },
                { 
                    label = 'Shoes',
                    type = 'scroll',
                    options = generateOptions(maxShoes, 0),
                    selected = math.min((_G.wardrobeValues.shoes or 0) + 1, maxShoes + 1),
                    onChange = function(val)
                        if type(val) == "number" then
                            local shoesIndex = val - 1
                            _G.wardrobeValues.shoes = shoesIndex
                            local ped = PlayerPedId()
                            SetPedComponentVariation(ped, 6, shoesIndex, 0, 0)
                        end
                    end
                },
                { 
                    label = 'Models',
                    type = 'divider'
                },
                { 
                    label = 'Model',
                    type = 'scroll',
                    options = {
                        'Michael',
                        'Franklin',
                        'Trevor',
                        'Lester',
                        'Lamar',
                        'Barry',
                        'Brad',
                        'Dave',
                        'Floyd',
                        'Jimmy',
                        'Lazlow',
                        'Nervous Ron',
                        'Omega',
                        'Ortega',
                        'Priest',
                        'Simeon',
                        'Tonya',
                        'Wade',
                        'mp_m_freemode_01',
                        'mp_f_freemode_01',
                        'Random Ped',
                        'Random Male',
                        'Random Female'
                    },
                    selected = 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            local modelNames = {
                                'Michael',
                                'Franklin',
                                'Trevor',
                                'Lester',
                                'Lamar',
                                'Barry',
                                'Brad',
                                'Dave',
                                'Floyd',
                                'Jimmy',
                                'Lazlow',
                                'Nervous Ron',
                                'Omega',
                                'Ortega',
                                'Priest',
                                'Simeon',
                                'Tonya',
                                'Wade',
                                'mp_m_freemode_01',
                                'mp_f_freemode_01',
                                'Random Ped',
                                'Random Male',
                                'Random Female'
                            }
                            
                            local selectedName = modelNames[val]
                            local modelHash = nil
                            
                            if selectedName == 'Michael' then
                                modelHash = GetHashKey('player_zero')
                            elseif selectedName == 'Franklin' then
                                modelHash = GetHashKey('player_one')
                            elseif selectedName == 'Trevor' then
                                modelHash = GetHashKey('player_two')
                            elseif selectedName == 'Lester' then
                                modelHash = GetHashKey('ig_lestercrest')
                            elseif selectedName == 'Lamar' then
                                modelHash = GetHashKey('ig_lamar')
                            elseif selectedName == 'Barry' then
                                modelHash = GetHashKey('ig_barry')
                            elseif selectedName == 'Brad' then
                                modelHash = GetHashKey('ig_brad')
                            elseif selectedName == 'Dave' then
                                modelHash = GetHashKey('ig_davenorton')
                            elseif selectedName == 'Floyd' then
                                modelHash = GetHashKey('ig_floyd')
                            elseif selectedName == 'Jimmy' then
                                modelHash = GetHashKey('ig_jimmyboston')
                            elseif selectedName == 'Lazlow' then
                                modelHash = GetHashKey('ig_lazlow')
                            elseif selectedName == 'Nervous Ron' then
                                modelHash = GetHashKey('ig_nervousron')
                            elseif selectedName == 'Omega' then
                                modelHash = GetHashKey('ig_omega')
                            elseif selectedName == 'Ortega' then
                                modelHash = GetHashKey('ig_ortega')
                            elseif selectedName == 'Priest' then
                                modelHash = GetHashKey('ig_priest')
                            elseif selectedName == 'Simeon' then
                                modelHash = GetHashKey('ig_siemonyetarian')
                            elseif selectedName == 'Tonya' then
                                modelHash = GetHashKey('ig_tonya')
                            elseif selectedName == 'Wade' then
                                modelHash = GetHashKey('ig_wade')
                            elseif selectedName == 'mp_m_freemode_01' then
                                modelHash = GetHashKey('mp_m_freemode_01')
                            elseif selectedName == 'mp_f_freemode_01' then
                                modelHash = GetHashKey('mp_f_freemode_01')
                            elseif selectedName == 'Random Ped' then
                                -- Get random ped model
                                local peds = {'a_m_m_skater_01', 'a_m_y_hipster_01', 'a_f_y_hipster_01', 'a_m_m_beach_01', 'a_f_y_beach_01'}
                                modelHash = GetHashKey(peds[math.random(1, #peds)])
                            elseif selectedName == 'Random Male' then
                                modelHash = GetHashKey('mp_m_freemode_01')
                            elseif selectedName == 'Random Female' then
                                modelHash = GetHashKey('mp_f_freemode_01')
                            end
                            
                            if modelHash then
                                -- Load model in a separate thread to prevent menu freezing
                                CreateThread(function()
                                    RequestModel(modelHash)
                                    
                                    -- Add timeout to prevent infinite loop
                                    local timeout = 0
                                    local maxTimeout = 3000 -- 3 seconds max
                                    
                                    while not HasModelLoaded(modelHash) and timeout < maxTimeout do
                                        Wait(10)
                                        timeout = timeout + 10
                                    end
                                    
                                    if HasModelLoaded(modelHash) then
                                        SetPlayerModel(PlayerId(), modelHash)
                                        SetModelAsNoLongerNeeded(modelHash)
                                        
                                        if _G.showNotification then
                                            _G.showNotification("success", "Model changed to: " .. selectedName)
                                        end
                                        print('Model changed to:', selectedName)
                                    else
                                        if _G.showNotification then
                                            _G.showNotification("error", "Failed to load model: " .. selectedName)
                                        end
                                        print('Failed to load model:', selectedName)
                                        SetModelAsNoLongerNeeded(modelHash)
                                    end
                                end)
                            end
                        end
                    end
                }
            }
        end
        
        callback(menuItems)
    end
})

table.insert(activeMenu, {
    label = 'Server',
    type = 'submenu',
    icon = 'ph-server',
    tabs = { 'List', 'Safe', 'Risky', 'Vehicle', 'Triggers' },
            getSubMenu = function(callback)
        -- Get current tab from menu state
        local currentTab = _G.serverMenuTab or 0
        local tabs = { 'List', 'Safe', 'Risky', 'Vehicle', 'Triggers' }
        local menuItems = {}
        
        -- Helper function to get selected players
        local function getSelectedPlayers()
            if not _G.selectedPlayers then
                return {}
            end
            local selected = {}
            for playerId, _ in pairs(_G.selectedPlayers) do
                if playerId and NetworkIsPlayerActive(playerId) then
                    table.insert(selected, playerId)
                end
            end
            return selected
        end
        
        -- Helper function to apply action to selected players
        local function applyToSelectedPlayers(actionName, actionFunc)
            local selected = getSelectedPlayers()
            if #selected == 0 then
                if _G.showNotification then
                    _G.showNotification("error", "No players selected!")
                end
                return
            end
            
            for _, playerId in ipairs(selected) do
                local serverId = GetPlayerServerId(playerId)
                actionFunc(playerId, serverId)
            end
            
            if _G.showNotification then
                _G.showNotification("success", actionName .. " applied to " .. #selected .. " player(s)")
            end
        end
        
        if currentTab == 0 then -- List
            -- Initialize selected players if not exists
            if not _G.selectedPlayers then
                _G.selectedPlayers = {}
            end
            
            menuItems = {
                { 
                    label = 'Select everyone',
                    type = 'checkbox',
                    checked = false,
                    onConfirm = function(setToggle)
                        local players = GetActivePlayers()
                        _G.selectedPlayers = {}
                        if setToggle then
                            for _, playerId in ipairs(players) do
                                _G.selectedPlayers[playerId] = true
                            end
                        end
                        print('Select everyone:', setToggle)
                    end
                },
                { 
                    label = 'Unselect everyone',
            type = 'button',
            onConfirm = function()
                        _G.selectedPlayers = {}
                        print('Unselected everyone')
                    end
                },
                { 
                    label = 'Method',
                    type = 'scroll',
                    selected = 1,
                    options = { 'Default', 'Teleport', 'Spectate', 'Kick', 'Ban' },
                    onConfirm = function(option)
                        print('Method selected:', option)
                    end
                },
                { 
                    label = 'Search for player',
                    type = 'button',
                    onConfirm = function()
                        print('Search for player pressed')
            end
        }
    }
            
            -- Add divider
            table.insert(menuItems, {
                label = 'Players',
                type = 'divider'
            })
            
            -- Get all active players
            local players = GetActivePlayers()
            for _, playerId in ipairs(players) do
                local playerPed = GetPlayerPed(playerId)
                local playerName = GetPlayerName(playerId)
                local playerServerId = GetPlayerServerId(playerId)
                
                -- Check player status
                local statusEmoji = ""
                local isInVehicle = IsPedInAnyVehicle(playerPed, false)
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                
                if isInVehicle then
                    statusEmoji = "🚗"
                else
                    -- Check if player is in interior (house)
                    local interiorId = GetInteriorFromEntity(playerPed)
                    if interiorId ~= 0 then
                        statusEmoji = "🏠"
                    else
                        statusEmoji = "🚶"
                    end
                end
                
                -- Create player label with emoji and ID
                local playerLabel = playerServerId .. " - " .. playerName .. " " .. statusEmoji
                
                table.insert(menuItems, {
                    label = playerLabel,
                    type = 'checkbox',
                    checked = _G.selectedPlayers[playerId] == true,
                    playerId = playerId,
                    playerServerId = playerServerId,
                    onConfirm = function(setToggle)
                        if setToggle then
                            _G.selectedPlayers[playerId] = true
                        else
                            _G.selectedPlayers[playerId] = nil
                        end
                        print('Player', playerServerId, 'selected:', setToggle)
                    end
                })
            end
        elseif currentTab == 1 then -- Safe
            -- Initialize safe menu values if not exists
            if not _G.safeMenuValues then
                _G.safeMenuValues = {
                    spectate = false,
                    teleportTo = 1,
                    friendList = 1,
                    playerInfo = 1,
                    spawnPickup = 1,
                    spawnObject = 1,
                    attachObject = 1,
                    blame = 1,
                    blameToggle = false,
                    keepFalling = false,
                    giveWeapon = 1,
                    infiniteAmmo = false,
                    noReload = false,
                    superJump = false,
                    fastRun = false,
                    ramVehicle = 1,
                    fallingCar = 1,
                    ghostCar = 1,
                    ghostCarToggle = false,
                    teleportToMe = false,
                    forceAnimation = 1,
                    forceAnimationToggle = false
                }
            end
            
            menuItems = {
                { 
                    label = 'Spectate',
                    type = 'checkbox',
                    checked = _G.safeMenuValues.spectate or false,
                    onConfirm = function(setToggle)
                        _G.safeMenuValues.spectate = setToggle
                        if setToggle then
                            local selected = getSelectedPlayers()
                            if #selected == 0 then
                                if _G.showNotification then
                                    _G.showNotification("error", "No players selected!")
                                end
                                return
                            end
                            -- Spectate first selected player
                            local playerId = selected[1]
                            local ped = GetPlayerPed(playerId)
                            NetworkSetInSpectatorMode(true, ped)
                            if _G.showNotification then
                                _G.showNotification("success", "Spectating player: " .. GetPlayerServerId(playerId))
                            end
                            print('Spectating player:', GetPlayerServerId(playerId))
                        else
                            NetworkSetInSpectatorMode(false, 0)
                            if _G.showNotification then
                                _G.showNotification("success", "Stopped spectating")
                            end
                            print('Stopped spectating')
                        end
                    end
                },
                { 
                    label = 'Teleport to',
                    type = 'scroll',
                    options = { 'Player', 'Vehicle', 'Waypoint' },
                    selected = _G.safeMenuValues.teleportTo or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.safeMenuValues.teleportTo = val
                        end
                    end,
                    onConfirm = function(option)
                        local selected = getSelectedPlayers()
                        local teleportOptions = {'Player', 'Vehicle', 'Waypoint'}
                        local selectedOption = teleportOptions[_G.safeMenuValues.teleportTo or 1]
                        
                        if selectedOption == 'Player' then
                            if #selected == 0 then
                                if _G.showNotification then
                                    _G.showNotification("error", "No players selected!")
                                end
                                return
                            end
                            local targetPlayerId = selected[1]
                            local targetPed = GetPlayerPed(targetPlayerId)
                            local coords = GetEntityCoords(targetPed)
                            local ped = PlayerPedId()
                            SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
                            if _G.showNotification then
                                _G.showNotification("success", "Teleported to player")
                            end
                        elseif selectedOption == 'Vehicle' then
                            if #selected == 0 then
                                if _G.showNotification then
                                    _G.showNotification("error", "No players selected!")
                                end
                                return
                            end
                            local targetPlayerId = selected[1]
                            local targetPed = GetPlayerPed(targetPlayerId)
                            if IsPedInAnyVehicle(targetPed, false) then
                                local vehicle = GetVehiclePedIsIn(targetPed, false)
                                local ped = PlayerPedId()
                                SetPedIntoVehicle(ped, vehicle, -1)
                                if _G.showNotification then
                                    _G.showNotification("success", "Teleported to vehicle")
                                end
                            else
                                if _G.showNotification then
                                    _G.showNotification("error", "Player is not in a vehicle!")
                                end
                            end
                        elseif selectedOption == 'Waypoint' then
                            local blip = GetFirstBlipInfoId(8)
                            if DoesBlipExist(blip) then
                                local coords = GetBlipInfoIdCoord(blip)
                                local ped = PlayerPedId()
                                SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
                                if _G.showNotification then
                                    _G.showNotification("success", "Teleported to waypoint")
                                end
                            else
                                if _G.showNotification then
                                    _G.showNotification("error", "No waypoint set!")
                                end
                            end
                        end
                    end
                },
                { 
                    label = 'Friend list',
                    type = 'scroll',
                    options = { 'Add', 'Remove', 'List' },
                    selected = _G.safeMenuValues.friendList or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.safeMenuValues.friendList = val
                        end
                    end,
                    onConfirm = function(option)
                        local selected = getSelectedPlayers()
                        local friendOptions = {'Add', 'Remove', 'List'}
                        local selectedOption = friendOptions[_G.safeMenuValues.friendList or 1]
                        
                        if #selected == 0 then
                            if _G.showNotification then
                                _G.showNotification("error", "No players selected!")
                            end
                            return
                        end
                        
                        if selectedOption == 'Add' then
                            if not _G.friendList then
                                _G.friendList = {}
                            end
                            for _, playerId in ipairs(selected) do
                                local serverId = GetPlayerServerId(playerId)
                                _G.friendList[serverId] = true
                            end
                            if _G.showNotification then
                                _G.showNotification("success", "Added to friend list")
                            end
                        elseif selectedOption == 'Remove' then
                            if _G.friendList then
                                for _, playerId in ipairs(selected) do
                                    local serverId = GetPlayerServerId(playerId)
                                    _G.friendList[serverId] = nil
                                end
                            end
                            if _G.showNotification then
                                _G.showNotification("success", "Removed from friend list")
                            end
                        elseif selectedOption == 'List' then
                            if _G.friendList then
                                local count = 0
                                for _ in pairs(_G.friendList) do
                                    count = count + 1
                                end
                                if _G.showNotification then
                                    _G.showNotification("info", "Friends: " .. count)
                                end
                            else
                                if _G.showNotification then
                                    _G.showNotification("info", "Friend list is empty")
                                end
                            end
                        end
                    end
                },
                { 
                    label = 'Player info',
                    type = 'scroll',
                    options = { 'Refresh', 'Copy ID', 'Copy Name' },
                    selected = _G.safeMenuValues.playerInfo or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.safeMenuValues.playerInfo = val
                        end
                    end,
                    onConfirm = function(option)
                        local selected = getSelectedPlayers()
                        if #selected == 0 then
                            if _G.showNotification then
                                _G.showNotification("error", "No players selected!")
                            end
                            return
                        end
                        
                        local infoOptions = {'Refresh', 'Copy ID', 'Copy Name'}
                        local selectedOption = infoOptions[_G.safeMenuValues.playerInfo or 1]
                        local targetPlayerId = selected[1]
                        local serverId = GetPlayerServerId(targetPlayerId)
                        local playerName = GetPlayerName(targetPlayerId)
                        
                        if selectedOption == 'Refresh' then
                            if _G.showNotification then
                                _G.showNotification("success", "Refreshed: " .. playerName .. " (ID: " .. serverId .. ")")
                            end
                        elseif selectedOption == 'Copy ID' then
                            -- Copy to clipboard (if available)
                            if _G.showNotification then
                                _G.showNotification("success", "ID copied: " .. serverId)
                            end
                            print("Player ID: " .. serverId)
                        elseif selectedOption == 'Copy Name' then
                            -- Copy to clipboard (if available)
                            if _G.showNotification then
                                _G.showNotification("success", "Name copied: " .. playerName)
                            end
                            print("Player Name: " .. playerName)
                        end
                    end
                },
                { 
                    label = 'Copy appearance',
                    type = 'button',
                    onConfirm = function()
                        local selected = getSelectedPlayers()
                        if #selected == 0 then
                            if _G.showNotification then
                                _G.showNotification("error", "No players selected!")
                            end
                            return
                        end
                        local targetPlayerId = selected[1]
                        local targetPed = GetPlayerPed(targetPlayerId)
                        local ped = PlayerPedId()
                        
                        -- Copy model
                        local model = GetEntityModel(targetPed)
                        RequestModel(model)
                        while not HasModelLoaded(model) do
                            Wait(10)
                        end
                        SetPlayerModel(PlayerId(), model)
                        SetModelAsNoLongerNeeded(model)
                        
                        -- Copy components
                        for i = 0, 11 do
                            local drawable = GetPedDrawableVariation(targetPed, i)
                            local texture = GetPedTextureVariation(targetPed, i)
                            SetPedComponentVariation(ped, i, drawable, texture, 0)
                        end
                        
                        -- Copy props
                        for i = 0, 7 do
                            local propIndex = GetPedPropIndex(targetPed, i)
                            local propTexture = GetPedPropTextureIndex(targetPed, i)
                            if propIndex ~= -1 then
                                SetPedPropIndex(ped, i, propIndex, propTexture, true)
                            else
                                ClearPedProp(ped, i)
                            end
                        end
                        
                        if _G.showNotification then
                            _G.showNotification("success", "Appearance copied")
                        end
                    end
                },
                { 
                    label = 'Spawn pickup',
                    type = 'scroll',
                    options = { 'Health', 'Armor', 'Weapon', 'Money' },
                    selected = _G.safeMenuValues.spawnPickup or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.safeMenuValues.spawnPickup = val
                        end
                    end,
                    onConfirm = function(option)
                        local selected = getSelectedPlayers()
                        local pickupOptions = {'Health', 'Armor', 'Weapon', 'Money'}
                        local selectedOption = pickupOptions[_G.safeMenuValues.spawnPickup or 1]
                        
                        if #selected == 0 then
                            local ped = PlayerPedId()
                            local coords = GetEntityCoords(ped)
                            coords = vector3(coords.x + 2.0, coords.y, coords.z)
                        else
                            applyToSelectedPlayers(function(targetPlayerId)
                                local targetPed = GetPlayerPed(targetPlayerId)
                                local coords = GetEntityCoords(targetPed)
                                coords = vector3(coords.x + 2.0, coords.y, coords.z)
                                
                                if selectedOption == 'Health' then
                                    local pickup = CreatePickup(GetHashKey('PICKUP_HEALTH_STANDARD'), coords.x, coords.y, coords.z, 0, 1, false)
                                elseif selectedOption == 'Armor' then
                                    local pickup = CreatePickup(GetHashKey('PICKUP_ARMOUR_STANDARD'), coords.x, coords.y, coords.z, 0, 1, false)
                                elseif selectedOption == 'Weapon' then
                                    local pickup = CreatePickup(GetHashKey('PICKUP_WEAPON_PISTOL'), coords.x, coords.y, coords.z, 0, 1, false)
                                elseif selectedOption == 'Money' then
                                    local pickup = CreatePickup(GetHashKey('PICKUP_MONEY_CASE'), coords.x, coords.y, coords.z, 0, 1, false)
                                end
                            end)
                        end
                        
                        if _G.showNotification then
                            _G.showNotification("success", "Pickup spawned: " .. selectedOption)
                        end
                    end
                },
                { 
                    label = 'Spawn object',
                    type = 'scroll',
                    options = { 'Custom', 'Prop', 'Vehicle' },
                    selected = _G.safeMenuValues.spawnObject or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.safeMenuValues.spawnObject = val
                        end
                    end,
                    onConfirm = function(option)
                        local selected = getSelectedPlayers()
                        local objectOptions = {'Custom', 'Prop', 'Vehicle'}
                        local selectedOption = objectOptions[_G.safeMenuValues.spawnObject or 1]
                        
                        local spawnCoords
                        if #selected == 0 then
                            local ped = PlayerPedId()
                            spawnCoords = GetEntityCoords(ped)
                            spawnCoords = vector3(spawnCoords.x + 2.0, spawnCoords.y, spawnCoords.z)
                        else
                            local targetPlayerId = selected[1]
                            local targetPed = GetPlayerPed(targetPlayerId)
                            spawnCoords = GetEntityCoords(targetPed)
                            spawnCoords = vector3(spawnCoords.x + 2.0, spawnCoords.y, spawnCoords.z)
                        end
                        
                        if selectedOption == 'Prop' then
                            local propHash = GetHashKey('prop_barrier_work05')
                            RequestModel(propHash)
                            while not HasModelLoaded(propHash) do
                                Wait(10)
                            end
                            local obj = CreateObject(propHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
                            SetModelAsNoLongerNeeded(propHash)
                        elseif selectedOption == 'Vehicle' then
                            local vehicleHash = GetHashKey('adder')
                            RequestModel(vehicleHash)
                            while not HasModelLoaded(vehicleHash) do
                                Wait(10)
                            end
                            local vehicle = CreateVehicle(vehicleHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, false)
                            SetModelAsNoLongerNeeded(vehicleHash)
                        end
                        
                        if _G.showNotification then
                            _G.showNotification("success", "Object spawned: " .. selectedOption)
                        end
                    end
                },
                { 
                    label = 'Attach object',
                    type = 'scroll',
                    options = { 'Dog sign', 'Prop', 'Custom' },
                    selected = _G.safeMenuValues.attachObject or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.safeMenuValues.attachObject = val
                        end
                    end,
                    onConfirm = function(option)
                        local selected = getSelectedPlayers()
                        if #selected == 0 then
                            if _G.showNotification then
                                _G.showNotification("error", "No players selected!")
                            end
                            return
                        end
                        
                        local attachOptions = {'Dog sign', 'Prop', 'Custom'}
                        local selectedOption = attachOptions[_G.safeMenuValues.attachObject or 1]
                        
                        applyToSelectedPlayers(function(targetPlayerId)
                            local targetPed = GetPlayerPed(targetPlayerId)
                            local boneIndex = GetPedBoneIndex(targetPed, 0xE5F3) -- Head bone
                            
                            if selectedOption == 'Dog sign' then
                                local propHash = GetHashKey('prop_dog_sign_01')
                                RequestModel(propHash)
                                while not HasModelLoaded(propHash) do
                                    Wait(10)
                                end
                                local obj = CreateObject(propHash, 0.0, 0.0, 0.0, false, false, false)
                                AttachEntityToEntity(obj, targetPed, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true)
                                SetModelAsNoLongerNeeded(propHash)
                            elseif selectedOption == 'Prop' then
                                local propHash = GetHashKey('prop_barrier_work05')
                                RequestModel(propHash)
                                while not HasModelLoaded(propHash) do
                                    Wait(10)
                                end
                                local obj = CreateObject(propHash, 0.0, 0.0, 0.0, false, false, false)
                                AttachEntityToEntity(obj, targetPed, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true)
                                SetModelAsNoLongerNeeded(propHash)
                            end
                        end)
                        
                        if _G.showNotification then
                            _G.showNotification("success", "Object attached: " .. selectedOption)
                        end
                    end
                },
                { 
                    label = 'Fake godmode',
                    type = 'button',
                    onConfirm = function()
                        local selected = getSelectedPlayers()
                        if #selected == 0 then
                            if _G.showNotification then
                                _G.showNotification("error", "No players selected!")
                            end
                            return
                        end
                        applyToSelectedPlayers(function(targetPlayerId)
                            local targetPed = GetPlayerPed(targetPlayerId)
                            -- Fake godmode by setting health to max repeatedly
                            CreateThread(function()
                                for i = 1, 10 do
                                    SetEntityHealth(targetPed, GetEntityMaxHealth(targetPed))
                                    Wait(100)
                                end
                            end)
                        end)
                        if _G.showNotification then
                            _G.showNotification("success", "Fake godmode applied")
                        end
                    end
                },
                { 
                    label = 'Blame',
                    type = 'scroll',
                    options = { 'Drag', 'Kick', 'Ban' },
                    selected = _G.safeMenuValues.blame or 1,
                    hasToggle = true,
                    checked = _G.safeMenuValues.blameToggle or false,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.safeMenuValues.blame = val
                        end
                    end,
                    onConfirm = function(setToggle)
                        _G.safeMenuValues.blameToggle = setToggle
                        local selected = getSelectedPlayers()
                        if #selected == 0 then
                            if _G.showNotification then
                                _G.showNotification("error", "No players selected!")
                            end
                            return
                        end
                        
                        local blameOptions = {'Drag', 'Kick', 'Ban'}
                        local selectedOption = blameOptions[_G.safeMenuValues.blame or 1]
                        
                        if setToggle then
                            applyToSelectedPlayers(function(targetPlayerId)
                                local serverId = GetPlayerServerId(targetPlayerId)
                                if selectedOption == 'Drag' then
                                    -- Trigger drag event
                                    TriggerServerEvent('esx_policejob:drag', serverId)
                                elseif selectedOption == 'Kick' then
                                    -- Trigger kick event
                                    TriggerServerEvent('esx:kickPlayer', serverId, 'Blamed')
                                elseif selectedOption == 'Ban' then
                                    -- Trigger ban event
                                    TriggerServerEvent('esx:banPlayer', serverId, 'Blamed')
                                end
                            end)
                            if _G.showNotification then
                                _G.showNotification("success", "Blame applied: " .. selectedOption)
                            end
                        end
                    end
                },
                { 
                    label = 'Fall',
                    type = 'button',
                    onConfirm = function()
                        local selected = getSelectedPlayers()
                        if #selected == 0 then
                            if _G.showNotification then
                                _G.showNotification("error", "No players selected!")
                            end
                            return
                        end
                        applyToSelectedPlayers(function(targetPlayerId)
                            local targetPed = GetPlayerPed(targetPlayerId)
                            SetPedCanRagdoll(targetPed, true)
                            SetPedToRagdoll(targetPed, 1000, 1000, 0, false, false, false)
                        end)
                        if _G.showNotification then
                            _G.showNotification("success", "Players made to fall")
                        end
                    end
                },
                { 
                    label = 'Keep falling',
                    type = 'checkbox',
                    checked = _G.safeMenuValues.keepFalling or false,
                    onConfirm = function(setToggle)
                        _G.safeMenuValues.keepFalling = setToggle
                        local selected = getSelectedPlayers()
                        if #selected == 0 then
                            if _G.showNotification then
                                _G.showNotification("error", "No players selected!")
                            end
                            return
                        end
                        
                        if setToggle then
                            CreateThread(function()
                                while _G.safeMenuValues.keepFalling do
                                    applyToSelectedPlayers(function(targetPlayerId)
                                        local targetPed = GetPlayerPed(targetPlayerId)
                                        SetPedCanRagdoll(targetPed, true)
                                        SetPedToRagdoll(targetPed, 1000, 1000, 0, false, false, false)
                                    end)
                                    Wait(500)
                                end
                            end)
                        end
                        
                        if _G.showNotification then
                            _G.showNotification("success", "Keep falling: " .. (setToggle and "ON" or "OFF"))
                        end
                    end
                },
                { 
                    label = 'Troll',
                    type = 'divider'
                },
                { 
                    label = 'Cage',
                    type = 'button',
                    onConfirm = function()
                        local selected = getSelectedPlayers()
                        if #selected == 0 then
                            if _G.showNotification then
                                _G.showNotification("error", "No players selected!")
                            end
                            return
                        end
                        applyToSelectedPlayers(function(targetPlayerId)
                            local targetPed = GetPlayerPed(targetPlayerId)
                            local coords = GetEntityCoords(targetPed)
                            -- Spawn cage around player
                            local cageHash = GetHashKey('prop_gold_cont_01')
                            RequestModel(cageHash)
                            while not HasModelLoaded(cageHash) do
                                Wait(10)
                            end
                            local cage = CreateObject(cageHash, coords.x, coords.y, coords.z - 1.0, false, false, false)
                            SetEntityHeading(cage, 0.0)
                            FreezeEntityPosition(cage, true)
                            SetModelAsNoLongerNeeded(cageHash)
                        end)
                        if _G.showNotification then
                            _G.showNotification("success", "Cage spawned")
                        end
                    end
                },
                { 
                    label = 'Launch in the air',
                    type = 'button',
                    onConfirm = function()
                        local selected = getSelectedPlayers()
                        if #selected == 0 then
                            if _G.showNotification then
                                _G.showNotification("error", "No players selected!")
                            end
                            return
                        end
                        applyToSelectedPlayers(function(targetPlayerId)
                            local targetPed = GetPlayerPed(targetPlayerId)
                            SetEntityVelocity(targetPed, 0.0, 0.0, 50.0)
                        end)
                        if _G.showNotification then
                            _G.showNotification("success", "Players launched")
                        end
                    end
                },
                { 
                    label = 'Ram with a vehicle',
                    type = 'scroll',
                    options = { 'Random', 'Police', 'Truck', 'Bus' },
                    selected = _G.safeMenuValues.ramVehicle or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.safeMenuValues.ramVehicle = val
                        end
                    end,
                    onConfirm = function(option)
                        local selected = getSelectedPlayers()
                        if #selected == 0 then
                            if _G.showNotification then
                                _G.showNotification("error", "No players selected!")
                            end
                            return
                        end
                        local vehicleNames = {'Random', 'Police', 'Truck', 'Bus'}
                        local vehicleModels = {
                            ['Random'] = {'police', 'police2', 'police3', 'firetruk', 'bus'},
                            ['Police'] = {'police', 'police2', 'police3'},
                            ['Truck'] = {'hauler', 'phantom', 'benson'},
                            ['Bus'] = {'bus', 'coach'}
                        }
                        local selectedName = vehicleNames[_G.safeMenuValues.ramVehicle or 1]
                        local vehicles = vehicleModels[selectedName] or vehicleModels['Random']
                        local vehicleModel = vehicles[math.random(1, #vehicles)]
                        
                        applyToSelectedPlayers(function(targetPlayerId)
                            local targetPed = GetPlayerPed(targetPlayerId)
                            local coords = GetEntityCoords(targetPed)
                            local vehicleHash = GetHashKey(vehicleModel)
                            RequestModel(vehicleHash)
                            while not HasModelLoaded(vehicleHash) do
                                Wait(10)
                            end
                            local vehicle = CreateVehicle(vehicleHash, coords.x + 5.0, coords.y, coords.z, 0.0, true, false)
                            SetEntityVelocity(vehicle, -20.0, 0.0, 0.0)
                            SetModelAsNoLongerNeeded(vehicleHash)
                        end)
                        if _G.showNotification then
                            _G.showNotification("success", "Vehicle spawned")
                        end
                    end
                },
                { 
                    label = 'Falling car',
                    type = 'scroll',
                    options = { 'Fall', 'Drop', 'Launch' },
                    selected = _G.safeMenuValues.fallingCar or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.safeMenuValues.fallingCar = val
                        end
                    end,
                    onConfirm = function(option)
                        local selected = getSelectedPlayers()
                        if #selected == 0 then
                            if _G.showNotification then
                                _G.showNotification("error", "No players selected!")
                            end
                            return
                        end
                        local carModels = {'adder', 'zentorno', 't20', 'osiris'}
                        local carModel = carModels[math.random(1, #carModels)]
                        
                        applyToSelectedPlayers(function(targetPlayerId)
                            local targetPed = GetPlayerPed(targetPlayerId)
                            local coords = GetEntityCoords(targetPed)
                            local vehicleHash = GetHashKey(carModel)
                            RequestModel(vehicleHash)
                            while not HasModelLoaded(vehicleHash) do
                                Wait(10)
                            end
                            local vehicle = CreateVehicle(vehicleHash, coords.x, coords.y, coords.z + 20.0, 0.0, true, false)
                            SetEntityVelocity(vehicle, 0.0, 0.0, -10.0)
                            SetModelAsNoLongerNeeded(vehicleHash)
                        end)
                        if _G.showNotification then
                            _G.showNotification("success", "Falling car spawned")
                        end
                    end
                },
                { 
                    label = 'Ghost car',
                    type = 'scroll',
                    options = { 'Default', 'Invisible', 'No Collision' },
                    selected = _G.safeMenuValues.ghostCar or 1,
                    hasToggle = true,
                    checked = _G.safeMenuValues.ghostCarToggle or false,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.safeMenuValues.ghostCar = val
                        end
                    end,
                    onConfirm = function(setToggle)
                        _G.safeMenuValues.ghostCarToggle = setToggle
                        local ped = PlayerPedId()
                        if IsPedInAnyVehicle(ped, false) then
                            local vehicle = GetVehiclePedIsIn(ped, false)
                            if setToggle then
                                SetEntityCollision(vehicle, false, false)
                                SetEntityVisible(vehicle, false, false)
                            else
                                SetEntityCollision(vehicle, true, true)
                                SetEntityVisible(vehicle, true, false)
                            end
                        end
                    end
                },
                { 
                    label = 'Spawn modded vehicle',
                    type = 'button',
                    onConfirm = function()
                        local ped = PlayerPedId()
                        local coords = GetEntityCoords(ped)
                        local vehicleHash = GetHashKey('adder')
                        RequestModel(vehicleHash)
                        while not HasModelLoaded(vehicleHash) do
                            Wait(10)
                        end
                        local vehicle = CreateVehicle(vehicleHash, coords.x + 2.0, coords.y, coords.z, 0.0, true, false)
                        SetVehicleModKit(vehicle, 0)
                        SetVehicleMod(vehicle, 11, 3, false) -- Engine
                        SetVehicleMod(vehicle, 12, 2, false) -- Brakes
                        SetVehicleMod(vehicle, 13, 2, false) -- Transmission
                        SetVehicleMod(vehicle, 15, 3, false) -- Suspension
                        ToggleVehicleMod(vehicle, 18, true) -- Turbo
                        SetModelAsNoLongerNeeded(vehicleHash)
                        if _G.showNotification then
                            _G.showNotification("success", "Modded vehicle spawned")
                        end
                    end
                },
                { 
                    label = 'Teleport to me [Local]',
                    type = 'checkbox',
                    checked = _G.safeMenuValues.teleportToMe or false,
                    onConfirm = function(setToggle)
                        _G.safeMenuValues.teleportToMe = setToggle
                        if setToggle then
                            CreateThread(function()
                                while _G.safeMenuValues.teleportToMe do
                                    local selected = getSelectedPlayers()
                                    if #selected > 0 then
                                        local myPed = PlayerPedId()
                                        local myCoords = GetEntityCoords(myPed)
                                        applyToSelectedPlayers(function(targetPlayerId)
                                            local targetPed = GetPlayerPed(targetPlayerId)
                                            SetEntityCoords(targetPed, myCoords.x, myCoords.y, myCoords.z, false, false, false, true)
                                        end)
                                    end
                                    Wait(1000)
                                end
                            end)
                        end
                    end
                },
                { 
                    label = 'Force animation [Local]',
                    type = 'scroll',
                    options = { 'Arrested', 'Hands Up', 'Dancing', 'Sitting', 'Lying' },
                    selected = _G.safeMenuValues.forceAnimation or 1,
                    hasToggle = true,
                    checked = _G.safeMenuValues.forceAnimationToggle or false,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.safeMenuValues.forceAnimation = val
                        end
                    end,
                    onConfirm = function(setToggle)
                        _G.safeMenuValues.forceAnimationToggle = setToggle
                        local selected = getSelectedPlayers()
                        if #selected == 0 then
                            if _G.showNotification then
                                _G.showNotification("error", "No players selected!")
                            end
                            return
                        end
                        local animations = {
                            ['Arrested'] = {'mp_arresting', 'idle'},
                            ['Hands Up'] = {'missfbi3_sniping', 'hands_up_anxious_scientist'},
                            ['Dancing'] = {'anim@amb@nightclub@dancers@sol@low@', 'low_left_up'},
                            ['Sitting'] = {'amb@world_human_picnic@male@idle_a', 'idle_a'},
                            ['Lying'] = {'amb@world_human_sunbathe@male@back@idle_a', 'idle_a'}
                        }
                        local animNames = {'Arrested', 'Hands Up', 'Dancing', 'Sitting', 'Lying'}
                        local selectedAnim = animNames[_G.safeMenuValues.forceAnimation or 1]
                        local animDict = animations[selectedAnim][1]
                        local animName = animations[selectedAnim][2]
                        
                        if setToggle then
                            applyToSelectedPlayers(function(targetPlayerId)
                                local targetPed = GetPlayerPed(targetPlayerId)
                                RequestAnimDict(animDict)
                                while not HasAnimDictLoaded(animDict) do
                                    Wait(10)
                                end
                                TaskPlayAnim(targetPed, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
                            end)
                        else
                            applyToSelectedPlayers(function(targetPlayerId)
                                local targetPed = GetPlayerPed(targetPlayerId)
                                ClearPedTasksImmediately(targetPed)
                            end)
                        end
                    end
                },
                { 
                    label = 'Fire around player',
                    type = 'button',
                    onConfirm = function()
                        local selected = getSelectedPlayers()
                        if #selected == 0 then
                            if _G.showNotification then
                                _G.showNotification("error", "No players selected!")
                            end
                            return
                        end
                        applyToSelectedPlayers(function(targetPlayerId)
                            local targetPed = GetPlayerPed(targetPlayerId)
                            local coords = GetEntityCoords(targetPed)
                            -- Spawn fire around player
                            for i = 1, 8 do
                                local angle = (i / 8) * 360
                                local rad = math.rad(angle)
                                local x = coords.x + math.cos(rad) * 2.0
                                local y = coords.y + math.sin(rad) * 2.0
                                AddExplosion(x, y, coords.z, 12, 0.5, true, false, 0.0) -- Fire explosion
                            end
                        end)
                        if _G.showNotification then
                            _G.showNotification("success", "Fire spawned")
                        end
                    end
                }
            }
        elseif currentTab == 2 then -- Risky
            menuItems = {
                { 
                    label = 'Explode Player',
                    type = 'button',
                    onConfirm = function()
                        applyToSelectedPlayers("Explode", function(playerId, serverId)
                            local ped = GetPlayerPed(playerId)
                            local coords = GetEntityCoords(ped)
                            AddExplosion(coords.x, coords.y, coords.z, 1, 100.0, true, false, true)
                            print('Exploded player:', serverId)
                        end)
                    end
                },
                { 
                    label = 'Drop Vehicle on Player',
                    type = 'button',
                    onConfirm = function()
                        applyToSelectedPlayers("Drop Vehicle", function(playerId, serverId)
                            local ped = GetPlayerPed(playerId)
                            local coords = GetEntityCoords(ped)
                            local vehicleHash = GetHashKey("adder") -- يمكن تغيير نوع السيارة
                            RequestModel(vehicleHash)
                            while not HasModelLoaded(vehicleHash) do
                                Wait(1)
                            end
                            local vehicle = CreateVehicle(vehicleHash, coords.x, coords.y, coords.z + 20.0, 0.0, true, false)
                            SetEntityVelocity(vehicle, 0.0, 0.0, -50.0)
                            SetVehicleOnGroundProperly(vehicle)
                            print('Dropped vehicle on player:', serverId)
                        end)
                    end
                },
                { 
                    label = 'Kill Player',
                    type = 'button',
                    onConfirm = function()
                        applyToSelectedPlayers("Kill", function(playerId, serverId)
                            local ped = GetPlayerPed(playerId)
                            SetEntityHealth(ped, 0)
                            print('Killed player:', serverId)
                        end)
                    end
                },
                { 
                    label = 'Freeze Player',
                    type = 'checkbox',
                    checked = false,
                    onConfirm = function(setToggle)
                        applyToSelectedPlayers("Freeze", function(playerId, serverId)
                            local ped = GetPlayerPed(playerId)
                            FreezeEntityPosition(ped, setToggle)
                            print('Freeze player', serverId, ':', setToggle)
                        end)
                    end
                },
                { 
                    label = 'Set Player on Fire',
                    type = 'button',
                    onConfirm = function()
                        applyToSelectedPlayers("Set on Fire", function(playerId, serverId)
                            local ped = GetPlayerPed(playerId)
                            StartEntityFire(ped)
                            print('Set player on fire:', serverId)
                        end)
                    end
                },
                { 
                    label = 'Kick Player',
                    type = 'button',
                    onConfirm = function()
                        applyToSelectedPlayers("Kick", function(playerId, serverId)
                            -- Add your kick logic here (usually server-side)
                            print('Kick player:', serverId)
                        end)
                    end
                }
            }
        elseif currentTab == 3 then -- Vehicle
            menuItems = {
                { 
                    label = 'Spawn Vehicle',
                    type = 'button',
                    onConfirm = function()
                        applyToSelectedPlayers("Spawn Vehicle", function(playerId, serverId)
                            local ped = GetPlayerPed(playerId)
                            local coords = GetEntityCoords(ped)
                            -- Add your vehicle spawn logic here
                            print('Spawn vehicle for player:', serverId)
                        end)
                    end
                },
                { 
                    label = 'Repair Vehicle',
                    type = 'button',
                    onConfirm = function()
                        applyToSelectedPlayers("Repair Vehicle", function(playerId, serverId)
                            local ped = GetPlayerPed(playerId)
                            local vehicle = GetVehiclePedIsIn(ped, false)
                            if vehicle ~= 0 then
                                SetVehicleFixed(vehicle)
                                SetVehicleDeformationFixed(vehicle)
                                SetVehicleUndriveable(vehicle, false)
                                SetVehicleEngineOn(vehicle, true, true)
                                print('Repaired vehicle for player:', serverId)
                            end
                        end)
                    end
                },
                { 
                    label = 'God Mode Vehicle',
                    type = 'checkbox',
                    checked = false,
                    onConfirm = function(setToggle)
                        applyToSelectedPlayers("Vehicle God Mode", function(playerId, serverId)
                            local ped = GetPlayerPed(playerId)
                            local vehicle = GetVehiclePedIsIn(ped, false)
                            if vehicle ~= 0 then
                                SetEntityInvincible(vehicle, setToggle)
                                print('Vehicle god mode for player', serverId, ':', setToggle)
                            end
                        end)
                    end
                }
            }
        elseif currentTab == 4 then -- Triggers
            menuItems = {
                { 
                    label = 'Trigger Event 1',
                    type = 'button',
                    onConfirm = function()
                        applyToSelectedPlayers("Trigger Event 1", function(playerId, serverId)
                            -- Add your trigger event logic here
                            print('Triggered event 1 for player:', serverId)
                        end)
                    end
                },
                { 
                    label = 'Trigger Event 2',
                    type = 'button',
                    onConfirm = function()
                        applyToSelectedPlayers("Trigger Event 2", function(playerId, serverId)
                            -- Add your trigger event logic here
                            print('Triggered event 2 for player:', serverId)
                        end)
                    end
                },
                { 
                    label = 'Trigger Event 3',
                    type = 'button',
                    onConfirm = function()
                        applyToSelectedPlayers("Trigger Event 3", function(playerId, serverId)
                            -- Add your trigger event logic here
                            print('Triggered event 3 for player:', serverId)
                        end)
                    end
                }
            }
        end
        
        callback(menuItems)
    end
})

table.insert(activeMenu, {
    label = 'Weapon',
    type = 'submenu',
    icon = 'ph-gun',
    tabs = { 'Weapon spawner', 'Weapon', 'Fun' },
    getSubMenu = function(callback)
        -- Get current tab from menu state
        local currentTab = _G.weaponMenuTab or 0
        local tabs = { 'Weapon spawner', 'Weapon', 'Fun' }
        local menuItems = {}
        
        -- Initialize weapon menu values if not exists
        if not _G.weaponMenuValues then
            _G.weaponMenuValues = {
                togglePreviews = false,
                spoofWeapons = false,
                pickup = false,
                addons = 1,
                melee = 1,
                handguns = 1,
                smg = 1,
                rifles = 1,
                shotguns = 1,
                snipers = 1,
                heavy = 1,
                throwables = 1,
                lmgs = 1,
                misc = 1
            }
        end
        
        if currentTab == 0 then -- Weapon spawner
            menuItems = {
                { 
                    label = 'Toggle previews',
                    type = 'checkbox',
                    checked = _G.weaponMenuValues.togglePreviews or false,
                    onConfirm = function(setToggle)
                        _G.weaponMenuValues.togglePreviews = setToggle
                        if _G.showNotification then
                            _G.showNotification("success", "Toggle previews: " .. (setToggle and "ON" or "OFF"))
                        end
                    end
                },
                { 
                    label = 'Give Weapon',
                    type = 'button',
                    onConfirm = function()
                        local ped = PlayerPedId()
                        local handgunOptions = {'Pistol', 'Pistol_mk2', 'Combat Pistol', 'APP Pistol', 'Stun Gun', 'Pistol .50', 'SNS Pistol', 'Heavy Pistol', 'Vintage Pistol', 'Marksman Pistol', 'Revolver', 'Revolver Mk II', 'Double Action Revolver', 'Up-Atomizer', 'Ceramic Pistol', 'Navy Revolver', 'Perico Pistol', 'Gadget Pistol'}
                        local selectedHandgun = handgunOptions[_G.weaponMenuValues.handguns or 1]
                        local weaponHash = GetHashKey('WEAPON_' .. selectedHandgun:upper():gsub(' ', '_'):gsub('%.', ''))
                        GiveWeaponToPed(ped, weaponHash, 250, false, true)
                        if _G.showNotification then
                            _G.showNotification("success", "Weapon given: " .. selectedHandgun)
                        end
                    end
                },
                { 
                    label = 'Remove weapon from hand',
                    type = 'button',
                    onConfirm = function()
                        local ped = PlayerPedId()
                        local currentWeapon = GetSelectedPedWeapon(ped)
                        if currentWeapon ~= GetHashKey('WEAPON_UNARMED') then
                            RemoveWeaponFromPed(ped, currentWeapon)
                            if _G.showNotification then
                                _G.showNotification("success", "Weapon removed from hand")
                            end
                        else
                            if _G.showNotification then
                                _G.showNotification("error", "No weapon in hand")
                            end
                        end
                    end
                },
                { 
                    label = 'Give all weapons',
                    type = 'button',
                    onConfirm = function()
                        local ped = PlayerPedId()
                        local allWeapons = {
                            -- Melee
                            'WEAPON_DAGGER', 'WEAPON_BAT', 'WEAPON_BOTTLE', 'WEAPON_CROWBAR', 'WEAPON_UNARMED',
                            'WEAPON_FLASHLIGHT', 'WEAPON_GOLFCLUB', 'WEAPON_HAMMER', 'WEAPON_HATCHET',
                            'WEAPON_KNUCKLE', 'WEAPON_KNIFE', 'WEAPON_MACHETE', 'WEAPON_SWITCHBLADE',
                            'WEAPON_NIGHTSTICK', 'WEAPON_WRENCH', 'WEAPON_BATTLEAXE', 'WEAPON_POOLCUE',
                            'WEAPON_STONE_HATCHET', 'WEAPON_CANDYCANE', 'WEAPON_STUNROD',
                            -- Handguns
                            'WEAPON_PISTOL', 'WEAPON_PISTOL_MK2', 'WEAPON_COMBATPISTOL', 'WEAPON_APPISTOL',
                            'WEAPON_STUNGUN', 'WEAPON_PISTOL50', 'WEAPON_SNSPISTOL', 'WEAPON_SNSPISTOL_MK2',
                            'WEAPON_HEAVYPISTOL', 'WEAPON_VINTAGEPISTOL', 'WEAPON_FLAREGUN', 'WEAPON_MARKSMANPISTOL',
                            'WEAPON_REVOLVER', 'WEAPON_REVOLVER_MK2', 'WEAPON_DOUBLEACTION', 'WEAPON_RAYPISTOL',
                            'WEAPON_CERAMICPISTOL', 'WEAPON_NAVYREVOLVER', 'WEAPON_GADGETPISTOL', 'WEAPON_STUNGUN_MP',
                            'WEAPON_PISTOLXM3',
                            -- SMG
                            'WEAPON_MICROSMG', 'WEAPON_SMG', 'WEAPON_SMG_MK2', 'WEAPON_ASSAULTSMG',
                            'WEAPON_COMBATPDW', 'WEAPON_MACHINEPISTOL', 'WEAPON_MINISMG', 'WEAPON_RAYCARBINE',
                            'WEAPON_TECPISTOL',
                            -- Shotguns
                            'WEAPON_PUMPSHOTGUN', 'WEAPON_PUMPSHOTGUN_MK2', 'WEAPON_SAWNOFFSHOTGUN', 'WEAPON_ASSAULTSHOTGUN',
                            'WEAPON_BULLPUPSHOTGUN', 'WEAPON_HEAVYSHOTGUN', 'WEAPON_DBSHOTGUN', 'WEAPON_AUTOSHOTGUN',
                            'WEAPON_COMBATSHOTGUN',
                            -- Assault Rifles
                            'WEAPON_ASSAULTRIFLE', 'WEAPON_ASSAULTRIFLE_MK2', 'WEAPON_CARBINERIFLE', 'WEAPON_CARBINERIFLE_MK2',
                            'WEAPON_ADVANCEDRIFLE', 'WEAPON_SPECIALCARBINE', 'WEAPON_SPECIALCARBINE_MK2', 'WEAPON_BULLPUPRIFLE',
                            'WEAPON_BULLPUPRIFLE_MK2', 'WEAPON_COMPACTRIFLE', 'WEAPON_MILITARYRIFLE', 'WEAPON_HEAVYRIFLE',
                            'WEAPON_TACTICALRIFLE',
                            -- Light Machine Guns
                            'WEAPON_MG', 'WEAPON_COMBATMG', 'WEAPON_COMBATMG_MK2', 'WEAPON_GUSENBERG',
                            -- Snipers
                            'WEAPON_SNIPERRIFLE', 'WEAPON_HEAVYSNIPER', 'WEAPON_HEAVYSNIPER_MK2', 'WEAPON_MARKSMANRIFLE',
                            'WEAPON_MARKSMANRIFLE_MK2', 'WEAPON_PRECISIONRIFLE', 'WEAPON_MUSKET',
                            -- Heavy Weapons
                            'WEAPON_RPG', 'WEAPON_GRENADELAUNCHER', 'WEAPON_GRENADELAUNCHER_SMOKE', 'WEAPON_MINIGUN',
                            'WEAPON_FIREWORK', 'WEAPON_RAILGUN', 'WEAPON_HOMINGLAUNCHER', 'WEAPON_COMPACTLAUNCHER',
                            'WEAPON_RAYMINIGUN', 'WEAPON_EMPLAUNCHER', 'WEAPON_RAILGUNXM3',
                            -- Throwables
                            'WEAPON_GRENADE', 'WEAPON_BZGAS', 'WEAPON_MOLOTOV', 'WEAPON_STICKYBOMB',
                            'WEAPON_PROXMINE', 'WEAPON_SNOWBALL', 'WEAPON_PIPEBOMB', 'WEAPON_BALL',
                            'WEAPON_SMOKEGRENADE', 'WEAPON_FLARE', 'WEAPON_ACIDPACKAGE',
                            -- Miscellaneous
                            'WEAPON_PETROLCAN', 'GADGET_PARACHUTE', 'WEAPON_FIREEXTINGUISHER', 'WEAPON_HAZARDCAN',
                            'WEAPON_FERTILIZERCAN'
                        }
                        for _, weaponName in ipairs(allWeapons) do
                            local weaponHash = GetHashKey(weaponName)
                            GiveWeaponToPed(ped, weaponHash, 250, false, true)
                        end
                        if _G.showNotification then
                            _G.showNotification("success", "All weapons given")
                        end
                    end
                },
                { 
                    label = 'Remove all weapons',
                    type = 'button',
                    onConfirm = function()
                        local ped = PlayerPedId()
                        RemoveAllPedWeapons(ped, true)
                        if _G.showNotification then
                            _G.showNotification("success", "All weapons removed")
                        end
                    end
                },
                { 
                    label = 'All Weapons',
                    type = 'divider'
                },
                { 
                    label = 'Spoof weapons',
                    type = 'checkbox',
                    checked = _G.weaponMenuValues.spoofWeapons or false,
                    onConfirm = function(setToggle)
                        _G.weaponMenuValues.spoofWeapons = setToggle
                        if _G.showNotification then
                            _G.showNotification("success", "Spoof weapons: " .. (setToggle and "ON" or "OFF"))
                        end
                    end
                },
                { 
                    label = 'Pickup',
                    type = 'checkbox',
                    checked = _G.weaponMenuValues.pickup or false,
                    onConfirm = function(setToggle)
                        _G.weaponMenuValues.pickup = setToggle
                        if _G.showNotification then
                            _G.showNotification("success", "Pickup: " .. (setToggle and "ON" or "OFF"))
                        end
                    end
                },
                { 
                    label = 'Addons',
                    type = 'scroll',
                    options = { 'Beretta', 'Glock', 'Desert Eagle', 'M1911', 'P250', 'USP' },
                    selected = _G.weaponMenuValues.addons or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.weaponMenuValues.addons = val
                        end
                    end,
                    onConfirm = function(option)
                        local addonOptions = {'Beretta', 'Glock', 'Desert Eagle', 'M1911', 'P250', 'USP'}
                        local selectedAddon = addonOptions[_G.weaponMenuValues.addons or 1]
                        if _G.showNotification then
                            _G.showNotification("info", "Addon selected: " .. selectedAddon)
                        end
                    end
                },
                { 
                    label = 'Melee',
                    type = 'scroll',
                    options = { 'Dagger', 'Bat', 'Bottle', 'Crowbar', 'Unarmed', 'Flashlight', 'Golf Club', 'Hammer', 'Hatchet', 'Knuckle', 'Knife', 'Machete', 'Switchblade', 'Nightstick', 'Wrench', 'Battleaxe', 'Pool Cue', 'Stone Hatchet', 'Candy Cane', 'Stunrod' },
                    selected = _G.weaponMenuValues.melee or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.weaponMenuValues.melee = val
                        end
                    end,
                    onConfirm = function(option)
                        local meleeOptions = {'Dagger', 'Bat', 'Bottle', 'Crowbar', 'Unarmed', 'Flashlight', 'Golf Club', 'Hammer', 'Hatchet', 'Knuckle', 'Knife', 'Machete', 'Switchblade', 'Nightstick', 'Wrench', 'Battleaxe', 'Pool Cue', 'Stone Hatchet', 'Candy Cane', 'Stunrod'}
                        local meleeHashes = {
                            ['Dagger'] = 'WEAPON_DAGGER',
                            ['Bat'] = 'WEAPON_BAT',
                            ['Bottle'] = 'WEAPON_BOTTLE',
                            ['Crowbar'] = 'WEAPON_CROWBAR',
                            ['Unarmed'] = 'WEAPON_UNARMED',
                            ['Flashlight'] = 'WEAPON_FLASHLIGHT',
                            ['Golf Club'] = 'WEAPON_GOLFCLUB',
                            ['Hammer'] = 'WEAPON_HAMMER',
                            ['Hatchet'] = 'WEAPON_HATCHET',
                            ['Knuckle'] = 'WEAPON_KNUCKLE',
                            ['Knife'] = 'WEAPON_KNIFE',
                            ['Machete'] = 'WEAPON_MACHETE',
                            ['Switchblade'] = 'WEAPON_SWITCHBLADE',
                            ['Nightstick'] = 'WEAPON_NIGHTSTICK',
                            ['Wrench'] = 'WEAPON_WRENCH',
                            ['Battleaxe'] = 'WEAPON_BATTLEAXE',
                            ['Pool Cue'] = 'WEAPON_POOLCUE',
                            ['Stone Hatchet'] = 'WEAPON_STONE_HATCHET',
                            ['Candy Cane'] = 'WEAPON_CANDYCANE',
                            ['Stunrod'] = 'WEAPON_STUNROD'
                        }
                        local selectedMelee = meleeOptions[_G.weaponMenuValues.melee or 1]
                        local weaponHash = GetHashKey(meleeHashes[selectedMelee])
                        local ped = PlayerPedId()
                        GiveWeaponToPed(ped, weaponHash, 1, false, true)
                        if _G.showNotification then
                            _G.showNotification("success", "Melee weapon given: " .. selectedMelee)
                        end
                    end
                },
                { 
                    label = 'Handguns',
                    type = 'scroll',
                    options = { 'Pistol', 'Pistol Mk II', 'Combat Pistol', 'AP Pistol', 'Stun Gun', 'Pistol .50', 'SNS Pistol', 'SNS Pistol Mk II', 'Heavy Pistol', 'Vintage Pistol', 'Flare Gun', 'Marksman Pistol', 'Heavy Revolver', 'Heavy Revolver Mk II', 'Double Action Revolver', 'Up-n-Atomizer', 'Ceramic Pistol', 'Navy Revolver', 'Perico Pistol', 'Stun Gun MP', 'WM 29 Pistol' },
                    selected = _G.weaponMenuValues.handguns or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.weaponMenuValues.handguns = val
                        end
                    end,
                    onConfirm = function(option)
                        local handgunOptions = {'Pistol', 'Pistol Mk II', 'Combat Pistol', 'AP Pistol', 'Stun Gun', 'Pistol .50', 'SNS Pistol', 'SNS Pistol Mk II', 'Heavy Pistol', 'Vintage Pistol', 'Flare Gun', 'Marksman Pistol', 'Heavy Revolver', 'Heavy Revolver Mk II', 'Double Action Revolver', 'Up-n-Atomizer', 'Ceramic Pistol', 'Navy Revolver', 'Perico Pistol', 'Stun Gun MP', 'WM 29 Pistol'}
                        local handgunHashes = {
                            ['Pistol'] = 'WEAPON_PISTOL',
                            ['Pistol Mk II'] = 'WEAPON_PISTOL_MK2',
                            ['Combat Pistol'] = 'WEAPON_COMBATPISTOL',
                            ['AP Pistol'] = 'WEAPON_APPISTOL',
                            ['Stun Gun'] = 'WEAPON_STUNGUN',
                            ['Pistol .50'] = 'WEAPON_PISTOL50',
                            ['SNS Pistol'] = 'WEAPON_SNSPISTOL',
                            ['SNS Pistol Mk II'] = 'WEAPON_SNSPISTOL_MK2',
                            ['Heavy Pistol'] = 'WEAPON_HEAVYPISTOL',
                            ['Vintage Pistol'] = 'WEAPON_VINTAGEPISTOL',
                            ['Flare Gun'] = 'WEAPON_FLAREGUN',
                            ['Marksman Pistol'] = 'WEAPON_MARKSMANPISTOL',
                            ['Heavy Revolver'] = 'WEAPON_REVOLVER',
                            ['Heavy Revolver Mk II'] = 'WEAPON_REVOLVER_MK2',
                            ['Double Action Revolver'] = 'WEAPON_DOUBLEACTION',
                            ['Up-n-Atomizer'] = 'WEAPON_RAYPISTOL',
                            ['Ceramic Pistol'] = 'WEAPON_CERAMICPISTOL',
                            ['Navy Revolver'] = 'WEAPON_NAVYREVOLVER',
                            ['Perico Pistol'] = 'WEAPON_GADGETPISTOL',
                            ['Stun Gun MP'] = 'WEAPON_STUNGUN_MP',
                            ['WM 29 Pistol'] = 'WEAPON_PISTOLXM3'
                        }
                        local selectedHandgun = handgunOptions[_G.weaponMenuValues.handguns or 1]
                        local weaponHash = GetHashKey(handgunHashes[selectedHandgun])
                        local ped = PlayerPedId()
                        GiveWeaponToPed(ped, weaponHash, 250, false, true)
                        if _G.showNotification then
                            _G.showNotification("success", "Handgun given: " .. selectedHandgun)
                        end
                    end
                },
                { 
                    label = 'Smg',
                    type = 'scroll',
                    options = { 'Micro SMG', 'SMG', 'SMG Mk II', 'Assault SMG', 'Combat PDW', 'Machine Pistol', 'Mini SMG', 'Unholy Hellbringer', 'Tactical SMG' },
                    selected = _G.weaponMenuValues.smg or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.weaponMenuValues.smg = val
                        end
                    end,
                    onConfirm = function(option)
                        local smgOptions = {'Micro SMG', 'SMG', 'SMG Mk II', 'Assault SMG', 'Combat PDW', 'Machine Pistol', 'Mini SMG', 'Unholy Hellbringer', 'Tactical SMG'}
                        local smgHashes = {
                            ['Micro SMG'] = 'WEAPON_MICROSMG',
                            ['SMG'] = 'WEAPON_SMG',
                            ['SMG Mk II'] = 'WEAPON_SMG_MK2',
                            ['Assault SMG'] = 'WEAPON_ASSAULTSMG',
                            ['Combat PDW'] = 'WEAPON_COMBATPDW',
                            ['Machine Pistol'] = 'WEAPON_MACHINEPISTOL',
                            ['Mini SMG'] = 'WEAPON_MINISMG',
                            ['Unholy Hellbringer'] = 'WEAPON_RAYCARBINE',
                            ['Tactical SMG'] = 'WEAPON_TECPISTOL'
                        }
                        local selectedSmg = smgOptions[_G.weaponMenuValues.smg or 1]
                        local weaponHash = GetHashKey(smgHashes[selectedSmg])
                        local ped = PlayerPedId()
                        GiveWeaponToPed(ped, weaponHash, 250, false, true)
                        if _G.showNotification then
                            _G.showNotification("success", "SMG given: " .. selectedSmg)
                        end
                    end
                },
                { 
                    label = 'Rifles',
                    type = 'scroll',
                    options = { 'Assault Rifle', 'Assault Rifle Mk II', 'Carbine Rifle', 'Carbine Rifle Mk II', 'Advanced Rifle', 'Special Carbine', 'Special Carbine Mk II', 'Bullpup Rifle', 'Bullpup Rifle Mk II', 'Compact Rifle', 'Military Rifle', 'Heavy Rifle', 'Tactical Rifle' },
                    selected = _G.weaponMenuValues.rifles or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.weaponMenuValues.rifles = val
                        end
                    end,
                    onConfirm = function(option)
                        local rifleOptions = {'Assault Rifle', 'Assault Rifle Mk II', 'Carbine Rifle', 'Carbine Rifle Mk II', 'Advanced Rifle', 'Special Carbine', 'Special Carbine Mk II', 'Bullpup Rifle', 'Bullpup Rifle Mk II', 'Compact Rifle', 'Military Rifle', 'Heavy Rifle', 'Tactical Rifle'}
                        local rifleHashes = {
                            ['Assault Rifle'] = 'WEAPON_ASSAULTRIFLE',
                            ['Assault Rifle Mk II'] = 'WEAPON_ASSAULTRIFLE_MK2',
                            ['Carbine Rifle'] = 'WEAPON_CARBINERIFLE',
                            ['Carbine Rifle Mk II'] = 'WEAPON_CARBINERIFLE_MK2',
                            ['Advanced Rifle'] = 'WEAPON_ADVANCEDRIFLE',
                            ['Special Carbine'] = 'WEAPON_SPECIALCARBINE',
                            ['Special Carbine Mk II'] = 'WEAPON_SPECIALCARBINE_MK2',
                            ['Bullpup Rifle'] = 'WEAPON_BULLPUPRIFLE',
                            ['Bullpup Rifle Mk II'] = 'WEAPON_BULLPUPRIFLE_MK2',
                            ['Compact Rifle'] = 'WEAPON_COMPACTRIFLE',
                            ['Military Rifle'] = 'WEAPON_MILITARYRIFLE',
                            ['Heavy Rifle'] = 'WEAPON_HEAVYRIFLE',
                            ['Tactical Rifle'] = 'WEAPON_TACTICALRIFLE'
                        }
                        local selectedRifle = rifleOptions[_G.weaponMenuValues.rifles or 1]
                        local weaponHash = GetHashKey(rifleHashes[selectedRifle])
                        local ped = PlayerPedId()
                        GiveWeaponToPed(ped, weaponHash, 250, false, true)
                        if _G.showNotification then
                            _G.showNotification("success", "Rifle given: " .. selectedRifle)
                        end
                    end
                },
                { 
                    label = 'Shotguns',
                    type = 'scroll',
                    options = { 'Pump Shotgun', 'Pump Shotgun Mk II', 'Sawed-Off Shotgun', 'Assault Shotgun', 'Bullpup Shotgun', 'Heavy Shotgun', 'Double Barrel Shotgun', 'Sweeper Shotgun', 'Combat Shotgun' },
                    selected = _G.weaponMenuValues.shotguns or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.weaponMenuValues.shotguns = val
                        end
                    end,
                    onConfirm = function(option)
                        local shotgunOptions = {'Pump Shotgun', 'Pump Shotgun Mk II', 'Sawed-Off Shotgun', 'Assault Shotgun', 'Bullpup Shotgun', 'Heavy Shotgun', 'Double Barrel Shotgun', 'Sweeper Shotgun', 'Combat Shotgun'}
                        local shotgunHashes = {
                            ['Pump Shotgun'] = 'WEAPON_PUMPSHOTGUN',
                            ['Pump Shotgun Mk II'] = 'WEAPON_PUMPSHOTGUN_MK2',
                            ['Sawed-Off Shotgun'] = 'WEAPON_SAWNOFFSHOTGUN',
                            ['Assault Shotgun'] = 'WEAPON_ASSAULTSHOTGUN',
                            ['Bullpup Shotgun'] = 'WEAPON_BULLPUPSHOTGUN',
                            ['Heavy Shotgun'] = 'WEAPON_HEAVYSHOTGUN',
                            ['Double Barrel Shotgun'] = 'WEAPON_DBSHOTGUN',
                            ['Sweeper Shotgun'] = 'WEAPON_AUTOSHOTGUN',
                            ['Combat Shotgun'] = 'WEAPON_COMBATSHOTGUN'
                        }
                        local selectedShotgun = shotgunOptions[_G.weaponMenuValues.shotguns or 1]
                        local weaponHash = GetHashKey(shotgunHashes[selectedShotgun])
                        local ped = PlayerPedId()
                        GiveWeaponToPed(ped, weaponHash, 250, false, true)
                        if _G.showNotification then
                            _G.showNotification("success", "Shotgun given: " .. selectedShotgun)
                        end
                    end
                },
                { 
                    label = 'Snipers',
                    type = 'scroll',
                    options = { 'Sniper Rifle', 'Heavy Sniper', 'Heavy Sniper Mk II', 'Marksman Rifle', 'Marksman Rifle Mk II', 'Precision Rifle', 'Musket' },
                    selected = _G.weaponMenuValues.snipers or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.weaponMenuValues.snipers = val
                        end
                    end,
                    onConfirm = function(option)
                        local sniperOptions = {'Sniper Rifle', 'Heavy Sniper', 'Heavy Sniper Mk II', 'Marksman Rifle', 'Marksman Rifle Mk II', 'Precision Rifle', 'Musket'}
                        local sniperHashes = {
                            ['Sniper Rifle'] = 'WEAPON_SNIPERRIFLE',
                            ['Heavy Sniper'] = 'WEAPON_HEAVYSNIPER',
                            ['Heavy Sniper Mk II'] = 'WEAPON_HEAVYSNIPER_MK2',
                            ['Marksman Rifle'] = 'WEAPON_MARKSMANRIFLE',
                            ['Marksman Rifle Mk II'] = 'WEAPON_MARKSMANRIFLE_MK2',
                            ['Precision Rifle'] = 'WEAPON_PRECISIONRIFLE',
                            ['Musket'] = 'WEAPON_MUSKET'
                        }
                        local selectedSniper = sniperOptions[_G.weaponMenuValues.snipers or 1]
                        local weaponHash = GetHashKey(sniperHashes[selectedSniper])
                        local ped = PlayerPedId()
                        GiveWeaponToPed(ped, weaponHash, 250, false, true)
                        if _G.showNotification then
                            _G.showNotification("success", "Sniper given: " .. selectedSniper)
                        end
                    end
                },
                { 
                    label = 'Heavy Weapons',
                    type = 'scroll',
                    options = { 'RPG', 'Grenade Launcher', 'Grenade Launcher Smoke', 'Minigun', 'Firework Launcher', 'Railgun', 'Homing Launcher', 'Compact Grenade Launcher', 'Widowmaker', 'Compact EMP Launcher', 'Railgun XM3' },
                    selected = _G.weaponMenuValues.heavy or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.weaponMenuValues.heavy = val
                        end
                    end,
                    onConfirm = function(option)
                        local heavyOptions = {'RPG', 'Grenade Launcher', 'Grenade Launcher Smoke', 'Minigun', 'Firework Launcher', 'Railgun', 'Homing Launcher', 'Compact Grenade Launcher', 'Widowmaker', 'Compact EMP Launcher', 'Railgun XM3'}
                        local heavyHashes = {
                            ['RPG'] = 'WEAPON_RPG',
                            ['Grenade Launcher'] = 'WEAPON_GRENADELAUNCHER',
                            ['Grenade Launcher Smoke'] = 'WEAPON_GRENADELAUNCHER_SMOKE',
                            ['Minigun'] = 'WEAPON_MINIGUN',
                            ['Firework Launcher'] = 'WEAPON_FIREWORK',
                            ['Railgun'] = 'WEAPON_RAILGUN',
                            ['Homing Launcher'] = 'WEAPON_HOMINGLAUNCHER',
                            ['Compact Grenade Launcher'] = 'WEAPON_COMPACTLAUNCHER',
                            ['Widowmaker'] = 'WEAPON_RAYMINIGUN',
                            ['Compact EMP Launcher'] = 'WEAPON_EMPLAUNCHER',
                            ['Railgun XM3'] = 'WEAPON_RAILGUNXM3'
                        }
                        local selectedHeavy = heavyOptions[_G.weaponMenuValues.heavy or 1]
                        local weaponHash = GetHashKey(heavyHashes[selectedHeavy])
                        local ped = PlayerPedId()
                        GiveWeaponToPed(ped, weaponHash, 250, false, true)
                        if _G.showNotification then
                            _G.showNotification("success", "Heavy weapon given: " .. selectedHeavy)
                        end
                    end
                },
                { 
                    label = 'Light Machine Guns',
                    type = 'scroll',
                    options = { 'MG', 'Combat MG', 'Combat MG Mk II', 'Gusenberg Sweeper' },
                    selected = _G.weaponMenuValues.lmgs or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.weaponMenuValues.lmgs = val
                        end
                    end,
                    onConfirm = function(option)
                        local lmgOptions = {'MG', 'Combat MG', 'Combat MG Mk II', 'Gusenberg Sweeper'}
                        local lmgHashes = {
                            ['MG'] = 'WEAPON_MG',
                            ['Combat MG'] = 'WEAPON_COMBATMG',
                            ['Combat MG Mk II'] = 'WEAPON_COMBATMG_MK2',
                            ['Gusenberg Sweeper'] = 'WEAPON_GUSENBERG'
                        }
                        local selectedLmg = lmgOptions[_G.weaponMenuValues.lmgs or 1]
                        local weaponHash = GetHashKey(lmgHashes[selectedLmg])
                        local ped = PlayerPedId()
                        GiveWeaponToPed(ped, weaponHash, 250, false, true)
                        if _G.showNotification then
                            _G.showNotification("success", "LMG given: " .. selectedLmg)
                        end
                    end
                },
                { 
                    label = 'Throwables',
                    type = 'scroll',
                    options = { 'Grenade', 'BZ Gas', 'Molotov Cocktail', 'Sticky Bomb', 'Proximity Mines', 'Snowballs', 'Pipe Bombs', 'Baseball', 'Tear Gas', 'Flare', 'Acid Package' },
                    selected = _G.weaponMenuValues.throwables or 1,
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.weaponMenuValues.throwables = val
                        end
                    end,
                    onConfirm = function(option)
                        local throwableOptions = {'Grenade', 'BZ Gas', 'Molotov Cocktail', 'Sticky Bomb', 'Proximity Mines', 'Snowballs', 'Pipe Bombs', 'Baseball', 'Tear Gas', 'Flare', 'Acid Package'}
                        local throwableHashes = {
                            ['Grenade'] = 'WEAPON_GRENADE',
                            ['BZ Gas'] = 'WEAPON_BZGAS',
                            ['Molotov Cocktail'] = 'WEAPON_MOLOTOV',
                            ['Sticky Bomb'] = 'WEAPON_STICKYBOMB',
                            ['Proximity Mines'] = 'WEAPON_PROXMINE',
                            ['Snowballs'] = 'WEAPON_SNOWBALL',
                            ['Pipe Bombs'] = 'WEAPON_PIPEBOMB',
                            ['Baseball'] = 'WEAPON_BALL',
                            ['Tear Gas'] = 'WEAPON_SMOKEGRENADE',
                            ['Flare'] = 'WEAPON_FLARE',
                            ['Acid Package'] = 'WEAPON_ACIDPACKAGE'
                        }
                        local selectedThrowable = throwableOptions[_G.weaponMenuValues.throwables or 1]
                        local weaponHash = GetHashKey(throwableHashes[selectedThrowable])
                        local ped = PlayerPedId()
                        GiveWeaponToPed(ped, weaponHash, 25, false, true)
                        if _G.showNotification then
                            _G.showNotification("success", "Throwable given: " .. selectedThrowable)
                        end
                    end
                },
                { 
                    label = 'Miscellaneous',
                    type = 'scroll',
                    options = { 'Jerry Can', 'Parachute', 'Fire Extinguisher', 'Hazardous Jerry Can', 'Fertilizer Can' },
                    selected = (_G.weaponMenuValues.misc or 1),
                    onChange = function(val)
                        if type(val) == "number" then
                            _G.weaponMenuValues.misc = val
                        end
                    end,
                    onConfirm = function(option)
                        local miscOptions = {'Jerry Can', 'Parachute', 'Fire Extinguisher', 'Hazardous Jerry Can', 'Fertilizer Can'}
                        local miscHashes = {
                            ['Jerry Can'] = 'WEAPON_PETROLCAN',
                            ['Parachute'] = 'GADGET_PARACHUTE',
                            ['Fire Extinguisher'] = 'WEAPON_FIREEXTINGUISHER',
                            ['Hazardous Jerry Can'] = 'WEAPON_HAZARDCAN',
                            ['Fertilizer Can'] = 'WEAPON_FERTILIZERCAN'
                        }
                        local selectedMisc = miscOptions[_G.weaponMenuValues.misc or 1]
                        local weaponHash = GetHashKey(miscHashes[selectedMisc])
                        local ped = PlayerPedId()
                        GiveWeaponToPed(ped, weaponHash, 1, false, true)
                        if _G.showNotification then
                            _G.showNotification("success", "Misc item given: " .. selectedMisc)
                        end
                    end
                }
            }
        elseif currentTab == 1 then -- Weapon
            menuItems = {
                { 
                    label = 'Infinite Ammo',
                    type = 'checkbox',
                    checked = _G.infiniteAmmo or false,
                    onConfirm = function(setToggle)
                        _G.infiniteAmmo = setToggle
                        if setToggle then
                            CreateThread(function()
                                while _G.infiniteAmmo do
                                    local ped = PlayerPedId()
                                    SetPedInfiniteAmmoClip(ped, true)
                                    Wait(100)
                                end
                                local ped = PlayerPedId()
                                SetPedInfiniteAmmoClip(ped, false)
                            end)
                        end
                        if _G.showNotification then
                            _G.showNotification("success", "Infinite ammo: " .. (setToggle and "ON" or "OFF"))
                        end
                    end
                },
                { 
                    label = 'No Reload',
                    type = 'checkbox',
                    checked = _G.noReload or false,
                    onConfirm = function(setToggle)
                        _G.noReload = setToggle
                        if setToggle then
                            CreateThread(function()
                                while _G.noReload do
                                    local ped = PlayerPedId()
                                    SetPedInfiniteAmmo(ped, true)
                                    Wait(100)
                                end
                                local ped = PlayerPedId()
                                SetPedInfiniteAmmo(ped, false)
                            end)
                        end
                        if _G.showNotification then
                            _G.showNotification("success", "No reload: " .. (setToggle and "ON" or "OFF"))
                        end
                    end
                },
                { 
                    label = 'One Shot Kill',
                    type = 'checkbox',
                    checked = _G.oneShotKill or false,
                    onConfirm = function(setToggle)
                        _G.oneShotKill = setToggle
                        if setToggle then
                            CreateThread(function()
                                while _G.oneShotKill do
                                    local ped = PlayerPedId()
                                    SetPlayerWeaponDamageModifier(PlayerId(), 1000.0)
                                    Wait(100)
                                end
                                SetPlayerWeaponDamageModifier(PlayerId(), 1.0)
                            end)
                        else
                            SetPlayerWeaponDamageModifier(PlayerId(), 1.0)
                        end
                        if _G.showNotification then
                            _G.showNotification("success", "One shot kill: " .. (setToggle and "ON" or "OFF"))
                        end
                    end
                }
            }
        elseif currentTab == 2 then -- Fun
            menuItems = {
                { 
                    label = 'Fireworks',
                    type = 'button',
                    onConfirm = function()
                        local ped = PlayerPedId()
                        local coords = GetEntityCoords(ped)
                        for i = 1, 5 do
                            CreateThread(function()
                                Wait(i * 500)
                                AddExplosion(coords.x + math.random(-10, 10), coords.y + math.random(-10, 10), coords.z + 20.0, 38, 1.0, true, false, 0.0)
                            end)
                        end
                        if _G.showNotification then
                            _G.showNotification("success", "Fireworks launched")
                        end
                    end
                },
                { 
                    label = 'Rain Weapons',
                    type = 'button',
                    onConfirm = function()
                        local ped = PlayerPedId()
                        local coords = GetEntityCoords(ped)
                        CreateThread(function()
                            for i = 1, 20 do
                                Wait(100)
                                local weaponHash = GetHashKey('WEAPON_PISTOL')
                                local pickup = CreatePickup(GetHashKey('PICKUP_WEAPON_PISTOL'), coords.x + math.random(-5, 5), coords.y + math.random(-5, 5), coords.z + 10.0, 0, 1, false)
                            end
                        end)
                        if _G.showNotification then
                            _G.showNotification("success", "Weapons raining")
                        end
                    end
                },
                { 
                    label = 'Explosive Ammo',
                    type = 'checkbox',
                    checked = _G.explosiveAmmo or false,
                    onConfirm = function(setToggle)
                        _G.explosiveAmmo = setToggle
                        if setToggle then
                            CreateThread(function()
                                while _G.explosiveAmmo do
                                    local ped = PlayerPedId()
                                    SetPedInfiniteAmmo(ped, true)
                                    SetPedInfiniteAmmoClip(ped, true)
                                    Wait(100)
                                end
                                local ped = PlayerPedId()
                                SetPedInfiniteAmmo(ped, false)
                                SetPedInfiniteAmmoClip(ped, false)
                            end)
                        end
                        if _G.showNotification then
                            _G.showNotification("success", "Explosive ammo: " .. (setToggle and "ON" or "OFF"))
                        end
                    end
                }
            }
        end
        
        callback(menuItems)
    end
})

table.insert(activeMenu, {
    label = 'Combat',
    type = 'submenu',
    icon = 'ph-sword',
    submenu = {
        { 
            label = 'God Mode',
            type = 'checkbox',
            checked = _G.combatGodMode or false,
            onConfirm = function(setToggle)
                _G.combatGodMode = setToggle
                local ped = PlayerPedId()
                SetEntityInvincible(ped, setToggle)
                if _G.showNotification then
                    _G.showNotification("success", "God mode: " .. (setToggle and "ON" or "OFF"))
                end
            end
        },
        { 
            label = 'No Ragdoll',
            type = 'checkbox',
            checked = _G.noRagdoll or false,
            onConfirm = function(setToggle)
                _G.noRagdoll = setToggle
                local ped = PlayerPedId()
                SetPedCanRagdoll(ped, not setToggle)
                if _G.showNotification then
                    _G.showNotification("success", "No ragdoll: " .. (setToggle and "ON" or "OFF"))
                end
            end
        },
        { 
            label = 'Super Jump',
            type = 'checkbox',
            checked = _G.superJump or false,
            onConfirm = function(setToggle)
                _G.superJump = setToggle
                if setToggle then
                    CreateThread(function()
                        while _G.superJump do
                            SetSuperJumpThisFrame(PlayerId())
                            Wait(0)
                        end
                    end)
                end
                if _G.showNotification then
                    _G.showNotification("success", "Super jump: " .. (setToggle and "ON" or "OFF"))
                end
            end
        }
    }
})

table.insert(activeMenu, {
    label = 'Vehicle',
    type = 'submenu',
    icon = 'ph-car',
    submenu = {
        { 
            label = 'Spawn Vehicle',
            type = 'scroll',
            options = { 'Adder', 'Zentorno', 'T20', 'Osiris', 'Entity XF', 'Turismo R' },
            selected = 1,
            onChange = function(val)
                if type(val) == "number" then
                    _G.vehicleSpawnValue = val
                end
            end,
            onConfirm = function(option)
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local vehicleModels = {
                    ['Adder'] = 'adder',
                    ['Zentorno'] = 'zentorno',
                    ['T20'] = 't20',
                    ['Osiris'] = 'osiris',
                    ['Entity XF'] = 'entityxf',
                    ['Turismo R'] = 'turismor'
                }
                local vehicleOptions = {'Adder', 'Zentorno', 'T20', 'Osiris', 'Entity XF', 'Turismo R'}
                local selectedName = vehicleOptions[_G.vehicleSpawnValue or 1]
                local vehicleModel = vehicleModels[selectedName]
                
                if vehicleModel then
                    local vehicleHash = GetHashKey(vehicleModel)
                    RequestModel(vehicleHash)
                    while not HasModelLoaded(vehicleHash) do
                        Wait(10)
                    end
                    local vehicle = CreateVehicle(vehicleHash, coords.x + 2.0, coords.y, coords.z, 0.0, true, false)
                    SetPedIntoVehicle(ped, vehicle, -1)
                    SetModelAsNoLongerNeeded(vehicleHash)
                    if _G.showNotification then
                        _G.showNotification("success", "Vehicle spawned: " .. selectedName)
                    end
                end
            end
        },
        { 
            label = 'Repair Vehicle',
            type = 'button',
            onConfirm = function()
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle ~= 0 then
                    SetVehicleFixed(vehicle)
                    SetVehicleDeformationFixed(vehicle)
                    SetVehicleUndriveable(vehicle, false)
                    SetVehicleEngineOn(vehicle, true, true)
                    if _G.showNotification then
                        _G.showNotification("success", "Vehicle repaired")
                    end
                else
                    if _G.showNotification then
                        _G.showNotification("error", "You are not in a vehicle!")
                    end
                end
            end
        },
        { 
            label = 'God Mode Vehicle',
            type = 'checkbox',
            checked = _G.vehicleGodMode or false,
            onConfirm = function(setToggle)
                _G.vehicleGodMode = setToggle
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle ~= 0 then
                    SetEntityInvincible(vehicle, setToggle)
                    if _G.showNotification then
                        _G.showNotification("success", "Vehicle god mode: " .. (setToggle and "ON" or "OFF"))
                    end
                else
                    if _G.showNotification then
                        _G.showNotification("error", "You are not in a vehicle!")
                    end
                end
            end
        },
        { 
            label = 'Speed Multiplier',
            type = 'slider',
            min = 1,
            max = 10,
            value = _G.vehicleSpeedMultiplier or 1,
            step = 0.1,
            onChange = function(val)
                _G.vehicleSpeedMultiplier = val
            end,
            onConfirm = function(val)
                _G.vehicleSpeedMultiplier = val
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle ~= 0 then
                    SetVehicleEnginePowerMultiplier(vehicle, val)
                    if _G.showNotification then
                        _G.showNotification("success", "Speed multiplier: " .. string.format("%.1f", val))
                    end
                else
                    if _G.showNotification then
                        _G.showNotification("error", "You are not in a vehicle!")
                    end
                end
            end
        }
    }
})

table.insert(activeMenu, {
    label = 'Visual',
    type = 'submenu',
    icon = 'ph-eye',
    submenu = {
        { 
            label = 'ESP',
            type = 'checkbox',
            checked = false,
            onConfirm = function(setToggle)
                print('ESP:', setToggle)
            end
        },
        { 
            label = 'Crosshair',
            type = 'checkbox',
            checked = false,
            onConfirm = function(setToggle)
                print('Crosshair:', setToggle)
            end
        },
        { 
            label = 'No Clip',
            type = 'checkbox',
            checked = false,
            onConfirm = function(setToggle)
                print('No clip:', setToggle)
            end
        }
    }
})

table.insert(activeMenu, {
    label = 'Miscellaneous',
    type = 'submenu',
    icon = 'ph-list',
    submenu = {
        { 
            label = 'Clear Area',
            type = 'slider',
            min = 5,
            max = 50,
            value = 10,
            step = 5,
            onChange = function(val)
                _G.clearAreaRadius = val
            end,
            onConfirm = function(val)
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                ClearAreaLeaveVehicleHealth(coords.x, coords.y, coords.z, val + 0.0, false, false, false, false, false)
                if _G.showNotification then
                    _G.showNotification("success", "Area cleared (radius: " .. val .. "m)")
                end
            end
        },
        { 
            label = 'Change Weather',
            type = 'scroll',
            selected = 1,
            options = { 'Clear', 'Cloudy', 'Rain', 'Fog', 'Snow', 'Thunder' },
            onChange = function(val)
                if type(val) == "number" then
                    _G.weatherValue = val
                end
            end,
            onConfirm = function(option)
                local weatherOptions = {'Clear', 'Cloudy', 'Rain', 'Fog', 'Snow', 'Thunder'}
                local selectedWeather = weatherOptions[_G.weatherValue or 1]
                local weatherHashes = {
                    ['Clear'] = 'CLEAR',
                    ['Cloudy'] = 'CLOUDS',
                    ['Rain'] = 'RAIN',
                    ['Fog'] = 'FOGGY',
                    ['Snow'] = 'SNOW',
                    ['Thunder'] = 'THUNDER'
                }
                local weatherHash = weatherHashes[selectedWeather]
                if weatherHash then
                    SetWeatherTypeNow(weatherHash)
                    if _G.showNotification then
                        _G.showNotification("success", "Weather changed to: " .. selectedWeather)
                    end
                end
            end
        }
    }
})

table.insert(activeMenu, {
    label = 'Settings',
    type = 'submenu',
    icon = 'ph-gear',
    submenu = {
        { 
            label = 'Menu Position',
            type = 'scroll',
            selected = 1,
            options = { 'Left', 'Right' },
            onConfirm = function(option)
                print('Menu position:', option)
            end
        },
        { 
            label = 'Menu Opacity',
            type = 'slider',
            min = 0,
            max = 100,
            value = 80,
            onConfirm = function(val)
                print('Menu opacity:', val)
            end
        },
        { 
            label = 'Notifications',
            type = 'checkbox',
            checked = true,
            onConfirm = function(setToggle)
                print('Notifications:', setToggle)
            end
        }
    }
})

table.insert(activeMenu, {
    label = 'Search',
    type = 'button',
    icon = 'ph-magnifying-glass',
    onConfirm = function()
        print('Search pressed')
    end
})

-- ===================== SAFE COPY FOR DUI =====================
local function safeMenuCopy(menu)
    local copy = {}
    for i, v in ipairs(menu) do
        local item = {
            label = v.label or "",
            type = v.type or ""
        }
        if v.icon then item.icon = v.icon end

        if v.type == "scroll" then
            item.options = {}
            for _, opt in ipairs(v.options or {}) do
                if type(opt) == "string" or type(opt) == "number" then
                    table.insert(item.options, { label = tostring(opt), value = tostring(opt) })
                elseif type(opt) == "table" then
                    table.insert(item.options, {
                        label = tostring(opt.label or opt[1] or ""),
                        value = tostring(opt.value or opt.label or opt[1] or "")
                    })
                else
                    table.insert(item.options, { label = tostring(opt), value = tostring(opt) })
                end
            end
            if #item.options == 0 then
                item.options = {{ label = "(empty)", value = "(empty)" }}
            end
            local sel = v.selected or 1
            if sel < 1 then sel = 1 end
            if sel > #item.options then sel = #item.options end
            item.selected = sel - 1 -- 0-based for JS
            if v.hasToggle then
                item.hasToggle = true
                item.checked = v.checked == true
            end
        elseif v.type == "slider" then
            item.min = v.min or 0
            item.max = v.max or 100
            item.value = v.value or item.min
        elseif v.type == "checkbox" then
            item.checked = v.checked == true
            if v.godmodeType then
                item.godmodeType = v.godmodeType
                item.godmodeLabel = (v.godmodeType == 1) and '- Safe -' or '- Risky -'
            end
            if v.bypassLabel then
                item.bypassLabel = v.bypassLabel
            end
            if v.hasSlider then
                item.hasSlider = true
                item.sliderMin = v.sliderMin or 0
                item.sliderMax = v.sliderMax or 100
                item.sliderValue = v.sliderValue or v.sliderMin or 0
                item.sliderStep = v.sliderStep or 1
            end
        elseif v.type == "submenu" then
            if type(v.submenu) == "table" then
                item.submenu = safeMenuCopy(v.submenu)
            else
                item.dynamic = type(v.getSubMenu) == "function"
            end
        end
        copy[i] = item
    end
    return copy
end

-- ===================== HELPERS =====================
local function unloadMenu()
    _G.clientMenuShowing = false
end

local function setCurrent()
    if dui then
        local message = {
            action = 'setCurrent',
            current = activeIndex,
            menu = safeMenuCopy(activeMenu)
        }
        
        -- Check if current menu has tabs (from nested menu context)
        if _G.currentMenuTabs then
            message.tabs = _G.currentMenuTabs
            message.tabIndex = _G.currentMenuTabIndex or 0
        end
        
        MachoSendDuiMessage(dui, json.encode(message))
        print('setCurrent called with index:', activeIndex)
    end
end

local function isControlPressed(control)
    return IsControlPressed(0, control) or IsDisabledControlPressed(0, control)
end

local function isControlJustPressed(control)
    return IsControlJustPressed(0, control) or IsDisabledControlJustPressed(0, control)
end

local function isControlJustReleased(control)
    return IsControlJustReleased(0, control) or IsDisabledControlJustReleased(0, control)
end

-- Helper function to find next selectable index (skipping dividers)
local function findNextSelectableIndex(menu, currentIndex, direction)
    if not menu or #menu == 0 then return 1 end
    
    local step = direction == 'down' and 1 or -1
    local newIndex = currentIndex + step
    
    -- Wrap around
    if newIndex < 1 then newIndex = #menu end
    if newIndex > #menu then newIndex = 1 end
    
    -- Skip dividers
    local attempts = 0
    while menu[newIndex] and menu[newIndex].type == 'divider' and attempts < #menu do
        newIndex = newIndex + step
        if newIndex < 1 then newIndex = #menu end
        if newIndex > #menu then newIndex = 1 end
        attempts = attempts + 1
    end
    
    return newIndex
end

-- ===================== MAIN THREAD =====================
CreateThread(function()
    -- Check authentication before initializing menu
    if not checkAuthentication() then
        print("^1[Menu] Menu initialization blocked - Unauthorized user^0")
        return
    end
    
    dui = MachoCreateDui("http://localhost:5173/")
    print('DUI created')
    MachoShowDui(dui)
    
    -- Send authentication success notification
    MachoMenuNotification("Menu Access", "Welcome! Menu initialized successfully.")

    _G.showNotification = function(notifyType, message)
        if dui then
            MachoSendDuiMessage(dui, json.encode({
                action = 'notify',
                type = notifyType,
                message = tostring(message)
            }))
            print('Notification sent:', notifyType, message)
        end
    end

    _G.changeMenuPosition = function(position)
        if dui then
            MachoSendDuiMessage(dui, json.encode({
                action = 'position',
                position = position
            }))
            print('Position changed to:', position)
        end
    end

    Wait(1000)
    -- Ensure initial index is not a divider
    if activeMenu[activeIndex] and activeMenu[activeIndex].type == 'divider' then
        activeIndex = findNextSelectableIndex(activeMenu, activeIndex, 'down')
    end
    setCurrent()

    local showing = true
    local nestedMenus = {}
    local currentSubMenuRefresher = nil
    local isDynamicSubMenu = false
    local menuStateMap = {}
    local baseDelay = 250
    local minDelay = 50
    local speedupStep = 30
    local holdTimers = {
        ['ArrowLeft'] = {lastTime = 0, delay = 100, pressCount = 0},
        ['ArrowRight'] = {lastTime = 0, delay = 100, pressCount = 0},
    }
    
    -- Slider speed multipliers (for step increments)
    local sliderSpeedMultipliers = {1, 2, 4, 6, 8, 10}

    _G.clientMenuShowing = true

    while _G.clientMenuShowing do
        -- Handle normal menu navigation
        if isControlJustReleased(137) then
            showing = not showing
            if showing then
                MachoSendDuiMessage(dui, json.encode({
                    action = 'setVisible',
                    visible = true
                }))
                print('Menu shown')
            else
                MachoSendDuiMessage(dui, json.encode({
                    action = 'setVisible',
                    visible = false
                }))
                print('Menu hidden')
            end
        elseif showing then
            local now = GetGameTimer()
            for control, bind in pairs({
                ['ArrowUp'] = 188,
                ['ArrowDown'] = 187,
                ['ArrowLeft'] = 189,
                ['ArrowRight'] = 190,
                ['Backspace'] = 194,
                ['Enter'] = 191
            }) do
                if control == 'ArrowLeft' or control == 'ArrowRight' then
                    local timer = holdTimers[control]
                    if isControlPressed(bind) then
                        if now - timer.lastTime >= timer.delay then
                            timer.lastTime = now
                            timer.delay = math.max(minDelay, timer.delay - speedupStep)
                            
                            -- Increase press count for slider speed
                            local activeData = activeMenu[activeIndex]
                            if activeData and (activeData.type == 'slider' or (activeData.type == 'checkbox' and activeData.hasSlider)) then
                                timer.pressCount = timer.pressCount + 1
                            else
                                timer.pressCount = 0
                            end

                            local activeData = activeMenu[activeIndex]
                            local setType = activeData.type
                            local onChange = activeData.onChange

                            if control == 'ArrowLeft' then
                                if setType == 'scroll' then
                                    local selected = (activeData.selected or 1) - 1
                                    if selected <= 0 then selected = #activeData.options end
                                    activeData.selected = selected
                                    if onChange then onChange(selected) end
                                elseif setType == 'slider' then
                                    local minVal = activeData.min or 0
                                    local maxVal = activeData.max or 100
                                    local currentVal = activeData.value or minVal
                                    local baseStep = activeData.step or 1
                                    
                                    -- Calculate speed multiplier based on press count
                                    local speedIndex = math.min(math.floor(timer.pressCount / 5) + 1, #sliderSpeedMultipliers)
                                    local speedMultiplier = sliderSpeedMultipliers[speedIndex] or 1
                                    local adjustedStep = baseStep * speedMultiplier
                                    
                                    local newValue = math.max(minVal, math.min(maxVal, currentVal - adjustedStep))
                                    activeData.value = newValue
                                    if onChange then onChange(newValue) end
                                elseif setType == 'checkbox' then
                                    if activeData.hasSlider and activeData.onSliderChange then
                                        -- Handle slider change for checkbox with slider
                                        local minVal = activeData.sliderMin or 0
                                        local maxVal = activeData.sliderMax or 100
                                        local currentVal = activeData.sliderValue or minVal
                                        local baseStep = activeData.sliderStep or 0.1
                                        
                                        -- Calculate speed multiplier based on press count
                                        local speedIndex = math.min(math.floor(timer.pressCount / 5) + 1, #sliderSpeedMultipliers)
                                        local speedMultiplier = sliderSpeedMultipliers[speedIndex] or 1
                                        local adjustedStep = baseStep * speedMultiplier
                                        
                                        local newValue = math.max(minVal, math.min(maxVal, currentVal - adjustedStep))
                                        activeData.sliderValue = newValue
                                        if activeData.onSliderChange then activeData.onSliderChange(newValue) end
                                    elseif onChange then
                                        onChange('left')
                                    end
                                    setCurrent()
                                end
                            elseif control == 'ArrowRight' then
                                if setType == 'scroll' then
                                    local selected = (activeData.selected or 1) + 1
                                    if selected > #activeData.options then selected = 1 end
                                    activeData.selected = selected
                                    if onChange then onChange(selected) end
                                elseif setType == 'slider' then
                                    local minVal = activeData.min or 0
                                    local maxVal = activeData.max or 100
                                    local currentVal = activeData.value or minVal
                                    local baseStep = activeData.step or 1
                                    
                                    -- Calculate speed multiplier based on press count
                                    local speedIndex = math.min(math.floor(timer.pressCount / 5) + 1, #sliderSpeedMultipliers)
                                    local speedMultiplier = sliderSpeedMultipliers[speedIndex] or 1
                                    local adjustedStep = baseStep * speedMultiplier
                                    
                                    local newValue = math.max(minVal, math.min(maxVal, currentVal + adjustedStep))
                                    activeData.value = newValue
                                    if onChange then onChange(newValue) end
                                elseif setType == 'checkbox' then
                                    if activeData.hasSlider and activeData.onSliderChange then
                                        -- Handle slider change for checkbox with slider
                                        local minVal = activeData.sliderMin or 0
                                        local maxVal = activeData.sliderMax or 100
                                        local currentVal = activeData.sliderValue or minVal
                                        local baseStep = activeData.sliderStep or 0.1
                                        
                                        -- Calculate speed multiplier based on press count
                                        local speedIndex = math.min(math.floor(timer.pressCount / 5) + 1, #sliderSpeedMultipliers)
                                        local speedMultiplier = sliderSpeedMultipliers[speedIndex] or 1
                                        local adjustedStep = baseStep * speedMultiplier
                                        
                                        local newValue = math.max(minVal, math.min(maxVal, currentVal + adjustedStep))
                                        activeData.sliderValue = newValue
                                        if activeData.onSliderChange then activeData.onSliderChange(newValue) end
                                    elseif onChange then
                                        onChange('right')
                                    end
                                    setCurrent()
                                end
                            end
                            setCurrent()
                        end
                    else
                        timer.delay = baseDelay
                        timer.lastTime = 0
                        timer.pressCount = 0
                    end
                elseif isControlJustPressed(bind) then
                    if control == 'ArrowDown' then
                        activeIndex = findNextSelectableIndex(activeMenu, activeIndex, 'down')
                        setCurrent()
                        print('Navigated down to index:', activeIndex)
                    elseif control == 'ArrowUp' then
                        activeIndex = findNextSelectableIndex(activeMenu, activeIndex, 'up')
                        setCurrent()
                        print('Navigated up to index:', activeIndex)
                    elseif control == 'Enter' then
                        local activeData = activeMenu[activeIndex]
                        print('Enter pressed on:', activeData.label, activeData.type)
                        if activeData.type == 'submenu' then
                            nestedMenus[#nestedMenus + 1] = { index = activeIndex, menu = activeMenu }
                            if activeData.submenu then
                                menuStateMap[activeData.label or ''] = activeIndex
                                activeIndex = 1
                                activeMenu = activeData.submenu
                                -- Skip dividers if first item is a divider
                                if activeMenu[activeIndex] and activeMenu[activeIndex].type == 'divider' then
                                    activeIndex = findNextSelectableIndex(activeMenu, activeIndex, 'down')
                                end
                                currentSubMenuRefresher = nil
                                isDynamicSubMenu = false
                                setCurrent()
                                print('Entered submenu:', activeData.label)
                            else
                                currentSubMenuRefresher = activeData.getSubMenu
                                isDynamicSubMenu = true
                                
                                -- Check if this menu has tabs
                                if activeData.tabs then
                                    _G.currentMenuTabs = activeData.tabs
                                    _G.currentMenuTabIndex = 0
                                    
                                    -- Set appropriate tab variable based on menu label
                                    if activeData.label == 'Server' then
                                        _G.serverMenuTab = 0
                                    elseif activeData.label == 'Player' then
                                        _G.playerMenuTab = 0
                                    elseif activeData.label == 'Weapon' then
                                        _G.weaponMenuTab = 0
                                    end
                                else
                                    _G.currentMenuTabs = nil
                                    _G.currentMenuTabIndex = nil
                                end
                                
                                activeData.getSubMenu(function(setMenu)
                                    menuStateMap[activeData.label or ''] = activeIndex
                                    activeIndex = math.min(menuStateMap[activeData.label or ''] or 1, #setMenu)
                                    activeMenu = setMenu
                                    -- Skip dividers if current index is a divider
                                    if activeMenu[activeIndex] and activeMenu[activeIndex].type == 'divider' then
                                        activeIndex = findNextSelectableIndex(activeMenu, activeIndex, 'down')
                                    end
                                    setCurrent()
                                    print('Entered dynamic submenu:', activeData.label)
                                end)
                            end
                        else
                            if activeData.type == 'checkbox' then
                                activeData.checked = not activeData.checked
                                setCurrent()
                                if activeData.onConfirm then activeData.onConfirm(activeData.checked) end
                                print('Checkbox toggled:', activeData.checked)
                            elseif activeData.type == 'scroll' then
                                if activeData.hasToggle then
                                    -- Toggle the checkbox
                                    activeData.checked = not (activeData.checked or false)
                                    setCurrent()
                                    if activeData.onConfirm then 
                                        local success, err = pcall(activeData.onConfirm, activeData.checked)
                                        if not success then
                                            print('Error in scroll toggle onConfirm:', err)
                                        end
                                    end
                                    print('Scroll toggle:', activeData.checked)
                                else
                                    if activeData.onConfirm then
                                        local selectedIndex = activeData.selected or 1
                                        local options = activeData.options or {}
                                        if options[selectedIndex] then
                                            local selectedOption = options[selectedIndex]
                                            local success, err = pcall(activeData.onConfirm, selectedOption)
                                            if not success then
                                                print('Error in scroll onConfirm:', err)
                                            end
                                            print('Scroll confirmed:', selectedOption)
                                        end
                                    end
                                end
                            elseif activeData.onConfirm then
                                if activeData.type == 'slider' then
                                    activeData.onConfirm(activeData.value)
                                    print('Slider confirmed:', activeData.value)
                                elseif activeData.type == 'button' then
                                    activeData.onConfirm()
                                    print('Button confirmed')
                                end
                            end
                        end
                    elseif control == 'Backspace' then
                        local lastMenu = nestedMenus[#nestedMenus]
                        if lastMenu then
                            table.remove(nestedMenus)
                            activeMenu = lastMenu.menu
                            activeIndex = lastMenu.index
                            -- Skip dividers if returned index is a divider
                            if activeMenu[activeIndex] and activeMenu[activeIndex].type == 'divider' then
                                activeIndex = findNextSelectableIndex(activeMenu, activeIndex, 'down')
                            end
                            _G.currentMenuTabs = nil
                            _G.currentMenuTabIndex = nil
                            _G.serverMenuTab = nil
                            _G.playerMenuTab = nil
                            _G.weaponMenuTab = nil
                            setCurrent()
                            print('Returned to previous menu, index:', activeIndex)
                        else
                            showing = false
                            MachoSendDuiMessage(dui, json.encode({
                                action = 'setVisible',
                                visible = false
                            }))
                            print('Menu closed')
                        end
                        currentSubMenuRefresher = nil
                        isDynamicSubMenu = false
                    end
                end
            end
            
            -- Handle tab navigation with E (right) and Q (left)
            if showing and _G.currentMenuTabs and isDynamicSubMenu and currentSubMenuRefresher then
                -- Determine which menu tab variable to use
                local currentTab = 0
                if _G.serverMenuTab ~= nil then
                    currentTab = _G.serverMenuTab
                elseif _G.playerMenuTab ~= nil then
                    currentTab = _G.playerMenuTab
                elseif _G.weaponMenuTab ~= nil then
                    currentTab = _G.weaponMenuTab
                end
                
                if isControlJustPressed(38) then -- E key (right/next tab)
                    local maxTab = #_G.currentMenuTabs - 1
                    currentTab = currentTab + 1
                    if currentTab > maxTab then currentTab = 0 end
                    
                    -- Update appropriate tab variable
                    if _G.serverMenuTab ~= nil then
                        _G.serverMenuTab = currentTab
                    elseif _G.playerMenuTab ~= nil then
                        _G.playerMenuTab = currentTab
                    elseif _G.weaponMenuTab ~= nil then
                        _G.weaponMenuTab = currentTab
                    end
                    _G.currentMenuTabIndex = currentTab
                    
                    -- Refresh menu with new tab
                    currentSubMenuRefresher(function(setMenu)
                        activeIndex = math.min(activeIndex, #setMenu)
                        activeMenu = setMenu
                        setCurrent()
                        print('Switched to tab:', _G.currentMenuTabs[currentTab + 1])
                    end)
                elseif isControlJustPressed(44) then -- Q key (left/previous tab)
                    local maxTab = #_G.currentMenuTabs - 1
                    currentTab = currentTab - 1
                    if currentTab < 0 then currentTab = maxTab end
                    
                    -- Update appropriate tab variable
                    if _G.serverMenuTab ~= nil then
                        _G.serverMenuTab = currentTab
                    elseif _G.playerMenuTab ~= nil then
                        _G.playerMenuTab = currentTab
                    elseif _G.weaponMenuTab ~= nil then
                        _G.weaponMenuTab = currentTab
                    end
                    _G.currentMenuTabIndex = currentTab
                    
                    -- Refresh menu with new tab
                    currentSubMenuRefresher(function(setMenu)
                        activeIndex = math.min(activeIndex, #setMenu)
                        activeMenu = setMenu
                        setCurrent()
                        print('Switched to tab:', _G.currentMenuTabs[currentTab + 1])
                    end)
                end
            end
        end
        Wait(0)
    end

    if dui then
        MachoDestroyDui(dui)
        print('DUI destroyed')
    end
    dui = nil
end)