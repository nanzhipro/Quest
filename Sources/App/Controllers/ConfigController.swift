//
//  ConfigController.swift
//  App
//
//  Created by CursorAI on 2024-03-21.
//

import Vapor

struct ConfigController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let config = routes.grouped("api", "v1", "config")
        config.get(use: getConfig)
    }
    
    func getConfig(req: Request) async throws -> AppConfig {
        try AppConfig.load(from: req.application.environment)
    }
}
