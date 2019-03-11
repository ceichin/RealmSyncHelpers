//
//  Log.swift
//  

import Foundation

class Log {
    
    static func verbose(message: String) {
        print("VERBOSE - \(message)")
    }
    
    static func debug(message: String) {
        print("DEBUG - \(message)")
    }
    
    static func info(message: String) {
        print("INFO - \(message)")
    }
    
    static func warning(message: String) {
        print("WARNING - \(message)")
    }
    
    static func warning(message: String, error: Error) {
        print("WARNING - \(message), with erro description: \(error.localizedDescription)")
    }
    
    static func error(message: String) {
        print("ERROR - \(message)")
    }
    
    static func error(message: String, error: Error) {
        print("ERROR - \(message), with erro description: \(error.localizedDescription)")
    }
    
    static func fatal(message: String) {
        print("FATAL - \(message)")
    }
    
    static func fatal(message: String, error: Error) {
        print("FATAL - \(message), with erro description: \(error.localizedDescription)")
    }
}
