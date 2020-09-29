module Encode
include("constant.jl")

using Printf
using .Constant: NONO_SIZE


"""
Encode the clues with random distributing the "availableBlock"(empty space) to the clues\n
If "availableBlock" are enough to give each clues, "preserves" will provide least block(s) to each clues\n
If need to perform incompletely distribution(also "availableBlock" > 0), "denominatorExtends" will increase the loss chance\n
If "isReversed" is true, all blocks will be reversed order\n
Return permutated clues and if it is determined exactly one(according to "availableBlock", which subtracted by preserves),
    return true(to prevent from unnecessarily repeating encoding)

*** Example => block = 'b', clue = 'c', availableBlock = 10(calculated), '1' is necessary interval(excluded from blocks) ***
Generate initial clue:
    if `preserves == 0`:
        c 1 c 1 c
    if `preserves == 1`:
        b c 1 b c 1 b c
Stage on encode: 
    assume staged = b c 1 b c 1 b c, availableBlock => 10 - 3 = 7:
        without denominatorExtends:
            may rolled to be: b b b b c 1 b b c 1 b b b b c ''(no back block)
        with denominatorExtends:
            may rolled to be: b b c 1 b b c 1 b b b b c 'b b'(have back blocks)
Final result in return:
    assume encoded = b b b c 1 b c 1 b b b b c b b
        if `isReversed == true`:
            b b c 1 b b b b c 1 b c b b b

`Noted: if denominatorExtends is 1, the distribution is most equality`
"""
function dist_random_encode!(clues::Array{Int,1}, preserves::Int, denominatorExtends::Int, isReversed::Bool = false)::Tuple{UInt128,Bool}
    len = length(clues)
    availPreserve, availableBlock = __get_available_status(len, sum(clues), preserves)
    blocks = fill(availPreserve, len)
    # choose index of blocks to push value
    for i in rand(1:(len + denominatorExtends), availableBlock)
        if i > len
            continue
        end
        blocks[i] += 1
    end
    return __get_result!(clues, blocks, availableBlock - sum(blocks), isReversed), (availableBlock == 0)
end

"""
Encode the clues with step by step and fill them in permutations, the first will get rolled blocks from "availableBlock",
    and remained "availableBlock" will give to next one to roll\n
If "availableBlock" are enough to give each clues, "preserves" will provide least block(s) to each clues\n
If "isLastTakeRemains" are true, the last clue will take all of the remained "availableBlock"\n
If "isReversed" is true, all blocks will be reversed order\n
Return permutated clues and if it is determined exactly one(according to "availableBlock", which subtracted by preserves),
    return true(to prevent from unnecessarily repeating encoding)

*** Example => block = 'b', clue = 'c', availableBlock = 10(calculated), '1' is necessary interval(excluded from blocks) ***
Generate initial clue:
    if `preserves == 0`:
        c 1 c 1 c
    if `preserves == 1`:
        b c 1 b c 1 b c
Stage on encode: 
    assume staged = c 1 c 1 c, remainBlock = availableBlock = 10:
        first clue takes roll from 0 ~ 10 => 6:
            => b b b b b b c 1 c 1 c => remainBlock - 6 = 4
        second clue takes roll from 0 ~ 4 => 1:
            => b b b b b b c 1 b c 1 c => remainBlock - 1 = 3
        last clue takes:
        if `isLastTakeRemains` => takes all:
            => b b b b b b c 1 b c 1 b b b c ''(no back block)
        if `not isLastTakeRemains` => takes roll from 0 ~ 3 => 2:
            => b b b b b b c 1 b c 1 b b c 'b'(remainBlock - 2 = '1' back block)
Final result in return:
    assume encoded = b b b c 1 b c 1 b b b b c b b
        if use `isReversed`:
            b b c 1 b b b b c 1 b c b b b

`Noted: this encode method is not an equality distribution, it may tend to the first to having more blocks`
"""
function step_random_encode!(clues::Array{Int,1}, preserves::Int, isLastTakeRemains::Bool, isReversed::Bool = false)::Tuple{UInt128,Bool}
    len = length(clues)
    availPreserve, availableBlock = __get_available_status(len, sum(clues), preserves)
    blocks = fill(availPreserve, len)
    remainBlock = availableBlock
    # step by step to fill blocks from remained blocks
    for i in 1:len
        if remainBlock == 0
            break
        end
        fillBlock = ((i == len && isLastTakeRemains) ? remainBlock : rand(0:remainBlock))
        blocks[i] += fillBlock
        remainBlock -= fillBlock
    end
    return __get_result!(clues, blocks, remainBlock, isReversed), (availableBlock == 0)
end

function __get_available_status(length::Int, sum::Int, expectPreserve::Int)::Tuple{Int,Int}
    # calc the remain blocks in clues
    availableBlock = NONO_SIZE - sum - (length - 1)
    while availableBlock < expectPreserve * length && expectPreserve > 0
        expectPreserve -= 1
        # debug feature
        # println(@sprintf("Restricting preserves value to %d.", preserves))
    end
    availableBlock -= expectPreserve * length
    # available preserves and available blocks
    return expectPreserve, availableBlock
end

function __get_result!(clues::Array{Int,1}, blocks::Array{Int,1}, remainBlock::Int, isReversed::Bool)::UInt128
    result = UInt128(0)
    len = length(clues)
    push!(blocks, remainBlock)
    if isReversed
        reverse!(blocks)
    end
    for (i, clue) in enumerate(clues)
        result = (result << (blocks[i] + clue + 1)) | ((UInt128(1) << clue) - 1)
    end
    return (result << last(blocks))
end
end