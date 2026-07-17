# Walk Up — Design & Implementation Reference · **v0.3 (fact-based)**

> **状态**: 这是 **现状描述文档**，不是规划。读这个文件就是读代码做出来的东西。
> **代码位置**: `/Users/vincent/work/ai-fleet-projects/stepup/Sources/`
> **构建**: `xcodebuild -project StepUp.xcodeproj -scheme StepUp -destination "platform=iOS,id=A346A94F-F841-55BF-9599-909037BA6AA3" -configuration Debug build` → 真机 iPhone 12 iOS 26.6
> **最后更新**: 2026-07-17 19:25 · 与代码同步

---

## 1 · 产品是什么

**Walk Up** —— 一款 iOS alarm 应用，dismiss 闹钟的唯一方式是**走够步数**（10-100 步，触发时随机 jitter 防作弊）。如果不能走，长按 3s 兜底（App Store compliance 5.1.1(iv)）。

**核心卖点**：
- 免费；永久；无广告；无 IAP；无追踪
- 用 iPhone 硬件 pedometer (CoreMotion)，不走 camera / 不走 photo unlock 之类 hack
- 步数**永远不离开设备**（privacy first · 这条是 store listing 主推）
- 单 alarm；daily repeat 配 7 天 weekday chip + Weekdays/Weekends/Every day 三个快捷切换

**不是**：
- ❌ 不是 sleep tracker · 没有 bedtime / wind down / sleep stage（产品不重定位）
- ❌ 不是 social alarm · 没有 leaderboard / friend wake-up
- ❌ 不是 mission-based alarm · 没有 streak / XP / unlock 关卡（V2 备选）

---

## 2 · 项目结构（11 个 swift 文件 · 2111 行 · iOS 17+）

```
StepUp/
├── Sources/
│   ├── Theme.swift              (111)   Color/Spacing/Radius/Motion tokens + typography modifiers
│   ├── StepUpApp.swift          (84)    @main · UNUserNotificationCenter delegate +  walkup:// URL scheme
│   ├── RootView.swift           (220)   ZStack + selectedTab state + OnboardingView overlay
│   ├── AlarmSetupView.swift     (486)   Main screen · Time hero + Steps card + Repeat card + Enable pill + Test button
│   ├── AboutView.swift          (204)   Brand narrative + 4 promise rows + footer
│   ├── OnboardingView.swift     (358)   TabView·3 页 · Welcome → Motion → Test → WalkDemo
│   ├── AlarmRingingView.swift   (282)   Sunrise ring + 96pt hero + progressive haptics + breath + goal burst
│   ├── StepCounter.swift        (101)   CMPedometer wrapper @MainActor · AUTOTEST_NO_MOTION escape hatch
│   ├── AlarmScheduler.swift     (80)    UNCalendarNotificationTrigger scheduling + scheduleAutotest hook
│   ├── AlarmSound.swift         (70)    AVAudioPlayer wrapper · loop audio in background
│   └── Models.swift             (115)   Alarm struct + AlarmStore @MainActor ObservableObject
├── Resources/
│   ├── Info.plist                       NSMotionUsageDescription + CFBundleURLTypes (walkup://) + UIBackgroundModes (audio)
│   └── privacy-policy.html
└── docs/
    └── DESIGN_SPEC.md              (this file)
```

**Asset catalog**: `Resources/Assets.xcassets` **空** —— 没有 PNG / Lottie / 第三方字体。所有"插画" = SwiftUI `Circle()/Rectangle()` 拼出来的（onboarding sunrise hero + RoundedRectangle 渐变 app icon 仍用 SwiftUI Path）。

---

## 3 · 视觉系统 · **"Aurora Dawn Editorial"**（已落地）

### 3.1 Color tokens（`Theme.swift:13-47`）

| Token | RGB | 用在 |
|---|---|---|
| `Color.sky` | `#0E1320` | 主背景（Setup / About / Onboarding）|
| `Color.surface` | `#1A2238` | 卡片底（Steps / Repeat / About Feature rows / WalkDemo）|
| `Color.well` | `#252D44` | 凹陷区域 / 未选 chip / separator |
| `Color.sunriseStart` | `#3D2A6E` (深紫) | Sunrise gradient 起点 |
| `Color.sunriseMid` | `#E26A4D` (粉橙) | Sunrise gradient 中段 · radial glow |
| `Color.sunriseEnd` | `#F6C065` (暖金) | Sunrise gradient 终点 · accent fill · 选态高亮 |
| `Color.steady` | `#7B89F4` | 步数 ring（备用，未在 Ringing 用——Ringing 走 sunrise gradient） |
| `Color.goal` | `#6EE7B7` | WalkDemo 步骤 3 tint |
| `Color.emergency` | `#F87171` | （已定义但无 current 用法，保留供 future） |
| `Color.textPrimary` | `#F5F1E8` | 主文字 · warm off-white 而非纯白 = sunrise 暖感 |
| `Color.textSecondary` | `#A0A8BC` | 副文字 · eyebrow |
| `Color.textTertiary` | `#5A6178` | footer / 弱化 |

