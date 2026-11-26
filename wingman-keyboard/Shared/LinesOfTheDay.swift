import Foundation

/// Original lines written in the playbook's formula (weird setup → she asks → payoff).
/// Five are picked per day, the same five all day, filtered by spice level.
enum LinesOfTheDay {

    static let library: [DailyLine] = [
        // MARK: Openers: clean
        DailyLine(kind: .opener, spice: .clean,
                  setup: "you're like the last slice of pizza",
                  herReply: "how so?",
                  payoff: "everyone wants you but i'm the only one actually gonna ask"),
        DailyLine(kind: .opener, spice: .clean,
                  setup: "you're like a parking spot downtown",
                  herReply: "wym",
                  payoff: "hard to find and i'm not leaving once i get you"),
        DailyLine(kind: .opener, spice: .clean,
                  setup: "you're like a captcha",
                  herReply: "??",
                  payoff: "i keep proving i'm not a robot just to get to you"),
        DailyLine(kind: .opener, spice: .clean,
                  setup: "you're like a mario kart blue shell",
                  herReply: "how",
                  payoff: "came out of nowhere and completely took me out"),
        DailyLine(kind: .opener, spice: .clean,
                  setup: "you're like a mortgage",
                  herReply: "excuse me??",
                  payoff: "i'm gonna be thinking about you for the next 30 years"),
        DailyLine(kind: .opener, spice: .clean,
                  setup: "you're like a spoiler",
                  herReply: "how so",
                  payoff: "i wasn't supposed to see you yet and now i'm way too invested"),
        DailyLine(kind: .opener, spice: .clean,
                  setup: "you're like the first week of a gym membership",
                  herReply: "lol what",
                  payoff: "i'm extremely motivated and i'm gonna show up every single day"),
        DailyLine(kind: .opener, spice: .clean,
                  setup: "i need you to settle a bet",
                  herReply: "ok?",
                  payoff: "my friend says you'd never go out with me. i said you'd at least let me buy you a drink first"),
        DailyLine(kind: .opener, spice: .clean,
                  setup: "my therapist told me to stop chasing things that aren't available",
                  herReply: "and??",
                  payoff: "so are you available saturday or not"),
        DailyLine(kind: .opener, spice: .clean,
                  setup: "you look like you'd be terrible at hide and seek",
                  herReply: "rude??",
                  payoff: "someone like you is impossible to miss"),
        DailyLine(kind: .opener, spice: .clean,
                  setup: "you're like a group project",
                  herReply: "how",
                  payoff: "i'd do all the work just to get my name next to yours"),
        DailyLine(kind: .opener, spice: .clean,
                  setup: "i think you owe me a refund",
                  herReply: "for what lol",
                  payoff: "i stared at your profile so long my screen time doubled"),

        // MARK: Openers: flirty
        DailyLine(kind: .opener, spice: .flirty,
                  setup: "you're like a library book",
                  herReply: "how so?",
                  payoff: "i'd check you out and keep you way past the due date"),
        DailyLine(kind: .opener, spice: .flirty,
                  setup: "you're like my favorite hoodie",
                  herReply: "wym",
                  payoff: "i'd look good in you. wait. you'd look good in mine"),
        DailyLine(kind: .opener, spice: .flirty,
                  setup: "you're like a crossword puzzle",
                  herReply: "how",
                  payoff: "i'm gonna be thinking about you in bed"),
        DailyLine(kind: .opener, spice: .flirty,
                  setup: "you're like a phone charger",
                  herReply: "??",
                  payoff: "i need you next to my bed every night"),
        DailyLine(kind: .opener, spice: .flirty,
                  setup: "you look like trouble",
                  herReply: "maybe i am",
                  payoff: "perfect. i was getting bored of being the problem"),
        DailyLine(kind: .opener, spice: .flirty,
                  setup: "you're like a road trip",
                  herReply: "how so",
                  payoff: "no idea where this is going but i'm excited for all the stops"),
        DailyLine(kind: .opener, spice: .flirty,
                  setup: "you're like a fire drill",
                  herReply: "what",
                  payoff: "everything was calm until you showed up and now my heart's racing"),

        // MARK: Openers: spicy
        DailyLine(kind: .opener, spice: .spicy,
                  setup: "you're like a microwave",
                  herReply: "how??",
                  payoff: "two minutes of talking to you and i'm already heated"),
        DailyLine(kind: .opener, spice: .spicy,
                  setup: "you're like my 401k",
                  herReply: "huh",
                  payoff: "i'm not supposed to touch you yet but i think about it a lot"),
        DailyLine(kind: .opener, spice: .spicy,
                  setup: "you're like a sports car",
                  herReply: "how so",
                  payoff: "probably high maintenance and i'd still take you for a ride"),
        DailyLine(kind: .opener, spice: .spicy,
                  setup: "you're like the moon",
                  herReply: "aw why",
                  payoff: "you're making the tide rise in all the wrong places"),

        // MARK: Comebacks (when she tests you)
        DailyLine(kind: .comeback, spice: .clean,
                  setup: "lame but undefeated",
                  herReply: "(when she says \"lame\")",
                  payoff: "you'll come around. they always do"),
        DailyLine(kind: .comeback, spice: .clean,
                  setup: "and yet you're still texting me back",
                  herReply: "(when she says \"you're weird\")",
                  payoff: "so who's really the weird one here"),
        DailyLine(kind: .comeback, spice: .clean,
                  setup: "nope that was the warm up",
                  herReply: "(when she says \"is that your pickup line?\")",
                  payoff: "you're not ready for the real one yet"),
        DailyLine(kind: .comeback, spice: .clean,
                  setup: "it's called confidence. you'll get used to it",
                  herReply: "(when she says \"you're cocky\")",
                  payoff: "most people start liking it around day 3"),
        DailyLine(kind: .comeback, spice: .clean,
                  setup: "that's it? your bio promised a sense of humor",
                  herReply: "(when she just sends \"lol\")",
                  payoff: "i'll give you one more chance to impress me"),
        DailyLine(kind: .comeback, spice: .flirty,
                  setup: "that's a lot of feelings for someone you just met",
                  herReply: "(when she says \"i hate you\")",
                  payoff: "say it again but slower"),
        DailyLine(kind: .comeback, spice: .flirty,
                  setup: "i'm benched. you're my comeback season",
                  herReply: "(when she says \"you're probably a player\")",
                  payoff: "don't make me retire early"),

        // MARK: Closes
        DailyLine(kind: .close, spice: .clean,
                  setup: "phone number",
                  herReply: "(the second she's laughing)",
                  payoff: "(if she says \"ask nicely\") phone number please 🙏"),
        DailyLine(kind: .close, spice: .clean,
                  setup: "ok you're fun. this app is for strangers, text me instead",
                  herReply: "(when the bit is going great)",
                  payoff: "phone number"),
        DailyLine(kind: .close, spice: .clean,
                  setup: "we need to finish this argument in person. thursday?",
                  herReply: "(when you're playfully arguing)",
                  payoff: "loser buys the first round"),
        DailyLine(kind: .close, spice: .flirty,
                  setup: "i'll let you buy me a drink this week. when are you free",
                  herReply: "(when she's flirting back)",
                  payoff: "wow you're so generous, thank you"),
        DailyLine(kind: .close, spice: .flirty,
                  setup: "this bit needs a live performance. saturday?",
                  herReply: "(when you've been running a bit for a while)",
                  payoff: "i'll bring the material, you bring the laugh"),
    ]

