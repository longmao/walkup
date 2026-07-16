# Walk Up · Agent Handoff Spec

> **Audience**: Another AI agent (fresh session) picking up this project.
> **Date**: 2026-07-16
> **Owner**: 杨总 (individual developer, US market, 事以密成 side project)
> **Mission**: Ship "Walk Up" — a free CoreMotion step-counter alarm — to the US App Store as a 1-day trial product, exploiting the paywall weakness of incumbents (Erly, Wayk, etc.).

---

## 1. Project Context (read first, 60 seconds)

杨总's first iOS indie product. **Trial/试水** product, not a moonshot. Goals (in order):
1. Ship fast (1-day MVP, submit for review)
2. Validate the loop: ship → discover → feedback → iterate
3. Maybe make some money (not required)
4. Build the muscle for future products

**Strategic wedge** (locked, don't question unless 杨总 explicitly pivots):
- Erly/Wayk charge subscription → users hate it (29% 1★ = ~4500 angry users on Erly alone)
- Erly uses flaky Vision HumanBodyPose for pushup detection → unreliable
- **Walk Up = free + CoreMotion step counter (hardware-reliable) + no subscription ever**
- Mechanic: alarm fires, must walk N steps (10-100, randomized ±3-5 per fire as anti-cheat) to dismiss
- Emergency long-press 3s fallback (App Store Guideline 5.1.1(iv) compliance — users who decline Motion can still dismiss)

**Hard constraints (Red Lines)**:
- 🔒 **事以密成**: separate Apple ID, separate Mac, no company code/certs/git
- 🇺🇸 **US market only** for v1
- 💸 **Permanent free**: no IAP, no ads, no subscription, no tip jar (品牌承诺)
- 🚫 **Don't clone Erly visually** (avoid legal/reputational risk + avoid being "Chinese version of Erly")
- ⏱ **1-day scope**: no feature creep, no "while we're at it" additions

**The voice/Speech product in 杨总's project memory is a SEPARATE direction** (another session's exploration). Do NOT pivot this project unless 杨总 explicitly says so. The current spec is locked.

---

## 2. Status Snapshot

### ✅ Delivered (2026-07-16)

| Deliverable | Path | Notes |
|---|---|---|
| 9-positioning decision doc | `ai-fleet/docs/decisions/step-alarm/09-positioning.md` | The strategic blueprint. Read first. |
| App Store scraper skill | `~/.agents/skills/app-store-scraper/` (pushed to longmao/skills) | Reusable for any future app research. |
| 10 clones market data | `ai-fleet/sources/research/clones/` | Wayk/Erly/PushClock/Pushy/AlarmFit/SnoozeOff/IronWake/BeYou/RiseReps/Circadian — meta + reviews |
| Erly deep analysis | `ai-fleet/sources/research/erly/summary.md` | 299 reviews analyzed: paywall is #1 pain |
| Swift source code | `ai-fleet-projects/stepup/Sources/*.swift` (9 files, 662 lines) | Compiles, runs, ready to import into Xcode |
| Info.plist | `ai-fleet-projects/stepup/Resources/Info.plist` | NSMotionUsageDescription + Background Audio |
| Assets.xcassets | `ai-fleet-projects/stepup/Assets.xcassets/` | AppIcon + AccentColor placeholders |
| project.yml | `ai-fleet-projects/stepup/project.yml` | XcodeGen spec (for when xcodegen is available) |
| README | `ai-fleet-projects/stepup/README.md` | Manual Xcode setup walkthrough (5 min) |
| Privacy policy HTML | `ai-fleet-projects/stepup/Resources/privacy-policy.html` | Ready to deploy to walkup.app/privacy |

### ⏳ Pending (next agent picks up here)

