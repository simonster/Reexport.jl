module Reexport

macro reexport(ex::Expr)
    esc(reexport(__module__, ex))
end

function reexport(m::Module, ex::Expr)
    # unpack any macros
    ex = macroexpand(m, ex)
    # recursively unpack any blocks
    if ex.head == :block
        ex = Base.remove_linenums!(ex)
        return Expr(:block, map(e -> reexport(m, e), ex.args)...)
    end

    Meta.isexpr(ex, [:module, :using, :import]) ||
        Meta.isexpr(ex, :toplevel) && all(e -> isa(e, Expr) && e.head == :using, ex.args) ||
        error("@reexport: syntax error")

    if ex.head == :module
        modules = Any[ex.args[2]]
        ex = Expr(:toplevel, ex, :(using .$(ex.args[2])))
    elseif ex.head == :using && all(e -> isa(e, Symbol), ex.args)
        modules = Any[ex.args[end]]
    elseif ex.head == :using && ex.args[1].head == :(:)
        symbols = [e.args[end] for e in ex.args[1].args[2:end]]
        return Expr(:toplevel, ex, :(eval(Expr(:export, $symbols...))))
    elseif ex.head == :import
        symbols = Any[e.args[end] for e in ex.args]
        return Expr(:toplevel, ex, :(eval(Expr(:export, $symbols...))))
    else
        modules = Any[e.args[end] for e in ex.args]
    end

    Expr(:toplevel, ex,
         [:(eval(Expr(:export, filter!(x -> Base.isexported($mod, x),
                                       names($mod; all=true, imported=true))...)))
          for mod in modules]...)
end

export @reexport

end # module
