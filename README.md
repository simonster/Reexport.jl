# Reexport

[![Build Status](https://travis-ci.org/simonster/Reexport.jl.svg)](https://travis-ci.org/simonster/Reexport.jl)

## Introduction

Maybe you have a module `X` that depends on module `Y` and you want `using X` to pull in all of the symbols from `Y`. Maybe you have an outer module `A` with an inner module `B`, and you want to export all of the symbols in `B` from `A`. It would be nice to have this functionality built into Julia, but we have yet to reach an agreement on what it should look like (see [JuliaLang/julia#1986](https://github.com/JuliaLang/julia/issues/1986)). This short macro is a stopgap we have a better solution.

## Usage

`@reexport using <modules>` calls `using <modules>` and also re-exports their symbols:

```julia
module Y
    ...
end

module X
    using Reexport
    @reexport using Y
    # all of Y's exported symbols available here
end

using X
# all of Y's exported symbols also available here
```

`@reexport module <modulename> ... end` defines `module <modulename>` and also re-exports its symbols:

```julia
module A
    using Reexport
    @reexport module B
    	...
    end
    # all of B's exported symbols available here
end

using A
# all of B's exported symbols available here
```
