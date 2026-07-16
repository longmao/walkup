# Walk Up · v0.3 Rollback Plan

> **触发**：任一闸不过 / 7-day gate ≤3/8 / App Review 拒 2 次 / 杨总叫停
> **原则**：分阶段清 · 凭证先删 · 主账户切回 · 不留 PII
> **回滚 = 反向施工**：按 D1→D16 倒序 · 每阶段验证"账户/项目/资源清空"

---

## 阶段 1 · Apple Developer Program 退订（最早可回）

1. ASC → **Membership** → **Cancel Subscription** → 选原因 → 确认
2. 当年剩余不退 · $99/yr 不退 · 失效日 = 当前周期末
3. **删 Account**（彻底）：developer.apple.com → Account → **Request Account Closure**（不可逆）
4. 清 Team ID 文件：`rm ~/.config/walkup/team_id`
5. ✅ 验证：`developer.apple.com` 登录后 Membership 显示 *Inactive*

## 阶段 2 · Cloud Build 清资源

1. **删 Workflow**：Xcode → Report navigator → Cloud → 选 `WalkUp - Main` → **Delete Workflow**
2. **撤 GitHub App 授权**：github.com/settings/installations → Xcode Cloud App → **Uninstall**（org/repo 双层）
3. **删 Xcode Cloud Project**（如自建）：ASC → Settings → Xcode Cloud → 选 project → Delete
4. 清本地 Xcode Cloud cache：`rm -rf ~/Library/Caches/com.apple.dt.Xcode/CloudBuilds/`
5. ✅ 验证：ASC → Xcode Cloud tab 无 WalkUp workflow · GitHub installations 无 Xcode Cloud

## 阶段 3 · TestFlight 清 build + group + tester

1. **撤 internal tester**：ASC → TestFlight → Internal → 选 `Core Team` → 删 longmaodashu@gmail.com + 其他
2. **删 internal group**：ASC → TestFlight → Internal → 删 `Core Team`
3. **撤 external tester**：ASC → TestFlight → External → 选 `Beta Users` → 批量删 tester（100+）
4. **删 external group**：ASC → TestFlight → External → 删 `Beta Users`
5. **删所有 build**：ASC → TestFlight → Builds → 选 build → **Expire Build**（立即过期 · 不能真删但禁用）
6. ✅ 验证：ASC → TestFlight tab 无 active group + 无可用 build

## 阶段 4 · Distribute 撤 App Store 上架

1. **删 in-review build**：ASC → WalkUp → App Store tab → 选 in-review version → **Remove from Review**
2. **下架已上架 app**：ASC → WalkUp → App Store → Pricing and Availability → **Make App Unavailable**（立即生效 · 已下载用户保留但不再分发）
3. **删 metadata 草稿**：ASC → WalkUp → App Information → 清 name/subtitle/description/screenshots
4. **删 App 元数据**：ASC → My Apps → 选 WalkUp → **Archive App**（保留 30 天可恢复 · 30 天后自动删）
5. ✅ 验证：App Store 搜 "Walk Up" 无结果 · ASC → Archived Apps 仅 30 天可见

## 通用 · 清凭证 + 资源 + 主账户

1. **清 .p8 凭证**：
   ```bash
   shred -u ~/Library/Application\ Support/WalkUp/credentials/AuthKey_*.p8 2>/dev/null || \
   rm ~/Library/Application\ Support/WalkUp/credentials/AuthKey_*.p8
   rm -rf ~/Library/Application\ Support/WalkUp/
   ```
2. **清 ASC API env**：`rm ~/.config/walkup/asc.env`
3. **撤 GitHub Pages**（Privacy Policy）：gh repo → Settings → Pages → Source = None
4. **主账户切回 longmaodashu@gmail.com**：ASC 改 primary email（撤回操作期间若临时切到其他邮箱）
5. **清本地 build artifact**：`rm -rf ~/Developer/WalkUp/build/` · `xcodegen` 不动（项目保留可重建）
6. **清 cron/launchd**（若有）：`launchctl unload ~/Library/LaunchAgents/com.walkup.*.plist`
7. ✅ 验证：`find ~/Library/Application\ Support/WalkUp -type f` 空 · `grep -r "ASC_KEY_ID" ~/.config/walkup/` 空

---

**回滚总耗时**：阶段 1 = 5min · 阶段 2 = 5min · 阶段 3 = 15min · 阶段 4 = 24h（Apple 审核删除）· 通用 = 10min
**不可逆节点**：阶段 1 #3（Request Account Closure）+ 阶段 4 #4（30 天后自动删 archive）
**PII 检查**：回滚完 grep `longmaodashu` + `WalkUp` + `StepUp` 整仓 + ASC + GitHub 无残留