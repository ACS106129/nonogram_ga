module Nonogram
include("encode.jl")
include("checker.jl")
include("constant.jl")
include("generator.jl")
include("transform.jl")

using Pkg
if !in("StatsBase", keys(Pkg.installed()))
    Pkg.add("StatsBase")
end
using Printf
using StatsBase
using Statistics
using .Encode
using .Checker
using .Generator
using .Transform
using .Constant: NONO_SIZE, PROBLEMS, ATTEMPT_TRY, NEW_GEN, PAIRS


"""
New children in new generation
"""
function new_children!(rows::Array{Array{Int,1},1}, eachNumber::Int)::Array{UInt128,2}
    return vcat(Generator.generate_children!(rows, eachNumber, Encode.dist_random_encode!, 0, 0, false),
        Generator.generate_children!(rows, eachNumber, Encode.dist_random_encode!, 0, 0, true),
        Generator.generate_children!(rows, eachNumber, Encode.dist_random_encode!, 1, 0, false),
        Generator.generate_children!(rows, eachNumber, Encode.dist_random_encode!, 1, 0, true),
        Generator.generate_children!(rows, eachNumber, Encode.dist_random_encode!, 0, 1, false),
        Generator.generate_children!(rows, eachNumber, Encode.dist_random_encode!, 0, 1, true),
        Generator.generate_children!(rows, eachNumber, Encode.dist_random_encode!, 1, 1, false),
        Generator.generate_children!(rows, eachNumber, Encode.dist_random_encode!, 1, 1, true),
        Generator.generate_children!(rows, eachNumber, Encode.step_random_encode!, 0, false, false),
        Generator.generate_children!(rows, eachNumber, Encode.step_random_encode!, 0, false, true),
        Generator.generate_children!(rows, eachNumber, Encode.step_random_encode!, 1, false, false),
        Generator.generate_children!(rows, eachNumber, Encode.step_random_encode!, 1, false, true),
        Generator.generate_children!(rows, eachNumber, Encode.step_random_encode!, 0, true, false),
        Generator.generate_children!(rows, eachNumber, Encode.step_random_encode!, 0, true, true),
        Generator.generate_children!(rows, eachNumber, Encode.step_random_encode!, 1, true, false),
        Generator.generate_children!(rows, eachNumber, Encode.step_random_encode!, 1, true, true))
end

"""
Select children for the best remained
"""
function select_children!(cols::Array{Array{Int,1},1}, children::Array{UInt128,2}, pairs::Int)::Tuple{Array{UInt128,2},Array{Int,1}}
    if pairs * 2 > div(length(children), NONO_SIZE)
        throw(ArgumentError("Pairs to be got are over children's amount!"))
    end
    fitnesses = [(i, fitness) for (i, fitness) in enumerate([Checker.get_fitness(cols, Transform.transform_column!(child)) for child in eachrow(children)])]
    sort!(fitnesses, by = x->x[2], rev = true)
    return children[[i[1] for i in fitnesses[1:(pairs * 2)]], :], [i[2] for i in fitnesses[1:(pairs * 2)]]
end

"""
Crossover the children gene in best children
"""
function crossover_children!(cols::Array{Array{Int,1},1}, children::Array{UInt128,2})::Tuple{Array{UInt128,2}, Array{Int,1}}
    crossedChildren = Array{UInt128,1}(undef, 0)
    fitnesses = Array{Int,1}(undef, 0)
    divideRange = rand(2:(NONO_SIZE - 1))
    for i in 1:size(children, 1)
        for j in 1:size(children, 1)
            if i == j
                continue
            end
            cated = vcat(children[i, 1:divideRange], children[j, divideRange + 1:end])
            push!(crossedChildren, cated...)
            push!(fitnesses, Checker.get_fitness(cols, Transform.transform_column!(cated)))
        end
    end
    crossedChildren = transpose(reshape(crossedChildren, NONO_SIZE, :))
    fitnesses = [(i, fitness) for (i, fitness) in enumerate(fitnesses)]
    sort!(fitnesses, by = x->x[2], rev = true)
    return crossedChildren[[i[1] for i in fitnesses], :], [i[2] for i in fitnesses]
