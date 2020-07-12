Monadic
=======

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://schlichtanders.github.io/Monadic.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://schlichtanders.github.io/Monadic.jl/dev)
[![Build Status](https://github.com/schlichtanders/Monadic.jl/workflows/CI/badge.svg)](https://github.com/schlichtanders/Monadic.jl/actions)
[![Coverage](https://codecov.io/gh/schlichtanders/Monadic.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/schlichtanders/Monadic.jl)

This package provides the macro `@monadic` and its little helper ``@pure``.

With both you can define custom monadic syntax, let's look at an example to clarifiy what this means.

```julia
my_map(f, a::Vector) = f.(a)
my_flatmap(f, a::Vector) = vcat(f.(a)...)
# to show you what flatmap does, a small example
my_flatmap(x -> [x, x], [1, 2])  # [1, 1, 2, 2]  i.e. it applies `f` to every element and concatenates all results

using Monadic
@monadic my_map my_flatmap begin
  a = [:a,:b]
  b = [1, 2]
  c = [b + 4, b + 5]
  @pure Symbol(a, b, c)
end
# returns [:a15, :a16, :a26, :a27, :b15, :b16, :b26, :b27]
```
Apparently, this use of `@monadic` works like a nested for-loop, collecting the results.

To summarize what happens is that each line is interpreted as a kind of context or context-assignment (instead of
a usual value or value assignment in normal syntax). With the `@pure` macro you can indicate that the code should be
 interpreted normally (without context).

The context here is defined by our Vector, which we interpreted by ``my_map`` and ``my_flatmap`` as a kind of "do the computation for all combinations". It is like a context for indeterminism.

So let's read the `@monadic` syntax out loud:
```
for every a in [:a, :b]
for every b in [1, 2]
for every c in [b + 4, b + 5]
do a normal computation ``Symbol(a, b, c)`` (because it is prepended with `@pure`)
and collect the last computation for all combinations (because it is the last expression)
```

For more details check out the [documentation manual](https://schlichtanders.github.io/Monadic.jl/dev/manual/).
