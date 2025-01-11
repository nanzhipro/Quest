
import Vapor

protocol PromptService {
    func getLatestPrompt() async throws -> Prompt
}