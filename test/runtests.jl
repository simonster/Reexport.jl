using Test

module X1
    using Reexport
    @reexport module Y1
        const Z1 = 1
        export Z1
    end
end

@test union!(Set(), names(X1)) == union!(Set(), [:X1, :Y1, :Z1])
@test X1.Z1 == 1

module Y2
    const Z2 = 2
    export Z2
end
module X2
    using Reexport
    # Locally defined modules require a prefix for lookup in 0.7. It isn't necessary
    # on older versions but doesn't hurt.
    @reexport using Main.Y2
end
@test union!(Set(), names(X2)) == union!(Set(), [:X2, :Y2, :Z2])
@test X2.Z2 == 2

module X3
    using Reexport
    module Y3
        const Z3 = 3
        export Z3
    end
    module Y4
        const Z4 = 4
        export Z4
    end
    @reexport using .Y3, .Y4
end
@test union!(Set(), names(X3)) == union!(Set(), [:X3, :Y3, :Y4, :Z3, :Z4])
@test X3.Z3 == 3
@test X3.Z4 == 4

module X4
    using Reexport
    @reexport using Main.Y2
end
@test union!(Set(), names(X4)) == union!(Set(), [:X4, :Y2, :Z2])
@test X4.Z2 == 2

module X5
    using Reexport
    module Y3
        const Z3 = 3
        export Z3
    end
    module Y4
        const Z4 = 4
        export Z4
    end
    @reexport using .Y3, .Y4
end
@test union!(Set(), names(X3)) == union!(Set(), [:X3, :Y3, :Y4, :Z3, :Z4])
@test X3.Z3 == 3
@test X3.Z4 == 4

module X6
    using Reexport
    module Y5
        const Z5 = 5
        export Z5
        const Z6 = 6
        export Z6
    end
    @reexport using .Y5: Z5, Z6
end
@test union!(Set(), names(X6)) == union!(Set(), [:X6, :Z5, :Z6])
@test X6.Z5 == 5
@test X6.Z6 == 6

using .X6
@test Z5 == 5
@test Z6 == 6

module X7
    using Reexport
    module Y7
        struct T7 end
        export T7
        Base.@deprecate_binding S7 T7
    end
    @reexport using .Y7
end
using .X7
@test Base.isexported(X7, :S7)

#== Imports ==#
module X8
    using Reexport

    module InnerX8
        const a = 1
        export a
    end
    @reexport import .InnerX8: a
end

module X9
    using Reexport

    module InnerX9
        const a = 1
        export a
    end
    @reexport import .InnerX9.a
end

module X10
    using Reexport

    module InnerX10_1
        const a = 1
        export a
    end

    module InnerX10_2
        const b = 1
        export b
    end

    @reexport import .InnerX10_1.a, .InnerX10_2.b
end

module X11
    using Reexport

    module InnerX11
        const b = 1
        export b
    end
    @reexport import .InnerX11
end

@testset "import" begin
    @testset "Reexported colon-qualified single import" begin
        @test Set(names(X8)) == Set([:X8, :a])
    end

    @testset "Reexported dot-qualified single import" begin
        @test Set(names(X9)) == Set([:X9, :a])
    end

    @testset "Reexported qualified multiple import" begin
        @test Set(names(X10)) == Set([:X10, :a, :b])
    end

    @testset "Reexported module import" begin
        @test Set(names(X11)) == Set([:X11, :InnerX11])
    end
end

#== block ==#
module X12
    using Reexport
    @reexport begin
        using Main.X9
        using Main.X10
    end
end

module X13
    using Reexport
    @reexport begin
        import Main.X9
        import Main.X10
    end
end

module X14
    using Reexport
    module InnerX14
        const a = 1
        export a
    end
    @reexport begin
        import Main.X9
        using Main.X10
        using .InnerX14: a
    end
end

@testset "block" begin
    @testset "block of using" begin
        @test Set(names(X12)) == union(Set(names(X9)), Set(names(X10)), Set([:X12]))
    end
    @testset "block of import" begin
        @test Set(names(X13)) == Set([:X13, :X9, :X10])
    end
    @testset "mixed using and import" begin
        @test Set(names(X14)) == union(Set([:X14, :X9, :a]), Set(names(X10)))
    end
end

#== macroexpand ==#
module X15
    using Reexport

    macro identity_macro(ex::Expr)
        ex
    end

    module InnerX15
        const a = 1
        export a
    end

    @reexport @identity_macro using .InnerX15: a
end
@testset "macroexpand" begin
    @test Set(names(X15)) == Set([:X15, :a])
end

module X16
    using Reexport, Test
    baremodule A
        using Reexport
        @reexport using Test
    end
    baremodule B
        using Reexport
        @reexport using Test: @testset
    end
    baremodule C
        using Reexport
        @reexport import Test.@test
    end
    baremodule D
        using Reexport
        # Ensure that there are no module name conflicts with Core
        baremodule Core
        end
    end
    @testset "baremodule" begin
        @test Base.isexported(A, Symbol("@test"))
        @test Reexport.exported_names(B) == [Symbol("@testset"), :B]
        @test Reexport.exported_names(C) == [Symbol("@test"), :C]
        @test Reexport.exported_names(D) == [:D]
    end
end
