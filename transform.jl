module Transform
include("constant.jl")

using .Constant: NONO_SIZE


"""
Transform the row permutations to column format, which start from leftmost to rightmost
Return transformed column
"""
function transform_column!(permRows::Union{SubArray,Array})::Array{Array{Int,1},1}
    cols = [Array{Int,1}(undef, 0) for i in 1:NONO_SIZE]
    accumulator = fill(0, NONO_SIZE)
    for permRow in permRows
        for i in 1:NONO_SIZE
            if (permRow & (1 << (i - 1))) != 0
                accumulator[i] += 1
            elseif accumulator[i] > 0
                push!(cols[i], accumulator[i])
                accumulator[i] = 0
            end
        end
    end
    for (i, acc) in enumerate(accumulator)
        if acc != 0
            push!(cols[i], acc)
        end
    end
    return reverse!(cols)
end
end