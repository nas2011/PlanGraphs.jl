
@kwdef mutable struct StepConfig
    name::String
    about::String
    run::Function
    maxIter::Int
    level::Int
end

mutable struct PlanGraph
    mg::MetaGraph
    name::String
    about::String

    function PlanGraph(name::String, about::String)
        # Create the underlying MetaGraph
        # We specify: Label type String, Node data StepConfig, Edge data Nothing
        mg = MetaGraph(
            SimpleDiGraph(),
            label_type = String,
            vertex_data_type = StepConfig,
            graph_data = Dict()
        )
        return new(mg, name, about)
    end
end

function addStep!(pg::PlanGraph,step::StepConfig;afterNodes::Union{Nothing,Vector{StepConfig}}=nothing)
    pg.mg[step.name] = step    
    if !isnothing(afterNodes)
        existingNodes = collect(labels(pg.mg))
        @assert all(r->in(r.name,existingNodes),afterNodes) "All afterNodes must already be in graph. You gave $(map(r->r.name, afterNodes)) and the existing nodes are: $(existingNodes)"
        for precedingNode in afterNodes
            pg.mg[precedingNode.name,step.name] = nothing
        end
    end
end

function sortByLevel(pg::PlanGraph)
    entries = collect(pairs(pg.mg.vertex_properties))
    levels = map(r->r[2][2].level,entries) |> unique |> sort
    nt = map(levels) do level 
        parts = filter(r->r[2][2].level == level,entries)
        (level = level, parts = parts)
    end |> 
    y->sort(y, by=r->r.level)
    Dict(nt) |> sort
end

function plotPG(pg::PlanGraph)
    gp = gplot(
        pg.mg,
        nodesize = 150,
        nodefillc = colorant"darkblue",
        nodelabel = values(sort(pg.mg.vertex_labels)),
        nodelabelsize = 50,
        nodelabelc = colorant"darkgrey",
        edgestrokec = colorant"blue"
    )
    compose(context(),Compose.rectangle()) |>
    y->compose(y,fill("black"))|>
    y->compose(y,gp)
end

function printPlanLevels(pg::PlanGraph)
        sl = sortByLevel(pg)
        kvs = collect(pairs(sl))
        map(kvs) do level
            levelNum = level[1]
            components = level[2]
            compNum = 1
            compString = map(components) do comp
                st = "|" *(repeat(["  "],levelNum) |> join ) * "$compNum) " * comp[1] * "<-----Run on Thread $compNum"
                compNum += 1
                return st
            end |>y->join(y,"\n")
            levelIdent = repeat(["->"],levelNum-1) |> join
            """|$(levelIdent)Level $levelNum\n$compString
            """
        end |> y->join(y,"") |> println
    end
