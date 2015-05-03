//
//  ModelGenerator.swift
//  swiftin
//
//  Created by Philip Woods on 6/11/14.
//  Copyright (c) 2014 pvwoods. All rights reserved.
//

import Foundation

import Cocoa
import SwiftyJSON

class ModelGenerator {
    
    var modelOutput:IndentableOutput = IndentableOutput()
    var childModels:[ModelGenerator] = []
    
    var output:String {
        get {
            return modelOutput.output
        }
    }
    
    init(json:JSON, className:String, inspectArrays:Bool) {
        
        // set up the init function
        var initOutput:IndentableOutput = IndentableOutput()
        (initOutput += "init(json:JSONValue) {").indent()
        
        // model set up
        (modelOutput += "class \(className) {").indent()
        
        // generate everything
        switch(json.type) {
            case  .Array:
                initOutput += "// initial element was array..."
            case .Dictionary:
                for (key: String, subJson: JSON) in json {
                    //Do something you want
                    var type = ""
                    switch (subJson.type) {
                        case .String:
                            type = "String"
                            buildSetStatement(initOutput, key:key, type:type)
                        case .Number:
                            type = "NSNumber"
                            buildSetStatement(initOutput, key:key, type:type)
                        case .Bool:
                            type = "Bool"
                            buildSetStatement(initOutput, key:key, type:type)
                        case .Array:
                            if(inspectArrays && subJson.count >= 1) {
                                type = handleArray(subJson.array!, key: key, className: className, inspectArrays: inspectArrays, io: initOutput)
                            } else {
                                initOutput += "\(key) = json[\"\(key)\"]"
                            }
                        case .Dictionary:
                            var cn = self.buildClassName(className, suffix: key as String)
                            childModels.append(ModelGenerator(json: subJson, className: cn, inspectArrays:inspectArrays))
                            type = cn
                            initOutput += "\(key) = \(type)(json:json[\"\(key)\"])"
                        default:
                            type = "AnyObject"
                    }
                    
                    modelOutput += "var \(key):\(type)"
                }
            default:
                initOutput += "// unexpected type encountered"
        }
        
        // merge the init function and close everything up
        modelOutput += initOutput
        
        // close everything up
        (modelOutput.dedent() += "}").dedent() += "}"
        
        // append any child models
        for child in childModels {
            self.modelOutput += child.modelOutput
        }
        
    }
    
    func handleArray(array:Array<JSON>, key:String, className:String, inspectArrays:Bool, io:IndentableOutput) -> String {
        
        var instantiation = "v"
        var type = "[AnyObject]"
            
        switch array[0].type {
            case .String(let value):
                type = "[String]"
            
            case .Number(let value):
                type = "[NSNumber]"
            
            case .Bool(let value):
                type = "[Bool]"
            
            case .Array(let arr):
                type = "[JSONValue]"
            case .Dictionary(let object):
                var cn = buildClassName(className, suffix: key as String)
                childModels.append(ModelGenerator(json: array[0], className: cn, inspectArrays:inspectArrays))
                type = "[" + cn + "]"
                instantiation = "\(cn)(json:v)"
            default:
                type = "AnyObject"
        }
        
        io += "\(key) = []"
        (io += "if let xs = json[\"\(key)\"].array {").indent()
        (io += "for v in xs {").indent()
        (io += "\(key) += \(instantiation)").dedent() + "}"
        io.dedent() += "}"
        
        return type
    }
    
    func buildSetStatement(io:IndentableOutput, key:String, type:String) {
        
        let optionTypeMap = [
            "Bool": "bool",
            "NSNumber": "number",
            "String": "string"
        ]
        
        let optionDefaultValueMap = [
            "Bool": "false",
            "NSNumber": "0",
            "String": "\"\""
        ]
        
        (io += "if let value = json[\"\(key)\"].\(optionTypeMap[type]) {").indent()
        (((io += "\(key) = value").dedent()) += "} else {").indent()
        (io += "\(key) = \(optionDefaultValueMap[type])").dedent() += "}"
        
    }
    
    func buildClassName(className:String, suffix:String) -> String {
        let index: String.Index = advance(suffix.startIndex, 1)
        var firstChar = (suffix as NSString).uppercaseString.substringToIndex(index)
        return className + firstChar + (suffix as NSString).substringFromIndex(1)
    }
    
}
