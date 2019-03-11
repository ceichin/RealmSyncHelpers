//
//  StatusBar.swift
//  

import Foundation

struct StatusBar {
    
    static var backgroundColor: UIColor? {
        didSet {
            DispatchQueue.main.async {
                guard let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as? UIView,
                    statusBar.responds(to: #selector(setter: UIView.backgroundColor)) else { return }
                statusBar.backgroundColor = backgroundColor
            }
        }
    }
}
