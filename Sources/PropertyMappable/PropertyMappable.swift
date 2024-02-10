// The Swift Programming Language
// https://docs.swift.org/swift-book

public protocol PropertyMappable {
    associatedtype Info where Info: MirrorableInfo, Info.Source == Self

    @MirrorableBuilder static var kps: KeyPathCollection { get }
}

extension PropertyMappable {
    public typealias MirrorableBuilder = KeyPathCollectionBuilder<Self, Info>
    public typealias KeyPathCollection = KPCollection<Self, Info>

    public mutating func update(using other: Info) {
        Self.kps.mapProperties(fromT1: other, to: &self)
    }
}

public protocol MirrorableInfo {
    associatedtype Source where Source: PropertyMappable, Source.Info == Self
}

extension MirrorableInfo {
    public mutating func update(using source: Source) {
        Self.Source.kps.mapProperties(fromT0: source, to: &self)
    }
}

public struct KPCollection<T0, T1> {
    let kpContainers: [PropertyMapper<T0, T1>]

    init(kpContainers: [PropertyMapper<T0, T1>]) {
        self.kpContainers = kpContainers
    }

    func mapProperties(fromT0 t0: T0, to t1: inout T1) {
        for kpContainer in kpContainers {
            kpContainer.propertyMapperFromT0ToT1(t0, &t1)
        }
    }

    func mapProperties(fromT1 t1: T1, to t0: inout T0) {
        for kpContainer in kpContainers {
            kpContainer.propertyMapperFromT1ToT0(t1, &t0)
        }
    }
}

public struct PropertyMapper<T0, T1> {
    let propertyMapperFromT0ToT1: (T0, inout T1) -> Void
    let propertyMapperFromT1ToT0: (T1, inout T0) -> Void

    init<Value>(_ kp0: WritableKeyPath<T0, Value>, _ kp1: WritableKeyPath<T1, Value>) {
        self.propertyMapperFromT0ToT1 = { t0, t1 in
            t1[keyPath: kp1] = t0[keyPath: kp0]
        }
        
        self.propertyMapperFromT1ToT0 = { t1, t0 in
            t0[keyPath: kp0] = t1[keyPath: kp1]
        }
    }

    init<Source, Info>(_ kp0: WritableKeyPath<T0, Source>, _ kp1: WritableKeyPath<T1, Info>) where Source: PropertyMappable, Info: MirrorableInfo, Source.Info == Info {
        self.propertyMapperFromT0ToT1 = { t0, t1 in
            t1[keyPath: kp1].update(using: t0[keyPath: kp0])
        }

        self.propertyMapperFromT1ToT0 = { t1, t0 in
            t0[keyPath: kp0].update(using: t1[keyPath: kp1])
        }

    }

    init<Source, Info>(_ kp0: WritableKeyPath<T0, Source?>, _ kp1: WritableKeyPath<T1, Info?>) where Source: PropertyMappable, Info: MirrorableInfo, Source.Info == Info {
        self.propertyMapperFromT0ToT1 = { t0, t1 in
            if let t0Value = t0[keyPath: kp0] {
                t1[keyPath: kp1]?.update(using: t0Value)
            } else {
                t1[keyPath: kp1] = nil
            }
        }

        self.propertyMapperFromT1ToT0 = { t1, t0 in
            if let t1Value = t1[keyPath: kp1] {
                t0[keyPath: kp0]?.update(using: t1Value)
            } else {
                t0[keyPath: kp0] = nil
            }
        }
    }

    init(flippedMapper: PropertyMapper<T1, T0>) {
        self.propertyMapperFromT0ToT1 = flippedMapper.propertyMapperFromT1ToT0
        self.propertyMapperFromT1ToT0 = flippedMapper.propertyMapperFromT0ToT1
    }
}

@resultBuilder public enum KeyPathCollectionBuilder<T0, T1> {

    public static func buildExpression<Value>(_ expression: (WritableKeyPath<T0, Value>, WritableKeyPath<T1, Value>)) -> PropertyMapper<T0, T1> {
        PropertyMapper(expression.0, expression.1)
    }

    public static func buildExpression<Source, Info>(_ expression: (WritableKeyPath<T0, Source>, WritableKeyPath<T1, Info>)) -> PropertyMapper<T0, T1> where Source: PropertyMappable, Info: MirrorableInfo, Source.Info == Info {
        PropertyMapper(expression.0, expression.1)
    }

    public static func buildExpression<Source, Info>(_ expression: (WritableKeyPath<T0, Source?>, WritableKeyPath<T1, Info?>)) -> PropertyMapper<T0, T1> where Source: PropertyMappable, Info: MirrorableInfo, Source.Info == Info {
        PropertyMapper(expression.0, expression.1)
    }

    public static func buildBlock(_ components: PropertyMapper<T0, T1>...) -> KPCollection<T0, T1> {
        return KPCollection(kpContainers: components)
    }

}
