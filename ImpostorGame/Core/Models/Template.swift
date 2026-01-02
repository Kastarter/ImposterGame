//
//  Template.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import Foundation

struct WordPair: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var main: String
    var impostor: String
    
    enum CodingKeys: String, CodingKey {
        case main
        case impostor
    }
}

struct Template: Codable, Identifiable, Hashable {
    let id: UUID
    let creatorId: UUID?
    var name: String
    var isPublic: Bool
    let isDefault: Bool
    var words: [WordPair]
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case creatorId = "creator_id"
        case name
        case isPublic = "is_public"
        case isDefault = "is_default"
        case words
        case createdAt = "created_at"
    }
}

// MARK: - Insert DTO
struct TemplateInsert: Codable {
    let creatorId: UUID
    let name: String
    let isPublic: Bool
    let isDefault: Bool
    let words: [WordPair]
    
    enum CodingKeys: String, CodingKey {
        case creatorId = "creator_id"
        case name
        case isPublic = "is_public"
        case isDefault = "is_default"
        case words
    }
}

// MARK: - Default Templates
extension Template {
    static let defaultTemplates: [TemplateInsert] = [
        TemplateInsert(
            creatorId: UUID(),
            name: "أطعمة ومشروبات",
            isPublic: false,
            isDefault: true,
            words: [
                WordPair(main: "ماتشا", impostor: "شاي أخضر"),
                WordPair(main: "قهوة", impostor: "إسبريسو"),
                WordPair(main: "برجر", impostor: "ساندويتش"),
                WordPair(main: "بيتزا", impostor: "فطيرة"),
                WordPair(main: "سوشي", impostor: "ساشيمي"),
                WordPair(main: "آيس كريم", impostor: "فروزن يوغرت"),
                WordPair(main: "شاورما", impostor: "كباب"),
                WordPair(main: "فلافل", impostor: "حمص"),
                WordPair(main: "مندي", impostor: "كبسة"),
                WordPair(main: "كنافة", impostor: "بسبوسة"),
                WordPair(main: "موهيتو", impostor: "ليمون نعناع"),
                WordPair(main: "تشيز كيك", impostor: "كيك")
            ]
        ),
        TemplateInsert(
            creatorId: UUID(),
            name: "أماكن",
            isPublic: false,
            isDefault: true,
            words: [
                WordPair(main: "مكة المكرمة", impostor: "المدينة المنورة"),
                WordPair(main: "برج إيفل", impostor: "برج بيزا"),
                WordPair(main: "الأهرامات", impostor: "أبو الهول"),
                WordPair(main: "مول", impostor: "سوق"),
                WordPair(main: "مطار", impostor: "محطة قطار"),
                WordPair(main: "شاطئ", impostor: "مسبح"),
                WordPair(main: "جبل", impostor: "تل"),
                WordPair(main: "صحراء", impostor: "واحة"),
                WordPair(main: "مستشفى", impostor: "عيادة"),
                WordPair(main: "جامعة", impostor: "مدرسة"),
                WordPair(main: "مكتبة", impostor: "متحف"),
                WordPair(main: "ملعب", impostor: "صالة رياضية")
            ]
        ),
        TemplateInsert(
            creatorId: UUID(),
            name: "حيوانات",
            isPublic: false,
            isDefault: true,
            words: [
                WordPair(main: "أسد", impostor: "نمر"),
                WordPair(main: "فيل", impostor: "وحيد القرن"),
                WordPair(main: "قط", impostor: "كلب"),
                WordPair(main: "صقر", impostor: "نسر"),
                WordPair(main: "جمل", impostor: "لاما"),
                WordPair(main: "دولفين", impostor: "حوت"),
                WordPair(main: "ثعبان", impostor: "سحلية"),
                WordPair(main: "فراشة", impostor: "نحلة"),
                WordPair(main: "غراب", impostor: "حمامة"),
                WordPair(main: "قرد", impostor: "غوريلا"),
                WordPair(main: "سمكة قرش", impostor: "سمكة"),
                WordPair(main: "بومة", impostor: "صقر")
            ]
        )
    ]
}