end

"""
Mutate the best children
"""
function mutate_children!(rows::Array{Array{Int,1},1}, cols::Array{Array{Int,1},1}, children::Array{UInt128,2})::Tuple{Array{UInt128,2}, Array{Int,1}}
    fitnesses = Array{Int,1}(undef, 0)
    len = size(children, 1)
    for i in 1:len
        for mutateIndex in sample(1:NONO_SIZE, 1, replace = false)
            children[i, mutateIndex] = Encode.dist_random_encode!(rows[mutateIndex], rand(0:1), 1, rand(Bool))[1]
        end
        push!(fitnesses, Checker.get_fitness(cols, Transform.transform_column!(children[i, :])))
    end
    fitnesses = [(i, fitness) for (i, fitness) in enumerate(fitnesses)]
    sort!(fitnesses, by = x->x[2], rev = true)
    return children[[i[1] for i in fitnesses[1:div(len, 3)]], :], [i[2] for i in fitnesses[1:div(len, 3)]]
end

function solve!(problem::SubArray)
    # input cols from problem
    cols = [[parse(Int, n) for n in split(col)] for col in problem[1:NONO_SIZE]]
    # input rows from problem
    rows = [[parse(Int, n) for n in split(row)] for row in problem[NONO_SIZE + 1:end]]
    recordsChildren = undef
    newFile = open("new.log", "w+")
    crossoverFile = open("crossover.log", "w+")
    mutateFile = open("mutate.log", "w+")
    for attempt in 1:ATTEMPT_TRY
        # generate children and get the best
        if recordsChildren == undef
            children, fitnesses = select_children!(cols, new_children!(rows, NEW_GEN), PAIRS)
        else
            children, fitnesses = select_children!(cols, vcat(new_children!(rows, NEW_GEN), recordsChildren), PAIRS)
        end
        if fitnesses[1] == 0
            println(@sprintf("Found solution in %d generation in select_children", attempt))
            break
        end
        # debug feature
        println(@sprintf("Try time: %d, in new Fitness: %d", attempt, fitnesses[1]))
        println(newFile, fitnesses[1], ',')
        flush(newFile)
        children, fitnesses = crossover_children!(cols, children)
        if fitnesses[1] == 0
            println(@sprintf("Found solution in %d generation in crossover_children", attempt))
            break
        end
        # debug feature
        println(@sprintf("Try time: %d, in crossover Fitness: %d", attempt, fitnesses[1]))
        println(crossoverFile, fitnesses[1], ',')
        flush(crossoverFile)
        recordsChildren, fitnesses = mutate_children!(rows, cols, children)
        if fitnesses[1] == 0
            println(@sprintf("Found solution in %d generation in mutate_children", attempt))
            break
        end
        # debug feature
        println(@sprintf("Try time: %d, in mutate Fitness: %d", attempt, fitnesses[1]))
        println(mutateFile, fitnesses[1], ',')
        flush(mutateFile)
    end
    close(newFile)
    close(crossoverFile)
    close(mutateFile)
end

inputLines = Array{String,1}(undef, 0)
@timev open("nonogram_input.txt", "r") do file
    # problem count and line count
    pc, lc = 0, 0
    while !eof(file)
        line = strip(readline(file))
        if isempty(line)
            continue
        end
        if startswith(line, '$')
            lc = NONO_SIZE * 2
            if pc == PROBLEMS
                break
            end
            pc += 1
        elseif lc > 0
            lc -= 1
            push!(inputLines, line)
        end
    end
end
# reshape lines into problem size (NONO_SIZE * 2, PROBLEM)
problems = reshape(inputLines, NONO_SIZE * 2, :)
@timev for (index, problem) in enumerate(eachcol(problems))
    println("Used $(@sprintf("%.6f seconds in problem %04d", @elapsed(solve!(problem)), index)).")
end
end