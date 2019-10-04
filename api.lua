local UPDATE_INTERVAL = 5
local WATER_LEVEL = 0
local CLOUD_LEVEL = 120

local players = {}
weather = {}
weather.registered_weathers = {}

minetest.register_on_leaveplayer(function(obj, timed_out)
    local name = obj:get_player_name()
    players[name] = nil
end)

function weather.register_weather(name, weather_data)
    if not weather_data or not weather_data.temp or not weather_data.humid or not weather_data.textures then
        return
    end

    data = weather_data
    data.chance = data.chance or 10
    data.amount = data.amount or 100
    data.time_range = data.time_range or {120, 240}
    data.temp_threshold = data.temp_threshold or 0
    data.humid_threshold = data.humid_threshold or 0
    data.area_size = data.area_size or 10
    data.elev_range = data.elev_range or {8, 10}
    data.horz_vel_range = data.horz_vel_range or 1
    data.vert_vel_range = data.vert_vel_range or {-3, -4}
    data.exp_time_range = data.exp_time_range or {4, 5}
    data.prtcl_size_range = data.prtcl_size_range or {1, 2}
    data.vertical = data.vertical or true

    weather.registered_weathers[name] = data
end

local time = 0
minetest.register_globalstep(function(dtime)
    --print("it works!")
    time = time + dtime
    if time > 5 then
        for _, player in pairs(minetest.get_connected_players()) do
            local pos = player:get_pos()
            local name = player:get_player_name()
            local heat = minetest.get_heat(player:get_pos())
            local humid = minetest.get_humidity(player:get_pos())
            local current = minetest.get_us_time() / 1000000
            local is_weather = false
            print("heat: " .. dump(heat))
            print("humid: " .. dump(humid))
            --print(dump(weather.registered_weathers))
            for weather_name, weather in pairs(weather.registered_weathers) do
                if not (pos.y + weather.elev_range[1] <= WATER_LEVEL and pos.y + weather.elev_range[1] >= CLOUD_LEVEL) then 
                    print(dump(weather))
                    if (players[name] and players[name].weather and players[name].weather.current == weather_name and current - players[name].weather.strt_time <= players[name].weather.time) then
                        is_weather = true
                    elseif (((heat >= weather.temp and heat <= weather.temp + weather.temp_threshold) or (heat <= weather.temp and heat >= weather.temp - weather.temp_threshold)) and ((humid >= weather.humid and humid <= weather.humid + weather.humid_threshold) or (humid <= weather.humid and humid >= weather.humid - weather.humid_threshold))) and math.random(100) <= weather.chance then
                        players[name] = {}
                        players[name].weather = {}
                        players[name].weather.current = weather_name
                        players[name].weather.time = math.random(weather.time_range[1], weather.time_range[2])
                        players[name].weather.strt_time = current

                        is_weather = true
                    end
                    if is_weather then
                        print("initializing weather sequence dumbass")
                        for i = 1, #weather.textures do
                            minetest.add_particlespawner({
                                time = UPDATE_INTERVAL,
                                amount = math.floor(weather.amount / #weather.textures),
                                minpos = {x = weather.area_size, y = weather.elev_range[1], z = weather.area_size},
                                maxpos = {x = -weather.area_size, y = weather.elev_range[2], z = -weather.area_size},
                                minvel = {x = -weather.horz_vel_range, y = weather.vert_vel_range[1] , z = -weather.horz_vel_range},
                                maxvel = {x = weather.horz_vel_range, y = weather.vert_vel_range[2] , z = weather.horz_vel_range},
                                minexptime = weather.exp_time_range[1],
                                maxexptime = weather.exp_time_range[2],
                                minsize = weather.prtcl_size_range[1],
                                maxsize = weather.prtcl_size_range[2],
                                collisiondetection = true,
                                collision_removal = true,
                                attached = player,
                                vertical = weather.vertical,
                                texture = weather.textures[i],
                                playername = player:get_player_name(),
                            })
                        end
                        break
                    end
                end
            end
        end
        time = 0
    end
end)