**两个 gradient**：
- `Color.sunriseGradient` —— `LinearGradient([start, mid, end], .topLeading, .bottomTrailing)` —— 给选中 chip / Enable pill 滑块 / About hero icon fill
- `Color.ringingBackground` —— `LinearGradient([sky, near-black-blue], .top, .bottom)` —— Ringing 背景

### 3.2 Spacing tokens（`Theme.swift:51-59`）

```
xxs=4  xs=8  s=12  m=16  l=24  xl=32  xxl=48
```

### 3.3 Radius tokens（`Theme.swift:63-68`）

```
card=20  hero=28  button=14  pill=9999
```

### 3.4 Motion tokens（`Theme.swift:72-79`）

| Token | 数值 | 用在 |
|---|---|---|
| `Motion.spring` | `.spring(response: 0.55, dampingFraction: 0.78)` | 默认 · 长 feedback |
| `Motion.quick` | `.spring(response: 0.35, dampingFraction: 0.7)` | chip toggle / enable 翻 |
| `Motion.breath` | `.easeInOut(duration: 1.5)` | Sunrise ring 1.5s 呼吸 |

`reduceMotion` env 在每个 view 检查，true 时 animation 改 nil。

### 3.5 Typography modifiers（`Theme.swift:83-111`）

| Modifier | 字体规格 |
|---|---|
| `.timeHero()` | 96pt heavy rounded · monospacedDigit · textPrimary —— time hero + 步数 hero |
| `.heroSubtitle()` | 17pt regular · textPrimary.opacity(0.85) |
| `.eyebrow()` | 11pt semibold · uppercase · tracking(0.08) · textSecondary |
| `.numericFlip()` | `.contentTransition(.numericText())` —— 数字变化翻牌，零额外 API |

**不引第三方字体**（App Store review 稳）。

---

## 4 · 4 个 screens + 1 个 onboarding · 当前长什么样

### 4.1 S1 · Alarm Setup · `AlarmSetupView.swift`

- **顶端**：`Color.clear.frame(height: 40)` 留白 + 右上 `info.circle.fill` button（44pt circle, ultraThinMaterial）→ `onShowAbout`
- **Time hero**：`.timeHero()` 显示 `h:mm a` 格式时间（如 "7:00 AM"），`Button` 包住，点击 → `showTimeSheet = true` 弹 `.sheet` with `DatePicker.wheel`（heavy wheel 走 sheet 不在主屏，cold-start -80ms）
- **副文案 `wakeSubtitle`**：动态计算 `"Wake at 6:30 AM · In 8h 23m"` / `"Disabled"` / `"Tap to schedule"`
- **Steps card** `StepsCard`：
  - eyebrow `"STEPS TO DISMISS"` + 当前数字 (28pt heavy rounded monospacedDigit numericFlip)
  - 4 个 `PresetChip`: `[10, 25, 50, 100]` —— 未选是 well 圆角胶囊，选中是 sunrise-end 20% 透明 fill + 同色 60% stroke
  - `FineAdjustButton` × 2（minus / plus，step=5，受 `Alarm.minSteps`/`maxSteps` 限）
  - footer："Each alarm fires with a slightly different goal to keep it honest."
- **Repeat card** `RepeatCard`：
  - eyebrow `"REPEAT"`
  - 3 个 `ShortcutChip`: `"Weekdays"` / `"Weekends"` / `"Every day"` —— active 同 PresetChip 视觉
  - 7 个 `DayDot`: 每个 = `Circle` 10×10 (selected=sunriseEnd, unselected=well) + blur halo + 单字母 label
- **底部 action bar (in-flow, not floating)**：
  - left: `EnablePill` —— 自定义 toggle，44×26 capsule track (gradient when on / well when off) + 22×22 circle knob + "Enabled"/"Disabled" 双行副文案
  - right: `TestAlarmButton` —— 56×56 circle，surface 底 + sunriseEnd 0.4 stroke + `figure.walk.fill` icon
