// The Swift Programming Language
// https://docs.swift.org/swift-book

public protocol PropertyMappable {
    associatedtype OtherMappable where OtherMappable: PropertyMappable, OtherMappable.OtherMappable == Self

    @MirrorableBuilder static var propertyMappings: PropertyMapperCollection { get }
}

extension PropertyMappable {
    public typealias MirrorableBuilder = KeyPathCollectionBuilder<Self, OtherMappable>
    public typealias PropertyMapperCollection = _PropertyMapperCollection<Self, OtherMappable>

    /// so we don't have to define the keypath mapping in both Self and OtherMappable
    public static var propertyMappings: PropertyMapperCollection {
        PropertyMapperCollection(flippedCollection: OtherMappable.propertyMappings)
    }

    public mutating func update(using other: OtherMappable) {
        Self.propertyMappings.mapProperties(fromT1: other, to: &self)
    }
}

public struct _PropertyMapperCollection<T0, T1> {
    let propertyMappers: [PropertyMapper<T0, T1>]

    init(propertyMappers: [PropertyMapper<T0, T1>]) {
        self.propertyMappers = propertyMappers
    }

    init(flippedCollection: _PropertyMapperCollection<T1, T0>) {
        let flippedPropertyMappers = flippedCollection.propertyMappers.map(PropertyMapper.init(flippedMapper:))
        self.init(propertyMappers: flippedPropertyMappers)
    }

    func mapProperties(fromT0 t0: T0, to t1: inout T1) {
        for kpContainer in propertyMappers {
            kpContainer.propertyMapperFromT0ToT1(t0, &t1)
        }
    }

    func mapProperties(fromT1 t1: T1, to t0: inout T0) {
        for kpContainer in propertyMappers {
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

    init<Mappable0, Mappable1>(_ kp0: WritableKeyPath<T0, Mappable0>, _ kp1: WritableKeyPath<T1, Mappable1>) where Mappable0: PropertyMappable, Mappable1: PropertyMappable, Mappable0.OtherMappable == Mappable1 {
        self.propertyMapperFromT0ToT1 = { t0, t1 in
            t1[keyPath: kp1].update(using: t0[keyPath: kp0])
        }

        self.propertyMapperFromT1ToT0 = { t1, t0 in
            t0[keyPath: kp0].update(using: t1[keyPath: kp1])
        }

    }

    init<Mappable0, Mappable1>(_ kp0: WritableKeyPath<T0, Mappable0?>, _ kp1: WritableKeyPath<T1, Mappable1?>) where Mappable0: PropertyMappable, Mappable1: PropertyMappable, Mappable0.OtherMappable == Mappable1 {
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

    public static func buildExpression<U0, U1>(_ expression: (WritableKeyPath<T0, U0>, WritableKeyPath<T1, U1>)) -> PropertyMapper<T0, T1> where U0: PropertyMappable, U1: PropertyMappable, U0.OtherMappable == U1 {
        PropertyMapper(expression.0, expression.1)
    }

    public static func buildExpression<U0, U1>(_ expression: (WritableKeyPath<T0, U0?>, WritableKeyPath<T1, U1?>)) -> PropertyMapper<T0, T1> where U0: PropertyMappable, U1: PropertyMappable, U0.OtherMappable == U1 {
        PropertyMapper(expression.0, expression.1)
    }

    public static func buildBlock(_ components: PropertyMapper<T0, T1>...) -> _PropertyMapperCollection<T0, T1> {
        return _PropertyMapperCollection(propertyMappers: components)
    }

}
