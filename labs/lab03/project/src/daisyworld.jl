# # Daisyworld — модель
# Определение агента `Daisy` и функций шага модели.

using Agents
import StatsBase
using Random

# ## Тип агента
# Чёрные и белые маргаритки. Агент живёт на 2D-сетке (`GridAgent{2}`).

@agent struct Daisy(GridAgent{2})
    breed::Symbol        # :black или :white
    age::Int             # количество шагов с момента появления
    albedo::Float64      # 0–1, отражательная способность
end

# ## Обновление температуры поверхности в клетке

function update_surface_temperature!(pos, model)
    absorbed_luminosity = if isempty(pos, model)   # нет маргаритки
        (1 - model.surface_albedo) * model.solar_luminosity
    else
        daisy = model[id_in_position(pos, model)]
        (1 - daisy.albedo) * model.solar_luminosity
    end
    local_heating = absorbed_luminosity > 0 ?
        72 * log(absorbed_luminosity) + 80 : 80
    model.temperature[pos...] = (model.temperature[pos...] + local_heating) / 2
    return nothing
end

# ## Диффузия температуры между клетками

function diffuse_temperature!(pos, model)
    ratio = model.ratio
    npos = nearby_positions(pos, model)
    model.temperature[pos...] = (1 - ratio) * model.temperature[pos...] +
        sum(model.temperature[p...] for p in npos) * 0.125 * ratio
    return nothing
end

# ## Размножение маргариток

function propagate!(pos, model)
    isempty(pos, model) && return
    daisy = model[id_in_position(pos, model)]
    temperature = model.temperature[pos...]
    seed_threshold = 0.1457 * temperature - 0.0032 * temperature^2 - 0.6443
    if rand(abmrng(model)) < seed_threshold
        # Собираем свободные соседние позиции
        npos_list = collect(nearby_positions(pos, model))
        empty_positions = [p for p in npos_list if isempty(p, model)]
        if !isempty(empty_positions)
            chosen = rand(abmrng(model), empty_positions)
            add_agent!(chosen, model, daisy.breed, 0, daisy.albedo)
        end
    end
    return nothing
end

# ## Шаг агента: старение и смерть

function daisy_step!(agent::Daisy, model)
    agent.age += 1
    agent.age >= model.max_age && remove_agent!(agent, model)
    return nothing
end

# ## Шаг модели

function daisyworld_step!(model)
    for p in positions(model)
        update_surface_temperature!(p, model)
        diffuse_temperature!(p, model)
        propagate!(p, model)
    end
    model.tick += 1
    solar_activity!(model)
    return nothing
end

# ## Изменение солнечной активности

function solar_activity!(model)
    if model.scenario == :ramp
        if model.tick > 200 && model.tick <= 400
            model.solar_luminosity += model.solar_change
        end
        if model.tick > 500 && model.tick <= 750
            model.solar_luminosity -= model.solar_change / 2
        end
    elseif model.scenario == :change
        model.solar_luminosity += model.solar_change
    end
    return nothing
end

# ## Конструктор модели

function daisyworld(;
    griddims = (30, 30),
    max_age = 25,
    init_white = 0.2,
    init_black = 0.2,
    albedo_white = 0.75,
    albedo_black = 0.25,
    surface_albedo = 0.4,
    solar_change = 0.005,
    solar_luminosity = 1.0,
    scenario = :default,
    seed = 165)

    rng = MersenneTwister(seed)
    space = GridSpaceSingle(griddims; periodic = true)

    properties = Dict(
        :max_age => max_age,
        :surface_albedo => surface_albedo,
        :solar_luminosity => solar_luminosity,
        :solar_change => solar_change,
        :scenario => scenario,
        :tick => 0,
        :ratio => 0.5,
        :temperature => zeros(griddims),
    )

    model = StandardABM(Daisy, space;
        properties,
        rng,
        agent_step! = daisy_step!,
        model_step! = daisyworld_step!)

    grid = collect(positions(model))
    num_positions = prod(griddims)

    white_positions = StatsBase.sample(grid,
        Int(init_white * num_positions); replace=false)
    for wp in white_positions
        add_agent!(wp, model, :white,
            rand(abmrng(model), 0:max_age), albedo_white)
    end

    allowed = setdiff(grid, white_positions)
    black_positions = StatsBase.sample(allowed,
        Int(init_black * num_positions); replace=false)
    for bp in black_positions
        add_agent!(bp, model, :black,
            rand(abmrng(model), 0:max_age), albedo_black)
    end

    for p in positions(model)
        update_surface_temperature!(p, model)
    end

    return model
end
