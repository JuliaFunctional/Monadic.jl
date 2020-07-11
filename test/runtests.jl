using Monadic
using Test

myflatmap(f, x) = Iterators.flatten(map(f, x))
iteratorresult = @monadic map myflatmap begin
  x = 1:3
  y = [1, 6]
  @pure x + y
end
@test collect(iteratorresult) == [2, 7, 3, 8, 4, 9]


mywrapper(n::Int) = 1:n
mywrapper(any) = any
iteratorresult = @monadic map myflatmap mywrapper begin
  x = 3
  y = [1, 6]
  @pure x + y
end
@test collect(iteratorresult)  == [2, 7, 3, 8, 4, 9]


iteratorresult = @monadic map myflatmap begin
  1:3
  [1, 6]
end
@test collect(iteratorresult) == [1, 6, 1, 6, 1, 6]