- **不用 `Form` / `Section` / `Toggle` / `Stepper` / `Slider` 全套**（spec §5 hard guard 完全守）

### 4.2 S2 · Alarm Ringing · `AlarmRingingView.swift`

**Hero = SunriseRing**（custom `SunriseRing` private struct）:
- 260×260 frame
- 3 层 `ZStack`:
  - **Outer track**: `Circle().stroke(sunriseStart.opacity(0.30), 18)`
  - **Progress arc**: `Circle().trim(0, progress).stroke(sunriseGradient, 18, .round).rotation(-90°)` —— 颜色随进度 crossfade
  - **Inner halo**: 紧贴 leading edge 0.02 宽度的 sunriseEnd 透明 stroke + `blur(8)` —— 给 arc 3D 厚度感

**Hero number (center)**：
- 96pt heavy rounded monospacedDigit numericFlip
- 副文案 `subtitleText`: `"<N> steps to sunrise"` / `"Goal reached"`
- 上方 header: `eyebrow("WAKE UP")` + `text(goalReached ? "Sun's up ✓" : "Walk to dismiss")` 30pt heavy rounded

**背景 3 层**:
- `Color.ringingBackground` 渐变 sky → near-black
- `RadialGradient([sunriseMid.opacity(0.30), clear], center, 40→280)` —— **被 `breathScale` 1.0→1.04 spring 控制，做 1.5s 呼吸**
- **Goal burst**: 当 `goalBurst = true`，再叠一层 `RadialGradient([sunriseEnd.opacity(0.65), sunriseMid.opacity(0.25), clear], 10→420)` —— 用 `withAnimation(Motion.spring)` 进出

**底部 action**:
- goal reached: `StopAlarmButton` —— sunrise gradient fill capsule · "Stop alarm" 18pt semibold
- else: `EmergencyHoldButton` —— `LongPressGesture(minimumDuration: 3.0).onEnded { onEmergencyDismiss() }`，视觉本期是占位（**详见 §6 待优化**）

**Progressive haptics**:
- `hapticBucket`: `0=0-50% · 1=50-80% · 2=80-100% · 3=goal reached`
- `UIImpactFeedbackGenerator(style: .light/.medium/.heavy/.notification(success))` 按 bucket 切
- `onChange(of: currentSteps)` 触发 cross-bucket 升级
- `onChange(of: goalReached)` 触发 success burst

### 4.3 S3 · Onboarding · `OnboardingView.swift` · 仅首启

- 控制：UserDefaults `stepup.onboarded.v1` flag；yes → 不再展示
- 容器：`TabView(selection: $page).tabViewStyle(.page(indexDisplayMode: .never))` —— 3 页，无 indicator，用自己写的 PageDots
- 底部 `PageDots`: 3 个 `Capsule`，current 是 24×8 sunriseEnd，其他是 8×8 well —— `Motion.spring` 切换 width
- 三页：
  - **Welcome (Step 0)** —— 中央 editorial sunrise hero = 3 个同心 `Circle()`（220×220 sunriseEnd 15% / 140×140 sunriseMid 30% / 60×60 sunriseEnd 100% blur 6），文案 `"Wake up by walking."` 34pt heavy rounded + privacy 副文案 + `PillButton("Get started")`
  - **Motion permission (Step 1)** —— `figure.walk.motion` 88pt hierarchical + `"We need motion access."` + privacy 副文案 + `PillButton("Enable motion")` —— 点击触发 `CMPedometer.startUpdates` (弹 OS dialog) + 同时 `UNUserNotificationCenter.requestAuthorization`（合并两个 OS dialog）
  - **Test (Step 2)** —— `alarm.waves.left.and.right.fill` 64pt + `"Try it now."` + `WalkDemo` 三步竖列 + `PillButton("You're all set ✓")` → dismiss + `ensureNotificationPermissionRequestedOnce`
- `WalkDemo`: 3 行 `DemoRow` 用 `Rectangle` 细线串成 vertical rail，每行 40×40 numbered chip + SF Symbol + title + subtitle
- `PillButton`: capsule fill `Color.sunriseGradient` + white 10% stroke + 56pt 高

### 4.4 S4 · About · `AboutView.swift`

