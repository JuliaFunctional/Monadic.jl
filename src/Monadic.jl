module Monadic
export @pure, @monadic, monadic

"""
Simple helper type to mark pure code parts in monadic code block
"""
struct PureCode
  code
end
"""
Mark code to contain non-monadic code.

This can be thought of as generalized version of `pure` typeclass.
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

"""
    myflatmap(f, x) = Iterators.flatten(map(f, x))
    iteratorresult = @monadic map myflatmap begin
      x = 1:3
      y = [1, 6]
      @pure x + y
    end
    collect(iteratorresult)  # [2, 7, 3, 8, 4, 9]

The ``@monadic`` allows a syntax where containers and other contexts are treated rather as values, hiding the respective
well-defined side-effects.
Each line without @pure is regarded as a container, each line with @pure is treated as normal code which should be inlined.

For the example above you see that the side-effect semantics of iterables are the same as for nested for loops. With the
crucial distinction, that the @monadic syntax has a return value.

----------------------

`@monadic` can take a third argument `wrapper` in order to first apply a custom function before executing the @monadic
code.

```
mywrapper(n::Int) = 1:n
mywrapper(any) = any
myflatmap(f, x) = Iterators.flatten(map(f, x))
iteratorresult = @monadic map myflatmap mywrapper begin
  x = 3
  y = [1, 6]
  @pure x + y
end
collect(iteratorresult)  # [2, 7, 3, 8, 4, 9]
```
"""
macro monadic(maplike, flatmaplike, expr)
  expr = macroexpand(__module__, expr)
  esc(monadic(maplike, flatmaplike, expr))
end

macro monadic(maplike, flatmaplike, wrapper, expr)
  expr = macroexpand(__module__, expr)
  esc(monadic(maplike, flatmaplike, wrapper, expr))
end

_ismonad(x) = x isa Expr  # this is true because @pure expressions are parsed to PureCode and LineNumberNodes should be skipped

monadic(maplike, flatmaplike, expr) = monadic(maplike, flatmaplike, :identity, expr)
function monadic(maplike, flatmaplike, wrapper, expr)
  @assert(expr.head == :block, "@monadic only supports plain :block expr, got instead $(expr.head)")
  # @pure marked lines are not Expr but PureCode, hence everything which is a normal Expr is a Monad
  i = findfirst(_ismonad, expr.args)
  if isnothing(i)
    error("There need to be at least one non-@pure expression in a @monadic block")
  end
  # for everything before i we merge @pure expressions into normal code
  _mergepure!(1, i - 1, expr.args)
  _monadic(maplike, flatmaplike, wrapper, i, expr.args)
end

function _monadic(_, _, _, i::Nothing, block::Vector{Any})
  # we are checking for isnothing already beforehand
  error("this should never happen")
  # Expr(:block, block...)
end

function _monadic(maplike, flatmaplike, wrapper, i::Int, block::Vector{Any})
  wrap(expr) = wrapper === :identity ? expr : Expr(:call, wrapper, expr)

  e::Expr = block[i]
  j = findnext(_ismonad, block, i+1)
  if isnothing(j) # last _monadic Expr is a special case
    # either i is the last entry at all, then this can be returned directly
    if i == length(block)
      block[i] = wrap(e)
      Expr(:block, block...)
    # or this not the last entry, but @pure expressions may follow, then we construct a final fmap
    else
      _mergepure!(i + 1, length(block), block) # merge all left @pure
      lastblock = Expr(:block, block[i+1:end]...)

      callmap = if (e.head == :(=))
        subfunc = Expr(:->, Expr(:tuple, e.args[1]), lastblock)  # we need to use :tuple wrapper to support desctructuring https://github.com/JuliaLang/julia/issues/6614
        Expr(:call, maplike, subfunc, wrap(e.args[2]))
      else
        subfunc = Expr(:->, :_, lastblock)
        Expr(:call, maplike, subfunc, wrap(e))
      end
      Expr(:block, block[1:i-1]..., callmap)
    end
  # if i is not the last _monadic Expr
  else
    _mergepure!(i + 1, j - 1, block) # merge all new @pure inbetween
    submonadic = _monadic(maplike, flatmaplike, wrapper, j - i, block[i+1:end])

    callflatmap = if (e.head == :(=))
      subfunc = Expr(:->, Expr(:tuple, e.args[1]), submonadic)  # we need to use :tuple wrapper to support desctructuring https://github.com/JuliaLang/julia/issues/6614
      Expr(:call, flatmaplike, subfunc, wrap(e.args[2]))
    else
      subfunc = Expr(:->, :_, submonadic)
      Expr(:call, flatmaplike, subfunc, wrap(e))
    end
    Expr(:block, block[1:i-1]..., callflatmap)
  end
end

end # module
