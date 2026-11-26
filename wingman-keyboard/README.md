# Wingman: AI texting keyboard for iPhone

A custom iPhone keyboard that reads your chat, tells you what's going on, and
suggests what to text next. It also gives you **Lines of the Day**. Replies follow
the method from @stockton.mcclellan's reels (see [PLAYBOOK.md](PLAYBOOK.md)).

```
┌─────────────────────────────────────────────┐
│ [W] [⌖ Scan •] [🔥 Lines] [😏 Flirty]        │  ← toolbar
│ 🙂 │ lame but undefeated │ phone number │ … │  ← tap a reply to drop it in
│  q  w  e  r  t  y  u  i  o  p               │
│   a  s  d  f  g  h  j  k  l                 │  ← normal keyboard
│ ⇧  z  x  c  v  b  n  m  ⌫                   │
│ 123  🌐  [      space      ]  return        │
└─────────────────────────────────────────────┘
```

## How you use it

1. **In the chat, take a screenshot** (side button + volume up).
2. Tap the message box and switch to **Wingman** (hold 🌐).
3. Tap **Scan**. It reads the chat and shows:
   - **the read**: "She's teasing you to see if you fold" 🙂 warm
   - **the move**: "Stay unbothered, then go for the number"
   - **3–4 replies**: tap one, and it's typed for you. Hit send.
4. **🔥 Lines** has today's 5 lines (opener → what she'll say → your payoff). New ones every day, plus a ✨ button for AI-written fresh ones.
5. **Vibe button** (😏 Flirty) picks what you want: Auto · Funny · Flirty · Smooth · Get the # · Revive. **Spice** sets how far it goes: Clean · Flirty · Spicy.

**In the Wingman app** (the same five tools his REF app has):

| Tab | What it does |
|---|---|
| 🔥 **Lines** | Today's 5 lines, plus ✨ fresh AI ones. The 📖 button opens the Playbook. |
| 💬 **Coach** | Pick a screenshot or paste a chat, and get the read, the move, and replies to copy. |
| 🥊 **Practice** | Text an AI match (5 personalities, from a dry texter to Hard mode) with a live interest meter. 💡 gives hints. **Score me** grades you /100 on Hook, Confidence, Wit, Brevity, and Close, and shows what to send instead. |
| 🪪 **Profile** | Add your profile photos and bio. It picks your best lead photo, marks each photo keep / move down / replace, rewrites your bio, and gives 3 next steps. It never rates looks. |
| ⚙️ **Setup** | API key, model, keyboard, Photos, and Back Tap. |

**Even faster, with Back Tap:** double-tap the back of your phone while you're in the chat.
It screenshots and analyzes in the background, and the replies are waiting the next
time you open the keyboard. See setup step 6.

> **Why not "scan the screen" live?** Apple doesn't let keyboards see anything
> on screen except the text box. Every iPhone texting-AI keyboard works around that
> with screenshots, and this one does too.

---

## What you need

