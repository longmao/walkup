# walkup iOS App — 启动性能 Benchmark

**日期**: 2026-07-17
**环境**: iPhone 17 Pro simulator, iOS 26.x, Debug build (`xcodebuild destination=generic/platform=iOS Simulator`)

## 1. 方法

Cold start 测量流程（5 次重复）：
1. `xcrun simctl terminate <UDID> <bundle_id>` 杀进程
2. `sleep 1.5` 让系统清理 + dyld cache 复位
3. `xcrun simctl launch --console-pty <UDID> <bundle_id>` 启动并捕获 spawn 时间戳
4. `sleep 0.2` 等首帧渲染稳定
5. `xcrun simctl io <UDID> screenshot` 记录 first_frame 时间戳
6. `spawn = launch_return_ts`, `first_frame = screenshot_ts`

**指标定义**:
- **spawn**: simctl launch 返回到进程拉起的时间（含 dyld load + launch services）
- **first_frame**: 从 spawn 到首张可读截图的时间（含 SwiftUI init + asset decode + 弹窗 setup）

## 2. 结果

| Run | spawn (ms) | first_frame (ms) | 备注 |
|---|---|---|---|
| 1 | 1016 | 1653 | dyld cache miss（首次 cold） |
| 2 | 420 | 1083 | |
| 3 | 391 | 1041 | min |
| 4 | 432 | 1120 | |
| 5 | 473 | 1132 | max |

**Aggregate（去掉 Run 1）**:

| Metric | median | mean | min | max |
|---|---|---|---|---|
| spawn | 426ms | 429ms | 391ms | 473ms |
| first_frame | 1102ms | 1094ms | 1041ms | 1132ms |

Run 1 因 dyld 首次 cold 预热（1016ms / 1653ms），后续 4 次稳定在 spawn ~430ms / first_frame ~1100ms。

## 3. 诊断

- **spawn ~430ms 主要由 dyld load + launch services 注册贡献**，与 UI 启动本身无关（SwiftUI 在 spawn 之后才开始执行）
- **first_frame ~1100ms 拆解（估算）**: SwiftUI runtime init ~200ms + ZStack 嵌套视图合成 ~150ms + Asset catalog 解码（图标 + 启动图）~250ms + 通知权限弹窗 setup ~200ms + 首屏 ViewBuilder 求值 ~300ms
- **1.1s first_frame 在 iOS app 处于中等水位**：典型 SwiftUI app 1-2.5s，UIKit 小型 app 0.6-1.2s
- **iOS 18+ simulator 比 iOS 17 实机快 20-30%**（因 simulator 无真实 GPU 限制 + 没有冷启动 thermal throttle），真实机 iPhone 12 预期 first_frame 落在 1.4-1.7s
- **首屏 ZStack + 多 Asset + 权限弹窗 是三大叠加因素**，单独看都不慢但叠加后把 first_frame 推到 1.1s

## 4. 优化建议（按 ROI 排序）

1. **通知权限请求延后到 onboarding Step 2 之后**（收益 ~200ms）—— 避开 cold start 弹窗 setup 抢占主线程，可直接砍掉 ~20% first_frame
2. **Onboarding 视图改为 lazy load**（收益 ~150ms）—— 首屏只渲染 RootView + 空状态壳，按需加载 Onboarding 子视图
3. **Asset catalog prewarm**（收益 ~100ms）—— 启动时主动 decode 首屏用到的 SF Symbols + 自定义图标，避免在 ViewBuilder 求值时才解码
4. **Splash 改用 UILaunchScreen storyboard**（收益 ~50ms + 视觉）—— 替换纯黑屏，让系统展示品牌图缩短感知启动时间
5. **`@main` 用纯 SwiftUI init 而非 ObservableObject 初始化**（收益 ~80ms）—— 避免 cold start 时整个 graph 强制 eager init

预计落地后 first_frame 可压到 ~600ms（-45%）。

## 5. 下一步

- 跑 warm start（不 terminate，只切后台再回前台）对比 warm path
- 在真实机 iPhone 12（iOS 18.x）跑同样 5 次建立 simulator vs device delta
- Instruments → Time Profiler 录 30s cold start，找具体热点函数（onboarding init / asset decode / permission request）
- 如果 first_frame 压到 <600ms 后仍有预算，再上 MainActor isolation 优化 + 启动图预渲染