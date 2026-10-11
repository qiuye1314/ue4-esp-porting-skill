# 我(富江)读取你发来数据的完整步骤 —— 会话记忆固化

## 数据入口只有三个，按优先级
### A. 聊天直发（最直接）
- 文字/代码块：直接在我上下文里，无需工具
- 图片：你发图后我用 run_code 里的 read_image 或 bash 处理；run_code 调用带图工具的结果会自动附回我的上下文，我"看得见"
- 路径引用(@xxx)：你消息里 @ 出来的路径就是我该去读的位置

### B. 设备共享存储 /sdcard/Download（大数据走这里）
- 约定：**所有导出物、dump、SDK、报告统一落 /sdcard/Download/**
- 当前项目实例：透视 App 里点「导出调试报告」→ 写 /sdcard/Download/FPS2_debug.txt
- 我的读取方式（run_code 内）：
  1. tools.read({file_path:'/sdcard/Download/xxx'}) —— 文本逐行
  2. await tools.bash({command:'grep -E "关键行正则" /sdcard/Download/FPS2_debug.txt'}) —— 只看重点，不灌全文
  3. 大文件先 head/ls 定大小，再按 offset/limit 续读
- 限制：/sdcard 不可执行(所以外挂跑在 /data/local/tmp)；DCIM/Pictures/Android/data 等只读；写入普通 Download 允许

### C. 设备能力桥 /app/*（要看你手机本身时）
- 每轮先取 token：T=$(cat /root/.dsh/.bridge_token)，再 curl http://127.0.0.1:3090/app/...
- 端点清单一次拿全：curl "http://127.0.0.1:3090/app/help?token=$T"
- 常用：读屏 /app/ui/dump · 截屏 /app/ui/screenshot(需无障碍开启) · 按文字点按 /app/ui/tap?text= · 弹页面 /app/open?url= · 写剪贴板 /app/clip?text= · 导出文件 /app/export?path= · 读文件 /app/readfile?path=
- 回 DISABLED/NO_PERMISSION 就照实告诉用户去哪开，不反复重试

## 调试数据标准循环（本项目跑了18轮的流程）
1. 你操作 App → 点「导出调试报告」
2. 我 grep 关键行：相机(位姿/Fov) / DrawIo位串(开关真实状态) / NumIo(参数) / Aim表(scrD/ray三值/键位/触点)
3. 报告字段和你屏幕现象对账 → 定位是数据错、判定错还是执行错
4. 只改一个变量 → 重编(全量~4min) → cp 到 /data/local/tmp/start.sh → su 拉起
5. 你换装实测 → 现象或新报告回来 → 下一轮
- 铁律：报告是唯一远程通道，每加一个功能就同步加一行诊断输出；"用户跑的是旧版"要靠报告头/行为特征先排除

## 新游戏交接给我时，这样给最快
1. UE4Dump-MCP-Enhance 跑 dump → 8项数据存成 /sdcard/Download/<游戏名>_dump.txt（GNames/GWorld/GUObjectArray/关卡链/类名前缀/位置链/相机/三场景根）
2. 一句话报包名+游戏引擎版本
3. 截图一张主界面(确认渲染/竖屏横屏) → 直接发聊天
其余按 ue4-esp-porting-mobile skill 第二、三章开挖
