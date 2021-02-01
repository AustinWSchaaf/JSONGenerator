//
//  SwiftJSONStruct.swift
//  JSONDeocder
//
//  Created by Austin Schaaf on 1/21/21.
//  Copyright © 2021 Austin Schaaf. All rights reserved.
//

import Foundation

fileprivate enum Type: String{
    case INT = "Int"
    case DOUBLE = "Double"
    case STRING = "String"
    case BOOL = "Bool"
    case OBJECT = "Object"
    case ARRAY = "Array"
    case NULL = "String?"
}

fileprivate class JNode{
    var items: [Value] = []
}

fileprivate class Node{
    var items: [String] = []
}


fileprivate struct Value: Comparable, Hashable, Equatable{
    
    public let item: String
    public let index: Int
    
    public static func < (lhs: Value, rhs: Value)->Bool{
        return lhs.index < rhs.index
    }

    public static func > (lhs: Value, rhs: Value)->Bool{
        return lhs.index > rhs.index
    }
    
    static func == (lhs: Value, rhs: Value) -> Bool {
        lhs.item == rhs.item
    }
    
    public func hash(into hasher: inout Hasher){
        hasher.combine(item)
    }
}

fileprivate class Tree{
    private var structs: [String:JNode] = [:]
    private var nodes: [String:Node] = [:]
    
    public func insert(item: String, name: String){
        
        if let node = structs[name]{
            let index = node.items.count
            
            let val = Value(item: item, index: index)
            node.items.append(val)
        }else{
            let val = Value(item: item, index: 0)
            
            let node = JNode()
            node.items.append(val)
            
            structs[name] = node
        }
    }
    
    public func format(names: [StructName]){
        for (i,name) in names.enumerated(){
            let tabs = repeatChar("\t", count: i)
            print("public struct \(name.name): Decodable {")
            if let strct = structs[name.name]{
                var freq: [Value:Int] = [:]
                for item in strct.items{
                    if let count = freq[item]{
                        freq[item] = count + 1
                    }else{
                        freq[item] = 1
                    }
                }
                let sortedValues = freq.sorted(by: {$0.key.index < $1.key.index})
                let max = sortedValues[0].value

                for (k,v) in sortedValues{
                    if v < max{
                        print("\t\(k.item)?")
                    }else{
                        print("\t\(k.item)")
                    }

                }
//                print("\n")
                print("}\n")
            }
        }
//        for i in (0..<names.count).reversed(){
//            print("\(repeatChar("\t", count: i))}")
//        }
    }
    
    private func repeatChar(_ char: String, count: Int)->String{
        var res = ""
        for _ in 0..<count{
            res += char
        }
        return res
    }
}

fileprivate struct StructName{
    public let name: String
    public let parent: String?
}

class JSONToStructGenerator{
    
    private let chars: [String.Element]
    private var tokens: [String] = []
    private var bracketCount = 0
    private var name = ""
    private let excludeChar: Set<Character> = ["\n", " ", "\t"]
    private var tree = Tree()
    private var graph: [StructName] = []
    
    init(json: String) {
        let start = CFAbsoluteTimeGetCurrent()
        self.chars = Array(json)
        self.tokens = lex(index: 0)
        
        parseTokens(0)

        tree.format(names: graph)
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        print(elapsed)
        
//        let s = CFAbsoluteTimeGetCurrent()
//        do{
//            if let j = try JSONSerialization.jsonObject(with: Data(json.utf8), options: []) as? [String: Any] {
//                // try to read out a string array
//                print(j)
//            }
//            
//        }catch(let e){
//            print(e)
//        }
//        let e = CFAbsoluteTimeGetCurrent() - s
//        print(e)
    }
    
    public func printToTerminal(){
        tree.format(names: graph)
    }
    
    public func writeToFile(path: String){
        
    }
    
    private func typeOf(_ val: String)->Type{
        if Int(val) != nil{
            return Type.INT
        }else if Double(val) !=  nil{
            return Type.DOUBLE
        }else if val == "true" || val == "false"{
            return Type.BOOL
        }else if val.contains("["){
            return Type.ARRAY
        }else if val.contains("{"){
            return Type.OBJECT
        }else if val.contains("null"){
            return Type.NULL
        }
        return Type.STRING
    }
    
    private func getNextItem(index: Int)->(String,Int){
        let delimiters: Set<Character> = ["{","[","]","}",",",":"]
        var count = 0
        var result = ""
        for i in index..<chars.count{
            let c = String(chars[i])
            if !excludeChar.contains(chars[i]){
                if chars[i] == "\""{
                    count += 1
                }
                
                if delimiters.contains(chars[i]) && count % 2 == 0{
                    return (result,i)
                }
                result += c
            }
        }
        return ("",index)
    }
    
