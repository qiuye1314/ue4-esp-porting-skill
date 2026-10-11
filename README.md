# UE4 透视+自瞄逆向移植 Skill — FPS2 实战定版（v18 方法论沉淀）

> **Android UE4/UE5 手游 · 内存透视自瞄移植 · 零偏移表自助考古 · DSH 标准 skill**
>
> 基于 PUBGM「纯C ImGui+Vulkan 根覆盖层」模板，实战移植到 **枪战特训2（com.ShuiSha.FPS2）**，
> 18 轮真机迭代（v1→v18）全部踩坑记录在案。本包不含二进制外挂，**交付的是方法**：
> 拿到任何一款没有偏移表的新 UE4 手游，按此流程一步步挖出可用数据。

---

## 🎯 这个 skill 解决什么

| 移植常见死结 | 本定版答案 |
|---------|---------|
| 新游戏没有任何现成偏移表 | 「结构合理性+行为一致性」双验证考古法（四元数模∈[0.85,1.25]、scale∈[0.05,4]、平移 vs rootPos 逐轴<400） |
| 骨骼缓存数组恒空（0x740/0x750/0x758 num=0） | 几何伪骨骼：框内按比例画头/肩/脊柱/四肢，**任何距离形态一致**，永久方案不是过渡 |
| 掩体判定"近处必红、远处必绿" | 射线起点前移 60 破相机自穿 + 终点 45 贴身缓冲破目标自挡 + **头/胸/裆分部位滞回**——漏哪红哪 |
| 自瞄抖动、重叠敌人来回乒乓 | 24px 死区 + 世界坐标锁定滞回（新靶优势<45%不换人）+ 单帧位移钳制 |
| 颜色与自瞄各判各的（"变色了却打不了/没变色乱打"） | 判定与绘制共用同一份部位滞回账本，**同色同权** |
| 远程调参全靠猜 | 调试报告字段读法：DrawIo 位串/相机/Aim表/ray三值，每个现象都能定位到一行数据 |

---

## 📌 内容总览

```
你（或任何读它的 AI）
   │ 调用 ue4-esp-porting-mobile skill
   ▼
SKILL.md（七步移植 checklist + 每偏移挖法）
   │
   ├─ references/battle_log.md    v1→v18 版本血泪史：每版改动→用户现象→结论
   ├─ references/report_format.md 调试报告逐字段读法
   └─ scripts-install.sh          一键挂载进 DSH
```

### 关键实测数据（FPS2）
- **C2W = Mesh+0x1C0**（0x1A0 是局部偏移变换 t=(0,-90,0)，候选顺序即判据顺序）
- 队伍字节 pawn+0x4C8（0=己方）；类前缀 BP_AI_Pawn_A/B/C
- Embree 三场景：dyn=61（角色+活动掩体，不可去）/ st=52（建筑）/ hf=0
- HoldingFire+0x632 恒 0（废案）；开镜不改 Fov（FOV 法开镜自瞄在 FPS2 不可用）

---

## ✅ 真机验证

| 游戏 | 包名 | ESP | 分部位掩体 | 连续自瞄 |
|------|------|-----|-----------|---------|
| 枪战特训2 | `com.ShuiSha.FPS2` | ✅ 框/骨骼/射线/血量 | ✅ 漏哪红哪，远近同判据 | ✅ 无抖无闪（定版 v18） |

---

## 🛠 安装（DSH 手机端）

```bash
git clone https://github.com/qiuye1314/ue4-esp-porting-skill
cd ue4-esp-porting-skill && sh scripts-install.sh
# 下次会话 DSH skill 目录即出现 ue4-esp-porting-mobile
```

其他环境：整目录放进 `/.dsh/skills/ue4-esp-porting-mobile/` 即可（frontmatter 已含 name/description/whenToUse）。

---

## 📄 License

模板与逆向方法仅供学习研究；内存结构偏移均为特定游戏版本实测值，改版即失效，按第二章方法论重挖。
