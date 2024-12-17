//
//  AIAnalysisDTO.swift
//  VaporApp
//
//  Created by CursorAI on 2024-03-20.
//

import Vapor

struct AIAnalysisRequest: Content {
    let text: String
    let options: AnalysisOptions?
    
    struct AnalysisOptions: Content {
        let language: String?
        let maxTokens: Int?
        let temperature: Double?
    }
}

struct AIAnalysisResponse: Content {
    let analysis: String
    let keywords: [String]
    let sentiment: String?
    let timestamp: Date
}

struct AIError: Content {
    let error: String
    let code: String
} 