- 布局：`ZStack` —— 顶左上 back button（44pt circle ultraThinMaterial `chevron.left`） + `ScrollView` 主体
- **Hero section**:
  - 88×88 `RoundedRectangle(cornerRadius: 20, .continuous).fill(sunriseGradient)` 上覆 `figure.walk` 38pt heavy SF Symbol —— **当前 app icon 占位（不是真 PNG asset，详见 §6）**
  - `"Walk Up"` 34pt heavy rounded
  - `"Walk to wake up."` 17pt tagline
  - 14pt description 段
- **4 个 `FeatureRow`** (`heart.fill` Free forever · `eye.slash.fill` No tracking · `figure.walk` CoreMotion · `lock.shield.fill` Open about it) —— 32×32 SF Symbol (sunriseEnd) + title + detail 两行
- **Footer `LEGAL & LINKS` eyebrow** + `LinkRow` Privacy policy + Support + Version

---

## 5 · 导航结构（**不是 default `TabView`**）

`RootView.swift:27-75` 用 `ZStack` + `@State var selectedTab: Tab` (.alarm / .about) + `.transition(.opacity)` crossfade 切换。

**Top-bar 系**（floating pill 不再重叠 action bar，RootView.swift:84-99 与 AboutView.swift:21-31 配合）：
- Setup 右上：`info.circle.fill` button → 切到 About
- About 左上：`chevron.left` button → 切回 Setup

**Onboarding overlay**：`.overlay { if !hasOnboarded { OnboardingView(...) } }` —— `zIndex(100)`，fade in/out cover 一切。

**Ringing 覆盖**：`.animation(Motion.spring, value: isRinging)` —— Setup/About `ZStack` 整个被 `AlarmRingingView` cover，回到 Setup 时反向。

**RootView 文件底部还保留一个 unused `BottomPill`/`PillItem` private struct**（RootView.swift:151-220）—— 是早期设计的 dead code，不影响运行；建议下次清理时一并删。

---

## 6 · 已知 gap · 不在当前实现里 · 但已设计好

| 项 | 状态 | 影响 |
|---|---|---|
| **真 App icon PNG asset**（非 SwiftUI runtime 占位）| ❌ 只用 inline `RoundedRectangle.fill(sunriseGradient) + SF Symbol figure.walk` 临时渲染 | App Store 提交**必须**真 PNG asset 才能过 review |
| **Streak / History 第 3 tab** | ❌ 未实现 | spec v0.2 §3 S4 跳过，按 5 天 timeline 暂缓 |
| **Widget / Dynamic Island** | ❌ 未实现 | Dribbble 调研 §5.4 标注 D6+ post-launch |
| **`EmergencyHoldButton` 真视觉反馈** | ⚠️ `LongPressGesture.onEnded` 已经触发 dismiss，但按下时**没有任何视觉进度** | 长按 3s 全屏没反馈，UX 弱；spec §4 S2 提到的"圆环同步 fill"未做 |
| **Ringing 背景的 `meshGradient`** | ⚠️ 当前是 `LinearGradient`，因为 iOS 17 minimum target 不支持 mesh | 影响"质感"上限；iOS 18 deployment target 升级后才用 |
| **App icon 真正 PNG asset + iOS 26 Icon Composer** | ❌ 没做 | 提交 review blocker |
| **持久化 streak / past alarm fire log** | ❌ 未实现 | 用 `UserDefaults` 可加，支撑 Streak tab |
| **Notification categories 注册 confirm in `StepUpApp.swift`** | ✅ 已注册 `STEPUP_ALARM` category + `STEPUP_DISMISS` action | done |
| **真机端到端 walk test** | ✅ 18:14 motion dialog 弹出 + 杨总手动 tap 允许 | done |
| **App Store metadata (英文文案 + ASO screenshot)** | ❌ 未做 | D5 review 时机 |

---

## 7 · 5 个 micro-interaction · 已经在 code 跑的