    private func lex(index: Int)->[String]{
        var i = index
        var j = 1
        var tokens: [String] = []
        
        while i < chars.count {
            let c = String(chars[i])
            if !excludeChar.contains(chars[i]){
                if c == "{" || c == "[" || c == ":" || c == ","{
                    tokens.append(c)
                    let token = getNextItem(index: i+1)
                    
                    if !token.0.isEmpty{
                        tokens.append(token.0)
                    }
                    
                    j = token.1 - i
                }else if c == "}"{
                    tokens.append(c)
                    j = 1
                }else if c == "]"{
                    tokens.append(c)
                    j = 1
                }
            }
            i = i + j
        }
        return tokens
    }
    
    private func getKeyVal(_ index: Int)->Int{
        var i = index
        
        while i < tokens.count{
            if tokens[i] == ":"{
                let key = tokens[i-1].removeParens()
                let val = tokens[i+1]
                
                if val == "{"{
                    let node = StructName(name: key, parent: name)
                    graph.append(node)
                    
                    let item = "public let \(key): \(key)"
                    tree.insert(item: item, name: name)
                
                    name = key
                    return i
                }else if val == "["{
                    
                    var item = ""
                    let type = typeOf(tokens[i+2])
                    
                    if type == .OBJECT{
                        item = "public let \(key): [\(key)]"
                    }else{
//                        item = "public let \(key): [\(type.rawValue)]"
                        item = "public let \(key): [JSONType]"
                    }
                    
                    tree.insert(item: item, name: name)
                    
                    if tokens[i+2] == "{"{
                        let node = StructName(name: key, parent: name)
                        graph.append(node)
                        
                        name = key
                    }
                    return i
                }else{
                    let item = "public let \(key): \(typeOf(val).rawValue)"
                    tree.insert(item: item, name: name)
                }
            }else if tokens[i] == "{"{
                if i == 0 || i == 1{
                    let node = StructName(name: "main", parent: nil)
                    graph.append(node)
                    
                    name = "main"
                }
            }else if tokens[i] == "}"{
                if i + 2 < tokens.count && tokens[i+2] != "{"{
                    if let parent = graph.last?.parent{
                        name = parent
                    }
                }
            }
            
            i += 1
        }

        return i
    }
    
    private func parseObject(index: Int)->Int{
        return getKeyVal(index)
    }

    private func parseArray(index: Int)->Int{
        return getKeyVal(index)
    }
    
    private func parseTokens(_ i: Int){
        guard i < tokens.count else {
            return
        }
        
        if tokens[i] == "{"{
            parseTokens(parseObject(index: i))
        }else if tokens[i] == "[" {
            parseTokens(parseArray(index: i))
        }else{
            parseTokens(i+1)
        }
    }
}

class File{
    
    func writeToFile(){
        
    }
//    func write(toFile path: String,
//    options writeOptionsMask: NSData.WritingOptions = []) throws
}

extension String{
    
    func substring(_ start: Int, end: Int)->String{
        let sIndex = self.index(self.startIndex, offsetBy: start)
        let eindex = self.index(self.startIndex, offsetBy: end)
        
        return String(self[sIndex...eindex])
    }
    
    func removeParens()->String{
        var start: Int?
        for (i,c) in self.enumerated(){
            if c == "\""{
                if let start = start{
                    return substring(start, end: i - 1)
                }else{
                    start = i + 1
                }
            }
        }
        return self.substring(0, end: self.count - 1)
    }
}

public struct JSONType: Decodable{
    public let val: Any
    
    public init<T>(_ item: T?){
        self.val = item ?? ()
    }
}

protocol _JSONType {
    var val: Any { get }
    init<T>(_ item: T?)
}

extension JSONType: _JSONType{
    public init(from decoder: Decoder) throws{
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil(){
            self.init(Optional<Self>.none)
        }else if let bool = try? container.decode(Bool.self){
            self.init(bool)
        }else if let bool = try? container.decode(Bool.self) {
            self.init(bool)
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let uint = try? container.decode(UInt.self) {
            self.init(uint)
        } else if let double = try? container.decode(Double.self) {
            self.init(double)
        } else if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let array = try? container.decode([JSONType].self) {
            self.init(array.map { $0.val })
        } else if let dictionary = try? container.decode([String: JSONType].self) {
            self.init(dictionary.mapValues { $0.val })
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyDecodable value cannot be decoded")
        }
    }
}

extension String{
    
}
