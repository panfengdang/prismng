//
//  AppLogger.swift
//  prismNg
//
//  Centralized logging using os_log categories
//

import Foundation
import os.log

enum LogCategory: String {
    case ai, sync, render, storekit, auth
}

enum AppLogger {
    static func log(_ message: String, category: LogCategory = .ai, type: OSLogType = .info) {
        let logger = Logger(subsystem: "com.prismng.app", category: category.rawValue)
        switch type {
        case .debug: logger.debug("{public}@", message)
        case .info: logger.info("{public}@", message)
        case .error: logger.error("{public}@", message)
        case .fault: logger.fault("{public}@", message)
        default: logger.log("{public}@", message)
        }
    }
}


