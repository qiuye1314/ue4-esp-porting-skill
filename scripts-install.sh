#!/system/bin/sh
# 一键安装本 skill 到 DSH：把解压目录内容挂到 /root/.dsh/skills/ue4-esp-porting-mobile
set -e
D=/root/.dsh/skills/ue4-esp-porting-mobile
mkdir -p "$D/references"
cp SKILL.md "$D/"
cp references/*.md "$D/references/"
echo "已安装: $D —— 下次会话 DSH skill 目录即可见 ue4-esp-porting-mobile"
