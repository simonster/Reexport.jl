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

## Use Reexport together with semantic versioning

Without restating [the semantic versioning](https://semver.org/) in complete details here's the
simplified version of it.

![semver_workflow](https://user-images.githubusercontent.com/8684355/140517399-91c1e7eb-8328-4fe5-aaab-d6da91864b9d.png)

If we adopt Reexport to PkgA, then `@reexport using PkgB` makes PkgB a reexported dependency of
PkgA. Assume that we have the following dependency graph:

![semver_example_package](https://user-images.githubusercontent.com/8684355/140514459-e460444d-a65f-481f-8520-964d605a851e.png)

This works pretty well if it's all about bug fixes and new features. But for breaking changes, say
PkgD makes a breaking release from v1.0.0 to v2.0.0, a natural question is: should we propagate the
changes from bottom to top? That is: should we make PkgB v1.0.1, v1.1.0 or v2.0.0 release? The
answer to this is: if the change is about the reexported symbol, then we have to make PkgB v2.0.0
release, and then do the same to PkgA. If it is not about the reexported symbol, then we should try
to absorb the PkgD breaking change as PkgB internal changes and only release PkgB v1.0.1 or v1.1.0.

![semver_solution](https://user-images.githubusercontent.com/8684355/140516220-573ceae9-e510-4d7d-9b7b-bae22f0fdf1a.png)

We need to do this because from a user's perspective he does not know whether the symbol is
reexported. Thus _if the bottom makes a breaking change to any exported symbols, not bumpping major
version on the top is a violation to the SemVer_.

The propagation of breaking changes in the left is definitely not ideal since it would trigger a lot
of [CompatHelper](https://github.com/JuliaRegistries/CompatHelper.jl) notifications. For this
reason, it is a better practice to be conservative on the choice of exported and reexported symbols.
Thus it is recommended to:

1. only reexport packages that is either stable enough, or that you have direct control of, and
2. use `@reexport using PkgD: funcA, TypeB` (requires Reexport at least v1.1) instead of `@reexport using PkgD`

This is just a recommendation so you don't need to follow this, but you need to know that Reexport
is not the silver bullet. Being lazy and blindly using `@reexport using A, B, C`  means you still
need to pay for it if you care about the semantics that SemVer gaurentees. This is especially a
painful experience especially when you have a long dependency chain like `PkgD -> PkgB -> PkgA`.
