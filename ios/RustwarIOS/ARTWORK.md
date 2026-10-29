# 原生美术

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

## 原创陆地爆炸动画

- ExplosionAtlas.imageset/explosion-v1.png 使用内置 image_gen、transparent_background=true 生成，原文件直接复制到工程；未重绘、抠图或替换透明背景，没有复制商业游戏特效。
- 图集为4列2行、八个等大正方形UV单元，顺序从左到右、从上到下。生成图不保证宽高能被列/行数整除，因此使用归一化子纹理，不做整数除法截断；直接回归以整数像素边界取样，不用小数坐标误读RGBA字节。GeneratedExplosionArt 缓存全部帧，场景初始化时预加载，不在每次命中时解码图片；普通 alpha 混合保留炭黑烟尘，不用加色混合把黑烟擦除。
- 普通陆地命中和摧毁共享素材，但直径不同；0.6秒八帧加0.12秒淡出，Scene在0.76秒回收，继续使用既有64根特效/32焦痕预算、可见性来源和水面分支。减少动态效果使用单帧0.18秒静态淡出，不播放爆炸扩张。
- 旧几何表现仅作素材缺失后备；实际UI检查全部八帧成功加载。ci/effect-art.test.js 解码实际RGBA，检查每帧有效内容、透明边界、不同帧、火焰色彩与末帧烟尘消散；五张游戏画面仍需下载复看。静态场景及像素门控不证明完整动画节奏或真机性能。

### 爆炸图集最终提示词

```text
Use case: stylized-concept.
Asset type: production-ready animated explosion sprite atlas for an original premium military top-down RTS on iOS, matching realistic graphite/olive armored vehicles.
Primary request: ONE coherent eight-frame high-explosive ground impact, chronologically growing from a tiny white-hot ignition through a compact orange fireball and dark rolling smoke to dissipating charcoal dust. EXACT 4 COLUMNS x 2 ROWS uniform grid, eight square equal-sized cells, frame order left-to-right then top-to-bottom. Every frame stays centered on the same pivot at its cell center. Directly overhead orthographic camera, looking down onto the blast, NOT a side-view mushroom cloud.
Scene/backdrop: actual TRANSPARENT ALPHA, nothing behind or between sprites. No floor, no dark/white matte, no checkerboard pixels, no cast shadow outside the effect. Every cell has wide completely transparent padding, with the outermost smoke/sparks contained within central 72 percent of the cell width and height.
Style/medium: high-quality pre-rendered VFX textures, believable turbulent billows, crisp ember fragments, warm white/yellow ignition, rich restrained amber flames within detailed charcoal and gray smoke. Physical volume and subtle lighting, not cartoon, not flat circles, not vector art. Consistent overhead perspective and pivot across all frames. Small readable combat effect, not a cinematic background.
Animation stages: 1 small ignition; 2 compact white/amber burst; 3 expanding orange fire and initial soot; 4 peak irregular fireball embedded in smoke; 5 flame recedes into thick rolling smoke; 6 charcoal/dust plume with only a few embers; 7 thin broken smoke wisps; 8 almost dissipated faint gray wisps. The last frames should have significantly less opacity than the middle frames. Do not add a ring or a circular outline.
Constraints: exactly eight isolated sprites. Landscape canvas 2:1, with no borders, labels, text, numbers, logos or watermark. Maintain truly transparent alpha, including soft translucent smoke edges. Entire blast must remain within each equal cell, no overlap with neighbors.
```

## 原创工业建筑与生产标题

- 使用内置 image_gen、transparent_background=true 生成原创九建筑图集和单炮武器；选择的原始文件分别原样复制为 BuildingBaseAtlas.imageset/building-bases-v1.png、BuildingWeapon.imageset/building-weapon-v1.png。两图实际均为1254x1254 RGBA，不在线下载，不用脚本改图或抠图。
- 先生成九建筑，再尝试武器；第一次武器错误地混入固定底座、炮口类似光学模块，未进入工程。第二次改用既有原创 UnitMountAtlas 作风格参考，得到真正独立的单炮武器，才作为成品来源。建筑图集参考既有 UnitHullAtlas 的材质，不复制商业游戏图片。
- BuildingArtLayout.dataset/layout.json 使用1280x1280逻辑参考坐标记录实际裁剪、建筑轴和脚印跨度，再映射到源像素并向外取整；生成结果并非精确等分网格，禁止简单九宫格切图。每个裁剪保留透明边，脚印跨度只决定绘制比例，不改变 Core 的碰撞、选择或建造资格。
- 当前覆盖指挥中心T1、工厂T1/T2、采集器T1/T2/T3、雷达T1/T2和炮塔T1。工厂冷却模块、采集器泵组、雷达第二天线提供实际等级轮廓；敌方以红色材质调和既有阵营徽记区分，不另存玩法状态。
- GeneratedBuildingArt 缓存九种底座和唯一一组炮塔/炮管；固定底座不旋转，building-turret-mount继续走原有瞄准链路，building-recoil-mount只带动炮管。炮口取自实际炮管末端坐标，不把透明裁剪边当炮口；后坐与发射点共同减去原表现距离。
- 生产标题/概览的缩略图复用同一裁剪和当前真实建筑等级，最多九份共享缓存。Controller只读暴露选中生产建筑，不创建第二套选择、科技、队列或计时器。缺少素材时保留原几何/符号后备，但九种实际加载门控不接受后备代替。
- ci/building-art.test.js解码两张实际PNG，检查九种内容/透明留边/实体锚点/源细节、升级归一化轮廓差异、独立武器的轴/炮口边缘与炮管分割连续性；native真实UI保留全部点选、生产、升级、撤单、循环、集结和至少44pt/六卡首屏断言，五张云端图仍需实际复看。二维预渲染和静态截图不证明全设备交互或真机性能。

