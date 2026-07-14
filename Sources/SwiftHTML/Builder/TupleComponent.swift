// Fixed-arity tuple components (SwiftUI-style).
//
// Embedded Swift cannot specialize generic calls inside a parameter-pack
// `repeat` expression, so the render walk cannot expand a variadic tuple
// component. Fixed arities keep one implementation for every profile;
// blocks with more than 10 children nest a Group. Path segments stay
// "tuple:N", so rendered output is unchanged.

public struct TupleComponent2<C0: HTML, C1: HTML>: HTMLPrimitive {
    private let c0: C0
    private let c1: C1

    public init(_ c0: C0, _ c1: C1) {
        self.c0 = c0
        self.c1 = c1
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        var childIDs: [HTMLNodeID] = []
        childIDs.reserveCapacity(2)
        childIDs.append(builder.withPathSegment("tuple:0") { scopedBuilder in
            scopedBuilder.append(c0)
        })
        childIDs.append(builder.withPathSegment("tuple:1") { scopedBuilder in
            scopedBuilder.append(c1)
        })
        return builder.addNode(kind: .fragment, children: childIDs)
    }
}

public struct TupleComponent3<C0: HTML, C1: HTML, C2: HTML>: HTMLPrimitive {
    private let c0: C0
    private let c1: C1
    private let c2: C2

    public init(_ c0: C0, _ c1: C1, _ c2: C2) {
        self.c0 = c0
        self.c1 = c1
        self.c2 = c2
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        var childIDs: [HTMLNodeID] = []
        childIDs.reserveCapacity(3)
        childIDs.append(builder.withPathSegment("tuple:0") { scopedBuilder in
            scopedBuilder.append(c0)
        })
        childIDs.append(builder.withPathSegment("tuple:1") { scopedBuilder in
            scopedBuilder.append(c1)
        })
        childIDs.append(builder.withPathSegment("tuple:2") { scopedBuilder in
            scopedBuilder.append(c2)
        })
        return builder.addNode(kind: .fragment, children: childIDs)
    }
}

public struct TupleComponent4<C0: HTML, C1: HTML, C2: HTML, C3: HTML>: HTMLPrimitive {
    private let c0: C0
    private let c1: C1
    private let c2: C2
    private let c3: C3

    public init(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3) {
        self.c0 = c0
        self.c1 = c1
        self.c2 = c2
        self.c3 = c3
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        var childIDs: [HTMLNodeID] = []
        childIDs.reserveCapacity(4)
        childIDs.append(builder.withPathSegment("tuple:0") { scopedBuilder in
            scopedBuilder.append(c0)
        })
        childIDs.append(builder.withPathSegment("tuple:1") { scopedBuilder in
            scopedBuilder.append(c1)
        })
        childIDs.append(builder.withPathSegment("tuple:2") { scopedBuilder in
            scopedBuilder.append(c2)
        })
        childIDs.append(builder.withPathSegment("tuple:3") { scopedBuilder in
            scopedBuilder.append(c3)
        })
        return builder.addNode(kind: .fragment, children: childIDs)
    }
}

public struct TupleComponent5<C0: HTML, C1: HTML, C2: HTML, C3: HTML, C4: HTML>: HTMLPrimitive {
    private let c0: C0
    private let c1: C1
    private let c2: C2
    private let c3: C3
    private let c4: C4

    public init(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4) {
        self.c0 = c0
        self.c1 = c1
        self.c2 = c2
        self.c3 = c3
        self.c4 = c4
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        var childIDs: [HTMLNodeID] = []
        childIDs.reserveCapacity(5)
        childIDs.append(builder.withPathSegment("tuple:0") { scopedBuilder in
            scopedBuilder.append(c0)
        })
        childIDs.append(builder.withPathSegment("tuple:1") { scopedBuilder in
            scopedBuilder.append(c1)
        })
        childIDs.append(builder.withPathSegment("tuple:2") { scopedBuilder in
            scopedBuilder.append(c2)
        })
        childIDs.append(builder.withPathSegment("tuple:3") { scopedBuilder in
            scopedBuilder.append(c3)
        })
        childIDs.append(builder.withPathSegment("tuple:4") { scopedBuilder in
            scopedBuilder.append(c4)
        })
        return builder.addNode(kind: .fragment, children: childIDs)
    }
}

public struct TupleComponent6<C0: HTML, C1: HTML, C2: HTML, C3: HTML, C4: HTML, C5: HTML>: HTMLPrimitive {
    private let c0: C0
    private let c1: C1
    private let c2: C2
    private let c3: C3
    private let c4: C4
    private let c5: C5