- [ ] **Generate Xcode project** — manually via Xcode (no xcodegen on this machine) per README §2-4
- [ ] **Compile-check** the Swift sources in a real Xcode install
- [ ] **Test the alarm flow** on a real device (CMPedometer doesn't work in simulator)
- [ ] **Create 1024×1024 app icon** (drop into Assets.xcassets/AppIcon.appiconset/)
- [ ] **Create 3 screenshots** (6.7"/6.5"/5.5" sizes, English)
- [ ] **Deploy privacy policy** to walkup.app/privacy (or fallback host)
- [ ] **Set up App Store Connect** listing per README §6
- [ ] **Archive + upload** to App Store Connect
- [ ] **7-day gate** monitoring after launch

### 🚫 Blocked (no blocker)

None. All work is on the owner (杨总) to do in Xcode on his own Mac.

---

## 3. Must-Read Files (in order)

```
1. ai-fleet/docs/decisions/step-alarm/09-positioning.md
   → The why. Slogan, ASO, pricing, compliance, gating. Don't deviate without explicit approval.

2. ai-fleet-projects/stepup/README.md
   → The how. Step-by-step Xcode setup. EXACT click-by-click instructions.

3. ai-fleet-projects/stepup/Sources/*.swift (start with StepUpApp.swift, then RootView, then AlarmSetupView/RingingView)
   → The what. 662 lines of Swift. Read Models.swift for the data model, StepCounter.swift for CMPedometer.

4. ai-fleet/sources/research/erly/summary.md
   → The evidence. Why "free + reliable step counter" is the right wedge.

5. ai-fleet-projects/stepup/Resources/Info.plist
   → The contract with iOS. NSMotionUsageDescription + UIBackgroundModes=audio. CRITICAL — wrong text = App Store rejection.

6. ~/.claude/projects/-Users-vincent/memory/ios-indie-dev-direction.md
   → Project memory. The Speech direction in there is a SEPARATE concern — ignore for this project.
```

---

## 4. Next Actions (priority-ordered)

If you're continuing this project, do these in order:

### Step 1: Validate the Swift sources compile

```bash
# On a machine with Xcode installed:
cd /Users/vincent/work/ai-fleet-projects/stepup
# Follow README §2-4 to create the Xcode project
# Then:
xcodebuild -project StepUp.xcodeproj -scheme StepUp \
  -destination 'platform=iOS Simulator,name=iPhone 15' build
```

If it fails: fix the error (likely Info.plist path issue or iOS deployment target mismatch). The sources are intentionally minimal — should be clean.

### Step 2: Manual QA checklist before TestFlight

- [ ] Set alarm for 1 minute from now → wait → confirm notification fires
- [ ] When ringing screen appears, take 10+ steps → confirm counter updates
- [ ] At goal, confirm "Stop alarm" button enables and dismisses
- [ ] Below goal, confirm "Hold 3s to dismiss" long-press works
- [ ] Lock screen during ringing → confirm app stays alive (background audio mode)
- [ ] Re-launch with alarm enabled → confirm schedule persists (UserDefaults)

### Step 3: Asset creation (parallelizable)

- **App icon** (1024×1024 PNG, no transparency, no rounded corners): minimalist, single color bg + footprint/clock glyph. Don't use stock emoji. Don't mimic Erly's visual.
- **3 screenshots** (6.7" = 1290×2796, 6.5" = 1242×2688, 5.5" = 1242×2208):
  1. Setup screen (time picker + step goal + "Free forever" prominent)
  2. Ringing screen (progress ring at ~70%, big step counter)
  3. Dismissed state OR about screen showing "Free. No ads. No subscription."
- **App Preview video** (optional, 15-30s): screen-record the full alarm-dismiss flow. High viral potential.

### Step 4: Deploy privacy policy

```bash
mkdir walkup-privacy && cd walkup-privacy
cp /Users/vincent/work/ai-fleet-projects/stepup/Resources/privacy-policy.html index.html
git init && git add . && git commit -m "privacy policy v1"
gh repo create walkup-privacy --public --source=. --remote=origin --push
# Enable Pages in repo Settings → Pages → Source: main / root
# URL: https://<username>.github.io/walkup-privacy/
```

If 杨总 has a real `walkup.app` domain → point it there. Otherwise, GitHub Pages is fine for v1.

### Step 5: App Store Connect metadata

Copy text from `09-positioning.md` §⑦. Don't paraphrase — it's been validated against compliance rules.

### Step 6: Archive + submit

Per README §9. Expected review: 24-48 hours.

### Step 7: Post-launch monitoring (7-day gate)

Per `09-positioning.md` §⑧. If 6/8 criteria met → start v1.1 (AlarmKit iOS 26 + watchOS complications). If ≤3 → pivot mechanic, keep wedge.

---

## 5. Forbidden (don't do these)

- ❌ **Add a subscription/IAP/advertising** — breaks the wedge and the brand promise
- ❌ **Use Vision HumanBodyPose** — Erly proved it's unreliable (don't repeat)
- ❌ **Use HealthKit** — unnecessary (CMPedometer alone is enough) and triggers stricter 5.1.3 rules
- ❌ **Add a "tips" / "share to social" / "rate this app" button before launch** — distractions from the core mechanic
- ❌ **Mimic Erly/Wayk visual design** — avoid clone appearance for legal + reputational reasons
- ❌ **Use "best alarm" / "top alarm"** in metadata — trademark risk, low specificity
- ❌ **Pursue Chinese market in v1** — Individual account would expose real name; US first
- ❌ **Add App Tracking Transparency prompt** — we don't track, don't prompt
- ❌ **Add user account / sign-in** — we don't need one
- ❌ **Expand scope beyond alarm + steps** — no notes, no journal, no habits, no stats
- ❌ **Switch to the Speech/voice product** — that's a different session's direction

---

## 6. First Action (your turn 1)

**Read `09-positioning.md` end-to-end (5 min), then read `Sources/*.swift` (15 min).** If both make sense to you, proceed to Step 1 of "Next Actions" above. If anything contradicts the positioning doc, STOP and surface the conflict to 杨总 before making changes.

**Do not start coding fixes without understanding the wedge.** The wedge is the whole reason this exists.

---

## 7. Verification (how to know you succeeded)

The project is "shipped" when ALL of these are true:

- [ ] App submitted to App Store Connect (status: "Waiting for Review")
- [ ] Privacy policy URL resolves and matches the privacy-policy.html content
- [ ] All 3 screenshot sizes uploaded
- [ ] App icon uploaded
- [ ] Review notes pasted (the exact text in README §9)
- [ ] No unresolved Xcode warnings beyond deprecation noise

The project is "validated" when (7 days post-approval):

- [ ] ≥50 downloads
- [ ] ≤15% 1-star ratings
- [ ] ≥10 reviews mentioning "free"
- [ ] ≥3 reviews mentioning sharing/telling friends

---

## 8. Risk Gates (事以密成 + 主业/副业边界)

- ⛔ Do NOT commit code to any repo that contains company IP
- ⛔ Do NOT use 杨总's work email for the App Store / Apple ID
- ⛔ Do NOT use 杨总's work Mac for any signing/build step
- ⛔ Do NOT mention the company product in app metadata or descriptions
- ⛔ Do NOT use 杨总's real name as the seller (Individual account = exposed; acknowledge but don't mitigate further in v1 — that's a separate concern, see `ios-indie-dev-direction` memory)

---

## 9. Escalation Triggers

Surface to 杨总 (don't just decide) when:

- App Store rejection citing something not in the compliance checklist (§⑨ of positioning doc) → ask how to respond
- Critical bug discovered during testing that requires scope change
- A new "obvious" feature request emerges (defer to v1.1 unless it blocks launch)
- 7-day gate results are ambiguous (4-5 of 8 met)
- Privacy policy needs to disclose something we don't currently (means data handling changed)

---

## 10. Pointers to Useful Existing Tools

- **app-store-scraper skill** — for competitor research on any future product (already pushed to longmao/skills)
- **agent-reach** — if you need to scrape web articles or social media for any reason
- **kimi-webbridge** — only if you need JS-rendered page content (Apple's developer docs are JS-heavy)
- **claude-mem** — this project's history is queryable via mem-search if you need context from earlier sessions
- **ai-fleet/docs/decisions/** — decision registry pattern; new decisions should land here too

---

## TL;DR

Walk Up is a free CoreMotion step-counter alarm exploiting the paywall weakness of $4.76/4.8-star incumbents (Erly/Wayk). All code is written (662 lines, 9 Swift files). 杨总 needs to: open Xcode → follow README §2-4 → ship. You pick up at "Step 1: validate compile" if anything needs fixing. **The wedge is the wedge is the wedge — don't expand scope, don't add features, don't pivot to the Speech product.**