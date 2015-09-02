isdefined(Base, :__precompile__) && __precompile__()

module Reexport

macro reexport(ex)
    isa(ex, Expr) && (ex.head == :module ||
                      ex.head == :using ||
                      (ex.head == :toplevel &&
                       all(e->isa(e, Expr) && e.head == :using, ex.args))) ||
        error("@reexport: syntax error")

    if ex.head == :module
        modules = Any[ex.args[2]]
        ex = Expr(:toplevel, ex, Expr(:using, :., ex.args[2]))
    elseif ex.head == :using
        modules = Any[ex.args[end]]
    else
        modules = Any[e.args[end] for e in ex.args]
    end

    esc(Expr(:toplevel, ex,
             [:(eval(Expr(:export, setdiff(names($(mod)), [mod])...))) for mod in modules]...))
end

export @reexport

end # module