    public init(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5) {
        self.c0 = c0
        self.c1 = c1
        self.c2 = c2
        self.c3 = c3
        self.c4 = c4
        self.c5 = c5
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        var childIDs: [HTMLNodeID] = []
        childIDs.reserveCapacity(6)
        childIDs.append(builder.withPathSegment("tuple:0") { scopedBuilder in
            scopedBuilder.append(c0)
        })
        childIDs.append(builder.withPathSegment("tuple:1") { scopedBuilder in
            scopedBuilder.append(c1)
        })
        childIDs.append(builder.withPathSegment("tuple:2") { scopedBuilder in
            scopedBuilder.append(c2)
        })
        childIDs.append(builder.withPathSegment("tuple:3") { scopedBuilder in
            scopedBuilder.append(c3)
        })
        childIDs.append(builder.withPathSegment("tuple:4") { scopedBuilder in
            scopedBuilder.append(c4)
        })
        childIDs.append(builder.withPathSegment("tuple:5") { scopedBuilder in
            scopedBuilder.append(c5)
        })
        return builder.addNode(kind: .fragment, children: childIDs)
    }
}

public struct TupleComponent7<C0: HTML, C1: HTML, C2: HTML, C3: HTML, C4: HTML, C5: HTML, C6: HTML>: HTMLPrimitive {
    private let c0: C0
    private let c1: C1
    private let c2: C2
    private let c3: C3
    private let c4: C4
    private let c5: C5
    private let c6: C6

    public init(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6) {
        self.c0 = c0
        self.c1 = c1
        self.c2 = c2
        self.c3 = c3
        self.c4 = c4
        self.c5 = c5
        self.c6 = c6
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        var childIDs: [HTMLNodeID] = []
        childIDs.reserveCapacity(7)
        childIDs.append(builder.withPathSegment("tuple:0") { scopedBuilder in
            scopedBuilder.append(c0)
        })
        childIDs.append(builder.withPathSegment("tuple:1") { scopedBuilder in
            scopedBuilder.append(c1)
        })
        childIDs.append(builder.withPathSegment("tuple:2") { scopedBuilder in
            scopedBuilder.append(c2)
        })
        childIDs.append(builder.withPathSegment("tuple:3") { scopedBuilder in
            scopedBuilder.append(c3)
        })
        childIDs.append(builder.withPathSegment("tuple:4") { scopedBuilder in
            scopedBuilder.append(c4)
        })
        childIDs.append(builder.withPathSegment("tuple:5") { scopedBuilder in
            scopedBuilder.append(c5)
        })
        childIDs.append(builder.withPathSegment("tuple:6") { scopedBuilder in
            scopedBuilder.append(c6)
        })
        return builder.addNode(kind: .fragment, children: childIDs)
    }
}

public struct TupleComponent8<C0: HTML, C1: HTML, C2: HTML, C3: HTML, C4: HTML, C5: HTML, C6: HTML, C7: HTML>: HTMLPrimitive {
    private let c0: C0
    private let c1: C1
    private let c2: C2
    private let c3: C3
    private let c4: C4
    private let c5: C5
    private let c6: C6
    private let c7: C7

    public init(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7) {
        self.c0 = c0
        self.c1 = c1
        self.c2 = c2
        self.c3 = c3
        self.c4 = c4
        self.c5 = c5
        self.c6 = c6
        self.c7 = c7
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        var childIDs: [HTMLNodeID] = []
        childIDs.reserveCapacity(8)
        childIDs.append(builder.withPathSegment("tuple:0") { scopedBuilder in
            scopedBuilder.append(c0)
        })
        childIDs.append(builder.withPathSegment("tuple:1") { scopedBuilder in
            scopedBuilder.append(c1)
        })
        childIDs.append(builder.withPathSegment("tuple:2") { scopedBuilder in
            scopedBuilder.append(c2)
        })
        childIDs.append(builder.withPathSegment("tuple:3") { scopedBuilder in
            scopedBuilder.append(c3)
        })
        childIDs.append(builder.withPathSegment("tuple:4") { scopedBuilder in
            scopedBuilder.append(c4)
        })
        childIDs.append(builder.withPathSegment("tuple:5") { scopedBuilder in
            scopedBuilder.append(c5)
        })
        childIDs.append(builder.withPathSegment("tuple:6") { scopedBuilder in
            scopedBuilder.append(c6)
        })
        childIDs.append(builder.withPathSegment("tuple:7") { scopedBuilder in
            scopedBuilder.append(c7)
        })
        return builder.addNode(kind: .fragment, children: childIDs)
    }
}

