# FA Player Figura Port

FA+Player v1.1 的非官方 Figura 兼容移植，目标环境为 Minecraft 1.21.1 / NeoForge / Figura。

当前版本：`fix17`

## 安装

1. 下载本仓库。
2. 将仓库文件夹放入：

   ```text
   <Minecraft目录>/figura/avatars/FA-Player-Figura/
   ```

3. 在 Figura Wardrobe 中选择 `Fresh Animations Player — Figura Port fix17`。

## 已移植内容

- 待机、呼吸和视线跟随
- 步行、奔跑、疾跑、后退和横向移动
- 跳跃、下落、落地、潜行、骑乘、睡眠和攀爬
- 游泳、踩水、爬行和鞘翅飞行
- 主手、副手和左撇子攻击挥手
- 盾牌、弓、弩、三叉戟、刷子、望远镜和号角姿势
- 第一人称手部和地图姿势
- 外层皮肤、盔甲和鞘翅跟随

## fix17

- 修复举盾时手臂没有明显向前倾斜的问题。
- 攻击和交互挥手使用 Figura `getSwingArm()`。
- 盾牌等持续使用姿势使用 Figura `getActiveHand()`。
- 保留 Minecraft 计算的举盾手臂前倾、侧向旋转和肩部位置。

## 说明

- 玩家本体由 Figura `vanilla_model` 直接驱动。
- 披风渲染已禁用。
- `accessories.bbmodel` 仅保留鞘翅枢轴，原版翼面、动态贴图和附魔光效仍由 Minecraft/Figura 渲染。
- 若其他 Avatar 脚本同时修改 `vanilla_model`，可能会相互覆盖。

## 仓库边界

本仓库只包含完成的 Figura Avatar 文件，不包含：

- Fresh Animations / FA+Player 原始资源包和 `.jem` / `.jpm` 文件
- Entity Model Features、Entity Texture Features 或 Figura 源码
- 开发期间的参考截图、测试工具、旧版本目录或 ZIP

## 署名与条款

Fresh Animations 及 FA+Player 的原始模型与动画由 FreshLX 创作。本项目是对其动画逻辑的非官方 Figura 兼容转换，与 FreshLX 没有隶属或官方合作关系。

- Fresh Animations CurseForge: <https://www.curseforge.com/minecraft/texture-packs/fresh-animations>
- Fresh Animations Modrinth: <https://modrinth.com/resourcepack/fresh-animations>

原创内容的权利与使用条款仍归原作者所有。请在使用、修改或分发前阅读官方项目页面的最新条款。详见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
