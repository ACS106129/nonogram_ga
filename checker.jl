module Checker


"""
Get fitness by using control and test columns
"""
function get_fitness(controlCols::Array{Array{Int,1},1}, testCols::Array{Array{Int,1},1})::Int
    fitness = 0
    for (control, test) in zip(controlCols, testCols)
        zeroLen = length(control) - length(test)
        if zeroLen > 0
            push!(test, zeros(Int64, zeroLen)...)
        elseif zeroLen < 0
            push!(control, zeros(Int64, abs(zeroLen))...)
        end
        fitness -= sum(abs.(control - test))
    end
    return fitness
end
end