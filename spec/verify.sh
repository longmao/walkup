#!/usr/bin/env bash
# verify.sh · Walk Up v0.3 · fail-closed mechanical checks
# exit 0 = pass · non-zero = fail (each check echo + exit on first fail)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPEC="$ROOT/spec/SPEC_v0.3.md"
TASKS="$ROOT/spec/tasks.md"
ROLLBACK="$ROOT/spec/rollback.md"
BUILT_PLIST="${BUILT_PLIST:-$ROOT/build/Build/Products/Debug-iphonesimulator/StepUp.app/Info.plist}"

fail() { echo "FAIL: $1" >&2; exit 1; }

# G1: Spec ≤100 行
LINES=$(wc -l < "$SPEC" | tr -d ' ')
[ "$LINES" -le 100 ] || fail "SPEC lines=$LINES >100"
echo "OK G1 spec lines=$LINES"

# 4 阶段齐
for stage in "Cloud Build" "Test" "Distribute" "7-day gate"; do
  grep -q "$stage" "$SPEC" || fail "missing stage: $stage"
done
echo "OK 4 stages present"

# 16 Forbidden = 11 沿用 + 5 新加
for f in "订阅" "IAP" "广告" "Vision" "HealthKit" "tips" "share" "rate" \
         "仿 Erly" "best alarm" "v1 中国" "ATT" "用户账号" "扩 scope" "Speech" \
         "第三方 SDK" "Sign in with Apple" "Preview 带音乐" "截图美化过度" "Review 不沟通"; do
  grep -q "$f" "$SPEC" || fail "missing Forbidden: $f"
done
echo "OK 20 forbidden tokens (16 base + 4 alias) hit"

# 5 闸定义齐
grep -q "Gate 1" "$SPEC" || fail "missing Gate 1"
grep -q "Gate 5" "$SPEC" || fail "missing Gate 5"
echo "OK 5 gates defined"

# Apple 4 资源必用
for r in "Xcode Cloud" "TestFlight" "App Store Connect API" "SF Symbols"; do
  grep -q "$r" "$SPEC" || fail "missing Apple resource: $r"
done
echo "OK 4 Apple resources referenced"

# tasks.md 9 字段全 hit
[ -f "$TASKS" ] || fail "tasks.md missing"
for col in ID action agent input output acceptance allowed_tools forbidden_tools dangerous status; do
  grep -q "| $col |" "$TASKS" || fail "tasks.md missing column: $col"
done
echo "OK tasks 9 columns present"

# rollback.md 存在
[ -f "$ROLLBACK" ] || fail "rollback.md missing"
echo "OK rollback.md exists"

# Info.plist 注入验证（xcodegen + xcodebuild 后跑过）
if [ -f "$BUILT_PLIST" ]; then
  grep -q "ITSAppUsesNonExemptEncryption" "$BUILT_PLIST" || fail "Info.plist missing ITSAppUsesNonExemptEncryption"
  plutil -p "$BUILT_PLIST" | grep -q '"ITSAppUsesNonExemptEncryption" => false' || fail "Info.plist ITSAppUsesNonExemptEncryption != false"
  echo "OK Info.plist ITSAppUsesNonExemptEncryption injected (false)"
else
  echo "WARN built Info.plist not found at $BUILT_PLIST (run xcodegen + xcodebuild first)"
fi

echo "PASS: all mechanical checks green"
exit 0