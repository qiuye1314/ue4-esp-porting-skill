# UE4 透视+自瞄逆向移植 Skill — FPS2 实战定版（v18 方法论沉淀）

> **Android UE4/UE5 手游 · 内存透视自瞄移植 · dump 直供 8 项输入 + 零偏移考古兜底 · DSH 标准 skill**
>
> 基于 PUBGM「纯C ImGui+Vulkan 根覆盖层」模板，实战移植到 **枪战特训2（com.ShuiSha.FPS2）**，
> 18 轮真机迭代（v1→v18）全部踩坑记录在案。本包不含二进制外挂，**交付的是方法**：
> 拿到任何一款新的 UE4 手游，按此流程从数据到成品一步步落地。

---

## 🎯 你需要准备什么（唯一前置，双来源二选一）

目标游戏的 8 项关键数据，**两条路都能凑齐**：

- **路 A · dump 直供（推荐，10 分钟）**：用 UE4Dump-MCP-Enhance 对目标跑一次 dump，下表 8 项直接齐活——FPS2 当时就是这么喂进来的。
- **路 B · 零偏移考古（兜底，工具跑不动/项目改版时）**：一项数据都没有也能起步——本 skill 第二、三章给出每一项的自挖方法与验证判据，缺哪项挖哪项。

| # | 数据 | 用途 | 没有时怎么挖 |
|---|------|------|------|
| 1 | GNames（FNamePool 基址/偏移） | 解类名 → 过滤敌人 | SKILL.md §二 特征码/池结构判据 |
| 2 | GWorld（UWorld 基址/偏移） | 数据链根 | 同上，对象数组反查 |
| 3 | GUObjectArray（对象数组） | 类字典/对象验证 | 多对象连续验证法 |
| 4 | PersistentLevel → Actors 链 | 枚举全场 Actor | dump 结构对照，数量级 300~900 验证 |
| 5 | 敌人类名前缀（如 BP_AI_Pawn_*） | 目标过滤+队伍规律 | GNames 里 grep Pawn/Character |
| 6 | Pawn→RootComponent→Mesh→位置链 | 世界坐标来源 | 候选偏移+四元数/scale/平移三判据 |
| 7 | 相机 ViewMatrix[16] + Fov | WorldToScreen | 转身/移动逐帧方向验证 |
| 8 | Embree/物理场景根（st/dyn/hf） | 掩体漏打判定 | FPhysxSceneManager 链，先 st 后 dyn 分步验证 |

---

## 🎯 这个 skill 解决什么

| 移植常见死结 | 本定版答案 |
|---------|---------|
| 只有新游戏，dump 缺项/偏移改版失效 | 「结构合理性+行为一致性」双验证考古法（四元数模∈[0.85,1.25]、scale∈[0.05,4]、平移 vs rootPos 逐轴<400），逐项补齐 |
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
SKILL.md（输入清单 + 七步移植 checklist + 每偏移挖法）
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

其他环境：整目录放进 `~/.dsh/skills/ue4-esp-porting-mobile/` 即可（frontmatter 已含 name/description/whenToUse）。

---

## 📄 License

**GPL-3.0** — 修改必须开源回馈

- 基于 PUBGM 纯C ImGui+Vulkan 模板体系与 com.ShuiSha.FPS2 实战（v1→v18）
- 作者：**e7**
- 内存结构偏移均为特定游戏版本实测值，改版即失效，按第三章方法论重挖
