#!/usr/bin/env bash
# build_subs.sh
# 从固定优选 IP 列表和在线资源生成订阅文件

set -euo pipefail
IFS=$'\n\t'

OUT_DIR="${PWD}/subs_output"
mkdir -p "$OUT_DIR"
RAW_IPS="$OUT_DIR/raw_ips.txt"
SUB_FILE="$OUT_DIR/subs.txt"
SUB_B64="$OUT_DIR/subs_b64.txt"

# 1. 固定优选 IP 列表（手动维护）
cat > "$RAW_IPS" <<'EOF'
106.244.201.248:50000#韩国 首尔
66.98.121.132:8443#美国 洛杉矶
146.0.79.50:443#荷兰 阿姆斯特丹
46.226.167.205:8443#德国 法兰克福
144.168.56.119:40864#美国 洛杉矶
142.171.147.201:20274#美国 洛杉矶
109.120.189.103:1488#俄罗斯 莫斯科
138.2.89.64:32962#新加坡 新加坡
# ... 这里可以继续追加你发的所有 IP 列表 ...
EOF

# 2. 抓取 wetest.vip 提供的 Cloudflare 优选 IP（IPv6 / IPv4）
echo "[*] 抓取 Cloudflare 优选 IP..."
curl -fsSL "https://www.wetest.vip/page/cloudflare/address_v6.html" \
  | grep -Eo '([0-9a-fA-F:.]+):[0-9]+' >> "$RAW_IPS" || true
curl -fsSL "https://www.wetest.vip/page/cloudflare/address_v4.html" \
  | grep -Eo '([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):[0-9]+' >> "$RAW_IPS" || true

# 3. 去重
sort -u "$RAW_IPS" -o "$RAW_IPS"

# 4. 转换成订阅链接
# 这里我用 VLESS 模板（因为简单，不需要 base64 JSON）
# 格式：vless://UUID@IP:PORT?encryption=none&security=none#备注
UUID="11111111-2222-3333-4444-555555555555"   # 你需要替换成自己的 UUID

> "$SUB_FILE"
while read -r line; do
  ipport=$(echo "$line" | cut -d'#' -f1)
  tag=$(echo "$line" | cut -d'#' -f2-)
  [ -z "$ipport" ] && continue
  echo "vless://${UUID}@${ipport}?encryption=none&security=none#${tag}" >> "$SUB_FILE"
done < "$RAW_IPS"

# 5. 生成 base64 单行订阅
if base64 --help 2>&1 | grep -q -- '-w'; then
  base64 -w0 "$SUB_FILE" > "$SUB_B64"
else
  base64 "$SUB_FILE" | tr -d '\n' > "$SUB_B64"
fi

echo "[*] 完成 ✅"
echo "多行订阅文件: $SUB_FILE"
echo "单行 base64 订阅: $SUB_B64"
