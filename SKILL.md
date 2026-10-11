---
name: ue4-esp-porting-mobile
description: UE4 手游透视+自瞄逆向移植（FPS2 实战定版 v18）：在没有现成偏移表的游戏上，从成熟模板考古 GNames/C2W/骨骼/队伍字节/Embree 三场景并移植成 root 覆盖层 APK/shell 工程的完整方法论。当用户要「反采某款 UE4 游戏」「把这个透视模板移植到新游戏」「找 C2W/骨骼偏移」「掩体漏打判定」或提到 com.ShuiSha.FPS2、枪战特训、UE4Dump、process_vm_readv 透视时使用。
whenToUse: 用户要在新的 UE4/UE5 手游上做透视自瞄移植、要解释/复现某个偏移是怎么挖出来的、要调掩体可见性或自瞄防抖参数、或索要/修改 FPS2透视 工程时。
metadata:
  version: 1.0.0
  author: 富江
  upstream: PUBGM 纯C ImGui+Vulkan 模板 + com.ShuiSha.FPS2 实战 v1-v18
  dshHome: /root/.dsh/skills/ue4-esp-porting-mobile
  artifacts: /sdcard/Download/FPS2透视_start.sh /sdcard/Download/FPS2透视_AIDE.zip
---

# UE4 手游透视+自瞄逆向移植技能（FPS2 实战定版）

> 目标读者：需要在**没有现成偏移表**的 UE4 手游（本例 com.ShuiSha.FPS2 枪战特训2）上，
> 把一个成熟模板（PUBGM 纯C ImGui+Vulkan 根覆盖层）移植成可用 ESP/自瞄的 AI 或开发者。
> 工程本体：/sdcard/Download/FPS2透视_AIDE.zip（v18 定版），构建脚本 /tmp/w/out/build_fps2.sh。

## 一、总体架构（定版）
1. **root 覆盖层进程**（独立 exe，不注入游戏）：
   - 读内存：process_vm_readv（封装为 SysHal driver->read<T>()）
   - 绘制：ImGui+Vulkan 全屏透明窗口（FLAG_NOT_TOUCHABLE，触摸穿透给游戏）
   - 自瞄：uinput 虚拟触摸（TouchHelperA）拖拽"锚点"模拟视角滑动
2. **数据链**：GWorld → GameStage → ULevel → Actors[] → 类名过滤 BP_AI_Pawn_* → 逐 pawn 取
   Mesh(RootComponent+0xD0 常见) → C2W(Transform) 得世界坐标 → W2S(视图矩阵×FOV) 出屏幕框。

## 二、偏移考古总原则（没数据怎么找数据）
每个偏移用"**结构合理性 + 行为一致性**"双验证，宁试百次不吃一个坏值：
- 浮点三件套：位置=3×float 且量级∈[1e2,1e6]、四元数=4×float 且模∈[0.85,1.25]、
  缩放=3×float 且每分量∈[0.05,4]。
- **对照已知量**：候选平移 vs rootPos 逐轴差<400（UE4 mesh 世界位置≈root 位置±半步长），
  绝不能拿 |t| 绝对值当判据（v8 教训：把真 C2W 毙了）。
- 指针类偏移：候选+0x8 应仍是合法 UObject 地址（同 so 段区间），解引用名字能在 GNames 对上。
- **一次只动一个变量**：改一处→导出调试报告→比对屏幕现象。全案报告见 FPS2_debug.txt 格式(references/report_format.md)。

## 三、关键偏移与挖法（FPS2 实测值）
| 数据 | FPS2 偏移 | 挖法/验证 |
|---|---|---|
| GNames/GWorld | 模板基址+游戏常量 | UE4Dump 类工具 dump 类名单，或直接对比 PUBGM 特征码 |
| GameStage(持久关卡) | UWorld+0x30→+0x80 链 | dump 里找 PersistentLevel |
| Actor数组 | ULevel+0xA8 (ActorCount+0xB0) | 数量对局内 300~900，越界即结构错 |
| pawn类名 | ClassPrivate→NamePrivate 前缀 BP_AI_Pawn_ | 名单里 A/B/C=阵营后缀，逐队验证 |
| 队伍字节 | pawn+0x4C8 (0=己方) | 观战队友同值、敌人异值即成立 |
| Mesh组件 | pawn+0xD0 | +0x190 出 root 位置(量级对) |
| **C2W** | **Mesh+0x1C0** | 四元数模1 + scale 全1 + 平移与 rootPos 逐轴<400；候选表 {0x1C0,0x1A0,...}，0x1A0 是局部偏移变换(t=(0,-90,0)) 会过判据里的"四元数"但过不了"平移对rootPos"——这就是先测 0x1C0 排前的原因 |
| 骨骼缓存数组 | Mesh+0x740/0x750/0x758 | **FPS2 恒为 data=0,num=0**（游戏不用组件序列化骨骼缓存）→ 放弃真骨骼，见「几何伪骨骼」 |
| 相机 | GameClient+...→ViewMatrix[16]+Fov@+0x184 | 移动/转身逐帧比对 dump 值方向一致性 |
| Embree 场景 | FPhysxSceneManager→st/dyn/hf 三根 | 见掩体章节 |
| 持枪开火标志 | pawn+0x632 (HoldingFire) | FPS2 恒 0，**废案**，改 evdev 触点判开火(后定版也不用) |

