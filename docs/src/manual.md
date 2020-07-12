Manual
======

To load this package just run `using Monadic`. It will give you the one and only macro `@monadic` and its little helper `@pure`.

With both you can define custom monadic syntax, let's look at an example to clarifiy what this means.

```jldoctest session
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

# output

8-element Array{Symbol,1}:
 :a15
 :a16
 :a26
 :a27
 :b15
 :b16
 :b26
 :b27
```
Apparently, this use of `@monadic` works like a nested for-loop, collecting the results.

To summarize what happens is that each line is interpreted as a kind of context or context-assignment (instead of
a usual value or value assignment in normal syntax). With the `@pure` macro you can indicate that the code should be
 interpreted normally (without context).

The context here is defined by our Vector, which we interpreted by `my_map` and `my_flatmap` as a kind of "do the computation for all combinations". It is like a context for indeterminism.

So let's read the `@monadic` syntax out loud:
```
for every a in [:a, :b]
for every b in [1, 2]
for every c in [b + 4, b + 5]
do a normal computation `Symbol(a, b, c)` (because it is prepended with `@pure`)
and collect the last computation for all combinations (because it is the last expression)
```

Using a wrapper as a third argument
-----------------------------------

In addition, `@monadic` supports a little helper in order to initially apply a given function to all containers, before executing the standard `@monadic` semantics.

```jldoctest session
my_wrapper(i::Int) = collect(1:i)
my_wrapper(other) = other

@monadic my_map my_flatmap my_wrapper begin
  a = 2
  b = a + 2
  @pure (a, b)
end

# output

7-element Array{Tuple{Int64,Int64},1}:
 (1, 1)
 (1, 2)
 (1, 3)
 (2, 1)
 (2, 2)
 (2, 3)
 (2, 4)
```
This is equivalent to just calling the wrapper everywhere yourself
```julia
@monadic my_map my_flatmap begin
  a = my_wrapper(2)
  b = my_wrapper(a + 2)
  @pure (a, b)
end
```

Together, with only three functions `my_map`, `my_flatmap` and `my_wrapper`,
this gives you a compact and well-defined way to specify your own domain specific language.



How does it do it?
------------------

Let's inspect it with `@macroexpand`

```julia
@macroexpand @monadic my_map my_flatmap begin
  a = [:a,:b]
  b = [1, 2]
  c = [b + 4, b + 5]
  @pure Symbol(a, b, c)
end
```
which shows that it is translated to the following code
```julia
(my_flatmap)(((a,)->begin
   (my_flatmap)(((b,)->begin
       (my_map)(((c,)->begin
           #= none:9 =#
           Symbol(a, b, c)
       end), [b + 4, b + 5])
   end), [1, 2])
end), [:a, :b])
```
You see, it is just a nested call of `my_flatmap` and `my_map`. More concretely, for all but the last `=` sign `my_flatmap` is used and finally `my_map`.

You can easily check that this corresponds to a nested for-loop, which collects all results flat in one final array.


The use of `@pure`
--------------------

Some more example will help to better understand how the syntax works in detail. `@pure` can be
placed at any row and will just bring you back to normal semantics.

```jldoctest session
@monadic my_map my_flatmap begin
  a = [1, 3]
  @pure b = a + 6
  c = [b, b, b]
  @pure c
end

# output

6-element Array{Int64,1}:
 7
 7
 7
 9
 9
 9
```

Inspecting the macro with `@macroexpand` again shows that the `@pure` statement is now inlined into the respective `my_flatmap` (in the first example it was kind of inlined into the last call of `my_map`).
```julia
(my_flatmap)(((a,)->begin
   b = a + 6
   (my_map)(((c,)->begin
       c
   end), [b, b, b])
end), [1, 3])
```

The last value
--------------

The very last statement in a monadic code block has a special meaning as we already saw in the introductory example. For our Vector example, the last expression was the one which got collected. It my look like you always have to use `@pure` in the last row. You don't have to actually.

In fact, the last example can be simplified to the following
```jldoctest session
@monadic my_map my_flatmap begin
  a = [1, 3]
  @pure b = a + 6
  [b, b, b]
end

# output

6-element Array{Int64,1}:
 7
 7
 7
 9
 9
 9
```

Let's again look what this translates to
```julia
(my_flatmap)(((a,)->begin
    b = a + 6
    [b, b, b]
end), [1, 3])
```
You see the code is much simpler than before, the last use of `my_map` is completely dropped and what we previously called `c` is now directly returned. You can understand the last `@pure` respectively as "execute this on the final context", hence the need for `my_map`.


Using other functions instead of `map` and `flatmap`
----------------------------------------------------

You can define your own versions of `my_map` and `my_flatmap`, creating whatever context you would like. You can even use the syntax in a different way by not sticking to the semantics of `map` and `flatmap` for your functions.

A simple example would be to use `my_map` twice
```jldoctest session
@monadic my_map my_map begin
  a = [:a,:b]
  b = [1, 2]
  c = [b + 4, b + 5]
  @pure Symbol(a, b, c)
end

# output

2-element Array{Array{Array{Symbol,1},1},1}:
 [[:a15, :a16], [:a26, :a27]]
 [[:b15, :b16], [:b26, :b27]]
```
here you can clearly see the nestings, which usually get flattened out when using `my_flatmap` instead.


Implementation Details
----------------------

This implementation intentionally uses `map` and `flatmap`, and not a kind of `pure` and `flatmap`. One reason is that `map` is already well known and defined for almost everything. A second reason is that there are practical DataStructures for which you can define `map` but not `pure` (e.g. Dict if interpreted as Dict{Context} functor as in Scala, or the writer functor Pair{Context}.)
