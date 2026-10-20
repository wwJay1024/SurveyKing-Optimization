#!/usr/bin/env bash
# 服务器端同步：拉代码 → 构建 →（可选）部署。
#
# 默认只构建，不碰线上服务。要真正替换 jar 并重启，必须显式加 --deploy，
# 因为重启会让容器中断十几秒，有人在答题时会受影响。
#
# 用法：
#   bash tools/deploy-server.sh            只拉代码并构建，产物在 dist/
#   bash tools/deploy-server.sh --deploy   构建后替换 jar 并重启容器
#
# 可用环境变量覆盖：
#   SKO_HOME    仓库目录，默认 /opt/sko
#   JDK_HOME    JDK 目录，默认自动探测
#   LOMBOK_JAR  lombok.jar 路径
#   BASE_JAR    官方原版 jar 路径
#   CONTAINER   容器名，默认 surveyking
#   PORT        端口，默认 1991
set -euo pipefail

APP_DIR=${SKO_HOME:-/opt/sko}
LOMBOK=${LOMBOK_JAR:-$APP_DIR/.toolchain/lombok.jar}
BASE=${BASE_JAR:-$APP_DIR/.toolchain/surveyking-v1.13.2.jar}
NAME=${CONTAINER:-surveyking}
PORT=${PORT:-1991}
BAK_DIR=/var/backups/surveyking-role-repo

DEPLOY=no
for arg in "$@"; do
  case "$arg" in
    --deploy) DEPLOY=yes ;;
    *) echo "未知参数：$arg" >&2; exit 2 ;;
  esac
done

cd "$APP_DIR"

echo "== 1/3 拉取最新代码 =="
if ! git pull --ff-only; then
  echo "" >&2
  echo "拉取失败，检查 $APP_DIR 是否为 wwJay1024/SurveyKing-Optimization 的检出：" >&2
  echo "  git remote -v" >&2
  echo "  git status" >&2
  exit 1
fi
REV=$(git rev-parse --short HEAD)
SUBJECT=$(git log -1 --pretty=%s)
echo "   $REV $SUBJECT"

echo "== 2/3 构建 =="
mkdir -p dist
BUILD_ARGS=(--base "$BASE" --out "$APP_DIR/dist/surveyking.jar" --lombok "$LOMBOK")
if [ -n "${JDK_HOME:-}" ]; then
  BUILD_ARGS+=(--jdk "$JDK_HOME")
fi
python3 tools/build-injected-jar.py "${BUILD_ARGS[@]}"

echo "== 3/3 部署 =="
if [ "$DEPLOY" != "yes" ]; then
  echo "   已跳过。产物在 $APP_DIR/dist/surveyking.jar"
  echo "   确认当前无人答题后，加 --deploy 重新执行才会替换并重启容器。"
  exit 0
fi

sudo mkdir -p "$BAK_DIR"
STAMP=$(date +%Y%m%d-%H%M%S)
sudo docker cp "$NAME:/app/surveyking.jar" "$BAK_DIR/surveyking.jar.$STAMP" >/dev/null
echo "   已备份：$BAK_DIR/surveyking.jar.$STAMP"

sudo docker cp "$APP_DIR/dist/surveyking.jar" "$NAME:/app/surveyking.jar"
sudo docker restart "$NAME" >/dev/null
for i in $(seq 1 40); do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 "http://127.0.0.1:$PORT/home" || true)
  if [ "$code" = "200" ]; then
    echo "   容器已就绪（$((i * 2))s）"
    break
  fi
  sleep 2
done

for p in "/home" "/role-repo" "/system/role"; do
  printf '   %-14s %s\n' "$p" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "http://127.0.0.1:$PORT$p")"
done
sudo docker ps --filter "name=$NAME" --format '   {{.Names}} {{.Status}}'

echo "$REV $SUBJECT $(date '+%Y-%m-%d %H:%M:%S')" > "$APP_DIR/dist/DEPLOYED"
echo
echo "部署完成：$REV"
echo "回滚：sudo docker cp $BAK_DIR/surveyking.jar.$STAMP $NAME:/app/surveyking.jar && sudo docker restart $NAME"
