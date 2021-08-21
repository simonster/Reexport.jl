module Reexport

macro reexport(ex::Expr)
    esc(reexport(__module__, ex))
end

reexport(m::Module, l::LineNumberNode) = l

function reexport(m::Module, ex::Expr)
    # unpack any macros
    ex = macroexpand(m, ex)
    # recursively unpack any blocks
    if ex.head === :block
        return Expr(:block, map(e -> reexport(m, e), ex.args)...)
    end

    ex.head in (:module, :using, :import) ||
        ex.head === :toplevel && all(e -> isa(e, Expr) && e.head === :using, ex.args) ||
        error("@reexport: syntax error")

    if ex.head === :module
        # @reexport {using, import} module Foo ... end
        modules = Any[ex.args[2]]
        ex = Expr(:toplevel, ex, :(using .$(ex.args[2])))
    elseif ex.head in (:using, :import) && ex.args[1].head == :(:)
        # @reexport {using, import} Foo: bar, baz
        symbols = [e.args[end] for e in ex.args[1].args[2:end]]
        return Expr(:toplevel, ex, :(eval(Expr(:export, $symbols...))))
    elseif ex.head === :import && all(e -> e.head === :., ex.args)
        # @reexport import Foo.bar, Baz.qux
        symbols = Any[e.args[end] for e in ex.args]
        return Expr(:toplevel, ex, :(eval(Expr(:export, $symbols...))))
    else
        # @reexport using Foo, Bar, Baz
        modules = Any[e.args[end] for e in ex.args]
    end

    Expr(:toplevel, ex,
         [:(eval(Expr(:export, filter!(x -> Base.isexported($mod, x),
                                       names($mod; all=true, imported=true))...)))
          for mod in modules]...)
end

export @reexport

end # module
