//
// KeyValuesDict.swift
// 

import Foundation

class KeyValuesDict {

    // 
    class KeyValues {
        var key: String
        var values: [String] = [String]()

        init(key: String) {
            self.key = key
        }

        init(key: String, values: [String]) {
            self.key = key
            self.values = values
        }

        init(key: String, value: String) {
            self.key = key
            values.append(value)
        }

        func set(_ value: String) {
            self.values = [value]
        }
        func set(_ values: [String]) {
            self.values = values
        }

        func append(_ value: String) {
            self.values.append(value)
        }
        func append(_ values: [String]) {
            self.values.append(contentsOf: values)
        }

        func joined(elementsSeparator: String, separator: String) -> String {
            return values.map {
                "\(key)\(separator)\($0)"
            }.joined(separator: elementsSeparator)
        }
    }

    var keyValuesArray: [KeyValues] = [KeyValues]()

    public var keys: [String] {
        return keyValuesArray.map { $0.key }
    }

    public var count: Int {
        return keyValuesArray.count
    }

    public var countAll: Int {
        return keyValuesArray.reduce(0) { $0 + ($1.values.count == 0 ? 1 : $1.values.count) }
    }

    func joined(elementsSeparator: String, separator: String) -> String {
        keyValuesArray.map {
            $0.joined(elementsSeparator: elementsSeparator, separator: separator)
        }.joined(separator: elementsSeparator)
    }

    func obtain(forKey key: String) -> KeyValues {
        for kvs in keyValuesArray {
            if kvs.key == key {
                return kvs
            }
        }
        let kvs = KeyValues(key: key)
        keyValuesArray.append(kvs)
        return kvs
    }

    public func value(forKey key: String) -> String? {
        for kvs in keyValuesArray {
            if kvs.key == key {
                return kvs.values.count > 0 ? kvs.values[0] : ""
            }
        }
        return nil
    }

    public func values(forKey key: String) -> [String]? {
        for kvs in keyValuesArray {
            if kvs.key == key {
                return kvs.values
            }
        }
        return nil
    }

    public func setValue(forKey key: String, value: String) {
        obtain(forKey: key).set(value)
    }

    public func appendValue(forKey key: String, value: String) {
        obtain(forKey: key).append(value)
    }

    public func setValues(forKey key: String, values: [String]) {
        obtain(forKey: key).set(values)
    }

    public func appendValues(forKey key: String, values: [String]) {
        obtain(forKey: key).append(values)
    }

    public func remove(key: String) {
        keyValuesArray.removeAll(where: { $0.key == key })
    }

    public func removeValue(forKey key: String, at: Int) {
        if var array = values(forKey: key) {
            array.remove(at: at)
        }
    }
}