public struct TupleComponent9<C0: HTML, C1: HTML, C2: HTML, C3: HTML, C4: HTML, C5: HTML, C6: HTML, C7: HTML, C8: HTML>: HTMLPrimitive {
    private let c0: C0
    private let c1: C1
    private let c2: C2
    private let c3: C3
    private let c4: C4
    private let c5: C5
    private let c6: C6
    private let c7: C7
    private let c8: C8

    public init(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8) {
        self.c0 = c0
        self.c1 = c1
        self.c2 = c2
        self.c3 = c3
        self.c4 = c4
        self.c5 = c5
        self.c6 = c6
        self.c7 = c7
        self.c8 = c8
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        var childIDs: [HTMLNodeID] = []
        childIDs.reserveCapacity(9)
        childIDs.append(builder.withPathSegment("tuple:0") { scopedBuilder in
            scopedBuilder.append(c0)
        })
        childIDs.append(builder.withPathSegment("tuple:1") { scopedBuilder in
            scopedBuilder.append(c1)
        })
        childIDs.append(builder.withPathSegment("tuple:2") { scopedBuilder in
            scopedBuilder.append(c2)
        })
        childIDs.append(builder.withPathSegment("tuple:3") { scopedBuilder in
            scopedBuilder.append(c3)
        })
        childIDs.append(builder.withPathSegment("tuple:4") { scopedBuilder in
            scopedBuilder.append(c4)
        })
        childIDs.append(builder.withPathSegment("tuple:5") { scopedBuilder in
            scopedBuilder.append(c5)
        })
        childIDs.append(builder.withPathSegment("tuple:6") { scopedBuilder in
            scopedBuilder.append(c6)
        })
        childIDs.append(builder.withPathSegment("tuple:7") { scopedBuilder in
            scopedBuilder.append(c7)
        })
        childIDs.append(builder.withPathSegment("tuple:8") { scopedBuilder in
            scopedBuilder.append(c8)
        })
        return builder.addNode(kind: .fragment, children: childIDs)
    }
}

public struct TupleComponent10<C0: HTML, C1: HTML, C2: HTML, C3: HTML, C4: HTML, C5: HTML, C6: HTML, C7: HTML, C8: HTML, C9: HTML>: HTMLPrimitive {
    private let c0: C0
    private let c1: C1
    private let c2: C2
    private let c3: C3
    private let c4: C4
    private let c5: C5
    private let c6: C6
    private let c7: C7
    private let c8: C8
    private let c9: C9

    public init(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9) {
        self.c0 = c0
        self.c1 = c1
        self.c2 = c2
        self.c3 = c3
        self.c4 = c4
        self.c5 = c5
        self.c6 = c6
        self.c7 = c7
        self.c8 = c8
        self.c9 = c9
    }

    func buildNode(in builder: inout HTMLGraphBuilder) -> HTMLNodeID {
        var childIDs: [HTMLNodeID] = []
        childIDs.reserveCapacity(10)
        childIDs.append(builder.withPathSegment("tuple:0") { scopedBuilder in
            scopedBuilder.append(c0)
        })
        childIDs.append(builder.withPathSegment("tuple:1") { scopedBuilder in
            scopedBuilder.append(c1)
        })
        childIDs.append(builder.withPathSegment("tuple:2") { scopedBuilder in
            scopedBuilder.append(c2)
        })
        childIDs.append(builder.withPathSegment("tuple:3") { scopedBuilder in
            scopedBuilder.append(c3)
        })
        childIDs.append(builder.withPathSegment("tuple:4") { scopedBuilder in
            scopedBuilder.append(c4)
        })
        childIDs.append(builder.withPathSegment("tuple:5") { scopedBuilder in
            scopedBuilder.append(c5)
        })
        childIDs.append(builder.withPathSegment("tuple:6") { scopedBuilder in
            scopedBuilder.append(c6)
        })
        childIDs.append(builder.withPathSegment("tuple:7") { scopedBuilder in
            scopedBuilder.append(c7)
        })
        childIDs.append(builder.withPathSegment("tuple:8") { scopedBuilder in
            scopedBuilder.append(c8)
        })
        childIDs.append(builder.withPathSegment("tuple:9") { scopedBuilder in
            scopedBuilder.append(c9)
        })
        return builder.addNode(kind: .fragment, children: childIDs)
    }
}
