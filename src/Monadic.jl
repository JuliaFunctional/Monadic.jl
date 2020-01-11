module Monadic
export @pure, @monadic, monadic

# monadic programming style
# -------------------------

"""
Simple helper type to mark pure code parts in monadic code block
"""
struct PureCode
  code
end
"""
Mark code to contain non-monadic code.

This can be thought of as generalized version of `pure` function within @syntax_fflatmap context.
"""
macro pure(e)
  PureCode(e)
end

# @pure is expanded within monadic
function _mergepure!(a::Int, b::Int, block::Vector{Any})
  for k ∈ a:b
    if block[k] isa PureCode
      block[k] = block[k].code
    end
  end
end

macro monadic(maplike, flatmaplike, expr)
  esc(monadic(
    Core.eval(__module__, maplike),
    Core.eval(__module__, flatmaplike),
    macroexpand(__module__, expr),))
end

function monadic(maplike, flatmaplike, block::Expr)
  _monadic(maplike, flatmaplike, block)
end

function _monadic(maplike, flatmaplike, block::Expr)
  @assert block.head == :block
  i = findfirst(x -> x isa Expr, block.args)
  # for everything before i we merge @pure expressions into normal code
  _mergepure!(1, i - 1, block.args)
  _monadic(maplike, flatmaplike, i, block.args)
end

function _monadic(_, _, i::Nothing, block::Vector{Any})
  Expr(:block, block...)
end

function _monadic(maplike, flatmaplike, i::Int, block::Vector{Any})
  e::Expr = block[i]
  j = findnext(x -> x isa Expr, block, i+1)
  if isnothing(j) # last _monadic Expr is a special case
    # either i is the last entry at all, then this can be returned directly
    if i == length(block)
      Expr(:block, block...)
    # or this not the last entry, but @pure expressions may follow, then we construct a final fmap
    else
      _mergepure!(i + 1, length(block), block) # merge all left @pure
      lastblock = Expr(:block, block[i+1:end]...)

      callmap = if (e.head == :(=))
        subfunc = Expr(:->, Expr(:tuple, e.args[1]), lastblock)  # we need to use :tuple wrapper to support desctructuring https://github.com/JuliaLang/julia/issues/6614
        Expr(:call, maplike, subfunc, e.args[2])
      elseif (e.head == :call)
        subfunc = Expr(:->, :_, lastblock)
        Expr(:call, maplike, subfunc, e)
      else
        error("this should not happen")
      end
      Expr(:block, block[1:i-1]..., callmap)
    end
  # if i is not the last _monadic Expr
  else
    _mergepure!(i + 1, j - 1, block) # merge all new @pure inbetween
    submonadic = _monadic(maplike, flatmaplike, j - i, block[i+1:end])

    callflatmap = if (e.head == :(=))
      subfunc = Expr(:->, Expr(:tuple, e.args[1]), submonadic)  # we need to use :tuple wrapper to support desctructuring https://github.com/JuliaLang/julia/issues/6614
      Expr(:call, flatmaplike, subfunc, e.args[2])
    elseif (e.head == :call)
      subfunc = Expr(:->, :_, submonadic)
      Expr(:call, flatmaplike, subfunc, e)
    else
      error("this should not happen")
    end
    Expr(:block, block[1:i-1]..., callflatmap)
  end
end

end # module