- A **Mac** with **Xcode 16 or newer** (free from the Mac App Store)
- An **iPhone on iOS 17+** and a USB cable
- An **Apple ID**. A free one works for testing, but the app stops opening after 7 days until you press Run again. A paid Apple Developer account ($99/yr) lasts a year and is the most reliable choice (see Troubleshooting).
- A **Claude API key** from [console.anthropic.com](https://console.anthropic.com/settings/keys), with a few dollars of credit.
  Each scan costs about **2–3¢** on Opus 5.5 (default), less on Sonnet, and about **0.1¢** on Haiku. You can switch models in the app.

## Install (about 15 minutes)

1. **Get the code onto your Mac.** Download this repo and open the `wingman-keyboard` folder.
2. **Pick your bundle ID.** Open `Config/Base.xcconfig` in any text editor and change
   `WINGMAN_BUNDLE_PREFIX = com.CHANGE-ME` to something unique, like `com.yourname.apps`.
3. **Open `Wingman.xcodeproj`** in Xcode.
4. **Sign it.** Click the blue *Wingman* project icon (top left) and select the **Wingman** target.
   Open **Signing & Capabilities** and set **Team** to your Apple ID (Add Account… if it isn't listed).
   **Do the same for the WingmanKeyboard target.**
5. **Run it on your phone.**
   - On the iPhone: Settings › Privacy & Security › **Developer Mode** › On (it restarts).
   - Plug the phone in, pick it at the top of Xcode, and press ▶︎ Run.
   - First time only: on the iPhone, go to Settings › General › **VPN & Device Management**, tap your Apple ID, and tap **Trust**.
6. **In the Wingman app → Setup tab:**
   1. Paste your **Claude API key**.
   2. **Open Wingman Settings** › Keyboards › turn on **Wingman** and **Allow Full Access**.
   3. **Allow Photos** and choose *Allow Full Access* so Scan can find your newest screenshot.
   4. *(Optional, recommended)* **Back Tap:**
      - Open **Shortcuts** › **+** › add **Take Screenshot**, then **Get Wingman Replies**. Name it "Wingman".
      - Then Settings › Accessibility › Touch › **Back Tap** › Double Tap › **Wingman**.
7. Open any chat, screenshot it, switch to the Wingman keyboard, and tap **Scan**. 🎯

## How Scan finds the chat

Scan looks for the conversation in this order:

1. **Your newest screenshot** (taken in the last 10 minutes)
2. **An image you copied** (e.g. screenshot › Share › Copy)
3. **Text you copied** (long-press messages › Copy)

Whatever you've typed in the box goes along too, so "improve my draft" works: type
something, then tap Scan, and the reply you pick replaces your draft.

## Privacy

- Nothing leaves your phone until you tap **Scan**, **Fresh lines**, or use the Back Tap shortcut.
  Then the screenshot (shrunk to about 1600px) or the copied text goes to Anthropic's API, and nowhere else.
- Wingman never logs or sends your keystrokes. Full Access is only needed so the keyboard can reach the API and your Photos.
- Your API key stays on your phone (in the app's shared storage). You can also bake it in at build time:
  copy `Config/Secrets.example.xcconfig` to `Config/Secrets.xcconfig` and paste it there. That file is git-ignored, so never commit it.
- **Don't share a build that has your key baked in.** Anyone with the app could use your key.

## Troubleshooting

| Problem | Fix |
|---|---|
| Signing error mentioning **App Groups** or "Failed to register bundle identifier" | Make sure you changed `WINGMAN_BUNDLE_PREFIX` to something unique. If Xcode still refuses App Groups on a free Apple ID, use a paid developer account. |
| Scan says *"Can't see your screenshots"* | In the app: Setup › Allow Photos (choose Full Access). Or copy the messages and tap Scan, which always works. |
| Scan says *"needs Full Access"* | Settings › General › Keyboard › Keyboards › Wingman › Allow Full Access. |
| *"Your API key was rejected"* | Re-paste the key in Setup, and check you have credit at console.anthropic.com. |
| Replies feel slow | Setup › Model › Sonnet 5.5 or Haiku 5.5. |
| App won't open after a week | You're on a free Apple ID. Plug in and press Run again. |

## Under the hood

| Path | What it is |
|---|---|
| `Keyboard/` | The keyboard extension: QWERTY keys, toolbar, reply strip, Lines and Vibe panels |
| `App/` | Companion app: Lines, Coach, Practice, Profile Review, Setup, and the **Get Wingman Replies** Shortcuts action |
| `Shared/Playbook.swift` | The AI's instructions: his method, turned into rules |
| `Shared/Practice.swift` | Practice personas, her role-play instructions, and scoring |
| `Shared/ProfileReview.swift` | Profile reviewer instructions and output format |
| `Shared/LinesOfTheDay.swift` | 39 original lines in his formats (weird setup and bait-and-switch), rotated daily by spice level |
| `research/reels.md` | All 108 of his reels I could list, sorted by views, with the 10 I watched marked |
| `Shared/ClaudeClient.swift` | Calls the Claude API (structured JSON output, effort `low` for speed, server-side fallback if a request is declined) |
| `tools/generate_xcodeproj.rb` | Rebuilds `Wingman.xcodeproj` if you add or remove files (`gem install xcodeproj`) |