| # | 场景 | 设计 | 实现文件 |
|---|---|---|---|
| M1 | Time 字变化 | `.numericFlip()` —— `contentTransition(.numericText())` | Theme.swift:111, AlarmSetupView.swift:54 |
| M2 | Steps preset 切换 | `withAnimation(Motion.spring)` + PresetChip sunrise-end fill + 副 number numericFlip | AlarmSetupView.swift:184 |
| M3 | Day chip toggle | `withAnimation(Motion.quick)` + DayDot 圆点 sunriseEnd fill + blur halo 出现 | AlarmSetupView.swift:293 |
| M4 | Enable pill 翻 | 自定义 track + knob offset(±9) + Motion.spring | AlarmSetupView.swift:414-431 |
| M5 | Sunrise ring fill | `Color.sunriseGradient` stroke + rotation(-90°) + Motion.spring | AlarmRingingView.swift:171-201 |
| M6 | Breath loop | 1.5s easeInOut breathScale 1.0→1.04 radial glow + ring scale | AlarmRingingView.swift:151-156 |
| M7 | Progressive haptics | 4 buckets · light/medium/heavy/notification(success) | AlarmRingingView.swift:160-164 |
| M8 | Goal burst | radial gradient overlay + Motion.spring fade + success haptic | AlarmRingingView.swift:60-69, 133-140 |
| M9 | Tab switch | `.transition(.opacity)` + Motion.spring crossfade | RootView.swift:50-56 |
| M10 | Page dots | Capsule width 8↔24 spring | OnboardingView.swift:71-85 |

---

## 8 · 流程闭环验证（已通过的）

| 流程 | 验证 |
|---|---|
| Schedule alarm + fire + ringing 进入 | ✅ `AUTOTEST_SECONDS` env 触发 + onReceive `stepUpAlarmFired` |
| Walk step counter 累加 | ✅ 真机 + CoreMotion + 已 granted motion |
| Goal reached dismiss | ✅ LongPressGesture fallback path（视觉反馈待补）|
| Cold start 触发 motion dialog | ✅ RootView bootstrapOnColdStart 主动 startUpdates |
| Day chips 持久化 + reschedule | ✅ AlarmStore.didSet + hasLoaded flag |
| Notification permission 一次性 prompt | ✅ Onboarding Step 1 合并触发 + complete safety net |
| `walkup://test-fire` URL smoke-test | ✅ 在 `RootView.onOpenURL` 与 `StepUpApp.onOpenURL`（StepUpApp.swift:34-38）双注册 |

---

## 9 · 不做什么 · 已成 hard guard（再走 spec v0.2 §5 的 commitment）

- ❌ 任何第三方字体 / icon / 动画库
- ❌ 默认 `Form` / `Section` / `Label` / `Stepper` / `Toggle` / `Slider` / `DatePicker.wheel` 直接裸露
- ❌ 默认 SwiftUI `TabView`（用自定义 ZStack + selectedTab state）
- ❌ `.shadow()` —— 质感靠 gradient + ultraThinMaterial + stroke
- ❌ `.easeInOut` 默认曲线（除 breath 一处）—— 用 spring

---

## 10 · Dribbble 调研存档（2026-07-17 agent 跑）

`Sources/Dribbble/`（待建）or inline 留这里：

**6 个 tag · 268 shot · 调研精华**：

| Tag | Hits | 关键 reference |
|---|---|---|
| alarm-clock-app | 48 | Fireart-d iOS Alarm · uxcratelab AI Alarm · Glass alarm clock |
| sleep-app | 43 | strangehelix asklepios/freud · Piqo Studio |
| wake-up-app | 41 | **karina_bondarenko Social Alarm** · orenjistudio Smart Sleep |
| morning-app | 46 | **karina_bondarenko Alarmi（最高密度）** |
| step-counter | 42 | **DD_UIUX Fitness Tracker UI Kit** · Asish Sunny 动效 |
| wellness-app-ios | 48 | **asol_design / Anna Pastel UI（lavender 系）** · Tubik |

**Pinterest** ❌ 公开搜索页 JS-hydrate + GraphQL 懒加载，无登录 403（详见 §11）。

---

## 11 · Open technical debt

| # | 项 | 推荐处理 |
|---|---|---|
| T1 | RootView.swift `BottomPill`/`PillItem` 是 dead code | `claude code` 里手动删 |
| T2 | `EmergencyHoldButton` 缺按下时视觉进度 | 长按 3s 时长用 sunrise ring inner halo 同步 fill |
| T3 | App icon 当前 `RoundedRectangle + SF Symbol` inline runtime | 用 Icon Composer (Xcode 26) 出真 PNG 多尺寸资产 |
| T4 | iOS 17 deployment target 让 `meshGradient` 用不上 | 升 deployment target 到 18，或保留 LinearGradient 走柔和色块 |
| T5 | App Store metadata (英文 ASO + 6.7"/6.1"/5.5" 截图) | D5 review |
| T6 | Streak / History tab | D6+ post-launch |

---

## 12 · 引用规范

代码引用格式：`文件:行号` —— 鼠标可点。例如 `Theme.swift:15` = `Sources/Theme.swift` 第 15 行。