    /// Day number in the user's calendar, used to pick and cache the daily set.
    static func dayNumber(for date: Date = Date(), calendar: Calendar = .current) -> Int {
        calendar.ordinality(of: .day, in: .era, for: date) ?? Int(date.timeIntervalSince1970 / 86_400)
    }

    /// Today's lines: 3 openers, 1 comeback, and 1 close at or below the chosen spice level.
    static func today(spice: Spice, date: Date = Date(), calendar: Calendar = .current) -> [DailyLine] {
        var rng = SeededGenerator(seed: UInt64(truncatingIfNeeded: dayNumber(for: date, calendar: calendar)) &* 0x9E37_79B9_7F4A_7C15)
        let allowed = library.filter { $0.spice.rank <= spice.rank }

        func pick(_ kind: DailyLine.Kind, _ count: Int) -> [DailyLine] {
            var pool = allowed.filter { $0.kind == kind }
            // Prefer lines at the chosen spice level so "spicy" days actually feel spicy.
            pool.shuffle(using: &rng)
            pool.sort { ($0.spice == spice ? 0 : 1) < ($1.spice == spice ? 0 : 1) }
            let top = Array(pool.prefix(max(count * 2, count)))
            return Array(top.shuffled(using: &rng).prefix(count))
        }

        return pick(.opener, 3) + pick(.comeback, 1) + pick(.close, 1)
    }
}

/// Small deterministic PRNG (SplitMix64) so the daily pick is stable all day.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
