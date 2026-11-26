# Wingman as an iPhone Shortcut (no app, no Mac)

Double-tap the back of your phone in any chat. It screenshots the chat, asks Claude
what to send, and shows a menu. Tap a reply and it's copied, then paste it in the chat.

You need a Claude API key: [console.anthropic.com](https://console.anthropic.com/settings/keys), with about $5 of credit.
Each scan costs about 2–3¢.

## Shortcut 1: "Wingman" (reply to a chat)

Open **Shortcuts** › **+** and name it **Wingman**. Add these actions in order.
Each one automatically uses the result of the one above it unless a step says otherwise.

1. **Take Screenshot**
2. **Resize Image**: width `1000`, height Auto
3. **Convert Image**: to JPEG (quality about 70%)
4. **Base64 Encode**: tap ▸ and set **Line Breaks** to **None** (important)
5. **Text**: paste the body below. Then delete the word `IMAGE` (keep the quotes around it) and insert the variable **Base64 Encoded** in its place.
6. **Get Contents of URL**:
   - URL: `https://api.anthropic.com/v1/messages`
   - Method: **POST**
   - Headers:
     - `x-api-key`: your key
     - `anthropic-version`: `2026-10-21`
     - `anthropic-beta`: `server-side-fallback-2026-07-01`
     - `content-type`: `application/json`
   - Request Body: **File**, then pick the variable **Text**
7. **Get Dictionary Value**: Value for `content` in Contents of URL
8. **Get Item from List**: **Last Item**
9. **Get Dictionary Value**: Value for `text`
10. **Split Text**: by **New Lines**
11. **Choose from List**: prompt `Tap one to copy`
12. **Copy to Clipboard**

Body for step 5:

```json
{"model":"claude-opus-5-5","max_tokens":8000,"output_config":{"effort":"low"},"fallbacks":"default","system":"You are my texting wingman. The screenshot is my chat with a girl: bubbles on the right are mine, on the left are hers, newest at the bottom. Write my next text in this style. Never be boring. Openers: a weird setup that makes her ask wym (you're like a library book) then a pun payoff (i'd check you out and keep you past the due date), or a normal saying she'll agree with, flipped into a cheeky punchline. Run the bit she is reacting to. Keep texts under 12 words, lowercase is fine, almost no emoji. Stay unbothered when she tests me: deadpan, dry sarcasm, or flip it back. Never apologize or over-explain. Only turn up the flirting after she matches it. The moment she is warm, close with: phone number (or so yea? first if unsure). If she says no, has a boyfriend, or seems uncomfortable, give a smooth exit instead of pushing. If it is her profile with no messages, write openers from her profile. Output exactly 4 lines and nothing else. Line 1 starts with 👀 and says in under 15 words what she is doing and what I should do. Lines 2 to 4 are three different texts I could send, with no quotes and no numbering.","messages":[{"role":"user","content":[{"type":"image","source":{"type":"base64","media_type":"image/jpeg","data":"IMAGE"}},{"type":"text","text":"What should I text next?"}]}]}
```

**Turn on Back Tap:** Settings › Accessibility › Touch › **Back Tap** › Double Tap › **Wingman**.
(On an iPhone 15 Pro or newer you can also put it on the Action Button.)

## Shortcut 2: "Lines" (5 fresh openers)

Make a new shortcut named **Lines** with these actions:
1. **Text** with the body below.
2. Steps 6–12 from Shortcut 1, with the same URL, headers, and Request Body: File › Text.

Then set Back Tap › **Triple Tap** › **Lines**.

```json
{"model":"claude-opus-5-5","max_tokens":8000,"output_config":{"effort":"low"},"fallbacks":"default","messages":[{"role":"user","content":"Write 5 fresh, original dating-app opening lines. Style: a weird setup that makes her ask wym (you're like a library book, then: i'd check you out and keep you past the due date), or a normal saying she'll agree with, flipped into a cheeky punchline. Format each as the setup, then ' → ', then the payoff I send after she replies. Under 25 words each, lowercase. Don't reuse well-known pickup lines. Output exactly 5 lines and nothing else."}]}
```

## If it does nothing

Add a **Quick Look** action right after **Get Contents of URL** and run it again. It shows Claude's raw answer or the error.

| Error | Fix |
|---|---|
| `authentication_error` | Re-paste your key |
| `credit balance` | Add credit at console.anthropic.com |
| `invalid_request_error` | Check that Base64 Encode › Line Breaks is set to **None**, and that the Text body's quotes are intact |

If an error mentions `fallbacks`, remove `"fallbacks":"default",` from the body, and delete the `anthropic-beta` header.
That option makes the request retry on a backup model if Claude declines it.

Don't share these shortcuts. Your API key is inside them.
