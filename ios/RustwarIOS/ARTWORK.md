# 原生载具美术

## 来源与使用

- 使用内置 image_gen 生成原创素材，不使用额外 API Key，不复制铁锈战争图片或其他商业游戏单位。
- 最终资源是 Assets.xcassets 中的 UnitHullAtlas.imageset/unit-hulls-v1.png 与 UnitMountAtlas.imageset/unit-mounts-v1.png；原始生成文件原样复制，未用脚本重绘、抠图或替换透明背景。
- 统一方向：严格俯视、车头朝右、石墨/橄榄装甲、细金属倒角、可读履带/引擎/光学件、少量薄荷色识别条。工程车、侦察车、轻坦、重坦、悬浮、防空、火炮、炮艇具有不同轮廓。
- 游戏通过 UnitArtLayout.dataset/layout.json 的参考坐标裁剪图集，保留实际炮塔轴；weaponCutX 在炮尾分出独立后坐层。不能把图集等分当作精确锚点，也不能把整车图片当成可独立转炮塔的模型。
- 战场和生产/选兵缩略图复用同一套源图；敌方使用红色调和闭合三角徽记，我方使用薄荷色开放箭标。炮口特效距离从真实素材边界派生，雾、命中、伤害与订单仍以 Core 为准。
- 两张图集和每类三层纹理为有限缓存，不逐帧解码，不保存到对局存档，不引入网络依赖。原几何模型仅作资源缺失后备；云端实际 UI 必须证明八类生成模型均成功加载。

## 最终生成提示词

内置工具参数均为 transparent_background=true。首次整车图仅用于确定风格，没有作为成品资源引用。下列是最终两张图集的提示词；Image 1 分别为先前原创整车图、先前生成底盘图集的风格参考。

### 底盘图集

```text
Use case: stylized-concept. Image 1 is a STYLE REFERENCE only. Create a production sprite atlas for an original top-down RTS, exact orderly 4 COLUMN x 2 ROW equal-cell grid, no lines or labels. ALL EIGHT VEHICLES POINT EXACTLY RIGHT, directly overhead orthographic 90-degree camera. Entire canvas background must be genuinely TRANSPARENT ALPHA: absolutely no dark background, no gradients outside silhouettes, no drop shadows, no floor, no checkerboard pixels. Each equal cell contains exactly ONE CHASSIS/HULL ONLY, centered exactly in that cell, occupying 68% of cell width, with adequate transparent gutters. NO TURRETS, NO GUNS, NO CANNON BARRELS on any chassis; expose a small centered dark circular turret socket on combat chassis. Matching muted olive/graphite titanium armor, realistic bevels, engine vents, bolts, restrained mint team stripe, legible premium pre-rendered game materials, not a line drawing. Row 1 from left: (1) engineering builder, compact six-wheel utility rover with orange tool pods; (2) scout, low slender four-wheel armored recon buggy; (3) light tank, balanced tracked rectangular hull; (4) heavy tank, broad angular twin-track heavily plated chassis. Row 2 from left: (5) hover tank, four rounded turbine pods around a sleek floating armored hull, no tracks; (6) anti-air tracked vehicle with rear electronics deck; (7) artillery, long tracked chassis with folded rear stabilizer spades; (8) naval gunboat, narrow patrol-boat hull with pointed right bow, rear engine. Consistent illumination and overhead perspective; distinct readable silhouettes; each component entirely fits its cell. Only eight hull sprites, NO other objects. Atlas landscape aspect ratio 2:1; cells square. Preserve sharp physical detailing without busy noise.
```

### 武器图集

```text
Use case: stylized-concept. Image 1 is a style and component-scale reference ONLY. Produce the matching WEAPON-MOUNT sprite atlas for those eight RTS hulls, an exact 4 COLUMN x 2 ROW equal-cell grid on genuinely transparent alpha. Landscape canvas 2:1; eight square cells, no grid lines or labels, no shadows/background/terrain. Every mount points exactly to the RIGHT. STRICT ORTHOGRAPHIC directly overhead 90-degree view. NO vehicle chassis, NO tracks, NO wheels, NO boat hull. Only the small standalone turret/tool assemblies, isolated from vehicles. Each turret pivot must be EXACTLY at the CENTER of its cell, with the gun pointing right; enough margin for entire long barrels. Similar overall component scale, turret armor occupies roughly central 35% cell width, barrel extends right up to 42% of cell width. Row 1: (1) orange/mint engineering articulated tool head and repair arm; (2) small scout remote autocannon pod with single short thin barrel; (3) angular light-tank turret and single long gun; (4) broad heavy-tank turret and two parallel substantial barrels. Row 2: (5) compact rounded hover-tank pulse cannon mount with subtle teal optics; (6) anti-air rotary turret with two slim paired autocannon barrels; (7) artillery armored breech and very long thick howitzer barrel; (8) compact naval gun turret and medium cannon. Premium believable graphite/olive metallic surfaces, bevels, hatches, bolts, restrained mint identification strips, subtle wear matching Image 1. Readable at game scale, light from upper left. No text, logos, watermark, glowing outlines, checkerboard pattern, or baked lighting outside sprites.
```

## 云端验收与边界

- ci/unit-art.test.js 解码实际 PNG，检查 RGBA、每个实际裁剪的透明留边/可见像素、轴点与分割范围，避免不透明黑底、裁切和邻图串入。
- native CI 编译实际 App、执行中文真实点选/取消选择/移动/付费生产，以及既有多指/战斗/生产/UI 回归；五张云端场景图需下载复看。
- 图集仍是二维预渲染素材，不是完整 3D 模型；生成的磨损细节、炮管分割边缘、小比例清晰度和真机性能需要持续实际画面迭代，不能仅凭生成图宣布高端成品验收。
