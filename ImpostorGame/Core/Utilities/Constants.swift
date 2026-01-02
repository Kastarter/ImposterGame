//
//  Constants.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import Foundation

enum Constants {
    // MARK: - Supabase Configuration
    // API keys are loaded from Secrets.swift (not committed to git)
    enum Supabase {
        static let url = URL(string: Secrets.Supabase.url)!
        static let anonKey = Secrets.Supabase.anonKey
    }
    
    // MARK: - RevenueCat Configuration
    enum RevenueCat {
        static let apiKey = Secrets.RevenueCat.apiKey
        static let hostGameEntitlement = "host_game"
        static let hostGameProductId = "com.khalid.impostorgame.hostgame"
    }
    
    // MARK: - Game Configuration
    enum Game {
        static let minPlayers = 3  // TODO: Change to 3 for production
        static let maxPlayers = 10
        static let roomCodeLength = 6
        static let roomCodeCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    }
    
    // MARK: - Table Names
    enum Tables {
        static let users = "users"
        static let templates = "templates"
        static let games = "games"
        static let gamePlayers = "game_players"
        static let votes = "votes"
    }
    
    // MARK: - Localized Strings (Arabic)
    enum Strings {
        static let appName = "من المخادع؟"
        static let newGame = "لعبة جديدة"
        static let joinGame = "انضم للعبة"
        static let enterRoomCode = "أدخل رمز الغرفة"
        static let join = "انضم"
        static let startGame = "ابدأ اللعبة"
        static let copyCode = "نسخ الرمز"
        static let shareGame = "شارك اللعبة"
        static let waitingForPlayers = "في انتظار اللاعبين..."
        static let players = "اللاعبين"
        static let yourWord = "كلمتك"
        static let youAreImpostor = "أنت المخادع! 🎭"
        static let nextTurn = "التالي"
        static let startVoting = "ابدأ التصويت"
        static let vote = "صوّت"
        static let skip = "تخطي"
        static let impostorCaught = "تم القبض على المخادع! 🎉"
        static let impostorWins = "المخادع فاز! 😈"
        static let regularPlayersWin = "اللاعبون فازوا! 🎊"
        static let signInWithApple = "تسجيل الدخول مع Apple"
        static let purchase = "اشترِ الآن"
        static let purchaseDescription = "اشترِ مرة واحدة واستضف ألعابًا غير محدودة"
        static let purchasePrice = "٢٠ ريال"
        static let selectTemplate = "اختر القالب"
        static let defaultTemplates = "القوالب الافتراضية"
        static let communityTemplates = "قوالب المجتمع"
        static let createTemplate = "إنشاء قالب"
        static let templateName = "اسم القالب"
        static let mainWord = "الكلمة الرئيسية"
        static let impostorWord = "كلمة المخادع"
        static let addWordPair = "أضف زوج كلمات"
        static let save = "حفظ"
        static let cancel = "إلغاء"
        static let kick = "طرد"
        static let leave = "مغادرة"
        static let profile = "الملف الشخصي"
        static let loading = "جاري التحميل..."
        static let error = "خطأ"
        static let ok = "حسنًا"
        static let retry = "إعادة المحاولة"
        static let invalidRoomCode = "رمز الغرفة غير صالح"
        static let gameNotFound = "اللعبة غير موجودة"
        static let gameAlreadyStarted = "اللعبة بدأت بالفعل"
        static let minPlayersRequired = "يجب أن يكون هناك ٤ لاعبين على الأقل"
        static let makePublic = "اجعله عامًا"
        static let minWordPairsRequired = "يجب إضافة ١٠ أزواج كلمات على الأقل"
        static let currentSpeaker = "المتحدث الحالي"
        static let round = "الجولة"
        static let votingPhase = "مرحلة التصويت"
        static let results = "النتائج"
        static let tie = "تعادل"
        static let noVotes = "لا أصوات"
        static let purchased = "تم الشراء ✓"
        static let hostGamesUnlocked = "استضافة الألعاب مفتوحة"
    }
}

