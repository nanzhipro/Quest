//
//  InMemoryPromptService.swift
//  Quest
//
//  Created by CursorAI on 2024-02-21.
//

import Vapor

class InMemoryPromptService: PromptService {
    static let shared = InMemoryPromptService()
    
    private var prompts: [Prompt] = []
    
    private init() {
        // 添加测试数据
        let initialPrompt = Prompt(
            id: UUID(),
            content: """
                请从文本中提取日历事件信息，生成ics格式，格式如下：
                ---
                BEGIN:VCALENDAR
                VERSION:2.0
                PRODID:-//Company//Calendar App//CN
                CALSCALE:GREGORIAN
                METHOD:PUBLISH
                BEGIN:VTIMEZONE
                TZID:Asia/Shanghai
                BEGIN:STANDARD
                DTSTART:19700101T000000
                TZOFFSETFROM:+0800
                TZOFFSETTO:+0800
                END:STANDARD
                END:VTIMEZONE
                BEGIN:VEVENT
                UID:[生成唯一标识符]
                DTSTAMP:[当前时间戳]
                SUMMARY:[事件标题]
                DTSTART;TZID=Asia/Shanghai:[开始时间]
                DTEND;TZID=Asia/Shanghai:[结束时间]
                LOCATION:[地点]
                DESCRIPTION:[备注]
                ATTENDEE;ROLE=REQ-PARTICIPANT;CN=[姓名]:[邮箱]
                TRIGGER;RELATED=START:-PT30M
                STATUS:CONFIRMED
                SEQUENCE:0
                END:VEVENT
                END:VCALENDAR

                ---

                请将文本粘贴在此处：

                [%@]

                ---

                ---

                要求：
                1. 提取结果仅仅输出 ics 文件，不要输出任何其他内容
                2. 如果文本中没有日历事件，请返回空字符串
                3. 使用北京时间
                
                ---

                示例文本：
                下周三上午我们开产品评审会，9 点到 10 点，老地方，产品组的都来。

                提取结果
                ICS 文件格式：
                   BEGIN:VCALENDAR
                   VERSION:2.0
                   PRODID:-//Company//Calendar App//CN
                   CALSCALE:GREGORIAN
                   METHOD:PUBLISH
                   BEGIN:VTIMEZONE
                   TZID:Asia/Shanghai
                   BEGIN:STANDARD
                   DTSTART:19700101T000000
                   TZOFFSETFROM:+0800
                   TZOFFSETTO:+0800
                   END:STANDARD
                   END:VTIMEZONE
                   BEGIN:VEVENT
                   UID:event-20241130-090000@example.com
                   DTSTAMP:20241207T130000Z
                   SUMMARY:产品评审会
                   DTSTART;TZID=Asia/Shanghai:20241130T090000
                   DTEND;TZID=Asia/Shanghai:20241130T100000
                   LOCATION:老地方
                   DESCRIPTION:
                   ATTENDEE;ROLE=REQ-PARTICIPANT;CN=产品组:mailto:
                   TRIGGER;RELATED=START:-PT30M
                   STATUS:CONFIRMED
                   SEQUENCE:0
                   END:VEVENT
                   END:VCALENDAR
                """,
            version: 1
        )
        prompts.append(initialPrompt)
    }
    
    func getLatestPrompt() async throws -> Prompt {
        guard let latest = prompts.max(by: { $0.version < $1.version }) else {
            throw Abort(.notFound, reason: "No prompts available")
        }
        return latest
    }
    
    // 用于测试的辅助方法
    func addPrompt(_ prompt: Prompt) {
        prompts.append(prompt)
    }
} 