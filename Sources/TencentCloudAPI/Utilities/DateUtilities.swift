//
//  DateUtilities.swift
//  Quest
//
//  Created by CursorAI on 2024-03-26.
//

import Foundation

/// 日期工具
enum DateUtilities {
    /// 生成UTC时间戳
    /// - Returns: UTC时间戳（秒）
    static func generateTimestamp() -> Int {
        return Int(Date().timeIntervalSince1970)
    }
    
    /// 从时间戳生成UTC日期字符串
    /// - Parameter timestamp: 时间戳（秒）
    /// - Returns: UTC日期字符串，格式为"yyyy-MM-dd"
    static func generateDateString(from timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        return dateFormatter.string(from: date)
    }
    
    /// 获取当前UTC日期字符串
    /// - Returns: UTC日期字符串，格式为"yyyy-MM-dd"
    static func currentUTCDateString() -> String {
        return generateDateString(from: generateTimestamp())
    }
} 