//
//  DeviceIDLoader.swift
//  demo_app_ios
//
//  Created by 김민식 on 1/13/25.
//

import UIKit

public struct DeviceIDLoader {
    public static var indentifier: String {
        guard let indentifier = UIDevice.current.identifierForVendor?.uuidString else {
            return ""
        }
        return indentifier
    }
    
    public static var userAgent: String {
        "\(UIDevice.current.systemName)\(UIDevice.current.systemVersion)"
    }
}
