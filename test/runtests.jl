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
