# # SIR в агентном подходе — модель
# Агенты — люди на графе городов. Каждый день: миграция → заражение → выздоровление/смерть.

using Agents
using Agents.Graphs
using StatsBase: sample, Weights
using Distributions: Poisson
using Random

# ## Тип агента
@agent struct Person(GraphAgent)
    days_infected::Int    # дней с момента заражения
    status::Symbol        # :S, :I, :R
end

# ## Инициализация модели

function initialize_sir(;
    Ns = [1000, 1000, 1000],
    migration_rates = nothing,
    β_und = [0.5, 0.5, 0.5],
    β_det = [0.05, 0.05, 0.05],
    infection_period = 14,
    detection_time = 7,
    death_rate = 0.02,
    reinfection_probability = 0.1,
    Is = [0, 0, 1],
    seed = 42,
    n_steps = 100)

    rng = Xoshiro(seed)
    C = length(Ns)

    if migration_rates === nothing
        migration_rates = zeros(C, C)
        for i in 1:C
            for j in 1:C
                migration_rates[i, j] = (Ns[i] + Ns[j]) / Ns[i]
            end
        end
        for i in 1:C
            migration_rates[i, :] ./= sum(migration_rates[i, :])
        end
    end

    properties = Dict(
        :Ns => Ns,
        :β_und => β_und,
        :β_det => β_det,
        :migration_rates => migration_rates,
        :infection_period => infection_period,
        :detection_time => detection_time,
        :death_rate => death_rate,
        :reinfection_probability => reinfection_probability,
        :C => C
    )

    space = GraphSpace(complete_graph(C))
    model = StandardABM(Person, space;
        properties, rng,
        agent_step! = sir_agent_step!)

    for city in 1:C
        for _ in 1:Ns[city]
            add_agent!(city, model, 0, :S)
        end
    end

    for city in 1:C
        if Is[city] > 0
            city_agents = collect(ids_in_position(city, model))
            infected_ids = sample(rng, city_agents, Is[city]; replace=false)
            for id in infected_ids
                agent = model[id]
                agent.status = :I
                agent.days_infected = 1
            end
        end
    end

    return model
end

# ## Шаг агента: миграция → заражение → старение → смерть/выздоровление

function sir_agent_step!(agent, model)
    migrate!(agent, model)
    if agent.status == :I
        transmit!(agent, model)
        agent.days_infected += 1
    end
    recover_or_die!(agent, model)
    return nothing
end

# ## Миграция между городами

function migrate!(agent, model)
    current_city = agent.pos
    probs = model.migration_rates[current_city, :]
    target = sample(abmrng(model), 1:model.C, Weights(probs))
    if target != current_city
        move_agent!(agent, target, model)
    end
    return nothing
end

# ## Передача инфекции

function transmit!(agent, model)
    rate = if agent.days_infected < model.detection_time
        model.β_und[agent.pos]    # невыявленный
    else
        model.β_det[agent.pos]    # выявленный
    end

    n_infections = rand(abmrng(model), Poisson(rate))
    n_infections == 0 && return nothing

    neighbors = [a for a in agents_in_position(agent.pos, model)
                 if a.id != agent.id]

    shuffle!(abmrng(model), neighbors)

    for contact in neighbors
        if contact.status == :S
            contact.status = :I
            contact.days_infected = 1
            n_infections -= 1
            n_infections == 0 && return nothing
        elseif contact.status == :R && rand(abmrng(model)) <= model.reinfection_probability
            contact.status = :I
            contact.days_infected = 1
            n_infections -= 1
            n_infections == 0 && return nothing
        end
    end
    return nothing
end

# ## Выздоровление или смерть

function recover_or_die!(agent, model)
    if agent.status == :I && agent.days_infected >= model.infection_period
        if rand(abmrng(model)) <= model.death_rate
            remove_agent!(agent, model)
        else
            agent.status = :R
            agent.days_infected = 0
        end
    end
    return nothing
end

# ## Вспомогательные счётчики

infected_count(model) = count(a.status == :I for a in allagents(model))
recovered_count(model) = count(a.status == :R for a in allagents(model))
susceptible_count(model) = count(a.status == :S for a in allagents(model))
total_count(model) = nagents(model)
