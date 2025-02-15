--#region Variables

local weatherIndexes = {
    ['EXTRASUNNY'] = {4, 'Extra Sunny'},
    ['CLEAR'] = {5, 'Clear'},
    ['NEUTRAL'] = {6, 'Neutral'},
    ['SMOG'] = {7, 'Smog'},
    ['FOGGY'] = {8, 'Foggy'},
    ['CLOUDS'] = {9, 'Cloudy'},
    ['OVERCAST'] = {10, 'Overcast'},
    ['CLEARING'] = {11, 'Clearing'},
    ['RAIN'] = {12, 'Rainy'},
    ['THUNDER'] = {13, 'Thunder'},
    ['BLIZZARD'] = {14, 'Blizzard'},
    ['SNOW'] = {15, 'Snow'},
    ['SNOWLIGHT'] = {16, 'Light Snow'},
    ['XMAS'] = {17, 'X-MAS Snow'},
    ['HALLOWEEN'] = {18, 'Halloween'}
}

local timeSyncedWithMachine = GetConvar('berkie_menu_sync_time_to_machine_time', 'false') == 'true'
local timeFrozen = GetConvar('berkie_menu_freeze_time', 'false') == 'true'
local currentHour = tonumber(GetConvar('berkie_menu_current_hour', '7')) --[[@as number]]
local currentMinute = tonumber(GetConvar('berkie_menu_current_minute', '0')) --[[@as number]]
currentHour = currentHour < 0 and 0 or currentHour > 23 and 23 or currentHour
currentMinute = currentMinute < 0 and 0 or currentMinute > 23 and 23 or currentMinute
local showTimeOnScreen = false
local dynamicWeather = GetConvar('berkie_menu_dynamic_weather', 'true') == 'true'
local blackout = GetConvar('berkie_menu_enable_blackout', 'false') == 'true'
local snowEffects = GetConvar('berkie_menu_enable_snow_effects', 'false') == 'true'
local checkedDynamicWeather = dynamicWeather
local checkedBlackout = blackout
local checkedSnowEffects = snowEffects
local currentWeather = GetConvar('berkie_menu_current_weather', 'EXTRASUNNY'):upper()
currentWeather = not weatherIndexes[currentWeather] and 'EXTRASUNNY' or currentWeather
local currentChecked = 'EXTRASUNNY' -- Leave this so the checkmark can move itself accordingly in the loop
local weatherChangeTime = tonumber(GetConvar('berkie_menu_weather_change_time', '5')) --[[@as number]]
weatherChangeTime = weatherChangeTime < 0 and 0 or weatherChangeTime
local changingWeather = false

--#endregion Variables

--#region Functions

local function drawTextOnScreen(text, x, y, size, position --[[ 0: center | 1: left | 2: right ]], font, disableTextOutline)
    if
    not IsHudPreferenceSwitchedOn()
    or IsHudHidden()
    or IsPlayerSwitchInProgress()
    or IsScreenFadedOut()
    or IsPauseMenuActive()
    or IsFrontendFading()
    or IsPauseMenuRestarting()
    then
        return
    end

    size = size or 0.48
    position = position or 1
    font = font or 6

    SetTextFont(font)
    SetTextScale(1.0, size)
    if position == 2 then
        SetTextWrap(0, x)
    end
    SetTextJustification(position)
    if not disableTextOutline then
        SetTextOutline()
    end
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

--#endregion Functions

--#region Menu Registration

lib.registerMenu({
    id = 'berkie_menu_world_related_options',
    title = 'World Related Options',
    position = 'top-right',
    onClose = function(keyPressed)
        CloseMenu(false, keyPressed, 'berkie_menu_main')
    end,
    onSelected = function(selected)
        MenuIndexes['berkie_menu_world_related_options'] = selected
    end,
    options = {
        {label = 'Time Options', args = {'berkie_menu_time_options'}},
        {label = 'Weather Options', args = {'berkie_menu_weather_options'}}
    }
}, function(_, _, args)
    lib.showMenu(args[1], MenuIndexes[args[1]])
end)

