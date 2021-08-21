# Reexport

[![Build status](https://github.com/simonster/Reexport.jl/workflows/CI/badge.svg)](https://github.com/simonster/Reexport.jl/actions?query=workflow%3ACI+branch%3Amaster)

## Introduction

Maybe you have a module `X` that depends on module `Y` and you want `using X` to pull in all of the symbols from `Y`. Maybe you have an outer module `A` with an inner module `B`, and you want to export all of the symbols in `B` from `A`. It would be nice to have this functionality built into Julia, but we have yet to reach an agreement on what it should look like (see [JuliaLang/julia#1986](https://github.com/JuliaLang/julia/issues/1986)). This short macro is a stopgap we have a better solution.

## Usage

`@reexport using <modules>` calls `using <modules>` and also re-exports their symbols:

```julia
module Y
    ...
end

module Z
    ...
end

module X
    using Reexport
    @reexport using Y
    # all of Y's exported symbols available here
    @reexport using Z: x, y
    # Z's x and y symbols available here
end

using X
# all of Y's exported symbols and Z's x and y also available here
```

`@reexport import <module>.<name>` or `@reexport import <module>: <name>` exports `<name>` from `<module>` after importing it.

```julia
module Y
    ...
end

module Z
    ...
end

module X
    using Reexport
    @reexport import Y
    # Only `Y` itself is available here
    @reexport import Z: x, y
    # Z's x and y symbols available here
end

using X
# Y (but not its exported names) and Z's x and y are available here.
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

`@reexport @another_macro <import or using expression>` first expands `@another_macro` on the expression, making `@reexport` with other macros.

`@reexport begin ... end` will apply the reexport macro to every expression in the block.