## 四、几何伪骨骼（骨骼数组空的定版方案）
真骨骼不可得时，在 2D 框内按比例画人形：头顶圆(0.13W)、颈、肩线、脊柱、髋线、
双臂(肩→肘→手 垂 0.35H/0.55H)、双腿(髋→膝→脚 0.5/1.0)。
坐标全由框 TOP/BOTTOM/LEFT/RIGHT 线性组合而来——**任何距离形态一致**，用户不再抱怨"没骨骼"。

## 五、掩体判定（三轮翻车后定版）
判据函数：LineTrace(相机→部位点)：
- 起点沿视线**前移 60**（越过自己胶囊/武器，破"相机贴墙判全挡"）
- 终点只留 **max(45, 2%len)** 缓冲（FPS2 敌人刚体混在 DynamicRigid 场景里，
  不打这层会"静止敌人永远判挡、移动才红"——v5-v7 血案）
- len<110 直接判可见（贴脸物理上不可能被挡）
- 三场景 DynamicLoad/HeightField/DynamicRigid **命中即挡**
分部位：头(+0.9H)/胸(+0.25H)/裆(-0.45H) 三条独立射线，**各自帧间滞回**
（计账 c+=挡?1:-2，钳[-6,10]，c>=6 判该部位被挡）→ 漏哪红哪、全露全红、全挡才整灰绿；
滞回同时喂自瞄（Blocked=三部位全挡），**颜色与自瞄永远同一口径**（用户红线：漏打=变色）。
**禁止**用距离百分比大窗口(12%/5%)或对称 startZone——会把近/远两端判反（v16/v17 定案）。

## 六、自瞄定版（无抖动无闪）
- **连续模式**（用户定版=初版行为）：勾主开关即瞄，无开火/开镜触发门。
- 目标选择 findminat + **世界坐标锁定滞回**：static lockPos/lockIdx；
  换靶仅当新目标 scrD < 0.45×锁定者 scrD；锁定者 ObjAim 位移<250 保持——破重叠敌人乒乓。
- 死区 24px：|误差|<24 松手不拽（高频抖动源）。
- 比例拽：gain=速度/220，单帧位移钳 [8,100]；越界 clamp 重锚 NumIo[7]。
- zm 坐标映射照抄原作者（zm_y=scr.x, zm_x=ScreenX-scr.y）——**方向被原版验证过，别自创**。
- 主开关硬闸在最前：!DrawIo[20] → Touch::Up(); return。

## 七、构建/部署闭环（手机版）
1. 构建：bash /tmp/w/out/build_fps2.sh（TUSI NDK r29 arm64，-nostdlib++ 静态 libc++，全量~4min；
   失败判据 obj/arm64/.fail；打包前 rm -rf obj）
2. 部署（/sdcard 不可执行，必须拷 /data/local/tmp）：
   su -c 'pkill -f start.sh'; su -c 'cp /sdcard/Download/FPS2透视_start.sh /data/local/tmp/start.sh && chmod 755 /data/local/tmp/start.sh'; su -c '/data/local/tmp/start.sh &'
3. 验证：App 内「导出调试报告」→ /sdcard/Download/FPS2_debug.txt → 读 DrawIo 位串/相机/Aim 表/ray 值。
   **报告是唯一的远程调试通道**，每轮新功能都同步加一行诊断输出。

## 八、移植到新游戏的步骤（checklist）
1. dump GNames，grep Pawn/Character 类名 → 确定敌人前缀（含队伍后缀规律）
2. 拿一个 pawn：扫 RootComponent→Mesh→位置三连（rootPos/C2W 平移互差<400）
3. 骨骼数组三偏移探一遍，num=0 → 走几何伪骨骼
4. 相机 ViewMatrix：转身验证 pitch/yaw 与屏幕转向一致（符号别反）
5. Embree：确认 FPhysxSceneManager 结构存在，三场景根非空；先只开 st 看墙，再加 dyn 看木箱
6. 敌我验证：打一发看队伍字节；站掩体后看 ray 值是否≈挡距
7. 编译部署循环至现象收敛，每个异常只改一个参数