lib.registerMenu({
    id = 'berkie_menu_time_options',
    title = 'Time Options',
    position = 'top-right',
    onClose = function(keyPressed)
        CloseMenu(false, keyPressed, 'berkie_menu_world_related_options')
    end,
    onSelected = function(selected)
        MenuIndexes['berkie_menu_time_options'] = selected
    end,
    onCheck = function(_, checked, args)
        if args[1] == 'show_time' then
            showTimeOnScreen = checked
            lib.setMenuOptions('berkie_menu_time_options', {label = 'Show Time On Screen', args = {'show_time'}, checked = showTimeOnScreen, close = false}, 3)
        end
    end,
    options = {
        {label = 'Freeze/Unfreeze Time', args = {'freeze_time'}, close = false},
        {label = 'Sync Time To Server', args = {'sync_to_server'}, close = false},
        {label = 'Show Time On Screen', args = {'show_time'}, checked = showTimeOnScreen, close = false},
        {label = 'Early Morning (06:00, 6 AM)', args = {'set_time_preset', 6}, close = false},
        {label = 'Morning (09:00, 9 AM)', args = {'set_time_preset', 9}, close = false},
        {label = 'Noon (12:00, 12 PM)', args = {'set_time_preset', 12}, close = false},
        {label = 'Early Afternoon (15:00, 3 PM)', args = {'set_time_preset', 15}, close = false},
        {label = 'Afternoon (18:00, 6 PM)', args = {'set_time_preset', 18}, close = false},
        {label = 'Evening (21:00, 9 PM)', args = {'set_time_preset', 21}, close = false},
        {label = 'Midnight (00:00, 12 AM)', args = {'set_time_preset', 0}, close = false},
        {label = 'Night (03:00, 3 AM)', args = {'set_time_preset', 3}, close = false},
        {label = 'Set Custom Hour', args = {'set_time_custom', 'hours'}, values = {'00', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23'}, close = false},
        {label = 'Set Custom Minute', args = {'set_time_custom', 'minutes'}, values = {'00', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31', '32', '33', '34', '35', '36', '37', '38', '39', '40', '41', '42', '43', '44', '45', '46', '47', '48', '49', '50', '51', '52', '53', '54', '55', '56', '57', '58', '59'}, close = false}
    }
}, function(_, scrollIndex, args)
    timeSyncedWithMachine = GetConvar('berkie_menu_sync_time_to_machine_time', 'false') == 'true'

    if args[1] == 'sync_to_server' then
        TriggerServerEvent('berkie_menu:server:updateTime', currentHour, currentMinute, timeFrozen, not timeSyncedWithMachine)
    end

    if timeSyncedWithMachine and args[1] ~= 'sync_to_server' then
        lib.notify({
            description = 'Can\'t change the time when the time is synced to the server',
            type = 'error'
        })
        return
    end

    timeFrozen = GetConvar('berkie_menu_freeze_time', 'false') == 'true'
    if args[1] == 'freeze_time' then
        TriggerServerEvent('berkie_menu:server:updateTime', currentHour, currentMinute, not timeFrozen, timeSyncedWithMachine)
    elseif args[1] == 'set_time_preset' then
        TriggerServerEvent('berkie_menu:server:updateTime', args[2], 0, timeFrozen, timeSyncedWithMachine)
    elseif args[1] == 'set_time_custom' then
        if args[2] == 'hours' then
            local hour = scrollIndex - 1
            TriggerServerEvent('berkie_menu:server:updateTime', hour, currentMinute, timeFrozen, timeSyncedWithMachine)
        elseif args[2] == 'minutes' then
            local minute = scrollIndex - 1
            TriggerServerEvent('berkie_menu:server:updateTime', currentHour, minute, timeFrozen, timeSyncedWithMachine)
        end
    end
end)

lib.registerMenu({
    id = 'berkie_menu_weather_options',
    title = 'Weather Options',
    position = 'top-right',
    onClose = function(keyPressed)
        CloseMenu(false, keyPressed, 'berkie_menu_world_related_options')
    end,
    onSelected = function(selected)
        MenuIndexes['berkie_menu_weather_options'] = selected
    end,
    onCheck = function(_, checked, args)
        blackout = GetConvar('berkie_menu_enable_blackout', 'false') == 'true'
        snowEffects = GetConvar('berkie_menu_enable_snow_effects', 'false') == 'true'
        dynamicWeather = GetConvar('berkie_menu_dynamic_weather', 'true') == 'true'

        if args[1] == 'dynamic_weather' then
            checkedDynamicWeather = checked
            TriggerServerEvent('berkie_menu:server:updateWeather', currentWeather, blackout, checked, snowEffects)
            lib.setMenuOptions('berkie_menu_weather_options', {label = 'Dynamic Weather', description = 'Whether to randomize the state of the weather or not', args = {'dynamic_weather'}, checked = checked, close = false}, 1)
        elseif args[1] == 'blackout' then
            checkedBlackout = checked
            TriggerServerEvent('berkie_menu:server:updateWeather', currentWeather, checked, dynamicWeather, snowEffects)
            lib.setMenuOptions('berkie_menu_weather_options', {label = 'Blackout', description = 'If turned on, disables all light sources', args = {'blackout'}, checked = checked, close = false}, 2)
        elseif args[1] == 'snow_effects' then
            checkedSnowEffects = checked
            TriggerServerEvent('berkie_menu:server:updateWeather', currentWeather, blackout, dynamicWeather, checked)
            lib.setMenuOptions('berkie_menu_weather_options', {label = 'Snow Effects', description = 'This will force snow to appear on the ground and enable snow particles for peds and vehicles. Combine with X-MAS or Light Snow for the best results', args = {'snow_effects'}, checked = checked, close = false}, 3)
        end
    end,
    options = {
        {label = 'Dynamic Weather', description = 'Whether to randomize the state of the weather or not', args = {'dynamic_weather'}, checked = checkedDynamicWeather, close = false},
        {label = 'Blackout', description = 'If turned on, disables all light sources', args = {'blackout'}, checked = checkedBlackout, close = false},
        {label = 'Snow Effects', description = 'This will force snow to appear on the ground and enable snow particles for peds and vehicles. Combine with X-MAS or Light Snow for the best results', args = {'snow_effects'}, checked = checkedSnowEffects, close = false},
        {label = 'Extra Sunny', icon = 'circle-check', args = {'set_weather', 'EXTRASUNNY'}, close = false},
        {label = 'Clear', args = {'set_weather', 'CLEAR'}, close = false},
        {label = 'Neutral', args = {'set_weather', 'NEUTRAL'}, close = false},
        {label = 'Smog', args = {'set_weather', 'SMOG'}, close = false},
        {label = 'Foggy', args = {'set_weather', 'FOGGY'}, close = false},
        {label = 'Cloudy', args = {'set_weather', 'CLOUDS'}, close = false},
        {label = 'Overcast', args = {'set_weather', 'OVERCAST'}, close = false},
        {label = 'Clearing', args = {'set_weather', 'CLEARING'}, close = false},
        {label = 'Rainy', args = {'set_weather', 'RAIN'}, close = false},
        {label = 'Thunder', args = {'set_weather', 'THUNDER'}, close = false},
        {label = 'Blizzard', args = {'set_weather', 'BLIZZARD'}, close = false},
        {label = 'Snow', args = {'set_weather', 'SNOW'}, close = false},
        {label = 'Light Snow', args = {'set_weather', 'SNOWLIGHT'}, close = false},
        {label = 'X-MAS Snow', args = {'set_weather', 'XMAS'}, close = false},
        {label = 'Halloween', args = {'set_weather', 'HALLOWEEN'}, close = false},
        {label = 'Remove All Clouds', args = {'remove_clouds'}, close = false},
        {label = 'Randomize Clouds', args = {'randomize_clouds'}, close = false}
    }
}, function(_, _, args)
    if args[1] == 'set_weather' then
        if changingWeather then
            lib.notify({
                description = 'Already changing weather, please wait',
                type = 'error'
            })
            return
        end

        lib.notify({
            description = ('Changing weather to %s'):format(weatherIndexes[args[2]][2]),
            type = 'inform',
            duration = weatherChangeTime * 1000 + 2000
        })
        changingWeather = true
        blackout = GetConvar('berkie_menu_enable_blackout', 'false') == 'true'
        snowEffects = GetConvar('berkie_menu_enable_snow_effects', 'false') == 'true'
        dynamicWeather = GetConvar('berkie_menu_dynamic_weather', 'true') == 'true'
        TriggerServerEvent('berkie_menu:server:updateWeather', args[2], blackout, dynamicWeather, snowEffects)
    elseif args[1] == 'remove_clouds' then
        TriggerServerEvent('berkie_menu:server:setClouds', true)
    elseif args[1] == 'randomize_clouds' then
        TriggerServerEvent('berkie_menu:server:setClouds', false)
    end
end)

--#endregion Menu Registration

--#region Events

RegisterNetEvent('berkie_menu:client:setClouds', function(opacity, cloudType)
    if opacity == 0 and cloudType == 'removed' then
        ClearCloudHat()
        return
    end

    SetCloudHatOpacity(opacity)
    LoadCloudHat(cloudType, 4)
end)

--#endregion Events

--#region Threads

CreateThread(function()
    local sleep = 100
    while true do
        if showTimeOnScreen then
            sleep = 0
            drawTextOnScreen(('Current Time: %s:%s'):format(currentHour < 10 and '0'..currentHour or currentHour, currentMinute < 10 and '0'..currentMinute or currentMinute), 0.5, 0.0)
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        currentHour = tonumber(GetConvar('berkie_menu_current_hour', '7')) --[[@as number]]
        currentMinute = tonumber(GetConvar('berkie_menu_current_minute', '0')) --[[@as number]]
        currentHour = currentHour < 0 and 0 or currentHour > 23 and 23 or currentHour
        currentMinute = currentMinute < 0 and 0 or currentMinute > 59 and 59 or currentMinute
        NetworkOverrideClockTime(currentHour, currentMinute, 0)
        Wait(1000)
    end
end)

CreateThread(function()
    local changedThings = false
    while true do
        blackout = GetConvar('berkie_menu_enable_blackout', 'false') == 'true'
        snowEffects = GetConvar('berkie_menu_enable_snow_effects', 'false') == 'true'
        dynamicWeather = GetConvar('berkie_menu_dynamic_weather', 'true') == 'true'

        if checkedBlackout ~= blackout then
            lib.setMenuOptions('berkie_menu_weather_options', {label = 'Blackout', description = 'If turned on, disables all light sources', args = {'blackout'}, checked = blackout, close = false}, 2)
            checkedBlackout = blackout
            changedThings = true
        end

        if checkedSnowEffects ~= snowEffects then
            lib.setMenuOptions('berkie_menu_weather_options', {label = 'Snow Effects', description = 'This will force snow to appear on the ground and enable snow particles for peds and vehicles. Combine with X-MAS or Light Snow for the best results', args = {'snow_effects'}, checked = snowEffects, close = false}, 3)
            checkedSnowEffects = snowEffects
            changedThings = true
        end

        if checkedDynamicWeather ~= dynamicWeather then
            lib.setMenuOptions('berkie_menu_weather_options', {label = 'Dynamic Weather', description = 'Whether to randomize the state of the weather or not', args = {'dynamic_weather'}, checked = dynamicWeather, close = false}, 1)
            checkedDynamicWeather = dynamicWeather
            changedThings = true
        end

        ForceSnowPass(snowEffects)
        SetForceVehicleTrails(snowEffects)
        SetForcePedFootstepsTracks(snowEffects)

        if snowEffects then
            lib.requestNamedPtfxAsset('core_snow')
            UseParticleFxAsset('core_snow')
        else
            RemoveNamedPtfxAsset('core_snow')
        end

        SetArtificialLightsState(blackout)

        currentWeather = GetConvar('berkie_menu_current_weather', 'EXTRASUNNY'):upper()
        currentWeather = not weatherIndexes[currentWeather] and 'EXTRASUNNY' or currentWeather

        if currentChecked ~= currentWeather then
            local oldData = weatherIndexes[currentChecked]
            local newData = weatherIndexes[currentWeather]
            lib.setMenuOptions('berkie_menu_weather_options', {label = oldData[2], args = {'set_weather', currentChecked}, close = false}, oldData[1])
            lib.setMenuOptions('berkie_menu_weather_options', {label = newData[2], icon = 'circle-check', args = {'set_weather', currentWeather}, close = false}, newData[1])
            currentChecked = currentWeather
            changedThings = true
        end

        if changedThings and lib.getOpenMenu() == 'berkie_menu_weather_options' then
            lib.hideMenu(false)
            Wait(100)
            lib.showMenu('berkie_menu_weather_options', MenuIndexes['berkie_menu_weather_options'])
            changedThings = false
        elseif changedThings then
            changedThings = false
        end

        if GetNextWeatherTypeHashName() ~= joaat(currentWeather) then
            SetWeatherTypeOvertimePersist(currentWeather, weatherChangeTime)
            Wait(weatherChangeTime * 1000 + 2000)
            if changingWeather then
                lib.notify({
                    description = ('Changed weather to %s'):format(weatherIndexes[currentWeather][2]),
                    type = 'success'
                })
            end
            changingWeather = false
            TriggerEvent('berkie_menu:client:weatherChangeComplete', currentWeather)
        end
        Wait(1000)
    end
end)

--#endregion Threads