### 建筑图集最终提示词

```text
Use case: stylized-concept. Asset type: production-ready BUILDING BASE sprite atlas for an original premium top-down military RTS on iOS. Image 1 is a MATERIAL/QUALITY reference only, not an edit target; match its believable olive/graphite armor, brushed steel bevels and subtle mint identification paint, but create ORIGINAL buildings, not vehicles.
Composition: one SQUARE transparent PNG containing exactly NINE isolated structures in a precise 3 COLUMN x 3 ROW equal-cell grid. Each structure is centered in its cell and occupies only the central 72 percent of the cell width and height. Wide fully transparent gutters. Strict directly-overhead ORTHOGRAPHIC 90-degree camera, NOT isometric, no perspective, no visible front wall faces. Physical pre-rendered 3D material quality, crisp roof geometry, larger readable panels rather than busy noise. Soft directional light from upper left, ambient occlusion ONLY within structures. Actual transparent alpha outside silhouettes; no ground, no cast shadows, no checkerboard pixels, no matte, no borders, labels, text or logos.
ROW 1 left-to-right: (1) fortified COMMAND CENTER, octagonal reinforced concrete foundation with graphite armored central command roof, teal recessed roof windows, four compact cooling annexes and a communications antenna; (2) LAND VEHICLE FACTORY TIER 1, low rectangular industrial hangar with ribbed roof, recessed mechanical fan, large EXIT RAMP ON THE RIGHT, restrained amber/black hazard marks; (3) SAME FACTORY TIER 2, recognizable same central hangar/right-hand exit, upgraded side gantries and additional paired cooling modules, broader and more sophisticated silhouette, no extra adjacent building.
ROW 2 left-to-right: (4) RESOURCE EXTRACTOR TIER 1, central deep circular drilling well with machined steel rings and four radial olive mechanical support arms on an octagonal foundation; (5) SAME EXTRACTOR TIER 2, same central well plus four diagonal pump/reservoir pods, visibly richer intermediate silhouette; (6) SAME EXTRACTOR TIER 3, same central well plus armored perimeter pumping modules and two large cooling housings, substantial high-tech end-tier industrial silhouette. Three tiers must be visibly distinct without text.
ROW 3 left-to-right: (7) RADAR STATION TIER 1, compact reinforced equipment shelter with a single broad elliptical steel mesh radar dish and clear support/receiver assembly seen directly from above; (8) SAME RADAR STATION TIER 2, same large dish plus a smaller second dish and two side electronics pods, visibly advanced silhouette; (9) DEFENSE TURRET BASE ONLY, square chamfered concrete/steel plinth with four armored corner anchors and a precise EMPTY circular gun-bearing socket EXACTLY at the cell center. Absolutely NO turret housing, NO weapon and NO barrel on this last base; rotating weapon will be a separate asset.
All nine buildings belong to one coherent original industrial faction. Restrained pale mint strips, neutral dark olive titanium, warm steel edges, realistic recesses, fine bolts, vents and purposeful engineering. No bright glows, no thick outlines, no flat vector art, no cartoon, no surrounding scenery. Ensure every object is entirely inside its own cell with substantial transparent padding. This is one atlas asset with nine sprites, not a presentation sheet.
```

### 独立炮塔最终提示词

```text
Use case: stylized-concept. Image 1 is a reference of ORIGINAL isolated game weapon mounts, especially its top-row third and bottom-row third turret. Create ONE NEW isolated single-barrel defense GUN TURRET in that exact directly-overhead military game-sprite visual language. Only the movable gun turret and cannon, NOT its stationary support/base. SQUARE canvas with genuinely TRANSPARENT ALPHA, no floor or shadow outside the object.
The subject is a compact angular low-profile olive armored TANK-LIKE TURRET HOUSING on the left joined to ONE LONG NARROW MACHINED CANNON BARREL pointing precisely RIGHT. The turret housing rotation axis is at (40 percent canvas width, 50 percent canvas height). Housing extends roughly from 17 to 58 percent canvas width, and from 30 to 70 percent canvas height; a long straight barrel runs from 56 to 87 percent width along the exact horizontal canvas centerline. The barrel terminates in a small squared slotted MUZZLE BRAKE, NOT a camera or lens. A clean physical cannon design: rounded breech shroud at housing front, narrow machined steel tube, vented muzzle. No optical assembly at the muzzle. Tiny restrained optics may be located on the housing itself only.
Strict orthographic 90-degree overhead camera, zero isometric angle. Olive graphite titanium armor, brushed metal bevels, recessed panels, bolts, restrained pale mint painted stripe, believable fine wear, realistic pre-rendered materials consistent with Image 1. Clear readable silhouette, warm highlights from upper left. Substantial transparent margin around entire object. Do NOT draw the support base, a platform, foundation, circular pedestal, concrete, side cooling towers, tank hull, tracks or wheels. Do NOT place multiple objects or a sprite grid. No text, logo, watermark, glows, black/gray/white background, checkerboard pixels, cartoon or vector lines. Exactly one isolated operational cannon turret with a real straight barrel pointing right.
```
