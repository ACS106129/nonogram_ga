module Generator
include("constant.jl")

using Printf
using .Constant: NONO_SIZE


"""
Generate "number" children with "encodingFunc", return arrays of rows permutation according to number\n
Return a two-dimension array, which represents row as child number, col as permutated result of nonogram's rows
"""
function generate_children!(rows::Array{Array{Int,1},1}, number::Int, encodingFunc::Function, args...)::Array{UInt128,2}
    if number <= 0
        throw(ArgumentError("Number must be positive number!"))
    end
    permRows = Array{UInt128,1}(undef, 0)
    # record the encoding ignored indice of first child
    ignoreIndice = Array{Int}(undef, 0)
    for (i, row) in enumerate(rows)
        ans, isDetermine = encodingFunc(row, args...)
        if isDetermine
            push!(ignoreIndice, i)
        end
        push!(permRows, ans)
    end
    # after first child's children will follow the ignored indice
    for n in 1:(number - 1), (i, row) in enumerate(rows)
        if i in ignoreIndice
            # debug feature
            # println(@sprintf("Ignored %s index at %d in %d child.", row, i, n + 1))
            push!(permRows, permRows[i])
            continue
        end
        push!(permRows, encodingFunc(row, args...)[1])
    end
    # reshape to fit size(children numbers, nonogram size), need transpose because column-major
    return transpose(reshape(permRows, NONO_SIZE, :))
end
end