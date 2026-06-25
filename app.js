(() => {
  "use strict";

  const canvas = document.getElementById("gameCanvas");
  const ctx = canvas.getContext("2d");
  const minimap = document.getElementById("minimap");
  const mctx = minimap.getContext("2d");

  const ui = {
    metal: document.getElementById("metalValue"),
    income: document.getElementById("incomeValue"),
    supply: document.getElementById("supplyValue"),
    enemy: document.getElementById("enemyValue"),
    objective: document.getElementById("objectiveText"),
    campaign: document.getElementById("campaignBtn"),
    skirmish: document.getElementById("skirmishBtn"),
    survival: document.getElementById("survivalBtn"),
    challenge: document.getElementById("challengeBtn"),
    sandbox: document.getElementById("sandboxBtn"),
    map: document.getElementById("mapBtn"),
    ai: document.getElementById("aiBtn"),
    stats: document.getElementById("statsBtn"),
    pause: document.getElementById("pauseBtn"),
    speed: document.getElementById("speedBtn"),
    save: document.getElementById("saveBtn"),
    load: document.getElementById("loadBtn"),
    restart: document.getElementById("restartBtn"),
    title: document.getElementById("selectionTitle"),
    meta: document.getElementById("selectionMeta"),
    badge: document.getElementById("selectionBadge"),
    hpLabel: document.getElementById("hpLabel"),
    hpFill: document.getElementById("hpFill"),
    queue: document.getElementById("queueBox"),
    commands: document.getElementById("commandButtons"),
    feed: document.getElementById("feed"),
    statsPanel: document.getElementById("statsPanel"),
    statsClose: document.getElementById("statsClose"),
    statsChart: document.getElementById("statsChart"),
    statsBody: document.getElementById("statsBody"),
    sandboxPanel: document.getElementById("sandboxPanel"),
    sandboxModeLabel: document.getElementById("sandboxModeLabel"),
    sandboxSelect: document.getElementById("sandboxSelectBtn"),
    sandboxPlace: document.getElementById("sandboxPlaceBtn"),
    sandboxErase: document.getElementById("sandboxEraseBtn"),
    sandboxPlayer: document.getElementById("sandboxPlayerBtn"),
    sandboxEnemy: document.getElementById("sandboxEnemyBtn"),
    sandboxType: document.getElementById("sandboxType"),
    sandboxCombat: document.getElementById("sandboxCombatBtn"),
    sandboxFunds: document.getElementById("sandboxFundsBtn"),
    sandboxClear: document.getElementById("sandboxClearBtn"),
    sandboxReveal: document.getElementById("sandboxRevealBtn"),
    sandboxExport: document.getElementById("sandboxExportBtn"),
    sandboxImport: document.getElementById("sandboxImportBtn"),
    sandboxImportFile: document.getElementById("sandboxImportFile"),
    placeHint: document.getElementById("placeHint"),
  };
  const sctx = ui.statsChart.getContext("2d");

  const MAP_W = 4200;
  const MAP_H = 2800;
  const TILE = 44;
  const FOG = 84;
  const TEAM_PLAYER = 0;
  const TEAM_ENEMY = 1;
  const BUILD_PAD = 8;
  const SAVE_KEY = "rustwar-rts-prototype-save-v1";
  const AI_PREF_KEY = "rustwar-rts-ai-difficulty";
  const UNIT_STANCE_DEFAULT = "aggressive";

  const unitStances = {
    aggressive: { label: "主动开火", short: "主动", icon: "AT", hotkey: "Z", meta: "自动索敌", autoRange: 1 },
    defensive: { label: "阵地开火", short: "阵地", icon: "DF", hotkey: "X", meta: "近距还击", autoRange: 0.68 },
    holdFire: { label: "停止开火", short: "停火", icon: "HF", hotkey: "V", meta: "仅手动攻击", autoRange: 0 },
  };
  const unitStanceOrder = ["aggressive", "defensive", "holdFire"];

  const teamColor = {
    [TEAM_PLAYER]: "#62d66b",
    [TEAM_ENEMY]: "#e35959",
  };

  const teamDark = {
    [TEAM_PLAYER]: "#244f2b",
    [TEAM_ENEMY]: "#642628",
  };

  const terrainColors = {
    grass: "#38743c",
    grass2: "#3f7f43",
    dirt: "#836c55",
    sand: "#b69378",
    rock: "#777a73",
    water: "#1d69b6",
    deep: "#15538f",
    lava: "#9c2b20",
  };

  const aiDifficulties = {
    veryEasy: {
      label: "非常简单",
      income: 0.62,
      buildInterval: 5.6,
      trainInterval: 2.6,
      attackBase: 68,
      attackJitter: 34,
      waveScale: 0.55,
      survivalDelay: 18,
      survivalMin: 38,
      survivalScale: 0.58,
    },
    easy: {
      label: "简单",
      income: 0.9,
      buildInterval: 4.2,
      trainInterval: 1.8,
      attackBase: 46,
      attackJitter: 24,
      waveScale: 0.75,
      survivalDelay: 8,
      survivalMin: 30,
      survivalScale: 0.8,
    },
    normal: {
      label: "中等",
      income: 1.28,
      buildInterval: 3.2,
      trainInterval: 1.3,
      attackBase: 32,
      attackJitter: 18,
      waveScale: 1,
      survivalDelay: 0,
      survivalMin: 24,
      survivalScale: 1,
    },
    hard: {
      label: "困难",
      income: 1.58,
      buildInterval: 2.35,
      trainInterval: 0.9,
      attackBase: 23,
      attackJitter: 12,
      waveScale: 1.22,
      survivalDelay: -7,
      survivalMin: 19,
      survivalScale: 1.24,
    },
    veryHard: {
      label: "非常困难",
      income: 1.9,
      buildInterval: 1.8,
      trainInterval: 0.68,
      attackBase: 18,
      attackJitter: 9,
      waveScale: 1.48,
      survivalDelay: -13,
      survivalMin: 15,
      survivalScale: 1.52,
    },
    impossible: {
      label: "不可能",
      income: 2.35,
      buildInterval: 1.35,
      trainInterval: 0.48,
      attackBase: 14,
      attackJitter: 6,
      waveScale: 1.82,
      survivalDelay: -20,
      survivalMin: 12,
      survivalScale: 1.9,
    },
  };
  const aiDifficultyOrder = ["veryEasy", "easy", "normal", "hard", "veryHard", "impossible"];

  const mapPresets = {
    coast: {
      label: "海岸",
      playerBase: { x: 720, y: 2110 },
      enemyBase: { x: 3520, y: 720 },
      playerRally: { x: 810, y: 2230 },
      enemyRally: { x: 3350, y: 850 },
      camera: { x: 880, y: 2070, zoom: 0.82 },
      resources: [
        [470, 2085],
        [700, 1900],
        [950, 2260],
        [1200, 1970],
        [1520, 1530],
        [1715, 1030],
        [2110, 2070],
        [2420, 1610],
        [2720, 960],
        [2980, 1370],
        [3190, 590],
        [3450, 830],
        [3700, 510],
        [3820, 1010],
      ],
      player: {
        extractor: [700, 1900],
        factory: [930, 2105],
        builders: [
          [610, 2185, 560, 2180],
          [800, 2245, 825, 2260],
        ],
        units: [
          ["tank", 1030, 2020],
          ["scout", 1010, 2190],
        ],
        campaignFabricator: [835, 2015],
        campaignTank: [1085, 2070],
      },
      enemy: {
        extractors: [
          [3450, 830],
          [3700, 510],
        ],
        factory: [3300, 735],
        frontTurret: [3150, 915],
        builder: [3600, 840],
        units: [
          ["tank", 3180, 720],
          ["tank", 3235, 780],
          ["scout", 3120, 820],
        ],
        challengeExtractor: [3820, 1010],
        challengeDefences: {
          aaTurret: [3370, 560],
          laserDefence: [3565, 780],
          repairBay: [3420, 940],
        },
        challengeUnits: [
          ["heavyTank", 3120, 650],
          ["artillery", 3000, 850],
          ["interceptor", 3380, 600],
        ],
      },
    },
    islands: {
      label: "群岛",
      playerBase: { x: 760, y: 2040 },
      enemyBase: { x: 3450, y: 780 },
      playerRally: { x: 930, y: 2065 },
      enemyRally: { x: 3240, y: 930 },
      camera: { x: 980, y: 1980, zoom: 0.8 },
      resources: [
        [530, 2190],
        [790, 1880],
        [1110, 2150],
        [1460, 1730],
        [1830, 2140],
        [2160, 1210],
        [2460, 920],
        [2690, 1640],
        [3060, 1170],
        [3260, 680],
        [3540, 900],
        [3740, 550],
        [3860, 1110],
      ],
      player: {
        extractor: [790, 1880],
        factory: [980, 2035],
        builders: [
          [645, 2130, 600, 2180],
          [860, 2210, 900, 2190],
        ],
        units: [
          ["hover", 1100, 1970],
          ["scout", 1045, 2150],
        ],
        campaignFabricator: [870, 1940],
        campaignTank: [1125, 2055],
      },
      enemy: {
        extractors: [
          [3260, 680],
          [3540, 900],
        ],
        factory: [3210, 820],
        frontTurret: [3020, 1050],
        builder: [3565, 840],
        units: [
          ["hover", 3060, 850],
          ["gunboat", 2860, 1210],
          ["scout", 3150, 980],
        ],
        challengeExtractor: [3860, 1110],
        challengeDefences: {
          aaTurret: [3370, 575],
          laserDefence: [3520, 785],
          repairBay: [3270, 960],
        },
        challengeUnits: [
          ["heavyTank", 3040, 720],
          ["missileShip", 2800, 1240],
          ["interceptor", 3400, 640],
        ],
      },
    },
    lava: {
      label: "熔岩",
      playerBase: { x: 820, y: 2140 },
      enemyBase: { x: 3520, y: 690 },
      playerRally: { x: 960, y: 2195 },
      enemyRally: { x: 3310, y: 820 },
      camera: { x: 960, y: 2080, zoom: 0.82 },
      resources: [
        [520, 2020],
        [820, 1890],
        [1050, 2260],
        [1360, 1820],
        [1670, 1390],
        [1960, 1970],
        [2260, 1540],
        [2580, 1050],
        [2920, 1420],
        [3150, 620],
        [3460, 840],
        [3720, 520],
        [3860, 1010],
      ],
      player: {
        extractor: [820, 1890],
        factory: [1030, 2130],
        builders: [
          [680, 2200, 615, 2200],
          [920, 2260, 960, 2250],
        ],
        units: [
          ["tank", 1130, 2055],
          ["aaTank", 1090, 2220],
        ],
        campaignFabricator: [920, 1980],
        campaignTank: [1180, 2135],
      },
      enemy: {
        extractors: [
          [3460, 840],
          [3720, 520],
        ],
        factory: [3295, 720],
        frontTurret: [3100, 900],
        builder: [3610, 805],
        units: [
          ["tank", 3180, 700],
          ["artillery", 3100, 780],
          ["scout", 3190, 880],
        ],
        challengeExtractor: [3860, 1010],
        challengeDefences: {
          aaTurret: [3380, 555],
          laserDefence: [3540, 760],
          repairBay: [3400, 910],
        },
        challengeUnits: [
          ["heavyTank", 3120, 640],
          ["artillery", 3000, 840],
          ["interceptor", 3400, 590],
        ],
      },
    },
  };
  const mapOrder = ["coast", "islands", "lava"];
  let selectedMapKey = "coast";

  const unitTypes = {
    builder: {
      name: "工程车",
      icon: "B",
      domain: "ground",
      cost: 220,
      time: 7,
      hp: 170,
      radius: 13,
      speed: 76,
      vision: 285,
      supply: 1,
      buildPower: 34,
      repairPower: 18,
      weapon: { range: 120, damage: 8, reload: 0.9, speed: 560, canGround: true },
      description: "建造、维修、夺点",
    },
    scout: {
      name: "侦察车",
      icon: "S",
      domain: "ground",
      cost: 140,
      time: 5,
      hp: 95,
      radius: 10,
      speed: 126,
      vision: 410,
      supply: 1,
      weapon: { range: 145, damage: 7, reload: 0.55, speed: 700, canGround: true },
      description: "快速视野",
    },
    tank: {
      name: "轻型坦克",
      icon: "T",
      domain: "ground",
      cost: 260,
      time: 8,
      hp: 245,
      radius: 15,
      speed: 82,
      vision: 270,
      supply: 2,
      weapon: { range: 185, damage: 28, reload: 1.12, speed: 520, canGround: true },
      description: "主力装甲",
    },
    heavyTank: {
      name: "重型坦克",
      icon: "HT",
      domain: "ground",
      cost: 520,
      time: 15,
      hp: 520,
      radius: 19,
      speed: 58,
      vision: 300,
      supply: 4,
      weapon: { range: 225, damage: 52, reload: 1.35, speed: 520, canGround: true },
      description: "二级装甲突破",
    },
    hover: {
      name: "悬浮坦克",
      icon: "H",
      domain: "hover",
      cost: 360,
      time: 11,
      hp: 225,
      radius: 14,
      speed: 92,
      vision: 300,
      supply: 2,
      weapon: { range: 175, damage: 24, reload: 0.95, speed: 570, canGround: true },
      description: "跨越浅水",
    },
    artillery: {
      name: "自行火炮",
      icon: "A",
      domain: "ground",
      cost: 480,
      time: 14,
      hp: 170,
      radius: 16,
      speed: 54,
      vision: 360,
      supply: 3,
      weapon: {
        range: 430,
        minRange: 110,
        damage: 58,
        reload: 2.8,
        speed: 430,
        aoe: 58,
        canGround: true,
      },
      description: "远程溅射",
    },
    aaTank: {
      name: "防空车",
      icon: "AA",
      domain: "ground",
      cost: 340,
      time: 10,
      hp: 185,
      radius: 14,
      speed: 78,
      vision: 320,
      supply: 2,
      weapon: {
        range: 260,
        damage: 18,
        reload: 0.65,
        speed: 760,
        canAir: true,
        canGround: false,
      },
      description: "压制空军",
    },
    repairTank: {
      name: "维修车",
      icon: "RV",
      domain: "ground",
      cost: 420,
      time: 12,
      hp: 210,
      radius: 15,
      speed: 72,
      vision: 300,
      supply: 2,
      repairAura: 128,
      repairPower: 22,
      description: "移动维修光环",
    },
    shieldTank: {
      name: "护盾车",
      icon: "SH",
      domain: "ground",
      cost: 620,
      time: 18,
      hp: 260,
      radius: 17,
      speed: 62,
      vision: 310,
      supply: 3,
      shieldEmitter: { range: 165, energy: 340, maxEnergy: 340, regen: 18, costPerDamage: 0.85 },
      description: "为附近友军吸收伤害",
    },
    missileTank: {
      name: "导弹车",
      icon: "MT",
      domain: "ground",
      cost: 560,
      time: 16,
      hp: 190,
      radius: 16,
      speed: 68,
      vision: 360,
      supply: 3,
      weapon: { range: 390, damage: 42, reload: 1.75, speed: 650, aoe: 34, canGround: true, canAir: true },
      description: "多用途远程导弹平台",
    },
    laserTank: {
      name: "激光坦克",
      icon: "LT",
      domain: "ground",
      cost: 820,
      time: 21,
      hp: 360,
      radius: 17,
      speed: 66,
      vision: 330,
      supply: 4,
      weapon: { range: 255, damage: 18, reload: 0.22, speed: 980, canGround: true, canAir: true, kind: "laser" },
      description: "高速激光火力，可对空对地",
    },
    heavyHover: {
      name: "重型悬浮坦克",
      icon: "HH",
      domain: "hover",
      cost: 780,
      time: 20,
      hp: 520,
      radius: 19,
      speed: 64,
      vision: 335,
      supply: 5,
      weapon: { range: 235, damage: 56, reload: 1.35, speed: 560, aoe: 28, canGround: true },
      description: "两栖重装突击",
    },
    combatEngineer: {
      name: "战斗工程师",
      icon: "CE",
      domain: "ground",
      cost: 620,
      time: 16,
      hp: 360,
      radius: 18,
      speed: 58,
      vision: 340,
      supply: 4,
      buildPower: 42,
      repairPower: 24,
      mech: true,
      weapon: { range: 175, damage: 22, reload: 0.78, speed: 620, canGround: true },
      description: "武装建造/维修机甲",
    },
    minigunMech: {
      name: "机枪机甲",
      icon: "MG",
      domain: "ground",
      cost: 760,
      time: 19,
      hp: 620,
      radius: 22,
      speed: 48,
      vision: 340,
      supply: 5,
      mech: true,
      weapon: { range: 240, damage: 14, reload: 0.22, speed: 820, canGround: true },
      description: "近中程持续火力",
    },
    artilleryMech: {
      name: "火炮机甲",
      icon: "AM",
      domain: "ground",
      cost: 920,
      time: 24,
      hp: 430,
      radius: 21,
      speed: 42,
      vision: 390,
      supply: 6,
      mech: true,
      weapon: { range: 510, minRange: 135, damage: 72, reload: 2.7, speed: 440, aoe: 70, canGround: true },
      description: "远程重火炮机甲",
    },
    plasmaMech: {
      name: "等离子机甲",
      icon: "PM",
      domain: "ground",
      cost: 1180,
      time: 28,
      hp: 760,
      radius: 24,
      speed: 40,
      vision: 380,
      supply: 8,
      mech: true,
      weapon: { range: 315, damage: 84, reload: 1.5, speed: 560, aoe: 42, canGround: true, canAir: true },
      description: "高伤害等离子溅射",
    },
    teslaMech: {
      name: "特斯拉机甲",
      icon: "TM",
      domain: "ground",
      cost: 1420,
      time: 32,
      hp: 820,
      shield: 260,
      shieldRegen: 9,
      radius: 25,
      speed: 38,
      vision: 410,
      supply: 9,
      mech: true,
      weapon: { range: 285, damage: 58, reload: 1.1, speed: 980, canGround: true, canAir: true, chain: 3, chainRange: 135, chainFalloff: 0.62, kind: "tesla" },
      description: "链式电弧攻击",
    },
    interceptor: {
      name: "拦截机",
      icon: "I",
      domain: "air",
      cost: 360,
      time: 10,
      hp: 150,
      radius: 14,
      speed: 156,
      vision: 390,
      supply: 2,
      weapon: {
        range: 260,
        damage: 22,
        reload: 0.52,
        speed: 860,
        canAir: true,
        canGround: false,
      },
      description: "高速制空",
    },
    gunship: {
      name: "武装直升机",
      icon: "G",
      domain: "air",
      cost: 420,
      time: 12,
      hp: 190,
      radius: 16,
      speed: 112,
      vision: 360,
      supply: 3,
      weapon: { range: 210, damage: 25, reload: 0.85, speed: 650, canGround: true },
      description: "空中突击",
    },
    heavyGunship: {
      name: "重型武装直升机",
      icon: "HG",
      domain: "air",
      cost: 860,
      time: 22,
      hp: 420,
      radius: 20,
      speed: 86,
      vision: 390,
      supply: 5,
      weapon: { range: 245, damage: 54, reload: 1.18, speed: 640, aoe: 34, canGround: true },
      description: "厚甲空中火力平台",
    },
    bomber: {
      name: "轰炸机",
      icon: "M",
      domain: "air",
      cost: 720,
      time: 18,
      hp: 250,
      radius: 18,
      speed: 102,
      vision: 330,
      supply: 4,
      weapon: {
        range: 118,
        damage: 105,
        reload: 3.2,
        speed: 440,
        aoe: 74,
        canGround: true,
      },
      description: "高伤溅射",
    },
    dropship: {
      name: "运输机",
      icon: "DS",
      domain: "air",
      cost: 540,
      time: 14,
      hp: 320,
      radius: 19,
      speed: 108,
      vision: 360,
      supply: 3,
      transportCapacity: 6,
      description: "空运地面部队",
    },
    spyDrone: {
      name: "侦察无人机",
      icon: "D",
      domain: "air",
      cost: 250,
      time: 9,
      hp: 130,
      radius: 11,
      speed: 138,
      vision: 560,
      supply: 1,
      selfRepair: 8,
      description: "大范围视野",
    },
    gunboat: {
      name: "炮艇",
      icon: "GB",
      domain: "sea",
      cost: 350,
      time: 11,
      hp: 260,
      radius: 18,
      speed: 72,
      vision: 320,
      supply: 3,
      weapon: { range: 240, damage: 32, reload: 1.1, speed: 560, canGround: true },
      description: "近岸火力",
    },
    transportShip: {
      name: "运输舰",
      icon: "TS",
      domain: "sea",
      cost: 620,
      time: 18,
      hp: 520,
      radius: 24,
      speed: 46,
      vision: 360,
      supply: 4,
      transportCapacity: 10,
      description: "海上运输地面/悬浮部队",
    },
    battleship: {
      name: "战列舰",
      icon: "BS",
      domain: "sea",
      cost: 880,
      time: 22,
      hp: 660,
      radius: 27,
      speed: 48,
      vision: 420,
      supply: 6,
      weapon: {
        range: 520,
        damage: 78,
        reload: 2.4,
        speed: 500,
        aoe: 62,
        canGround: true,
      },
      description: "海上重炮",
    },
    sub: {
      name: "潜艇",
      icon: "U",
      domain: "sea",
      cost: 520,
      time: 15,
      hp: 280,
      radius: 18,
      speed: 64,
      vision: 330,
      supply: 4,
      weapon: { range: 230, damage: 46, reload: 1.5, speed: 390, canSea: true },
      description: "反舰单位",
    },
    missileShip: {
      name: "导弹舰",
      icon: "MS",
      domain: "sea",
      cost: 760,
      time: 19,
      hp: 430,
      radius: 22,
      speed: 54,
      vision: 430,
      supply: 5,
      weapon: {
        range: 420,
        damage: 46,
        reload: 1.9,
        speed: 640,
        aoe: 38,
        canGround: true,
        canAir: true,
      },
      description: "舰载远程导弹",
    },
    heavyAaShip: {
      name: "重型防空舰",
      icon: "HA",
      domain: "sea",
      cost: 920,
      time: 24,
      hp: 560,
      radius: 25,
      speed: 50,
      vision: 470,
      supply: 6,
      weapon: {
        range: 390,
        damage: 30,
        reload: 0.55,
        speed: 920,
        canAir: true,
        canGround: false,
      },
      description: "海军重型防空平台",
    },
    nautilus: {
      name: "Nautilus",
      icon: "NT",
      domain: "sea",
      cost: 1580,
      time: 38,
      hp: 980,
      shield: 260,
      shieldRegen: 7,
      radius: 31,
      speed: 42,
      vision: 540,
      supply: 10,
      weapon: {
        range: 360,
        damage: 72,
        reload: 1.65,
        speed: 500,
        aoe: 38,
        canGround: true,
        canSea: true,
      },
      antiNuke: { range: 760, ammoMax: 2, reloadTime: 42 },
      deploys: { type: "spyDrone", cooldown: 36, launchDistance: 160 },
      description: "终局潜航母舰，可反核并发射侦察无人机",
    },
    experimental: {
      name: "实验机甲",
      icon: "X",
      domain: "ground",
      cost: 1800,
      time: 42,
      hp: 1300,
      radius: 29,
      speed: 45,
      vision: 430,
      supply: 10,
      weapon: {
        range: 350,
        damage: 88,
        reload: 1.75,
        speed: 540,
        aoe: 42,
        canGround: true,
        canAir: true,
      },
      description: "终局重型单位",
    },
    experimentalTank: {
      name: "实验攻城坦克",
      icon: "XT",
      domain: "ground",
      cost: 2450,
      time: 56,
      hp: 2100,
      shield: 420,
      shieldRegen: 10,
      radius: 34,
      speed: 32,
      vision: 470,
      supply: 15,
      weapon: { range: 560, minRange: 120, damage: 138, reload: 2.4, speed: 520, aoe: 88, canGround: true, canSea: true },
      description: "终局远程攻城单位",
    },
    spider: {
      name: "模块化蜘蛛",
      icon: "SP",
      domain: "hover",
      cost: 3200,
      time: 68,
      hp: 2600,
      shield: 900,
      shieldRegen: 18,
      radius: 36,
      speed: 38,
      vision: 520,
      supply: 18,
      buildPower: 58,
      repairPower: 32,
      selfRepair: 18,
      speedModule: { multiplier: 1.62, duration: 8, cooldown: 28 },
      blinkModule: { range: 430, cooldown: 26 },
      deathNuke: { damage: 360, aoe: 210 },
      weapon: {
        range: 430,
        damage: 116,
        reload: 1.55,
        speed: 600,
        aoe: 62,
        canGround: true,
        canAir: true,
      },
      description: "终局模块化蜘蛛，可建造、自修、跨浅水、加速与闪现",
    },
  };

  const buildingTypes = {
    command: {
      name: "指挥中心",
      icon: "CC",
      cost: 0,
      time: 1,
      hp: 1850,
      size: 84,
      income: 4,
      supply: 18,
      vision: 520,
      produces: ["builder"],
      description: "基地核心",
    },
    extractor: {
      name: "资源采集器",
      icon: "EX",
      cost: 260,
      time: 10,
      hp: 560,
      size: 48,
      income: 9,
      vision: 240,
      requiresNode: true,
      upgrades: [
        { name: "采集器 T2", cost: 650, time: 20, income: 18, hp: 760, vision: 290 },
        { name: "采集器 T3", cost: 1250, time: 32, income: 32, hp: 1020, vision: 340 },
      ],
      description: "占据资源点",
    },
    fabricator: {
      name: "资源制造器",
      icon: "FB",
      cost: 520,
      time: 18,
      hp: 430,
      size: 50,
      income: 4.8,
      powerDrain: true,
      vision: 230,
      upgrades: [
        { name: "制造器 T2", cost: 780, time: 24, income: 10, hp: 560, vision: 260 },
        { name: "制造器 T3", cost: 1600, time: 36, income: 21, hp: 720, vision: 300 },
      ],
      description: "后期补经济",
    },
    radar: {
      name: "雷达站",
      icon: "RD",
      cost: 420,
      time: 16,
      hp: 380,
      size: 50,
      vision: 320,
      radar: true,
      radarRange: 920,
      upgrades: [
        { name: "雷达站 T2", cost: 780, time: 22, hp: 520, vision: 390, radar: true, radarRange: 1360 },
      ],
      description: "近距视野与远程雷达信号",
    },
    landFactory: {
      name: "陆军工厂",
      icon: "LF",
      cost: 620,
      time: 22,
      hp: 920,
      size: 76,
      supply: 8,
      vision: 310,
      produces: ["scout", "tank", "hover", "artillery", "aaTank"],
      upgrades: [
        {
          name: "陆军工厂 T2",
          cost: 900,
          time: 30,
          hp: 1220,
          supply: 14,
          vision: 360,
          produces: ["scout", "tank", "heavyTank", "hover", "heavyHover", "artillery", "aaTank", "missileTank", "laserTank", "repairTank", "shieldTank"],
        },
      ],
      description: "生产地面部队",
    },
    mechFactory: {
      name: "机甲工厂",
      icon: "MF",
      cost: 980,
      time: 30,
      hp: 980,
      size: 78,
      supply: 12,
      vision: 340,
      produces: ["combatEngineer", "minigunMech", "artilleryMech"],
      upgrades: [
        {
          name: "机甲工厂 T2",
          cost: 1250,
          time: 34,
          hp: 1280,
          supply: 18,
          vision: 410,
          produces: ["combatEngineer", "minigunMech", "artilleryMech", "plasmaMech", "teslaMech"],
        },
      ],
      description: "生产中后期机甲单位",
    },
    airFactory: {
      name: "空军工厂",
      icon: "AF",
      cost: 760,
      time: 26,
      hp: 780,
      size: 76,
      supply: 6,
      vision: 360,
      produces: ["spyDrone", "dropship", "gunship"],
      upgrades: [
        {
          name: "空军工厂 T2",
          cost: 980,
          time: 32,
          hp: 1020,
          supply: 12,
          vision: 430,
          produces: ["spyDrone", "dropship", "interceptor", "gunship", "heavyGunship", "bomber"],
        },
      ],
      description: "生产空中单位",
    },
    seaFactory: {
      name: "海军工厂",
      icon: "SF",
      cost: 680,
      time: 24,
      hp: 860,
      size: 78,
      supply: 6,
      vision: 360,
      produces: ["gunboat", "sub"],
      upgrades: [
        {
          name: "海军工厂 T2",
          cost: 900,
          time: 30,
          hp: 1150,
          supply: 12,
          vision: 430,
          produces: ["gunboat", "sub", "transportShip", "missileShip", "heavyAaShip", "battleship", "nautilus"],
        },
      ],
      waterBuilding: true,
      description: "在水域生产舰艇",
    },
    experimentalFactory: {
      name: "实验工厂",
      icon: "EF",
      cost: 1850,
      time: 42,
      hp: 1250,
      size: 84,
      supply: 16,
      vision: 390,
      produces: ["experimental", "experimentalTank", "spider"],
      description: "生产终局实验单位",
    },
    turret: {
      name: "机枪炮塔",
      icon: "TR",
      cost: 330,
      time: 13,
      hp: 620,
      size: 44,
      vision: 330,
      weapon: { range: 260, damage: 20, reload: 0.55, speed: 760, canGround: true },
      upgrades: [
        {
          name: "机枪炮塔 T2",
          cost: 520,
          time: 18,
          hp: 860,
          vision: 380,
          weapon: { range: 315, damage: 30, reload: 0.46, speed: 820, canGround: true },
        },
      ],
      description: "地面防御",
    },
    aaTurret: {
      name: "防空塔",
      icon: "AT",
      cost: 360,
      time: 14,
      hp: 560,
      size: 44,
      vision: 420,
      weapon: {
        range: 360,
        damage: 22,
        reload: 0.58,
        speed: 820,
        canAir: true,
        canGround: false,
      },
      upgrades: [
        {
          name: "防空塔 T2",
          cost: 560,
          time: 18,
          hp: 760,
          vision: 480,
          weapon: { range: 440, damage: 31, reload: 0.48, speed: 900, canAir: true, canGround: false },
        },
      ],
      description: "空中防御",
    },
    laserDefence: {
      name: "激光防御",
      icon: "LD",
      cost: 720,
      time: 24,
      hp: 620,
      size: 52,
      vision: 360,
      shield: { range: 255, energy: 220, maxEnergy: 220, regen: 18, costPerDamage: 0.9 },
      upgrades: [
        {
          name: "激光防御 T2",
          cost: 880,
          time: 26,
          hp: 820,
          vision: 420,
          shield: { range: 330, energy: 380, maxEnergy: 380, regen: 28, costPerDamage: 0.75 },
        },
      ],
      description: "拦截炮弹与导弹",
    },
    repairBay: {
      name: "维修平台",
      icon: "RP",
      cost: 440,
      time: 17,
      hp: 520,
      size: 58,
      vision: 260,
      repairAura: 155,
      description: "自动维修附近友军",
    },
    nukeLauncher: {
      name: "核弹发射井",
      icon: "NK",
      cost: 1450,
      time: 36,
      hp: 920,
      size: 68,
      vision: 370,
      nuke: true,
      description: "制造并发射核弹",
    },
    antiNuke: {
      name: "反核防御",
      icon: "AN",
      cost: 1250,
      time: 34,
      hp: 820,
      size: 62,
      vision: 430,
      antiNuke: { range: 980, ammoMax: 4, buildCost: 720, buildTime: 22 },
      description: "制造拦截弹并自动反核",
    },
  };

  const buildMenu = [
    "extractor",
    "fabricator",
    "radar",
    "landFactory",
    "mechFactory",
    "airFactory",
    "seaFactory",
    "experimentalFactory",
    "turret",
    "aaTurret",
    "laserDefence",
    "repairBay",
    "nukeLauncher",
    "antiNuke",
  ];

  const unitFactoryFor = {
    builder: "command",
    scout: "landFactory",
    tank: "landFactory",
    heavyTank: "landFactory",
    hover: "landFactory",
    heavyHover: "landFactory",
    artillery: "landFactory",
    aaTank: "landFactory",
    missileTank: "landFactory",
    laserTank: "landFactory",
    repairTank: "landFactory",
    shieldTank: "landFactory",
    combatEngineer: "mechFactory",
    minigunMech: "mechFactory",
    artilleryMech: "mechFactory",
    plasmaMech: "mechFactory",
    teslaMech: "mechFactory",
    experimental: "experimentalFactory",
    experimentalTank: "experimentalFactory",
    spider: "experimentalFactory",
    spyDrone: "airFactory",
    dropship: "airFactory",
    interceptor: "airFactory",
    gunship: "airFactory",
    heavyGunship: "airFactory",
    bomber: "airFactory",
    gunboat: "seaFactory",
    transportShip: "seaFactory",
    sub: "seaFactory",
    missileShip: "seaFactory",
    heavyAaShip: "seaFactory",
    battleship: "seaFactory",
    nautilus: "seaFactory",
  };

  const sandboxDefaultType = "unit:tank";

  let dpr = 1;
  let viewW = 1;
  let viewH = 1;
  let terrainCanvas = null;
  let lastTime = performance.now();
  let uiDirty = true;
  let uiClock = 0;
  let idSeq = 1;
  let state = null;
  let preferredAiDifficulty = "normal";

  const camera = {
    x: 820,
    y: 2020,
    zoom: 0.72,
    targetZoom: 0.72,
  };

  const input = {
    mouseX: 0,
    mouseY: 0,
    worldX: 0,
    worldY: 0,
    downX: 0,
    downY: 0,
    downWorldX: 0,
    downWorldY: 0,
    isDown: false,
    dragSelect: false,
    pan: false,
    shift: false,
    keys: new Set(),
    buildMode: null,
    attackMove: false,
    patrolMode: false,
    guardMode: false,
    reclaimMode: false,
    nukeSourceId: null,
    unloadTransportIds: null,
    blinkUnitIds: null,
    lastClickTime: 0,
  };

  let selectedIds = new Set();
  const controlGroups = new Map();

  function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
  }

  function finiteOr(value, fallback) {
    const number = Number(value);
    return Number.isFinite(number) ? number : fallback;
  }

  function dist(a, b, c, d) {
    const dx = a - c;
    const dy = b - d;
    return Math.hypot(dx, dy);
  }

  function dist2(a, b, c, d) {
    const dx = a - c;
    const dy = b - d;
    return dx * dx + dy * dy;
  }

  function angleTo(a, b, c, d) {
    return Math.atan2(d - b, c - a);
  }

  function lerp(a, b, t) {
    return a + (b - a) * t;
  }

  function rectsOverlap(ax, ay, aw, ah, bx, by, bw, bh) {
    return ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by;
  }

  function nextId() {
    const id = idSeq;
    idSeq += 1;
    return id;
  }

  function createStats() {
    return {
      sampleClock: 0,
      history: [],
      kills: { [TEAM_PLAYER]: 0, [TEAM_ENEMY]: 0 },
      losses: { [TEAM_PLAYER]: 0, [TEAM_ENEMY]: 0 },
      unitsBuilt: { [TEAM_PLAYER]: 0, [TEAM_ENEMY]: 0 },
      buildingsBuilt: { [TEAM_PLAYER]: 0, [TEAM_ENEMY]: 0 },
      damageDone: { [TEAM_PLAYER]: 0, [TEAM_ENEMY]: 0 },
      shieldBlocked: { [TEAM_PLAYER]: 0, [TEAM_ENEMY]: 0 },
    };
  }

  function ensureStats() {
    if (!state) return null;
    const fresh = createStats();
    state.stats ||= fresh;
    for (const key of ["kills", "losses", "unitsBuilt", "buildingsBuilt", "damageDone", "shieldBlocked"]) {
      state.stats[key] ||= {};
      state.stats[key][TEAM_PLAYER] ??= 0;
      state.stats[key][TEAM_ENEMY] ??= 0;
    }
    state.stats.history ||= [];
    state.stats.sampleClock ??= 0;
    return state.stats;
  }

  function readAiPreference() {
    try {
      const value = localStorage.getItem(AI_PREF_KEY);
      return aiDifficulties[value] ? value : "normal";
    } catch (error) {
      return "normal";
    }
  }

  function writeAiPreference(value) {
    try {
      localStorage.setItem(AI_PREF_KEY, value);
    } catch (error) {
      // Preference persistence is optional; the current match still updates.
    }
  }

  function aiProfile() {
    const key = state?.ai?.difficulty || preferredAiDifficulty || "normal";
    return aiDifficulties[key] || aiDifficulties.normal;
  }

  function aiIncomeMultiplier(mode = state?.mode || "skirmish") {
    const modeFactor = mode === "campaign" ? 0.69 : mode === "survival" ? 0.7 : 1;
    return aiProfile().income * modeFactor;
  }

  function syncAiDifficulty() {
    if (!state?.ai) return;
    if (!aiDifficulties[state.ai.difficulty]) state.ai.difficulty = preferredAiDifficulty;
    state.ai.difficultyIncome = aiIncomeMultiplier(state.mode);
  }

  function normalizeMapKey(key) {
    return mapPresets[key] ? key : "coast";
  }

  function currentMap() {
    return mapPresets[normalizeMapKey(state?.mapKey || selectedMapKey)];
  }

  function mapLabel(key = selectedMapKey) {
    return mapPresets[normalizeMapKey(key)].label;
  }

  function createSandboxState() {
    return {
      tool: "place",
      team: TEAM_PLAYER,
      type: sandboxDefaultType,
      combat: false,
      reveal: true,
    };
  }

  function ensureSandbox() {
    if (!state) return null;
    state.sandbox ||= createSandboxState();
    state.sandbox.tool = ["select", "place", "erase"].includes(state.sandbox.tool) ? state.sandbox.tool : "place";
    state.sandbox.team = Number(state.sandbox.team) === TEAM_ENEMY ? TEAM_ENEMY : TEAM_PLAYER;
    if (!isSandboxType(state.sandbox.type)) state.sandbox.type = sandboxDefaultType;
    state.sandbox.combat = Boolean(state.sandbox.combat);
    state.sandbox.reveal = state.sandbox.reveal !== false;
    return state.sandbox;
  }

  function isSandboxType(value) {
    if (!value || typeof value !== "string" || !value.includes(":")) return false;
    const [kind, type] = value.split(":");
    return (kind === "unit" && Boolean(unitTypes[type])) || (kind === "building" && Boolean(buildingTypes[type]));
  }

  function terrainAt(x, y) {
    if (!state || !state.terrain) return "grass";
    const cx = clamp(Math.floor(x / TILE), 0, state.terrain.cols - 1);
    const cy = clamp(Math.floor(y / TILE), 0, state.terrain.rows - 1);
    return state.terrain.tiles[cy * state.terrain.cols + cx];
  }

  function terrainAllows(type, x, y) {
    const terrain = terrainAt(x, y);
    if (terrain === "lava") return false;
    if (type === "air") return true;
    if (type === "sea") return terrain === "water" || terrain === "deep";
    if (type === "hover") return terrain !== "deep";
    return terrain !== "water" && terrain !== "deep";
  }

  function isWater(x, y) {
    const t = terrainAt(x, y);
    return t === "water" || t === "deep";
  }

  function isBlockedForBuilding(x, y, size, buildingKey) {
    const half = size / 2 + BUILD_PAD;
    const wantWater = buildingTypes[buildingKey].waterBuilding;
    const sample = [
      [x, y],
      [x - half, y - half],
      [x + half, y - half],
      [x - half, y + half],
      [x + half, y + half],
    ];

    for (const [sx, sy] of sample) {
      if (sx < 0 || sy < 0 || sx > MAP_W || sy > MAP_H) return true;
      const water = isWater(sx, sy);
      if (wantWater && !water) return true;
      if (!wantWater && water) return true;
      if (terrainAt(sx, sy) === "lava") return true;
    }

    for (const b of state.buildings) {
      if (b.dead) continue;
      const bh = buildingTypes[b.type].size / 2;
      if (rectsOverlap(x - half, y - half, half * 2, half * 2, b.x - bh, b.y - bh, bh * 2, bh * 2)) {
        return true;
      }
    }
    return false;
  }

  function worldToScreen(x, y) {
    return {
      x: (x - camera.x) * camera.zoom + viewW / 2,
      y: (y - camera.y) * camera.zoom + viewH / 2,
    };
  }

  function screenToWorld(x, y) {
    return {
      x: (x - viewW / 2) / camera.zoom + camera.x,
      y: (y - viewH / 2) / camera.zoom + camera.y,
    };
  }

  function getViewportWorldRect() {
    return {
      x: camera.x - viewW / (2 * camera.zoom),
      y: camera.y - viewH / (2 * camera.zoom),
      w: viewW / camera.zoom,
      h: viewH / camera.zoom,
    };
  }

  function resize() {
    dpr = Math.max(1, Math.min(2.5, window.devicePixelRatio || 1));
    viewW = Math.max(1, canvas.clientWidth);
    viewH = Math.max(1, canvas.clientHeight);
    canvas.width = Math.round(viewW * dpr);
    canvas.height = Math.round(viewH * dpr);
    ctx.imageSmoothingEnabled = false;
    clampCamera();
  }

  function clampCamera() {
    const halfW = viewW / (2 * camera.zoom);
    const halfH = viewH / (2 * camera.zoom);
    camera.x = clamp(camera.x, halfW, MAP_W - halfW);
    camera.y = clamp(camera.y, halfH, MAP_H - halfH);
  }

  function terrainForCell(cx, cy, map) {
    const x = cx * TILE + TILE / 2;
    const y = cy * TILE + TILE / 2;

    for (const [rx, ry] of map.resources) {
      if (dist2(x, y, rx, ry) < 95 * 95) return "rock";
    }

    const playerBase = dist2(x, y, map.playerBase.x, map.playerBase.y) < 420 * 420;
    const enemyBase = dist2(x, y, map.enemyBase.x, map.enemyBase.y) < 420 * 420;
    if (playerBase || enemyBase) return ((cx + cy) % 5 === 0 ? "dirt" : "grass2");

    if (map === mapPresets.islands) {
      const land =
        ((x - map.playerBase.x) / 760) ** 2 + ((y - map.playerBase.y) / 520) ** 2 < 1 ||
        ((x - map.enemyBase.x) / 730) ** 2 + ((y - map.enemyBase.y) / 500) ** 2 < 1 ||
        ((x - 1840) / 520) ** 2 + ((y - 2120) / 330) ** 2 < 1 ||
        ((x - 2300) / 500) ** 2 + ((y - 1190) / 320) ** 2 < 1 ||
        ((x - 2940) / 430) ** 2 + ((y - 1600) / 280) ** 2 < 1 ||
        ((x - 1260) / 360) ** 2 + ((y - 1480) / 260) ** 2 < 1;
      if (!land) {
        const deep = ((x - 2250) / 1280) ** 2 + ((y - 1420) / 760) ** 2 < 1;
        return deep ? "deep" : "water";
      }
      const n = Math.sin(cx * 0.88 + cy * 1.21) + Math.sin(cx * 1.6 - cy * 0.71) * 0.45;
      if (n > 1.08) return "rock";
      if (n < -0.95) return "sand";
      return (cx + cy * 2) % 9 === 0 ? "dirt" : "grass";
    }

    if (map === mapPresets.lava) {
      const lavaRiver =
        Math.abs(x - (610 + y * 0.64 + Math.sin(y * 0.008) * 95)) < 125 ||
        Math.abs(x - (2820 - y * 0.38 + Math.sin(y * 0.01) * 120)) < 115;
      const lavaPool =
        ((x - 420) / 300) ** 2 + ((y - 940) / 700) ** 2 < 1 ||
        ((x - 3100) / 360) ** 2 + ((y - 450) / 320) ** 2 < 1;
      if ((lavaRiver || lavaPool) && !playerBase && !enemyBase) return "lava";
      const lake = ((x - 2340) / 500) ** 2 + ((y - 1680) / 280) ** 2 < 1;
      if (lake) return "water";
      const n = Math.sin(cx * 0.82 + cy * 1.5) + Math.sin(cx * 1.7 - cy * 0.62) * 0.5;
      if (n > 0.92) return "rock";
      if (n < -1.0) return "sand";
      return (cx + cy * 4) % 10 === 0 ? "dirt" : "grass2";
    }

    const lake =
      ((x - 2220) / 720) ** 2 + ((y - 1260) / 430) ** 2 < 1 ||
      ((x - 2870) / 500) ** 2 + ((y - 1720) / 310) ** 2 < 1 ||
      ((x - 1120) / 520) ** 2 + ((y - 2500) / 300) ** 2 < 1;
    const deep = ((x - 2350) / 450) ** 2 + ((y - 1280) / 250) ** 2 < 1;
    const lava =
      x < 620 + Math.sin(y * 0.009) * 70 &&
      y > 280 &&
      y < 1580 &&
      ((x - 280) / 280) ** 2 + ((y - 930) / 700) ** 2 < 1.25;

    if (lava) return "lava";
    if (deep) return "deep";
    if (lake) return "water";

    const n = Math.sin(cx * 0.73 + cy * 1.82) + Math.sin(cx * 1.9 - cy * 0.66) * 0.5;
    if (n > 1.05) return "rock";
    if (n < -1.05) return "sand";
    if ((cx + cy * 3) % 11 === 0) return "dirt";
    return (cx + cy) % 2 === 0 ? "grass" : "grass2";
  }

  function generateTerrain(map) {
    const cols = Math.ceil(MAP_W / TILE);
    const rows = Math.ceil(MAP_H / TILE);
    const tiles = new Array(cols * rows);
    for (let y = 0; y < rows; y += 1) {
      for (let x = 0; x < cols; x += 1) {
        tiles[y * cols + x] = terrainForCell(x, y, map);
      }
    }
    return { cols, rows, tiles };
  }

  function rebuildTerrainCanvas() {
    terrainCanvas = document.createElement("canvas");
    terrainCanvas.width = MAP_W;
    terrainCanvas.height = MAP_H;
    const tctx = terrainCanvas.getContext("2d");
    tctx.imageSmoothingEnabled = false;

    for (let y = 0; y < state.terrain.rows; y += 1) {
      for (let x = 0; x < state.terrain.cols; x += 1) {
        const kind = state.terrain.tiles[y * state.terrain.cols + x];
        const px = x * TILE;
        const py = y * TILE;
        tctx.fillStyle = terrainColors[kind];
        tctx.fillRect(px, py, TILE, TILE);

        const shade = ((x * 17 + y * 31) % 9) - 4;
        if (shade !== 0) {
          tctx.fillStyle = shade > 0 ? "rgba(255,255,255,0.035)" : "rgba(0,0,0,0.045)";
          tctx.fillRect(px, py, TILE, TILE);
        }

        if (kind === "water" || kind === "deep") {
          tctx.fillStyle = "rgba(255,255,255,0.08)";
          const wave = ((x * 13 + y * 7) % 29) / 29;
          tctx.fillRect(px + 5 + wave * 8, py + 17, 20, 2);
          tctx.fillRect(px + 19, py + 30 + wave * 5, 16, 2);
        }

        if (kind === "rock") {
          tctx.fillStyle = "rgba(20,20,20,0.18)";
          tctx.fillRect(px + 10, py + 9, 13, 8);
          tctx.fillRect(px + 24, py + 25, 10, 7);
        }
      }
    }

    tctx.strokeStyle = "rgba(20,25,20,0.18)";
    tctx.lineWidth = 2;
    for (let y = 0; y < MAP_H; y += TILE * 2) {
      tctx.beginPath();
      tctx.moveTo(0, y + 0.5);
      tctx.lineTo(MAP_W, y + 0.5);
      tctx.stroke();
    }

    drawCliffLines(tctx);
  }

  function drawCliffLines(target) {
    target.save();
    target.strokeStyle = "rgba(38, 36, 35, 0.48)";
    target.lineWidth = 9;
    target.lineJoin = "round";
    target.beginPath();
    target.moveTo(1280, 1280);
    target.bezierCurveTo(1420, 1080, 1530, 950, 1780, 900);
    target.bezierCurveTo(1810, 1120, 1710, 1330, 1530, 1460);
    target.stroke();

    target.strokeStyle = "rgba(205, 177, 145, 0.35)";
    target.lineWidth = 4;
    target.beginPath();
    target.moveTo(1300, 1256);
    target.bezierCurveTo(1430, 1070, 1540, 970, 1760, 930);
    target.stroke();

    target.strokeStyle = "rgba(38, 36, 35, 0.42)";
    target.lineWidth = 8;
    target.beginPath();
    target.moveTo(3140, 1210);
    target.bezierCurveTo(3300, 1130, 3420, 1030, 3540, 860);
    target.stroke();
    target.restore();
  }

  function createResources(map) {
    return map.resources.map(([x, y], index) => ({
      id: `node-${index}`,
      x,
      y,
      radius: 32,
      claimedBy: null,
      richness: 1,
    }));
  }

  function createBuilding(type, team, x, y, complete = true) {
    const def = buildingTypes[type];
    const building = {
      id: nextId(),
      kind: "building",
      type,
      team,
      x,
      y,
      hp: complete ? def.hp : Math.max(30, def.hp * 0.08),
      maxHp: def.hp,
      buildProgress: complete ? 1 : 0.02,
      buildTime: def.time,
      level: 1,
      queue: [],
      rally: { x: x + (team === TEAM_PLAYER ? 110 : -110), y },
      repeatUnit: null,
      reload: 0,
      targetId: null,
      ammo: 0,
      shieldEnergy: def.shield ? def.shield.energy : 0,
      interceptorAmmo: def.antiNuke ? Math.min(1, def.antiNuke.ammoMax) : 0,
      dead: false,
      nodeId: null,
    };
    if (state.stats) state.stats.buildingsBuilt[team] = (state.stats.buildingsBuilt[team] || 0) + 1;
    if (type === "extractor") {
      const node = nearestResource(x, y, 80);
      if (node) {
        node.claimedBy = team;
        building.nodeId = node.id;
      }
    }
    state.buildings.push(building);
    return building;
  }

  function createUnit(type, team, x, y, order = null) {
    const def = unitTypes[type];
    const unit = {
      id: nextId(),
      kind: "unit",
      type,
      team,
      x,
      y,
      hp: def.hp,
      maxHp: def.hp,
      shield: def.shield || 0,
      maxShield: def.shield || 0,
      shieldEnergy: def.shieldEmitter ? def.shieldEmitter.energy : 0,
      order,
      orderQueue: [],
      reload: 0,
      targetId: null,
      stance: UNIT_STANCE_DEFAULT,
      moveAngle: 0,
      stuckClock: 0,
      cargoIds: def.transportCapacity ? [] : null,
      carriedBy: null,
      interceptorAmmo: def.antiNuke ? Math.min(1, def.antiNuke.ammoMax) : 0,
      interceptorBuild: 0,
      deployCooldown: 0,
      speedBoost: 0,
      speedCooldown: 0,
      blinkCooldown: 0,
      dead: false,
    };
    state.units.push(unit);
    if (state.stats) state.stats.unitsBuilt[team] = (state.stats.unitsBuilt[team] || 0) + 1;
    return unit;
  }

  function createProjectile(source, target, weapon, kind = "shell") {
    if (!target || target.dead) return;
    const tx = target.x;
    const ty = target.y;
    const speed = weapon.speed || 520;
    const travel = dist(source.x, source.y, tx, ty) / speed;
    state.projectiles.push({
      id: nextId(),
      team: source.team,
      x: source.x,
      y: source.y,
      sx: source.x,
      sy: source.y,
      tx,
      ty,
      targetId: target.id,
      damage: weapon.damage,
      aoe: weapon.aoe || 0,
      chain: weapon.chain || 0,
      chainRange: weapon.chainRange || 0,
      chainFalloff: weapon.chainFalloff || 0.6,
      canAir: Boolean(weapon.canAir),
      canGround: weapon.canGround !== false,
      canSea: Boolean(weapon.canSea),
      speed,
      age: 0,
      travel: Math.max(0.05, travel),
      kind,
      dead: false,
    });
  }

  function createNuke(source, x, y) {
    state.projectiles.push({
      id: nextId(),
      team: source.team,
      x: source.x,
      y: source.y,
      sx: source.x,
      sy: source.y,
      tx: x,
      ty: y,
      damage: 780,
      aoe: 310,
      speed: 240,
      age: 0,
      travel: Math.max(1.8, dist(source.x, source.y, x, y) / 240),
      kind: "nuke",
      dead: false,
    });
  }

  function addParticle(x, y, color, count = 8, scale = 1) {
    for (let i = 0; i < count; i += 1) {
      const a = Math.random() * Math.PI * 2;
      const s = (30 + Math.random() * 95) * scale;
      state.particles.push({
        x,
        y,
        vx: Math.cos(a) * s,
        vy: Math.sin(a) * s,
        life: 0.45 + Math.random() * 0.8 * scale,
        maxLife: 0.45 + Math.random() * 0.8 * scale,
        color,
        size: 2 + Math.random() * 4 * scale,
      });
    }
  }

  function initGame(mode = "skirmish") {
    idSeq = 1;
    selectedIds = new Set();
    const difficulty = aiDifficulties[preferredAiDifficulty] ? preferredAiDifficulty : "normal";
    selectedMapKey = normalizeMapKey(selectedMapKey);
    const map = mapPresets[selectedMapKey];
    state = {
      mapKey: selectedMapKey,
      terrain: generateTerrain(map),
      resources: createResources(map),
      units: [],
      buildings: [],
      projectiles: [],
      particles: [],
      wrecks: [],
      messages: [],
      metal: {
        [TEAM_PLAYER]: 1050,
        [TEAM_ENEMY]: 1120,
      },
      elapsed: 0,
      mode,
      challenge: {
        timer: 0,
        targetIds: [],
      },
      campaign: {
        stage: 0,
        frontTurretId: null,
        enemyCommandId: null,
      },
      paused: false,
      speed: 1,
      gameOver: null,
      ai: {
        difficulty,
        buildClock: 0,
        trainClock: 0,
        attackClock: 28,
        scoutClock: 16,
        reclaimClock: 2.5,
        survivalClock: 40,
        survivalWave: 0,
        difficultyIncome: 1,
      },
      stats: createStats(),
      sandbox: createSandboxState(),
      fog: createFog(),
    };
    if (mode !== "sandbox") state.sandbox.reveal = false;
    syncAiDifficulty();
    rebuildTerrainCanvas();

    const pCommand = createBuilding("command", TEAM_PLAYER, map.playerBase.x, map.playerBase.y);
    createBuilding("extractor", TEAM_PLAYER, map.player.extractor[0], map.player.extractor[1]);
    createBuilding("landFactory", TEAM_PLAYER, map.player.factory[0], map.player.factory[1]);
    for (const [x, y, tx, ty] of map.player.builders) createUnit("builder", TEAM_PLAYER, x, y, { type: "move", x: tx, y: ty });
    for (const [type, x, y] of map.player.units) createUnit(type, TEAM_PLAYER, x, y);
    pCommand.rally = { ...map.playerRally };

    const eCommand = createBuilding("command", TEAM_ENEMY, map.enemyBase.x, map.enemyBase.y);
    const [enemyExtractorA, enemyExtractorB] = map.enemy.extractors;
    const eExtractorA = createBuilding("extractor", TEAM_ENEMY, enemyExtractorA[0], enemyExtractorA[1]);
    const eExtractorB = createBuilding("extractor", TEAM_ENEMY, enemyExtractorB[0], enemyExtractorB[1]);
    createBuilding("landFactory", TEAM_ENEMY, map.enemy.factory[0], map.enemy.factory[1]);
    const eFrontTurret = createBuilding("turret", TEAM_ENEMY, map.enemy.frontTurret[0], map.enemy.frontTurret[1]);
    createUnit("builder", TEAM_ENEMY, map.enemy.builder[0], map.enemy.builder[1]);
    for (const [type, x, y] of map.enemy.units) createUnit(type, TEAM_ENEMY, x, y);
    eCommand.rally = { ...map.enemyRally };

    if (mode === "campaign") {
      state.campaign.frontTurretId = eFrontTurret.id;
      state.campaign.enemyCommandId = eCommand.id;
      createBuilding("fabricator", TEAM_PLAYER, map.player.campaignFabricator[0], map.player.campaignFabricator[1]);
      createUnit("tank", TEAM_PLAYER, map.player.campaignTank[0], map.player.campaignTank[1]);
      state.metal[TEAM_PLAYER] = 1200;
      state.metal[TEAM_ENEMY] = 820;
      state.ai.attackClock = 78;
      state.ai.scoutClock = 28;
      syncAiDifficulty();
    }

    if (mode === "challenge") {
      const eExtractorC = createBuilding("extractor", TEAM_ENEMY, map.enemy.challengeExtractor[0], map.enemy.challengeExtractor[1]);
      for (const [type, point] of Object.entries(map.enemy.challengeDefences)) createBuilding(type, TEAM_ENEMY, point[0], point[1]);
      for (const [type, x, y] of map.enemy.challengeUnits) createUnit(type, TEAM_ENEMY, x, y);
      state.challenge.timer = 420;
      state.challenge.targetIds = [eExtractorA.id, eExtractorB.id, eExtractorC.id];
    }

    camera.x = map.camera.x;
    camera.y = map.camera.y;
    camera.zoom = map.camera.zoom;
    camera.targetZoom = map.camera.zoom;
    updateFog(true);
    if (mode === "campaign") {
      addMessage(`战役 01：${map.label}，建立资源网络并推平红方基地。`, "info");
    } else if (mode === "survival") {
      state.metal[TEAM_PLAYER] = 1350;
      state.metal[TEAM_ENEMY] = 900;
      state.ai.attackClock = 999;
      state.ai.survivalClock = 34;
      syncAiDifficulty();
      addMessage(`生存模式：${map.label}，抵挡越来越强的红方波次。`, "warn");
    } else if (mode === "challenge") {
      state.metal[TEAM_PLAYER] = 1600;
      state.metal[TEAM_ENEMY] = 1250;
      state.ai.attackClock = 42;
      addMessage(`挑战模式：${map.label}，7 分钟内摧毁 3 座红方采集器。`, "warn");
    } else if (mode === "sandbox") {
      state.metal[TEAM_PLAYER] = 12000;
      state.metal[TEAM_ENEMY] = 12000;
      state.sandbox.combat = false;
      state.sandbox.reveal = true;
      state.ai.attackClock = 999;
      revealMap();
      addMessage(`沙盒编辑器：${map.label}，选择对象后左键放置，右键删除。`, "info");
    } else {
      addMessage(`开局：${map.label}，占领资源点，扩张工厂，组织进攻。`, "info");
    }
    sampleStats(true);
    if (state.mode === "sandbox" && state.sandbox.reveal) revealMap();
    addMessage("右键移动/攻击，滚轮战略缩放，WASD 平移。", "info");
    updatePlaceHint();
    markUiDirty();
  }

  function createFog() {
    const cols = Math.ceil(MAP_W / FOG);
    const rows = Math.ceil(MAP_H / FOG);
    return {
      cols,
      rows,
      status: new Array(cols * rows).fill(0),
      clock: 0,
    };
  }

  function revealMap() {
    if (!state?.fog) return;
    state.fog.status.fill(2);
    state.fog.clock = 0.4;
  }

  function allEntities() {
    return [...state.units.filter((u) => !u.carriedBy), ...state.buildings];
  }

  function getUnitById(id) {
    return state.units.find((u) => u.id === id && !u.dead) || null;
  }

  function getAnyUnitById(id) {
    return state.units.find((u) => u.id === id) || null;
  }

  function findEntity(id) {
    return state.units.find((u) => u.id === id && !u.dead && !u.carriedBy) || state.buildings.find((b) => b.id === id && !b.dead) || null;
  }

  function entityDef(entity) {
    return entity.kind === "unit" ? unitTypes[entity.type] : buildingTypes[entity.type];
  }

  function entityRadius(entity) {
    if (entity.kind === "unit") return unitTypes[entity.type].radius;
    return (buildingCurrentDef(entity).size || buildingTypes[entity.type].size || 48) / 2;
  }

  function buildingLevel(building) {
    return Math.max(1, building.level || 1);
  }

  function buildingUpgradeDef(building, next = false) {
    const def = buildingTypes[building.type];
    if (!def.upgrades) return null;
    const index = buildingLevel(building) - 1 + (next ? 0 : -1);
    return def.upgrades[index] || null;
  }

  function buildingCurrentDef(building) {
    const base = buildingTypes[building.type];
    const upgrade = buildingUpgradeDef(building, false);
    return upgrade ? { ...base, ...upgrade, upgrades: base.upgrades, cost: base.cost, time: base.time } : base;
  }

  function buildingProduces(building) {
    const current = buildingCurrentDef(building);
    return current.produces || [];
  }

  function entityVision(entity) {
    if (entity.kind === "building") return buildingCurrentDef(entity).vision || 220;
    return unitTypes[entity.type].vision || 220;
  }

  function entityRadarRange(entity) {
    if (entity.kind !== "building" || entity.buildProgress < 1) return 0;
    const def = buildingCurrentDef(entity);
    return def.radar ? def.radarRange || def.vision || 0 : 0;
  }

  function entityWeapon(entity) {
    if (entity.kind === "building") return buildingCurrentDef(entity).weapon || null;
    return unitTypes[entity.type].weapon || null;
  }

  function entityAntiNukeDef(entity) {
    if (entity.kind === "building") return buildingCurrentDef(entity).antiNuke || null;
    return unitTypes[entity.type]?.antiNuke || null;
  }

  function nextUpgrade(building) {
    if (!building || building.kind !== "building") return null;
    return buildingUpgradeDef(building, true);
  }

  function canBuildWith(entity) {
    return entity && entity.kind === "unit" && Boolean(unitTypes[entity.type].buildPower);
  }

  function isTransportUnit(entity) {
    return entity && entity.kind === "unit" && Boolean(unitTypes[entity.type]?.transportCapacity);
  }

  function deployConfig(entity) {
    return entity && entity.kind === "unit" ? unitTypes[entity.type]?.deploys || null : null;
  }

  function transportCapacity(unit) {
    return unitTypes[unit.type]?.transportCapacity || 0;
  }

  function cargoSize(unit) {
    return unitTypes[unit.type]?.cargoSize || unitTypes[unit.type]?.supply || 1;
  }

  function cargoLoad(unit) {
    if (!isTransportUnit(unit)) return 0;
    return (unit.cargoIds || []).reduce((sum, id) => {
      const cargo = getUnitById(id);
      return cargo && cargo.carriedBy === unit.id ? sum + cargoSize(cargo) : sum;
    }, 0);
  }

  function canTransportUnit(transport, unit) {
    if (!isTransportUnit(transport) || !unit || unit.kind !== "unit") return false;
    if (transport.dead || unit.dead || unit.carriedBy || unit.id === transport.id || unit.team !== transport.team) return false;
    const def = unitTypes[unit.type];
    if (!def || def.domain === "air" || def.domain === "sea" || def.transportCapacity) return false;
    return cargoLoad(transport) + cargoSize(unit) <= transportCapacity(transport);
  }

  function nearestResource(x, y, maxDistance = Infinity) {
    let best = null;
    let bestD = maxDistance * maxDistance;
    for (const node of state.resources) {
      const d = dist2(x, y, node.x, node.y);
      if (d < bestD) {
        best = node;
        bestD = d;
      }
    }
    return best;
  }

  function nearestFreeResourceFor(team, x, y) {
    let best = null;
    let bestD = Infinity;
    for (const node of state.resources) {
      const claimedByLiving = extractorOnNode(node.id);
      if (claimedByLiving && claimedByLiving.team !== team) continue;
      if (claimedByLiving && claimedByLiving.team === team) continue;
      const d = dist2(x, y, node.x, node.y);
      if (d < bestD) {
        bestD = d;
        best = node;
      }
    }
    return best;
  }

  function extractorOnNode(nodeId) {
    return state.buildings.find((b) => !b.dead && b.type === "extractor" && b.nodeId === nodeId) || null;
  }

  function wreckSalvageValue(entity) {
    const def = entityDef(entity);
    const base = def.cost || (entity.kind === "building" ? 320 : 120);
    return Math.max(18, Math.round(base * 0.24));
  }

  function getWreckById(id) {
    return state.wrecks.find((w) => w.id === id && w.metal > 0 && w.ttl > 0) || null;
  }

  function nearestWreck(x, y, maxDistance = 80) {
    let best = null;
    let bestD = maxDistance * maxDistance;
    for (const wreck of state.wrecks) {
      if ((wreck.metal || 0) <= 0 || wreck.ttl <= 0) continue;
      const d = dist2(x, y, wreck.x, wreck.y);
      if (d < bestD) {
        best = wreck;
        bestD = d;
      }
    }
    return best;
  }

  function addMessage(text, tone = "info") {
    const line = {
      id: nextId(),
      text,
      tone,
      ttl: 8,
    };
    state.messages.unshift(line);
    state.messages = state.messages.slice(0, 5);
    renderFeed();
  }

  function renderFeed() {
    ui.feed.innerHTML = "";
    for (const msg of state.messages.slice(0, 4)) {
      const div = document.createElement("div");
      div.className = `feed-line ${msg.tone === "danger" ? "danger" : msg.tone === "warn" ? "warn" : ""}`;
      div.textContent = msg.text;
      ui.feed.appendChild(div);
    }
  }

  function markUiDirty() {
    uiDirty = true;
  }

  function currentSelection() {
    const out = [];
    for (const id of selectedIds) {
      const entity = findEntity(id);
      if (entity && (entity.team === TEAM_PLAYER || state.mode === "sandbox")) out.push(entity);
    }
    return out;
  }

  function selectEntities(entities, additive = false) {
    if (!additive) selectedIds = new Set();
    for (const entity of entities) {
      if (entity && (entity.team === TEAM_PLAYER || state.mode === "sandbox") && !entity.dead && !entity.carriedBy) selectedIds.add(entity.id);
    }
    markUiDirty();
  }

  function playerUnits() {
    return state.units.filter((u) => !u.dead && !u.carriedBy && u.team === TEAM_PLAYER);
  }

  function screenContains(entity) {
    const rect = getViewportWorldRect();
    const radius = entity.kind === "unit" ? unitTypes[entity.type].radius : buildingTypes[entity.type].size / 2;
    return entity.x + radius >= rect.x && entity.x - radius <= rect.x + rect.w && entity.y + radius >= rect.y && entity.y - radius <= rect.y + rect.h;
  }

  function isIdleBuilder(unit) {
    return canBuildWith(unit) && !unit.order && !unit.orderQueue?.length;
  }

  function isPlayerCombatUnit(unit) {
    return unit.team === TEAM_PLAYER && isCombatUnit(unit) && !canBuildWith(unit) && !isTransportUnit(unit);
  }

  function selectMacroGroup(kind) {
    let entities = [];
    if (kind === "idleBuilders") {
      entities = playerUnits().filter(isIdleBuilder);
    } else if (kind === "screenCombat") {
      entities = playerUnits().filter((u) => isPlayerCombatUnit(u) && screenContains(u));
    } else if (kind === "allCombat") {
      entities = playerUnits().filter(isPlayerCombatUnit);
    } else if (kind === "sameType") {
      const first = currentSelection().find((e) => e.kind === "unit" && e.team === TEAM_PLAYER);
      if (first) entities = playerUnits().filter((u) => u.type === first.type);
    }
    selectEntities(entities, false);
    const label = kind === "idleBuilders" ? "空闲工程单位" : kind === "screenCombat" ? "屏幕内作战单位" : kind === "sameType" ? "同类单位" : "全部作战单位";
    addMessage(entities.length ? `已选择 ${entities.length} 个${label}。` : `没有可选择的${label}。`, entities.length ? "info" : "warn");
    return entities.length;
  }

  function clearSelection() {
    selectedIds.clear();
    markUiDirty();
  }

  function getEntitiesInRect(x1, y1, x2, y2) {
    const left = Math.min(x1, x2);
    const right = Math.max(x1, x2);
    const top = Math.min(y1, y2);
    const bottom = Math.max(y1, y2);
    const units = state.units.filter(
      (u) =>
        !u.dead &&
        !u.carriedBy &&
        (u.team === TEAM_PLAYER || state.mode === "sandbox") &&
        u.x >= left &&
        u.x <= right &&
        u.y >= top &&
        u.y <= bottom,
    );
    if (units.length) return units;
    return state.buildings.filter((b) => {
      const size = buildingTypes[b.type].size / 2;
      return !b.dead && (b.team === TEAM_PLAYER || state.mode === "sandbox") && b.x + size >= left && b.x - size <= right && b.y + size >= top && b.y - size <= bottom;
    });
  }

  function topEntityAt(x, y, includeEnemy = true) {
    let best = null;
    let bestD = Infinity;
    for (const entity of allEntities()) {
      if (entity.dead) continue;
      if (!includeEnemy && entity.team !== TEAM_PLAYER) continue;
      if (entity.team === TEAM_ENEMY && !isVisibleAt(entity.x, entity.y)) continue;
      const def = entityDef(entity);
      const radius = entity.kind === "unit" ? def.radius + 7 : def.size / 2 + 4;
      const d = dist2(x, y, entity.x, entity.y);
      if (d < radius * radius && d < bestD) {
        best = entity;
        bestD = d;
      }
    }
    return best;
  }

  function selectionHas(predicate) {
    return currentSelection().some(predicate);
  }

  function canAfford(team, amount) {
    return state.metal[team] >= amount;
  }

  function spend(team, amount) {
    if (!canAfford(team, amount)) return false;
    state.metal[team] -= amount;
    return true;
  }

  function teamSupply(team) {
    let used = 0;
    let cap = 0;
    for (const b of state.buildings) {
      if (b.dead || b.team !== team || b.buildProgress < 1) continue;
      cap += buildingCurrentDef(b).supply || 0;
    }
    for (const u of state.units) {
      if (u.dead || u.team !== team) continue;
      used += unitTypes[u.type].supply || 0;
    }
    return { used, cap: Math.max(cap, 1) };
  }

  function incomeFor(team) {
    let income = 0;
    for (const b of state.buildings) {
      if (b.dead || b.team !== team || b.buildProgress < 1) continue;
      income += buildingCurrentDef(b).income || 0;
    }
    if (team === TEAM_ENEMY) income *= state.ai.difficultyIncome || aiIncomeMultiplier();
    return income;
  }

  function weaponPower(weapon) {
    if (!weapon) return 0;
    const dps = weapon.damage / Math.max(0.2, weapon.reload || 1);
    const aoe = weapon.aoe ? 1 + weapon.aoe / 140 : 1;
    const range = 0.65 + (weapon.range || 160) / 420;
    return dps * aoe * range;
  }

  function entityPower(entity) {
    if (entity.kind === "unit") {
      const def = unitTypes[entity.type];
      const health = entity.hp / 22 + (entity.shield || 0) / 30;
      const support = (def.repairAura ? def.repairPower * 1.2 : 0) + (def.shieldEmitter ? (entity.shieldEnergy || 0) / 12 : 0);
      const defence = def.antiNuke ? (entity.interceptorAmmo || 0) * 25 : 0;
      const utility = (def.transportCapacity ? def.transportCapacity * 3 : 0) + (def.deploys ? 18 : 0);
      return health + weaponPower(def.weapon) + support + defence + utility;
    }
    const def = buildingCurrentDef(entity);
    const health = entity.hp / 45;
    const economy = (def.income || 0) * 12 + (def.supply || 0) * 1.8;
    const defence = weaponPower(def.weapon) + (def.shield ? (entity.shieldEnergy || 0) / 9 : 0) + (def.antiNuke ? (entity.interceptorAmmo || 0) * 25 : 0);
    return health + economy + defence;
  }

  function teamSnapshot(team) {
    const liveUnits = state.units.filter((u) => !u.dead && u.team === team);
    const deployedUnits = liveUnits.filter((u) => !u.carriedBy);
    const liveBuildings = state.buildings.filter((b) => !b.dead && b.team === team);
    const completeBuildings = liveBuildings.filter((b) => b.buildProgress >= 1);
    const power = deployedUnits.reduce((sum, u) => sum + entityPower(u), 0) + completeBuildings.reduce((sum, b) => sum + entityPower(b), 0);
    const supply = teamSupply(team);
    return {
      units: liveUnits.length,
      deployedUnits: deployedUnits.length,
      buildings: liveBuildings.length,
      completeBuildings: completeBuildings.length,
      extractors: completeBuildings.filter((b) => b.type === "extractor").length,
      factories: completeBuildings.filter((b) => buildingProduces(b).length).length,
      combatUnits: deployedUnits.filter(isCombatUnit).length,
      supportUnits: deployedUnits.filter((u) => unitTypes[u.type].repairAura || unitTypes[u.type].shieldEmitter || isTransportUnit(u)).length,
      income: incomeFor(team),
      metal: state.metal[team] || 0,
      supplyUsed: supply.used,
      supplyCap: supply.cap,
      power,
    };
  }

  function sampleStats(force = false) {
    const stats = ensureStats();
    if (!stats) return;
    if (!force && stats.sampleClock > 0) return;
    stats.sampleClock = 4;
    const player = teamSnapshot(TEAM_PLAYER);
    const enemy = teamSnapshot(TEAM_ENEMY);
    stats.history.push({
      time: Math.floor(state.elapsed),
      playerPower: Math.round(player.power),
      enemyPower: Math.round(enemy.power),
      playerIncome: Number(player.income.toFixed(1)),
      enemyIncome: Number(enemy.income.toFixed(1)),
      playerUnits: player.units,
      enemyUnits: enemy.units,
    });
    if (stats.history.length > 120) stats.history.shift();
  }

  function updateStats(dt) {
    const stats = ensureStats();
    if (!stats) return;
    stats.sampleClock -= dt;
    sampleStats(false);
  }

  function toggleStatsPanel(force = null) {
    const show = force === null ? ui.statsPanel.hidden : Boolean(force);
    ui.statsPanel.hidden = !show;
    if (show) {
      sampleStats(true);
      renderStatsPanel();
    }
  }

  function renderStatsPanel() {
    if (ui.statsPanel.hidden || !state) return;
    ensureStats();
    drawStatsChart();
    const player = teamSnapshot(TEAM_PLAYER);
    const enemy = teamSnapshot(TEAM_ENEMY);
    const stats = state.stats;
    const rows = [
      ["AI 难度", aiProfile().label, "红方"],
      ["战力", Math.round(player.power), Math.round(enemy.power)],
      ["经济", `+${player.income.toFixed(1)}/s`, `+${enemy.income.toFixed(1)}/s`],
      ["资源", Math.floor(player.metal), Math.floor(enemy.metal)],
      ["单位", `${player.deployedUnits}/${player.units}`, `${enemy.deployedUnits}/${enemy.units}`],
      ["作战", player.combatUnits, enemy.combatUnits],
      ["支援", player.supportUnits, enemy.supportUnits],
      ["建筑", `${player.completeBuildings}/${player.buildings}`, `${enemy.completeBuildings}/${enemy.buildings}`],
      ["采集器", player.extractors, enemy.extractors],
      ["工厂", player.factories, enemy.factories],
      ["人口", `${player.supplyUsed}/${player.supplyCap}`, `${enemy.supplyUsed}/${enemy.supplyCap}`],
      ["部署", stats.unitsBuilt[TEAM_PLAYER], stats.unitsBuilt[TEAM_ENEMY]],
      ["建造", stats.buildingsBuilt[TEAM_PLAYER], stats.buildingsBuilt[TEAM_ENEMY]],
      ["击毁", stats.kills[TEAM_PLAYER], stats.kills[TEAM_ENEMY]],
      ["损失", stats.losses[TEAM_PLAYER], stats.losses[TEAM_ENEMY]],
      ["伤害", Math.floor(stats.damageDone[TEAM_PLAYER]), Math.floor(stats.damageDone[TEAM_ENEMY])],
      ["护盾吸收", Math.floor(stats.shieldBlocked[TEAM_PLAYER]), Math.floor(stats.shieldBlocked[TEAM_ENEMY])],
    ];
    ui.statsBody.innerHTML = rows
      .map(([label, playerValue, enemyValue]) => `<div><span>${label}</span><strong>${playerValue}</strong><strong>${enemyValue}</strong></div>`)
      .join("");
  }

  function drawStatsChart() {
    const w = ui.statsChart.width;
    const h = ui.statsChart.height;
    sctx.clearRect(0, 0, w, h);
    sctx.fillStyle = "rgba(4, 7, 8, 0.65)";
    sctx.fillRect(0, 0, w, h);
    sctx.strokeStyle = "rgba(255,255,255,0.08)";
    sctx.lineWidth = 1;
    for (let i = 1; i < 4; i += 1) {
      const y = (h * i) / 4;
      sctx.beginPath();
      sctx.moveTo(0, y);
      sctx.lineTo(w, y);
      sctx.stroke();
    }

    const history = state.stats.history;
    if (history.length < 2) {
      sctx.fillStyle = "rgba(238, 244, 240, 0.72)";
      sctx.font = "700 12px ui-sans-serif";
      sctx.fillText("统计采样中", 14, 24);
      return;
    }
    const maxPower = Math.max(40, ...history.map((p) => Math.max(p.playerPower, p.enemyPower)));
    drawStatsLine(history, "playerPower", maxPower, "#6dd072", w, h);
    drawStatsLine(history, "enemyPower", maxPower, "#ff6666", w, h);
    sctx.fillStyle = "#6dd072";
    sctx.fillRect(12, 12, 10, 3);
    sctx.fillStyle = "#eef4f0";
    sctx.font = "700 11px ui-sans-serif";
    sctx.fillText("玩家战力", 28, 16);
    sctx.fillStyle = "#ff6666";
    sctx.fillRect(104, 12, 10, 3);
    sctx.fillStyle = "#eef4f0";
    sctx.fillText("红方战力", 120, 16);
  }

  function drawStatsLine(history, key, maxPower, color, w, h) {
    sctx.strokeStyle = color;
    sctx.lineWidth = 2;
    sctx.beginPath();
    history.forEach((point, index) => {
      const x = history.length === 1 ? 0 : (index / (history.length - 1)) * (w - 18) + 9;
      const y = h - 12 - (point[key] / maxPower) * (h - 28);
      if (index === 0) sctx.moveTo(x, y);
      else sctx.lineTo(x, y);
    });
    sctx.stroke();
  }

  function isCombatUnit(entity) {
    return entity.kind === "unit" && Boolean(unitTypes[entity.type].weapon);
  }

  function normalizeUnitStance(stance) {
    return unitStances[stance] ? stance : UNIT_STANCE_DEFAULT;
  }

  function unitStance(unit) {
    return normalizeUnitStance(unit?.stance);
  }

  function unitStanceDef(unit) {
    return unitStances[unitStance(unit)];
  }

  function autoAcquireRange(attacker, range) {
    if (!attacker || attacker.kind !== "unit") return range;
    return range * unitStanceDef(attacker).autoRange;
  }

  function canAutoEngage(attacker, target, range) {
    const autoRange = autoAcquireRange(attacker, range);
    return autoRange > 0 && dist2(attacker.x, attacker.y, target.x, target.y) <= autoRange * autoRange;
  }

  function canContinueAutoAttackOrder(unit, target, range) {
    if (!unit.order?.auto || unitStance(unit) === "aggressive") return true;
    return canAutoEngage(unit, target, unit.order.leash || range);
  }

  function canAttack(attacker, target) {
    if (!attacker || !target || attacker.team === target.team) return false;
    const weapon = entityWeapon(attacker);
    if (!weapon) return false;
    const targetDomain = target.kind === "unit" ? unitTypes[target.type].domain : "ground";
    if (targetDomain === "air") return Boolean(weapon.canAir);
    if (targetDomain === "sea") return Boolean(weapon.canSea || weapon.canGround);
    return weapon.canGround !== false;
  }

  function isTargetableFor(attacker, target) {
    if (!canAttack(attacker, target)) return false;
    if (target.team === TEAM_ENEMY && attacker.team === TEAM_PLAYER && !isVisibleAt(target.x, target.y)) return false;
    return true;
  }

  function targetThreat(target) {
    const weapon = entityWeapon(target);
    const repair = target.kind === "unit" ? unitTypes[target.type].repairAura || unitTypes[target.type].repairPower || 0 : 0;
    const shield = target.kind === "unit" ? unitTypes[target.type].shieldEmitter?.maxEnergy || 0 : buildingCurrentDef(target).shield?.maxEnergy || 0;
    return weaponPower(weapon) + repair * 0.45 + shield * 0.05;
  }

  function targetPriorityScore(attacker, target, distanceSq, range) {
    const weapon = entityWeapon(attacker);
    const targetDef = entityDef(target);
    const targetDomain = target.kind === "unit" ? targetDef.domain : "ground";
    const distanceRatio = Math.sqrt(distanceSq) / Math.max(1, range);
    const hpPct = clamp(target.hp / Math.max(1, target.maxHp), 0, 1);
    let score = distanceRatio * 42;

    score -= targetThreat(target) * 1.8;
    score -= (1 - hpPct) * 34;
    if (target.kind === "building") score += 10;
    if (target.kind === "building" && target.type === "command") score -= 70;
    if (target.kind === "building" && target.type === "extractor") score -= 28;
    if (target.kind === "building" && buildingProduces(target).length) score -= 24;
    if (target.kind === "building" && (buildingCurrentDef(target).weapon || buildingCurrentDef(target).antiNuke || buildingCurrentDef(target).shield)) score -= 22;
    if (target.kind === "unit" && (targetDef.repairAura || targetDef.repairPower || targetDef.shieldEmitter)) score -= 20;
    if (target.kind === "unit" && targetDef.transportCapacity && target.cargoIds?.length) score -= 14 + target.cargoIds.length * 3;
    if (targetDomain === "air" && weapon?.canAir) score -= 18;
    if (targetDomain === "sea" && weapon?.canSea) score -= 12;
    if (weapon?.aoe && target.kind === "unit") score -= 8;
    if (weapon?.minRange && Math.sqrt(distanceSq) < weapon.minRange * 1.25) score += 45;
    return score;
  }

  function resumeAfterAttackOrder(unit) {
    const resume = unit.order?.resume;
    if (resume?.type === "patrol" || resume?.type === "guard") unit.order = resume;
    else if (resume) unit.order = { type: "attackMove", x: resume.x, y: resume.y };
    else unit.order = null;
    unit.targetId = null;
  }

  function selectedCombatUnits(selection = currentSelection()) {
    return selection.filter((entity) => entity.kind === "unit" && isCombatUnit(entity));
  }

  function setUnitStance(units, stance, announce = true) {
    const next = normalizeUnitStance(stance);
    let changed = 0;
    let eligible = 0;
    for (const unit of units) {
      if (!unit || unit.kind !== "unit" || !isCombatUnit(unit)) continue;
      eligible += 1;
      if (unit.stance !== next) changed += 1;
      unit.stance = next;
      if (unit.order?.type === "attack" && unit.order.auto && unitStances[next].autoRange <= 0) resumeAfterAttackOrder(unit);
      if (!(unit.order?.type === "attack" && !unit.order.auto)) unit.targetId = null;
    }
    if (announce && eligible) addMessage(`战斗姿态：${unitStances[next].label}。`, "info");
    if (changed || eligible) markUiDirty();
    return changed;
  }

  function stanceSummary(selection) {
    const combat = selectedCombatUnits(selection);
    if (!combat.length) return "";
    const stances = [...new Set(combat.map(unitStance))];
    return stances.length === 1 ? `姿态 ${unitStances[stances[0]].short}` : "姿态 混合";
  }

  function enqueueUnit(building, unitType) {
    if (building.team !== TEAM_PLAYER) return;
    if (queueUnitForProduction(building, unitType, true)) {
      addMessage(`${buildingTypes[building.type].name} 开始生产 ${unitTypes[unitType].name}。`, "info");
      markUiDirty();
    }
  }

  function queueUnitForProduction(building, unitType, announceFailure = false) {
    const unitDef = unitTypes[unitType];
    if (!unitDef || !buildingProduces(building).includes(unitType)) {
      if (announceFailure) addMessage("该工厂需要先升级。", "warn");
      return false;
    }
    const supply = teamSupply(building.team);
    if (supply.used + (unitDef.supply || 0) > supply.cap) {
      if (announceFailure) addMessage("人口容量不足，先扩张基地或工厂。", "warn");
      return false;
    }
    if (!spend(building.team, unitDef.cost)) {
      if (announceFailure) addMessage("资源不足。", "warn");
      return false;
    }
    building.queue.push({ kind: "unit", type: unitType, left: unitDef.time, total: unitDef.time });
    return true;
  }

  function setRepeatUnit(building, unitType) {
    if (!building || building.team !== TEAM_PLAYER || !buildingProduces(building).includes(unitType)) {
      addMessage("该工厂需要先升级。", "warn");
      return;
    }
    building.repeatUnit = building.repeatUnit === unitType ? null : unitType;
    addMessage(building.repeatUnit ? `重复生产：${unitTypes[unitType].name}。` : "重复生产已关闭。", building.repeatUnit ? "info" : "warn");
    markUiDirty();
  }

  function cycleRepeatUnit(building) {
    if (!building || building.team !== TEAM_PLAYER) return;
    const produces = buildingProduces(building).filter((type) => unitTypes[type]);
    if (!produces.length) return;
    const index = building.repeatUnit ? produces.indexOf(building.repeatUnit) : -1;
    const next = index < 0 ? produces[0] : index >= produces.length - 1 ? null : produces[index + 1];
    building.repeatUnit = next;
    addMessage(next ? `重复生产：${unitTypes[next].name}。` : "重复生产已关闭。", next ? "info" : "warn");
    markUiDirty();
  }

  function enqueueUpgrade(building) {
    const upgrade = nextUpgrade(building);
    if (!upgrade || building.team !== TEAM_PLAYER) return;
    if (building.queue.some((item) => item.kind === "upgrade")) {
      addMessage("升级已在队列中。", "warn");
      return;
    }
    if (!spend(building.team, upgrade.cost)) {
      addMessage("资源不足。", "warn");
      return;
    }
    building.queue.push({ kind: "upgrade", type: building.type, left: upgrade.time, total: upgrade.time, level: buildingLevel(building) + 1 });
    addMessage(`${buildingTypes[building.type].name} 开始升级到 T${buildingLevel(building) + 1}。`, "info");
    markUiDirty();
  }

  function enqueueNuke(building) {
    if (!buildingTypes[building.type].nuke || building.team !== TEAM_PLAYER) return;
    const cost = 1600;
    if (!spend(building.team, cost)) {
      addMessage("核弹制造需要 1600 资源。", "warn");
      return;
    }
    building.queue.push({ kind: "nuke", type: "nuke", left: 34, total: 34 });
    addMessage("核弹制造已加入队列。", "warn");
    markUiDirty();
  }

  function enqueueAntiNuke(building) {
    const def = buildingCurrentDef(building);
    if (!def.antiNuke || building.team !== TEAM_PLAYER) return;
    if ((building.interceptorAmmo || 0) >= def.antiNuke.ammoMax) {
      addMessage("反核拦截弹已满。", "warn");
      return;
    }
    if (!spend(building.team, def.antiNuke.buildCost)) {
      addMessage(`反核拦截弹需要 ${def.antiNuke.buildCost} 资源。`, "warn");
      return;
    }
    building.queue.push({ kind: "antiNuke", type: "antiNuke", left: def.antiNuke.buildTime, total: def.antiNuke.buildTime });
    addMessage("反核拦截弹制造已加入队列。", "info");
    markUiDirty();
  }

  function queueItemCost(building, item) {
    if (!item) return 0;
    if (item.kind === "unit") return unitTypes[item.type]?.cost || 0;
    if (item.kind === "upgrade") {
      const base = buildingTypes[item.type];
      return base?.upgrades?.[(item.level || buildingLevel(building) + 1) - 2]?.cost || 0;
    }
    if (item.kind === "nuke") return 1600;
    if (item.kind === "antiNuke") return buildingCurrentDef(building).antiNuke?.buildCost || 0;
    return 0;
  }

  function queueItemLabel(item) {
    if (!item) return "队列";
    if (item.kind === "unit") return unitTypes[item.type]?.name || "单位";
    if (item.kind === "upgrade") return `T${item.level || "?"} 升级`;
    if (item.kind === "nuke") return "核弹";
    if (item.kind === "antiNuke") return "反核拦截弹";
    return "队列项目";
  }

  function cancelLastQueueItem(building) {
    if (!building || building.kind !== "building" || building.team !== TEAM_PLAYER || !building.queue?.length) return;
    const originalLength = building.queue.length;
    const item = building.queue.pop();
    const cost = queueItemCost(building, item);
    const progress = originalLength === 1 && item.total ? clamp(1 - item.left / item.total, 0, 1) : 0;
    const refundRate = clamp(0.75 - progress * 0.45, 0.3, 0.75);
    const refund = Math.floor(cost * refundRate);
    state.metal[building.team] += refund;
    addMessage(`已取消 ${queueItemLabel(item)}，返还 ${refund} 资源。`, "info");
    markUiDirty();
  }

  function placeBuilding(type, x, y, team = TEAM_PLAYER, append = false) {
    const def = buildingTypes[type];
    if (!def) return false;
    const validation = validatePlacement(type, x, y, team, append);
    if (!validation.ok) {
      if (team === TEAM_PLAYER) addMessage(validation.reason, "warn");
      return false;
    }
    if (!spend(team, def.cost)) {
      if (team === TEAM_PLAYER) addMessage("资源不足。", "warn");
      return false;
    }

    const building = createBuilding(type, team, x, y, false);
    building.buildersAssigned = Math.max(1, currentSelection().filter(canBuildWith).length);
    if (team === TEAM_PLAYER) {
      for (const builder of currentSelection().filter(canBuildWith)) {
        assignUnitOrder(builder, { type: "build", targetId: building.id }, append);
      }
      addMessage(append ? `${def.name} 已加入建造队列。` : `${def.name} 建造开始。`, "info");
    } else {
      building.aiBuild = true;
    }
    if (!append) input.buildMode = null;
    updatePlaceHint();
    markUiDirty();
    return true;
  }

  function placeSandboxObject(x, y) {
    const sandbox = ensureSandbox();
    const [kind, type] = sandbox.type.split(":");
    if (kind === "unit") return placeSandboxUnit(type, sandbox.team, x, y);
    if (kind === "building") return placeSandboxBuilding(type, sandbox.team, x, y);
    return false;
  }

  function placeSandboxUnit(type, team, x, y) {
    const def = unitTypes[type];
    if (!def) return false;
    const seed = { type, x, y };
    const point = findReachablePoint(seed, x, y);
    const unit = createUnit(type, team, point.x, point.y);
    unit.moveAngle = team === TEAM_PLAYER ? 0 : Math.PI;
    selectedIds = new Set([unit.id]);
    addParticle(unit.x, unit.y, team === TEAM_PLAYER ? "rgba(105, 255, 145, 0.55)" : "rgba(255, 105, 105, 0.55)", 8, 0.55);
    sampleStats(true);
    markUiDirty();
    return true;
  }

  function placeSandboxBuilding(type, team, x, y) {
    const def = buildingTypes[type];
    if (!def) return false;
    const snap = snapBuild(type, x, y);
    const px = snap.x;
    const py = snap.y;
    if (def.requiresNode) {
      const node = nearestResource(px, py, 72);
      if (!node) {
        addMessage("沙盒：采集器仍需放在资源点上。", "warn");
        return false;
      }
    }
    if (isBlockedForBuilding(px, py, def.size, type)) {
      addMessage(def.waterBuilding ? "沙盒：海军工厂需要水域。" : "沙盒：位置被占用或地形不符。", "warn");
      return false;
    }
    const building = createBuilding(type, team, px, py, true);
    building.rally = { x: px + (team === TEAM_PLAYER ? 110 : -110), y: py };
    if (type === "antiNuke") building.interceptorAmmo = buildingCurrentDef(building).antiNuke.ammoMax;
    if (type === "nukeLauncher") building.ammo = 1;
    selectedIds = new Set([building.id]);
    addParticle(building.x, building.y, team === TEAM_PLAYER ? "rgba(105, 255, 145, 0.55)" : "rgba(255, 105, 105, 0.55)", 10, 0.65);
    sampleStats(true);
    markUiDirty();
    return true;
  }

  function eraseSandboxObject(x, y) {
    const target = topEntityAt(x, y, true);
    if (!target) return false;
    deleteSandboxEntity(target);
    sampleStats(true);
    markUiDirty();
    return true;
  }

  function deleteSandboxEntity(target) {
    if (!target || target.dead) return false;
    if (target.kind === "unit" && target.cargoIds?.length) unloadTransport(target, target.x, target.y);
    target.dead = true;
    selectedIds.delete(target.id);
    if (target.kind === "building" && target.type === "extractor" && target.nodeId) {
      const node = state.resources.find((n) => n.id === target.nodeId);
      if (node) node.claimedBy = null;
    }
    addParticle(target.x, target.y, "rgba(255, 210, 110, 0.55)", 8, 0.6);
    return true;
  }

  function builderPlanAnchor(builder) {
    let anchor = { x: builder.x, y: builder.y };
    for (const order of [builder.order, ...(builder.orderQueue || [])]) {
      const next = orderAnchor(order);
      if (next) anchor = next;
    }
    return anchor;
  }

  function validatePlacement(type, x, y, team, append = false) {
    const def = buildingTypes[type];
    if (!def) return { ok: false, reason: "未知建筑。" };

    if (def.requiresNode) {
      const node = nearestResource(x, y, 56);
      if (!node) return { ok: false, reason: "采集器必须放在资源点上。" };
      const extractor = extractorOnNode(node.id);
      if (extractor && extractor.team !== team) return { ok: false, reason: "该资源点已被敌方占据。" };
      if (extractor && extractor.team === team) return { ok: false, reason: "该资源点已经有采集器。" };
      x = node.x;
      y = node.y;
    }

    if (isBlockedForBuilding(x, y, def.size, type)) {
      return { ok: false, reason: def.waterBuilding ? "海军工厂需要放在水域。" : "该位置无法建造。" };
    }

    if (team === TEAM_PLAYER) {
      const builders = currentSelection().filter(canBuildWith);
      if (builders.length === 0) return { ok: false, reason: "需要选择工程车或实验蜘蛛。" };
      const near = builders.some((b) => {
        if (dist2(b.x, b.y, x, y) < 720 * 720) return true;
        if (!append) return false;
        const anchor = builderPlanAnchor(b);
        return dist2(anchor.x, anchor.y, x, y) < 720 * 720;
      });
      if (!near) return { ok: false, reason: "离工程车太远。" };
    }

    return { ok: true, reason: "" };
  }

  function unitOrderTargetId(order) {
    return order?.type === "attack" ? order.targetId : null;
  }

  function assignUnitOrder(unit, order, append = false) {
    if (!unit || unit.kind !== "unit") return false;
    unit.orderQueue ||= [];
    if (append && (unit.order || unit.orderQueue.length)) {
      unit.orderQueue.push(order);
    } else {
      unit.order = order;
      unit.targetId = unitOrderTargetId(order);
      if (!append) unit.orderQueue = [];
    }
    return true;
  }

  function movableUnits(selection) {
    return selection.filter((e) => e.kind === "unit" && !e.dead && !e.carriedBy);
  }

  function formationSpacing(units) {
    const maxRadius = units.reduce((best, unit) => Math.max(best, unitTypes[unit.type]?.radius || 14), 14);
    return clamp(maxRadius * 2 + 18, 42, 96);
  }

  function gridFormationSlots(units, spacing) {
    const sorted = [...units].sort((a, b) => (a.y - b.y) || (a.x - b.x));
    const cols = Math.ceil(Math.sqrt(sorted.length));
    const rows = Math.ceil(sorted.length / cols);
    return sorted.map((unit, i) => {
      const row = Math.floor(i / cols);
      const col = i % cols;
      return {
        unit,
        ox: (col - (cols - 1) / 2) * spacing,
        oy: (row - (rows - 1) / 2) * spacing,
      };
    });
  }

  function formationSlots(units) {
    if (units.length <= 1) return units.map((unit) => ({ unit, ox: 0, oy: 0 }));
    const spacing = formationSpacing(units);
    const center = units.reduce(
      (sum, unit) => {
        sum.x += unit.x;
        sum.y += unit.y;
        return sum;
      },
      { x: 0, y: 0 },
    );
    center.x /= units.length;
    center.y /= units.length;

    let minX = Infinity;
    let minY = Infinity;
    let maxX = -Infinity;
    let maxY = -Infinity;
    let maxDist = 0;
    for (const unit of units) {
      minX = Math.min(minX, unit.x);
      minY = Math.min(minY, unit.y);
      maxX = Math.max(maxX, unit.x);
      maxY = Math.max(maxY, unit.y);
      maxDist = Math.max(maxDist, dist(unit.x, unit.y, center.x, center.y));
    }

    const footprint = Math.max(maxX - minX, maxY - minY);
    const packedThreshold = spacing * Math.max(1.4, Math.sqrt(units.length) * 0.42);
    if (footprint < packedThreshold) return gridFormationSlots(units, spacing);

    const maxRadius = clamp(125 + Math.sqrt(units.length) * 36, 180, 560);
    const scale = maxDist > maxRadius ? maxRadius / maxDist : 1;
    return units.map((unit) => ({
      unit,
      ox: (unit.x - center.x) * scale,
      oy: (unit.y - center.y) * scale,
    }));
  }

  function formationTargets(selection, x, y) {
    return formationSlots(movableUnits(selection)).map(({ unit, ox, oy }) => {
      const point = findReachablePoint(unit, x + ox, y + oy);
      return { unit, x: point.x, y: point.y };
    });
  }

  function advanceQueuedOrder(unit) {
    if (!unit || unit.order || !unit.orderQueue?.length) return false;
    unit.order = unit.orderQueue.shift();
    if (unit.order.type === "patrol" && unit.order.fromX == null) {
      unit.order.fromX = unit.x;
      unit.order.fromY = unit.y;
    }
    unit.targetId = unitOrderTargetId(unit.order);
    return true;
  }

  function issueMove(units, x, y, attackMove = false, append = false) {
    const targets = formationTargets(units, x, y);
    if (!targets.length) return;
    for (const target of targets) {
      assignUnitOrder(target.unit, { type: attackMove ? "attackMove" : "move", x: target.x, y: target.y }, append);
    }
  }

  function issuePatrol(units, x, y, append = false) {
    const targets = formationTargets(units, x, y);
    if (!targets.length) return;
    for (const target of targets) {
      assignUnitOrder(target.unit, { type: "patrol", x: target.x, y: target.y, fromX: append ? null : target.unit.x, fromY: append ? null : target.unit.y }, append);
    }
  }

  function issueGuard(units, target, append = false) {
    if (!target || target.dead) return 0;
    const movable = units.filter((e) => e.kind === "unit" && e.team === target.team && e.id !== target.id);
    const radius = entityRadius(target) + 58;
    movable.forEach((unit, i) => {
      const a = (i / Math.max(1, movable.length)) * Math.PI * 2;
      assignUnitOrder(unit, {
        type: "guard",
        targetId: target.id,
        offsetX: Math.cos(a) * radius,
        offsetY: Math.sin(a) * radius,
      }, append);
    });
    return movable.length;
  }

  function acquireGuardTarget(unit, guarded, range) {
    const weapon = entityWeapon(unit);
    if (!weapon) return null;
    let best = null;
    let bestScore = Infinity;
    const localRange = autoAcquireRange(unit, range);
    if (localRange <= 0) return null;
    const guardRange = unitStance(unit) === "aggressive" ? Math.max(range, 260) : localRange;
    for (const entity of allEntities()) {
      if (entity.dead || entity.team === unit.team || entity.buildProgress < 1) continue;
      if (!isTargetableFor(unit, entity)) continue;
      const du = dist2(unit.x, unit.y, entity.x, entity.y);
      const dg = dist2(guarded.x, guarded.y, entity.x, entity.y);
      if (du > localRange * localRange && dg > guardRange * guardRange) continue;
      const score = Math.min(du, dg * 0.8) - (entity.hp < entity.maxHp * 0.35 ? 9000 : 0);
      if (score < bestScore) {
        best = entity;
        bestScore = score;
      }
    }
    return best;
  }

  function issueAttack(units, target, append = false) {
    for (const unit of units) {
      if (unit.kind !== "unit" && unit.kind !== "building") continue;
      if (!isTargetableFor(unit, target)) continue;
      if (unit.kind === "unit") assignUnitOrder(unit, { type: "attack", targetId: target.id }, append);
      else unit.targetId = target.id;
    }
  }

  function issueRepair(units, target, append = false) {
    for (const unit of units) {
      if (canBuildWith(unit) && target.team === unit.team) {
        assignUnitOrder(unit, { type: "repair", targetId: target.id }, append);
      }
    }
  }

  function issueBuild(units, target, append = false) {
    if (!target || target.kind !== "building" || target.buildProgress >= 1) return 0;
    let assigned = 0;
    for (const unit of units) {
      if (!canBuildWith(unit) || target.team !== unit.team) continue;
      assignUnitOrder(unit, { type: "build", targetId: target.id }, append);
      assigned += 1;
    }
    return assigned;
  }

  function issueReclaim(units, wreck, append = false) {
    if (!wreck || (wreck.metal || 0) <= 0) return 0;
    let assigned = 0;
    for (const unit of units) {
      if (!canBuildWith(unit)) continue;
      assignUnitOrder(unit, { type: "reclaim", wreckId: wreck.id }, append);
      assigned += 1;
    }
    return assigned;
  }

  function issueLoadIntoTransport(units, transport) {
    let assigned = 0;
    for (const unit of units) {
      if (!canTransportUnit(transport, unit)) continue;
      unit.order = { type: "load", targetId: transport.id };
      unit.orderQueue = [];
      unit.targetId = null;
      assigned += 1;
    }
    if (assigned) {
      addMessage(`${assigned} 个单位前往装载。`, "info");
      markUiDirty();
    } else {
      addMessage("运输单位货舱已满或目标无法装载。", "warn");
    }
  }

  function issueTransportPickup(transports, unit) {
    const transport = transports.find((candidate) => canTransportUnit(candidate, unit));
    if (!transport) {
      addMessage("没有可用运输单位或货舱空间不足。", "warn");
      return;
    }
    unit.order = { type: "load", targetId: transport.id };
    unit.orderQueue = [];
    unit.targetId = null;
    addMessage(`${entityDef(unit).name} 前往装载。`, "info");
    markUiDirty();
  }

  function loadUnitIntoTransport(unit, transport) {
    if (!canTransportUnit(transport, unit)) return false;
    transport.cargoIds ||= [];
    transport.cargoIds.push(unit.id);
    unit.carriedBy = transport.id;
    unit.order = null;
    unit.orderQueue = [];
    unit.targetId = null;
    unit.x = transport.x;
    unit.y = transport.y;
    selectedIds.delete(unit.id);
    addParticle(transport.x, transport.y, "rgba(130, 220, 255, 0.65)", 5, 0.6);
    markUiDirty();
    return true;
  }

  function loadNearbyTransports(transports) {
    let loaded = 0;
    for (const transport of transports.filter(isTransportUnit)) {
      const candidates = state.units
        .filter((u) => !u.dead && !u.carriedBy && u.team === transport.team && dist2(u.x, u.y, transport.x, transport.y) < 180 * 180)
        .sort((a, b) => dist2(a.x, a.y, transport.x, transport.y) - dist2(b.x, b.y, transport.x, transport.y));
      for (const unit of candidates) {
        if (loadUnitIntoTransport(unit, transport)) loaded += 1;
      }
    }
    addMessage(loaded ? `已装载附近 ${loaded} 个单位。` : "附近没有可装载单位。", loaded ? "info" : "warn");
  }

  function unloadTransports(transports, x, y) {
    let unloaded = 0;
    let blocked = 0;
    for (const transport of transports.filter(isTransportUnit)) {
      const result = unloadTransport(transport, x, y);
      unloaded += result.unloaded;
      blocked += result.blocked;
    }
    if (unloaded) addMessage(`运输单位卸载 ${unloaded} 个单位。`, "info");
    else if (blocked) addMessage("目标附近没有可卸载地面。", "warn");
    markUiDirty();
  }

  function unloadTransport(transport, x = transport.x, y = transport.y) {
    const ids = [...(transport.cargoIds || [])];
    const remaining = [];
    let unloaded = 0;
    let blocked = 0;
    ids.forEach((id, index) => {
      const unit = getUnitById(id);
      if (!unit || unit.carriedBy !== transport.id) return;
      const point = findUnloadPoint(unit, x, y, index);
      if (!point) {
        remaining.push(id);
        blocked += 1;
        return;
      }
      unit.carriedBy = null;
      unit.x = point.x;
      unit.y = point.y;
      unit.order = { type: "move", x: point.x, y: point.y };
      unit.moveAngle = angleTo(transport.x, transport.y, point.x, point.y);
      unloaded += 1;
      addParticle(point.x, point.y, "rgba(105, 255, 145, 0.5)", 4, 0.55);
    });
    transport.cargoIds = remaining;
    return { unloaded, blocked };
  }

  function launchScoutDrones(deployers, announce = true) {
    let launched = 0;
    for (const unit of deployers) {
      const deploy = deployConfig(unit);
      if (!deploy || unit.dead || unit.carriedBy || (unit.deployCooldown || 0) > 0) continue;
      const angle = unit.moveAngle || (unit.team === TEAM_PLAYER ? 0 : Math.PI);
      const sx = clamp(unit.x + Math.cos(angle) * (unitTypes[unit.type].radius + 18), 20, MAP_W - 20);
      const sy = clamp(unit.y + Math.sin(angle) * (unitTypes[unit.type].radius + 18), 20, MAP_H - 20);
      const scout = createUnit(deploy.type, unit.team, sx, sy, {
        type: "move",
        x: clamp(unit.x + Math.cos(angle) * deploy.launchDistance, 20, MAP_W - 20),
        y: clamp(unit.y + Math.sin(angle) * deploy.launchDistance, 20, MAP_H - 20),
      });
      scout.moveAngle = angle;
      unit.deployCooldown = deploy.cooldown;
      launched += 1;
      addParticle(scout.x, scout.y, "rgba(130, 220, 255, 0.7)", 7, 0.55);
    }
    if (announce) addMessage(launched ? `已发射 ${launched} 架侦察无人机。` : "侦察无人机发射器冷却中。", launched ? "info" : "warn");
    markUiDirty();
  }

  function activateSpeedModules(units, announce = true) {
    let activated = 0;
    for (const unit of units) {
      const module = unitTypes[unit.type]?.speedModule;
      if (!module || unit.dead || unit.carriedBy || (unit.speedCooldown || 0) > 0) continue;
      unit.speedBoost = module.duration;
      unit.speedCooldown = module.cooldown;
      activated += 1;
      addParticle(unit.x, unit.y, "rgba(105, 255, 145, 0.72)", 10, 0.7);
    }
    if (announce) addMessage(activated ? `加速模块已启动：${activated} 个单位。` : "加速模块冷却中。", activated ? "info" : "warn");
    if (activated) markUiDirty();
    return activated;
  }

  function startBlinkTarget(units) {
    const ids = units
      .filter((unit) => unitTypes[unit.type]?.blinkModule && (unit.blinkCooldown || 0) <= 0)
      .map((unit) => unit.id);
    if (!ids.length) {
      addMessage("闪现模块冷却中。", "warn");
      return;
    }
    input.blinkUnitIds = ids;
    input.buildMode = null;
    input.attackMove = false;
    input.patrolMode = false;
    input.guardMode = false;
    input.reclaimMode = false;
    input.nukeSourceId = null;
    input.unloadTransportIds = null;
    updatePlaceHint("闪现模块：左键选择落点，Esc 取消");
    addMessage("选择模块化蜘蛛闪现落点。", "info");
  }

  function blinkSelectedUnits(ids, x, y, announce = true) {
    const units = ids.map(getUnitById).filter((unit) => unit && !unit.carriedBy && unitTypes[unit.type]?.blinkModule && (unit.blinkCooldown || 0) <= 0);
    if (!units.length) {
      if (announce) addMessage("没有可闪现的单位。", "warn");
      return 0;
    }
    const cols = Math.ceil(Math.sqrt(units.length));
    const spacing = 62;
    let blinked = 0;
    units.forEach((unit, index) => {
      const module = unitTypes[unit.type].blinkModule;
      const row = Math.floor(index / cols);
      const col = index % cols;
      const targetX = x + (col - (cols - 1) / 2) * spacing;
      const targetY = y + (row - (Math.ceil(units.length / cols) - 1) / 2) * spacing;
      const point = findBlinkPoint(unit, targetX, targetY, module.range);
      if (!point) return;
      addParticle(unit.x, unit.y, "rgba(130, 220, 255, 0.78)", 12, 0.7);
      unit.x = point.x;
      unit.y = point.y;
      unit.order = null;
      unit.orderQueue = [];
      unit.targetId = null;
      unit.blinkCooldown = module.cooldown;
      unit.moveAngle = angleTo(unit.x, unit.y, targetX, targetY);
      addParticle(unit.x, unit.y, "rgba(130, 220, 255, 0.88)", 16, 0.85);
      blinked += 1;
    });
    if (announce) addMessage(blinked ? `闪现完成：${blinked} 个单位。` : "目标超出距离或地形无法落点。", blinked ? "info" : "warn");
    if (blinked) {
      updateFog(true);
      markUiDirty();
    }
    return blinked;
  }

  function findBlinkPoint(unit, x, y, range) {
    const maxRange = range * range;
    let tx = clamp(x, 20, MAP_W - 20);
    let ty = clamp(y, 20, MAP_H - 20);
    const d = dist(unit.x, unit.y, tx, ty);
    if (d > range) {
      const a = angleTo(unit.x, unit.y, tx, ty);
      tx = unit.x + Math.cos(a) * range;
      ty = unit.y + Math.sin(a) * range;
    }
    const candidates = [[tx, ty]];
    for (let r = 34; r <= 190; r += 28) {
      for (let i = 0; i < 14; i += 1) {
        const a = (i / 14) * Math.PI * 2;
        candidates.push([tx + Math.cos(a) * r, ty + Math.sin(a) * r]);
      }
    }
    for (const [cx, cy] of candidates) {
      const px = clamp(cx, 20, MAP_W - 20);
      const py = clamp(cy, 20, MAP_H - 20);
      if (dist2(unit.x, unit.y, px, py) > maxRange) continue;
      if (!terrainAllows(unitTypes[unit.type].domain, px, py)) continue;
      if (unitOverlapsAt(unit, px, py)) continue;
      return { x: px, y: py };
    }
    return null;
  }

  function findUnloadPoint(unit, x, y, index = 0) {
    const baseAngle = index * 1.7;
    for (let r = 38; r <= 260; r += 28) {
      for (let i = 0; i < 18; i += 1) {
        const a = baseAngle + (i / 18) * Math.PI * 2;
        const px = clamp(x + Math.cos(a) * r, 20, MAP_W - 20);
        const py = clamp(y + Math.sin(a) * r, 20, MAP_H - 20);
        if (terrainAllows(unitTypes[unit.type].domain, px, py) && !unitOverlapsAt(unit, px, py)) return { x: px, y: py };
      }
    }
    return null;
  }

  function unitOverlapsAt(unit, x, y) {
    const radius = unitTypes[unit.type].radius + 5;
    for (const other of state.units) {
      if (other.dead || other.carriedBy || other.id === unit.id || unitTypes[other.type].domain === "air") continue;
      if (dist2(x, y, other.x, other.y) < (radius + unitTypes[other.type].radius) ** 2) return true;
    }
    return false;
  }

  function issueStop(units) {
    for (const unit of units) {
      if (unit.kind === "unit") {
        unit.order = null;
        unit.orderQueue = [];
        unit.targetId = null;
      }
    }
  }

  function findReachablePoint(unit, x, y) {
    const domain = unitTypes[unit.type].domain;
    x = clamp(x, 20, MAP_W - 20);
    y = clamp(y, 20, MAP_H - 20);
    if (terrainAllows(domain, x, y)) return { x, y };
    for (let r = 48; r < 420; r += 36) {
      for (let i = 0; i < 16; i += 1) {
        const a = (i / 16) * Math.PI * 2;
        const nx = clamp(x + Math.cos(a) * r, 20, MAP_W - 20);
        const ny = clamp(y + Math.sin(a) * r, 20, MAP_H - 20);
        if (terrainAllows(domain, nx, ny)) return { x: nx, y: ny };
      }
    }
    return { x: unit.x, y: unit.y };
  }

  function update(dt) {
    if (state.mode === "sandbox" && !ensureSandbox().combat) {
      updateCamera(dt);
      updateParticles(dt);
      updateStats(dt);
      if (state.sandbox.reveal) revealMap();
      return;
    }
    state.elapsed += dt;
    if (state.mode === "challenge" && state.challenge.timer > 0) {
      state.challenge.timer = Math.max(0, state.challenge.timer - dt);
    }
    state.metal[TEAM_PLAYER] += incomeFor(TEAM_PLAYER) * dt;
    state.metal[TEAM_ENEMY] += incomeFor(TEAM_ENEMY) * dt;

    for (const msg of state.messages) msg.ttl -= dt;
    const before = state.messages.length;
    state.messages = state.messages.filter((msg) => msg.ttl > 0);
    if (before !== state.messages.length) renderFeed();

    updateCamera(dt);
    updateBuildings(dt);
    updateUnits(dt);
    updateDefenceSystems(dt);
    updateProjectiles(dt);
    updateParticles(dt);
    updateWrecks(dt);
    updateAI(dt);
    updateCampaign();
    updateFog(false, dt);
    if (state.mode === "sandbox" && state.sandbox.reveal) revealMap();
    updateStats(dt);
    checkWinLoss();
  }

  function updateCamera(dt) {
    const keySpeed = 680 / camera.zoom;
    let dx = 0;
    let dy = 0;
    if (input.keys.has("KeyW") || input.keys.has("ArrowUp")) dy -= 1;
    if (input.keys.has("KeyS") || input.keys.has("ArrowDown")) dy += 1;
    if (input.keys.has("KeyA") || input.keys.has("ArrowLeft")) dx -= 1;
    if (input.keys.has("KeyD") || input.keys.has("ArrowRight")) dx += 1;
    if (dx || dy) {
      const len = Math.hypot(dx, dy) || 1;
      camera.x += (dx / len) * keySpeed * dt;
      camera.y += (dy / len) * keySpeed * dt;
    }
    camera.zoom = lerp(camera.zoom, camera.targetZoom, 1 - Math.pow(0.001, dt));
    clampCamera();
  }

  function updateBuildings(dt) {
    for (const b of state.buildings) {
      if (b.dead) continue;
      const def = buildingTypes[b.type];
      b.reload = Math.max(0, b.reload - dt);

      if (b.buildProgress < 1) {
        const nearbyBuilders = state.units.filter(
          (u) => !u.dead && u.team === b.team && canBuildWith(u) && dist2(u.x, u.y, b.x, b.y) < 150 * 150,
        ).length;
        const basePower = b.aiBuild ? 1.3 : 0.55;
        const builderPower = nearbyBuilders * 1.1;
        b.buildProgress = clamp(b.buildProgress + ((basePower + builderPower) * dt) / def.time, 0, 1);
        b.hp = Math.max(b.hp, def.hp * Math.max(0.1, b.buildProgress));
        if (b.buildProgress >= 1) {
          b.hp = b.maxHp;
          if (b.type === "extractor") {
            const node = nearestResource(b.x, b.y, 80);
            if (node) {
              node.claimedBy = b.team;
              b.nodeId = node.id;
            }
          }
          if (b.team === TEAM_PLAYER) addMessage(`${def.name} 建成。`, "info");
          markUiDirty();
        }
        continue;
      }

      if (def.repairAura) repairNearby(b, dt);
      if (entityWeapon(b)) updateAttacker(b, dt);
      updateProduction(b, dt);
    }
  }

  function repairNearby(building, dt) {
    const def = buildingTypes[building.type];
    repairNearbyEntities(building, def.repairAura, 24, dt, 5);
  }

  function repairNearbyEntities(source, range, power, dt, maxTargets = 5) {
    let repaired = 0;
    for (const entity of allEntities()) {
      if (entity.dead || entity.id === source.id || entity.team !== source.team || entity.hp >= entity.maxHp) continue;
      if (dist2(entity.x, entity.y, source.x, source.y) > range * range) continue;
      entity.hp = Math.min(entity.maxHp, entity.hp + power * dt);
      repaired += 1;
      if (repaired >= maxTargets) break;
    }
  }

  function updateProduction(b, dt) {
    if (!b.queue || !b.queue.length) return;
    const item = b.queue[0];
    item.left -= dt;
    if (item.left > 0) return;
    b.queue.shift();
    if (item.kind === "nuke") {
      b.ammo += 1;
      if (b.team === TEAM_PLAYER) addMessage("核弹已就绪。", "danger");
      return;
    }
    if (item.kind === "antiNuke") {
      const def = buildingCurrentDef(b);
      b.interceptorAmmo = Math.min(def.antiNuke.ammoMax, (b.interceptorAmmo || 0) + 1);
      if (b.team === TEAM_PLAYER) addMessage("反核拦截弹已就绪。", "info");
      markUiDirty();
      return;
    }
    if (item.kind === "upgrade") {
      completeUpgrade(b);
      return;
    }
    const spawn = getSpawnPoint(b, item.type);
    const unit = createUnit(item.type, b.team, spawn.x, spawn.y, {
      type: "move",
      x: b.rally ? b.rally.x : spawn.x,
      y: b.rally ? b.rally.y : spawn.y,
    });
    unit.moveAngle = angleTo(b.x, b.y, unit.order.x, unit.order.y);
    if (b.team === TEAM_PLAYER) addMessage(`${unitTypes[item.type].name} 已完成。`, "info");
    if (b.repeatUnit && b.queue.length === 0) {
      const repeated = queueUnitForProduction(b, b.repeatUnit, false);
      if (!repeated && b.team === TEAM_PLAYER) addMessage(`重复生产等待资源或人口：${unitTypes[b.repeatUnit]?.name || "单位"}。`, "warn");
    }
    markUiDirty();
  }

  function completeUpgrade(building) {
    building.level = buildingLevel(building) + 1;
    const current = buildingCurrentDef(building);
    const oldMax = building.maxHp;
    building.maxHp = current.hp || oldMax;
    building.hp = Math.min(building.maxHp, building.hp + Math.max(0, building.maxHp - oldMax));
    if (current.shield) {
      building.shieldEnergy = Math.min(current.shield.maxEnergy, Math.max(building.shieldEnergy || 0, current.shield.maxEnergy * 0.55));
    }
    if (building.team === TEAM_PLAYER) addMessage(`${buildingTypes[building.type].name} 已升级到 T${buildingLevel(building)}。`, "info");
    markUiDirty();
  }

  function getSpawnPoint(building, unitType) {
    const bDef = buildingTypes[building.type];
    const uDef = unitTypes[unitType];
    const angle = building.rally ? angleTo(building.x, building.y, building.rally.x, building.rally.y) : 0;
    for (let r = bDef.size * 0.75; r < 260; r += 22) {
      for (let i = 0; i < 16; i += 1) {
        const a = angle + (i % 2 === 0 ? 1 : -1) * Math.ceil(i / 2) * 0.32;
        const x = clamp(building.x + Math.cos(a) * r, 20, MAP_W - 20);
        const y = clamp(building.y + Math.sin(a) * r, 20, MAP_H - 20);
        if (terrainAllows(uDef.domain, x, y)) return { x, y };
      }
    }
    return { x: building.x + 80, y: building.y };
  }

  function updateUnits(dt) {
    for (const u of state.units) {
      if (u.dead || u.carriedBy) continue;
      const def = unitTypes[u.type];
      u.reload = Math.max(0, u.reload - dt);
      u.deployCooldown = Math.max(0, (u.deployCooldown || 0) - dt);
      u.speedBoost = Math.max(0, (u.speedBoost || 0) - dt);
      u.speedCooldown = Math.max(0, (u.speedCooldown || 0) - dt);
      u.blinkCooldown = Math.max(0, (u.blinkCooldown || 0) - dt);
      if (def.selfRepair && u.hp < u.maxHp) u.hp = Math.min(u.maxHp, u.hp + def.selfRepair * dt);
      if (def.shieldRegen && u.shield < u.maxShield) u.shield = Math.min(u.maxShield, (u.shield || 0) + def.shieldRegen * dt);
      if (def.shieldEmitter) u.shieldEnergy = Math.min(def.shieldEmitter.maxEnergy, (u.shieldEnergy || 0) + def.shieldEmitter.regen * dt);
      if (def.antiNuke) updateUnitAntiNuke(u, def, dt);
      if (def.deploys && u.team === TEAM_ENEMY && (u.deployCooldown || 0) <= 0 && Math.random() < dt * 0.04) {
        launchScoutDrones([u], false);
      }
      if (def.repairAura) {
        repairNearbyEntities(u, def.repairAura, def.repairPower || 18, dt, 3);
        if (Math.random() < dt * 1.8) {
          const damaged = allEntities().find((entity) => entity.team === u.team && entity.id !== u.id && entity.hp < entity.maxHp && dist2(entity.x, entity.y, u.x, u.y) < def.repairAura * def.repairAura);
          if (damaged) addParticle(damaged.x, damaged.y, "rgba(105, 255, 145, 0.35)", 1, 0.28);
        }
      }

      if (!u.order) advanceQueuedOrder(u);

      if (u.order) {
        if (u.order.type === "move" || u.order.type === "attackMove") {
          if (u.order.type === "attackMove") {
            const target = acquireTarget(u, def.weapon ? def.weapon.range * 1.15 : 230);
            if (target) {
              u.targetId = target.id;
              u.order.resume = { x: u.order.x, y: u.order.y };
              u.order = { type: "attack", targetId: target.id, resume: u.order.resume, auto: true, leash: def.weapon ? def.weapon.range * 1.15 : 230 };
            }
          }
          moveUnitToward(u, u.order.x, u.order.y, dt);
          if (dist2(u.x, u.y, u.order.x, u.order.y) < 20 * 20) {
            u.order = null;
          }
        } else if (u.order.type === "patrol") {
          const target = acquireTarget(u, def.weapon ? def.weapon.range * 1.15 : 230);
          if (target) {
            u.targetId = target.id;
            u.order = { type: "attack", targetId: target.id, resume: u.order, auto: true, leash: def.weapon ? def.weapon.range * 1.15 : 230 };
          } else {
            moveUnitToward(u, u.order.x, u.order.y, dt);
            if (dist2(u.x, u.y, u.order.x, u.order.y) < 22 * 22) {
              const nextX = u.order.fromX;
              const nextY = u.order.fromY;
              u.order.fromX = u.order.x;
              u.order.fromY = u.order.y;
              u.order.x = nextX;
              u.order.y = nextY;
            }
          }
        } else if (u.order.type === "guard") {
          const guarded = findEntity(u.order.targetId);
          if (!guarded || guarded.dead || guarded.team !== u.team) {
            u.order = null;
          } else if (canBuildWith(u) && guarded.hp < guarded.maxHp && dist2(u.x, u.y, guarded.x, guarded.y) <= 125 * 125) {
            guarded.hp = Math.min(guarded.maxHp, guarded.hp + def.repairPower * dt);
            addParticle(guarded.x, guarded.y, "rgba(105, 255, 145, 0.42)", 1, 0.32);
          } else {
            const target = acquireGuardTarget(u, guarded, def.weapon ? def.weapon.range * 1.2 : 230);
            if (target) {
              u.targetId = target.id;
              u.order = { type: "attack", targetId: target.id, resume: u.order, auto: true, leash: def.weapon ? def.weapon.range * 1.2 : 230 };
            } else {
              const gx = guarded.x + (u.order.offsetX || 0);
              const gy = guarded.y + (u.order.offsetY || 0);
              if (dist2(u.x, u.y, gx, gy) > 34 * 34) moveUnitToward(u, gx, gy, dt);
            }
          }
        } else if (u.order.type === "attack") {
          const target = findEntity(u.order.targetId);
          if (!target || target.dead || !isTargetableFor(u, target)) {
            resumeAfterAttackOrder(u);
          } else {
            const range = (def.weapon && def.weapon.range) || 0;
            const minRange = (def.weapon && def.weapon.minRange) || 0;
            const d = dist(u.x, u.y, target.x, target.y);
            if (!canContinueAutoAttackOrder(u, target, u.order.leash || range * 1.15)) {
              resumeAfterAttackOrder(u);
            } else if (d > range * 0.92) {
              moveUnitToward(u, target.x, target.y, dt);
            } else if (d < minRange) {
              const a = angleTo(target.x, target.y, u.x, u.y);
              moveUnitToward(u, u.x + Math.cos(a) * 90, u.y + Math.sin(a) * 90, dt);
            }
          }
        } else if (u.order.type === "build") {
          const target = findEntity(u.order.targetId);
          if (!target || target.dead || target.buildProgress >= 1) {
            u.order = null;
          } else if (dist2(u.x, u.y, target.x, target.y) > 125 * 125) {
            moveUnitToward(u, target.x, target.y, dt);
          } else {
            const bDef = buildingTypes[target.type];
            target.buildProgress = clamp(target.buildProgress + (def.buildPower * dt) / (bDef.time * 120), 0, 1);
            target.hp = Math.min(target.maxHp, Math.max(target.hp, target.maxHp * target.buildProgress));
            addParticle(target.x, target.y, "rgba(116, 215, 255, 0.65)", 1, 0.45);
          }
        } else if (u.order.type === "repair") {
          const target = findEntity(u.order.targetId);
          if (!target || target.dead || target.hp >= target.maxHp) {
            u.order = null;
          } else if (dist2(u.x, u.y, target.x, target.y) > 125 * 125) {
            moveUnitToward(u, target.x, target.y, dt);
          } else {
            target.hp = Math.min(target.maxHp, target.hp + def.repairPower * dt);
            addParticle(target.x, target.y, "rgba(105, 255, 145, 0.45)", 1, 0.35);
          }
        } else if (u.order.type === "reclaim") {
          const wreck = getWreckById(u.order.wreckId);
          if (!wreck) {
            u.order = null;
          } else if (dist2(u.x, u.y, wreck.x, wreck.y) > 92 * 92) {
            moveUnitToward(u, wreck.x, wreck.y, dt);
          } else {
            const amount = Math.min(wreck.metal, (def.buildPower || def.repairPower || 18) * 0.58 * dt);
            wreck.metal -= amount;
            wreck.ttl = Math.max(wreck.ttl, 8);
            state.metal[u.team] += amount;
            if (Math.random() < dt * 6) addParticle(wreck.x, wreck.y, "rgba(255, 203, 97, 0.58)", 1, 0.34);
            if (wreck.metal <= 0.1) {
              wreck.metal = 0;
              wreck.ttl = 0;
              u.order = null;
            }
            markUiDirty();
          }
        } else if (u.order.type === "load") {
          const transport = getUnitById(u.order.targetId);
          if (!transport || !canTransportUnit(transport, u)) {
            u.order = null;
          } else if (dist2(u.x, u.y, transport.x, transport.y) > 82 * 82) {
            moveUnitToward(u, transport.x, transport.y, dt);
          } else {
            loadUnitIntoTransport(u, transport);
          }
        }
      }

      if (!u.order) advanceQueuedOrder(u);
      updateAttacker(u, dt);
    }

    resolveUnitSeparation(dt);
  }

  function updateUnitAntiNuke(unit, def, dt) {
    const anti = def.antiNuke;
    if ((unit.interceptorAmmo || 0) >= anti.ammoMax) {
      unit.interceptorBuild = 0;
      return;
    }
    unit.interceptorBuild = (unit.interceptorBuild || 0) + dt;
    if (unit.interceptorBuild < anti.reloadTime) return;
    unit.interceptorBuild = 0;
    unit.interceptorAmmo = Math.min(anti.ammoMax, (unit.interceptorAmmo || 0) + 1);
    if (unit.team === TEAM_PLAYER) addMessage(`${def.name} 舰载反核弹已补充。`, "info");
    markUiDirty();
  }

  function updateDefenceSystems(dt) {
    for (const b of state.buildings) {
      if (b.dead || b.buildProgress < 1) continue;
      const def = buildingCurrentDef(b);
      if (def.shield) {
        b.shieldEnergy = Math.min(def.shield.maxEnergy, (b.shieldEnergy || 0) + def.shield.regen * dt);
      }
    }

    for (const p of state.projectiles) {
      if (p.dead) continue;
      if (p.kind === "nuke" && interceptNuke(p)) continue;
      if (p.kind !== "nuke") interceptProjectileWithLaser(p);
    }
  }

  function interceptNuke(projectile) {
    let best = null;
    let bestD = Infinity;
    for (const entity of allEntities()) {
      if (entity.dead || entity.team === projectile.team || (entity.buildProgress !== undefined && entity.buildProgress < 1) || (entity.interceptorAmmo || 0) <= 0) continue;
      const anti = entityAntiNukeDef(entity);
      if (!anti) continue;
      const d = dist2(entity.x, entity.y, projectile.x, projectile.y);
      if (d < anti.range * anti.range && d < bestD) {
        best = entity;
        bestD = d;
      }
    }
    if (!best) return false;
    best.interceptorAmmo -= 1;
    projectile.dead = true;
    addParticle(projectile.x, projectile.y, "rgba(255, 235, 135, 0.95)", 30, 1.35);
    addMessage(best.team === TEAM_PLAYER ? "反核拦截成功。" : "敌方反核拦截了核弹。", best.team === TEAM_PLAYER ? "info" : "warn");
    markUiDirty();
    return true;
  }

  function interceptProjectileWithLaser(projectile) {
    let best = null;
    let bestD = Infinity;
    for (const b of state.buildings) {
      if (b.dead || b.team === projectile.team || b.buildProgress < 1 || b.type !== "laserDefence") continue;
      const def = buildingCurrentDef(b);
      const needed = Math.max(10, projectile.damage * def.shield.costPerDamage);
      if ((b.shieldEnergy || 0) < needed) continue;
      const d = dist2(b.x, b.y, projectile.x, projectile.y);
      if (d < def.shield.range * def.shield.range && d < bestD) {
        best = b;
        bestD = d;
      }
    }
    if (!best) return false;
    const def = buildingCurrentDef(best);
    const energyCost = Math.max(10, projectile.damage * def.shield.costPerDamage);
    best.shieldEnergy = Math.max(0, (best.shieldEnergy || 0) - energyCost);
    ensureStats().shieldBlocked[best.team] += projectile.damage;
    projectile.dead = true;
    state.particles.push({
      x: projectile.x,
      y: projectile.y,
      vx: 0,
      vy: 0,
      life: 0.28,
      maxLife: 0.28,
      color: "rgba(115, 230, 255, 0.95)",
      size: 11,
    });
    markUiDirty();
    return true;
  }

  function moveUnitToward(unit, tx, ty, dt) {
    const def = unitTypes[unit.type];
    const dx = tx - unit.x;
    const dy = ty - unit.y;
    const len = Math.hypot(dx, dy);
    if (len < 2) return;
    let nx = dx / len;
    let ny = dy / len;
    const desiredAngle = Math.atan2(ny, nx);
    unit.moveAngle = lerpAngle(unit.moveAngle || desiredAngle, desiredAngle, 0.14);

    const moduleBoost = def.speedModule && (unit.speedBoost || 0) > 0 ? def.speedModule.multiplier : 1;
    const speed = def.speed * moduleBoost * terrainSpeedFactor(def.domain, unit.x, unit.y);
    let nextX = unit.x + nx * speed * dt;
    let nextY = unit.y + ny * speed * dt;
    if (!terrainAllows(def.domain, nextX, nextY)) {
      let found = false;
      for (const sign of [1, -1, 2, -2, 3, -3]) {
        const a = desiredAngle + sign * 0.42;
        const ax = unit.x + Math.cos(a) * speed * dt;
        const ay = unit.y + Math.sin(a) * speed * dt;
        if (terrainAllows(def.domain, ax, ay)) {
          nextX = ax;
          nextY = ay;
          nx = Math.cos(a);
          ny = Math.sin(a);
          found = true;
          break;
        }
      }
      if (!found) {
        unit.stuckClock += dt;
        return;
      }
    }
    unit.x = clamp(nextX, 10, MAP_W - 10);
    unit.y = clamp(nextY, 10, MAP_H - 10);
  }

  function terrainSpeedFactor(domain, x, y) {
    if (domain === "air") return 1;
    const t = terrainAt(x, y);
    if (t === "sand") return 0.88;
    if (t === "rock") return 0.78;
    if (domain === "hover" && (t === "water" || t === "deep")) return 0.82;
    return 1;
  }

  function lerpAngle(a, b, t) {
    let diff = b - a;
    while (diff > Math.PI) diff -= Math.PI * 2;
    while (diff < -Math.PI) diff += Math.PI * 2;
    return a + diff * t;
  }

  function resolveUnitSeparation(dt) {
    for (let i = 0; i < state.units.length; i += 1) {
      const a = state.units[i];
      if (a.dead || a.carriedBy || unitTypes[a.type].domain === "air") continue;
      for (let j = i + 1; j < state.units.length; j += 1) {
        const b = state.units[j];
        if (b.dead || b.carriedBy || unitTypes[b.type].domain === "air") continue;
        if (unitTypes[a.type].domain !== unitTypes[b.type].domain && unitTypes[a.type].domain !== "hover" && unitTypes[b.type].domain !== "hover") continue;
        const ar = unitTypes[a.type].radius;
        const br = unitTypes[b.type].radius;
        const min = ar + br + 5;
        const d = dist(a.x, a.y, b.x, b.y);
        if (d > 0 && d < min) {
          const push = ((min - d) / min) * 34 * dt;
          const nx = (a.x - b.x) / d;
          const ny = (a.y - b.y) / d;
          if (terrainAllows(unitTypes[a.type].domain, a.x + nx * push, a.y + ny * push)) {
            a.x += nx * push;
            a.y += ny * push;
          }
          if (terrainAllows(unitTypes[b.type].domain, b.x - nx * push, b.y - ny * push)) {
            b.x -= nx * push;
            b.y -= ny * push;
          }
        }
      }
    }
  }

  function updateAttacker(attacker, dt) {
    const weapon = entityWeapon(attacker);
    if (!weapon || attacker.buildProgress < 1) return;

    let target = attacker.targetId ? findEntity(attacker.targetId) : null;
    const range = weapon.range;
    const hasManualAttackOrder = attacker.order?.type === "attack" && !attacker.order.auto;
    const targetInvalid =
      !target ||
      !isTargetableFor(attacker, target) ||
      (!hasManualAttackOrder && dist2(attacker.x, attacker.y, target.x, target.y) > (range * 1.18) ** 2);

    if (targetInvalid) {
      target = hasManualAttackOrder ? null : acquireTarget(attacker, range);
      attacker.targetId = target ? target.id : null;
    }

    if (!target) return;
    const d = dist(attacker.x, attacker.y, target.x, target.y);
    const minRange = weapon.minRange || 0;
    if (d > range || d < minRange || attacker.reload > 0) return;

    attacker.reload = weapon.reload;
    const kind = weapon.kind || (weapon.aoe ? "shell" : weapon.canAir && !weapon.canGround ? "missile" : "bullet");
    createProjectile(attacker, target, weapon, kind);
  }

  function acquireTarget(attacker, range) {
    if (!entityWeapon(attacker)) return null;
    let best = null;
    let bestScore = Infinity;
    const maxRange = autoAcquireRange(attacker, range);
    if (maxRange <= 0) return null;
    const maxD = maxRange * maxRange;
    for (const entity of allEntities()) {
      if (entity.dead || entity.team === attacker.team || entity.buildProgress < 1) continue;
      if (!isTargetableFor(attacker, entity)) continue;
      const d = dist2(attacker.x, attacker.y, entity.x, entity.y);
      if (d > maxD) continue;
      const score = targetPriorityScore(attacker, entity, d, range);
      if (score < bestScore) {
        bestScore = score;
        best = entity;
      }
    }
    return best;
  }

  function updateProjectiles(dt) {
    for (const p of state.projectiles) {
      if (p.dead) continue;
      p.age += dt;
      const t = clamp(p.age / p.travel, 0, 1);
      const arc = p.kind === "nuke" ? Math.sin(t * Math.PI) * 420 : p.kind === "shell" ? Math.sin(t * Math.PI) * 50 : 0;
      p.x = lerp(p.sx, p.tx, t);
      p.y = lerp(p.sy, p.ty, t) - arc * 0.16;
      if (t >= 1) {
        impactProjectile(p);
        p.dead = true;
      }
    }
    state.projectiles = state.projectiles.filter((p) => !p.dead);
  }

  function impactProjectile(p) {
    const target = p.targetId ? findEntity(p.targetId) : null;
    const ix = target && !target.dead && p.kind !== "nuke" ? target.x : p.tx;
    const iy = target && !target.dead && p.kind !== "nuke" ? target.y : p.ty;

    if (p.aoe > 0) {
      for (const entity of allEntities()) {
        if (entity.dead || entity.team === p.team) continue;
        const d = dist(entity.x, entity.y, ix, iy);
        if (d > p.aoe) continue;
        const factor = clamp(1 - d / p.aoe, 0.22, 1);
        damageEntity(entity, p.damage * factor, p.team);
      }
      addParticle(ix, iy, p.kind === "nuke" ? "rgba(255, 210, 92, 0.95)" : "rgba(255, 156, 70, 0.85)", p.kind === "nuke" ? 58 : 18, p.kind === "nuke" ? 2.4 : 1);
      if (p.kind === "nuke") addMessage("核爆冲击波已命中目标区域。", p.team === TEAM_PLAYER ? "danger" : "warn");
    } else if (target && !target.dead) {
      damageEntity(target, p.damage, p.team);
      if (p.chain > 0) chainProjectile(p, target);
      addParticle(ix, iy, p.kind === "missile" ? "rgba(255, 200, 80, 0.85)" : p.kind === "tesla" ? "rgba(120, 235, 255, 0.9)" : "rgba(255,255,210,0.65)", 4, 0.55);
    }
  }

  function chainProjectile(projectile, firstTarget) {
    const hit = new Set([firstTarget.id]);
    let from = firstTarget;
    let damage = projectile.damage * projectile.chainFalloff;
    for (let jump = 0; jump < projectile.chain; jump += 1) {
      let best = null;
      let bestD = Infinity;
      for (const entity of allEntities()) {
        if (entity.dead || entity.team === projectile.team || hit.has(entity.id)) continue;
        if (!projectileCanDamage(projectile, entity)) continue;
        const d = dist2(from.x, from.y, entity.x, entity.y);
        if (d < projectile.chainRange * projectile.chainRange && d < bestD) {
          best = entity;
          bestD = d;
        }
      }
      if (!best) break;
      hit.add(best.id);
      damageEntity(best, damage, projectile.team);
      addParticle(best.x, best.y, "rgba(120, 235, 255, 0.72)", 5, 0.45);
      from = best;
      damage *= projectile.chainFalloff;
    }
  }

  function projectileCanDamage(projectile, entity) {
    const targetDomain = entity.kind === "unit" ? unitTypes[entity.type].domain : "ground";
    if (targetDomain === "air") return Boolean(projectile.canAir);
    if (targetDomain === "sea") return Boolean(projectile.canSea || projectile.canGround);
    return projectile.canGround !== false;
  }

  function damageEntity(entity, amount, sourceTeam) {
    if (entity.dead) return;
    const originalAmount = amount;
    const startHp = entity.hp;
    amount = absorbWithShieldEmitter(entity, amount, sourceTeam);
    const emitterBlocked = originalAmount - amount;
    if (emitterBlocked > 0) ensureStats().shieldBlocked[entity.team] += emitterBlocked;
    if (amount <= 0) return;
    if (entity.maxShield && entity.shield > 0) {
      const absorbed = Math.min(entity.shield, amount);
      entity.shield -= absorbed;
      amount -= absorbed;
      if (absorbed > 0) {
        ensureStats().shieldBlocked[entity.team] += absorbed;
        addParticle(entity.x, entity.y, "rgba(95, 220, 255, 0.55)", 2, 0.5);
      }
    }
    entity.hp -= amount;
    const hpDamage = Math.max(0, Math.min(startHp, amount));
    if (hpDamage > 0 && state.stats) state.stats.damageDone[sourceTeam] = (state.stats.damageDone[sourceTeam] || 0) + hpDamage;
    if (entity.hp > 0) return;
    entity.dead = true;
    const stats = ensureStats();
    stats.kills[sourceTeam] = (stats.kills[sourceTeam] || 0) + 1;
    stats.losses[entity.team] = (stats.losses[entity.team] || 0) + 1;
    if (entity.kind === "unit" && entity.cargoIds?.length) {
      let lost = 0;
      for (const id of entity.cargoIds) {
        const cargo = getAnyUnitById(id);
        if (!cargo || cargo.dead || cargo.carriedBy !== entity.id) continue;
        cargo.dead = true;
        cargo.carriedBy = null;
        selectedIds.delete(cargo.id);
        lost += 1;
      }
      entity.cargoIds = [];
      if (lost) {
        stats.kills[sourceTeam] = (stats.kills[sourceTeam] || 0) + lost;
        stats.losses[entity.team] = (stats.losses[entity.team] || 0) + lost;
      }
      if (lost && entity.team === TEAM_PLAYER) addMessage(`运输单位被摧毁，${lost} 个货舱单位损失。`, "danger");
    }
    if (entity.kind === "building" && entity.type === "extractor" && entity.nodeId) {
      const node = state.resources.find((n) => n.id === entity.nodeId);
      if (node) node.claimedBy = null;
    }
    const salvage = wreckSalvageValue(entity);
    state.wrecks.push({
      id: nextId(),
      x: entity.x,
      y: entity.y,
      size: entity.kind === "unit" ? unitTypes[entity.type].radius * 1.7 : buildingTypes[entity.type].size * 0.55,
      ttl: 58,
      team: entity.team,
      metal: salvage,
      maxMetal: salvage,
    });
    addParticle(entity.x, entity.y, sourceTeam === TEAM_PLAYER ? "rgba(245, 135, 85, 0.85)" : "rgba(255, 82, 72, 0.85)", entity.kind === "building" ? 24 : 11, entity.kind === "building" ? 1.3 : 0.8);
    if (entity.kind === "unit" && unitTypes[entity.type].deathNuke) {
      const blast = unitTypes[entity.type].deathNuke;
      state.projectiles.push({
        id: nextId(),
        team: entity.team,
        x: entity.x,
        y: entity.y,
        sx: entity.x,
        sy: entity.y,
        tx: entity.x,
        ty: entity.y,
        damage: blast.damage,
        aoe: blast.aoe,
        speed: 1,
        age: 0,
        travel: 0.05,
        kind: "blast",
        dead: false,
      });
    }
    if (entity.team === TEAM_PLAYER) addMessage(`${entityDef(entity).name} 被摧毁。`, "danger");
    selectedIds.delete(entity.id);
    markUiDirty();
  }

  function absorbWithShieldEmitter(target, amount, sourceTeam) {
    if (target.team === sourceTeam || amount <= 0) return amount;
    let best = null;
    let bestD = Infinity;
    for (const unit of state.units) {
      if (unit.dead || unit.carriedBy || unit.team !== target.team) continue;
      const def = unitTypes[unit.type];
      if (!def.shieldEmitter || (unit.shieldEnergy || 0) <= 0) continue;
      const d = dist2(unit.x, unit.y, target.x, target.y);
      if (d < def.shieldEmitter.range * def.shieldEmitter.range && d < bestD) {
        best = unit;
        bestD = d;
      }
    }
    if (!best) return amount;
    const shield = unitTypes[best.type].shieldEmitter;
    const absorbed = Math.min(amount, (best.shieldEnergy || 0) / shield.costPerDamage);
    if (absorbed <= 0) return amount;
    best.shieldEnergy = Math.max(0, (best.shieldEnergy || 0) - absorbed * shield.costPerDamage);
    addParticle(target.x, target.y, "rgba(90, 220, 255, 0.5)", 3, 0.55);
    markUiDirty();
    return amount - absorbed;
  }

  function updateParticles(dt) {
    for (const p of state.particles) {
      p.life -= dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vx *= 0.93;
      p.vy *= 0.93;
    }
    state.particles = state.particles.filter((p) => p.life > 0);
  }

  function updateWrecks(dt) {
    for (const w of state.wrecks) w.ttl -= dt;
    state.wrecks = state.wrecks.filter((w) => w.ttl > 0 && (w.metal || 0) > 0);
  }

  function updateAI(dt) {
    if (state.gameOver) return;
    syncAiDifficulty();
    const profile = aiProfile();
    state.ai.buildClock -= dt;
    state.ai.trainClock -= dt;
    state.ai.attackClock -= dt;
    state.ai.scoutClock -= dt;
    state.ai.reclaimClock -= dt;
    state.ai.survivalClock -= dt;

    if (state.ai.buildClock <= 0) {
      state.ai.buildClock = profile.buildInterval;
      aiBuild();
    }
    if (state.ai.trainClock <= 0) {
      state.ai.trainClock = profile.trainInterval;
      aiTrain();
    }
    if (state.ai.attackClock <= 0) {
      state.ai.attackClock = profile.attackBase + Math.random() * profile.attackJitter;
      if (state.mode === "skirmish") aiAttackWave();
    }
    if (state.mode === "survival" && state.ai.survivalClock <= 0) {
      spawnSurvivalWave();
    }
    if (state.ai.scoutClock <= 0) {
      state.ai.scoutClock = 24;
      const scout = state.units.find((u) => !u.dead && u.team === TEAM_ENEMY && u.type === "scout");
      if (scout) scout.order = { type: "attackMove", x: 1150 + Math.random() * 700, y: 1700 + Math.random() * 700 };
    }
    if (state.ai.reclaimClock <= 0) {
      state.ai.reclaimClock = 2.5;
      aiReclaimWrecks();
    }
  }

  function aiReclaimWrecks() {
    if (!state.wrecks.some((w) => (w.metal || 0) > 0 && w.ttl > 0)) return;
    const builders = state.units.filter((u) => !u.dead && !u.carriedBy && u.team === TEAM_ENEMY && canBuildWith(u) && !u.order);
    for (const builder of builders) {
      const wreck = nearestWreck(builder.x, builder.y, 560);
      if (!wreck) continue;
      issueReclaim([builder], wreck);
    }
  }

  function aiBuild() {
    const command = state.buildings.find((b) => !b.dead && b.team === TEAM_ENEMY && b.type === "command");
    if (!command) return;
    const enemyBuildings = state.buildings.filter((b) => !b.dead && b.team === TEAM_ENEMY);
    const has = (type) => enemyBuildings.filter((b) => b.type === type).length;
    const metal = state.metal[TEAM_ENEMY];

    const upgradeCandidate = enemyBuildings.find((b) => b.buildProgress >= 1 && nextUpgrade(b) && b.queue.length === 0);
    if (upgradeCandidate) {
      const upgrade = nextUpgrade(upgradeCandidate);
      const priority =
        upgradeCandidate.type === "extractor" ||
        (state.elapsed > 115 &&
          (upgradeCandidate.type === "landFactory" || upgradeCandidate.type === "mechFactory" || upgradeCandidate.type === "airFactory" || upgradeCandidate.type === "seaFactory")) ||
        (state.elapsed > 90 && upgradeCandidate.type === "radar") ||
        (state.elapsed > 160 && upgradeCandidate.type === "laserDefence");
      if (priority && metal > upgrade.cost + 260) {
        spend(TEAM_ENEMY, upgrade.cost);
        upgradeCandidate.queue.push({ kind: "upgrade", type: upgradeCandidate.type, left: upgrade.time, total: upgrade.time, level: buildingLevel(upgradeCandidate) + 1 });
        return;
      }
    }

    const node = nearestFreeResourceFor(TEAM_ENEMY, command.x, command.y);
    if (node && metal > 300 && has("extractor") < 6) {
      placeAiBuilding("extractor", node.x, node.y);
      return;
    }

    if (metal > 700 && has("landFactory") < 3) {
      const p = aiBuildSpot(command.x + randomRange(-420, 220), command.y + randomRange(170, 460), "landFactory");
      if (p) {
        placeAiBuilding("landFactory", p.x, p.y);
        return;
      }
    }

    if (metal > 1050 && state.elapsed > 85 && has("mechFactory") < 2) {
      const p = aiBuildSpot(command.x + randomRange(-460, 160), command.y + randomRange(-120, 420), "mechFactory");
      if (p) {
        placeAiBuilding("mechFactory", p.x, p.y);
        return;
      }
    }

    if (metal > 900 && state.elapsed > 95 && has("airFactory") < 2) {
      const p = aiBuildSpot(command.x + randomRange(-460, 120), command.y + randomRange(-360, 260), "airFactory");
      if (p) {
        placeAiBuilding("airFactory", p.x, p.y);
        return;
      }
    }

    if (metal > 560 && state.elapsed > 58 && has("radar") < 1) {
      const p = aiBuildSpot(command.x + randomRange(-260, 240), command.y + randomRange(-300, 260), "radar");
      if (p) {
        placeAiBuilding("radar", p.x, p.y);
        return;
      }
    }

    if (metal > 780 && state.elapsed > 120 && has("seaFactory") < 1) {
      const p = findWaterBuildSpot(2740, 1280, 680);
      if (p) {
        placeAiBuilding("seaFactory", p.x, p.y);
        return;
      }
    }

    if (metal > 430 && has("turret") < 5) {
      const p = aiBuildSpot(command.x + randomRange(-560, -180), command.y + randomRange(40, 430), Math.random() < 0.72 ? "turret" : "aaTurret");
      if (p) placeAiBuilding(Math.random() < 0.72 ? "turret" : "aaTurret", p.x, p.y);
      return;
    }

    if (metal > 780 && state.elapsed > 110 && has("laserDefence") < 2) {
      const p = aiBuildSpot(command.x + randomRange(-280, 260), command.y + randomRange(-260, 260), "laserDefence");
      if (p) {
        placeAiBuilding("laserDefence", p.x, p.y);
        return;
      }
    }

    if (metal > 1350 && state.elapsed > 175 && has("antiNuke") < 1) {
      const p = aiBuildSpot(command.x + randomRange(-220, 320), command.y + randomRange(-240, 260), "antiNuke");
      if (p) {
        placeAiBuilding("antiNuke", p.x, p.y);
        return;
      }
    }

    if (metal > 620 && has("fabricator") < 4) {
      const p = aiBuildSpot(command.x + randomRange(-120, 360), command.y + randomRange(-380, 300), "fabricator");
      if (p) placeAiBuilding("fabricator", p.x, p.y);
    }

    if (metal > 1900 && state.elapsed > 210 && has("nukeLauncher") < 1) {
      const p = aiBuildSpot(command.x + randomRange(120, 420), command.y + randomRange(-160, 220), "nukeLauncher");
      if (p) placeAiBuilding("nukeLauncher", p.x, p.y);
    }

    if (metal > 2200 && state.elapsed > 230 && has("experimentalFactory") < 1) {
      const p = aiBuildSpot(command.x + randomRange(-80, 430), command.y + randomRange(-120, 360), "experimentalFactory");
      if (p) placeAiBuilding("experimentalFactory", p.x, p.y);
    }
  }

  function placeAiBuilding(type, x, y) {
    const def = buildingTypes[type];
    if (!def || !canAfford(TEAM_ENEMY, def.cost)) return false;
    const validation = validateAiPlacement(type, x, y);
    if (!validation) return false;
    spend(TEAM_ENEMY, def.cost);
    const b = createBuilding(type, TEAM_ENEMY, x, y, false);
    b.aiBuild = true;
    return true;
  }

  function validateAiPlacement(type, x, y) {
    const def = buildingTypes[type];
    if (!def) return false;
    if (def.requiresNode) {
      const node = nearestResource(x, y, 56);
      if (!node) return false;
      const extractor = extractorOnNode(node.id);
      if (extractor) return false;
      x = node.x;
      y = node.y;
    }
    return !isBlockedForBuilding(x, y, def.size, type);
  }

  function aiBuildSpot(x, y, type) {
    for (let r = 0; r < 620; r += 58) {
      for (let i = 0; i < 18; i += 1) {
        const a = (i / 18) * Math.PI * 2 + r * 0.01;
        const nx = clamp(x + Math.cos(a) * r, 80, MAP_W - 80);
        const ny = clamp(y + Math.sin(a) * r, 80, MAP_H - 80);
        if (!isBlockedForBuilding(nx, ny, buildingTypes[type].size, type)) return { x: nx, y: ny };
      }
    }
    return null;
  }

  function findWaterBuildSpot(x, y, radius) {
    for (let r = 0; r < radius; r += 48) {
      for (let i = 0; i < 20; i += 1) {
        const a = (i / 20) * Math.PI * 2;
        const nx = x + Math.cos(a) * r;
        const ny = y + Math.sin(a) * r;
        if (!isBlockedForBuilding(nx, ny, buildingTypes.seaFactory.size, "seaFactory")) return { x: nx, y: ny };
      }
    }
    return null;
  }

  function randomRange(min, max) {
    return min + Math.random() * (max - min);
  }

  function aiTrain() {
    for (const b of state.buildings) {
      if (b.dead || b.team !== TEAM_ENEMY || b.buildProgress < 1 || !buildingProduces(b).length || b.queue.length > 2) continue;
      const supply = teamSupply(TEAM_ENEMY);
      const options = buildingProduces(b).filter((type) => {
        const def = unitTypes[type];
        return def && state.metal[TEAM_ENEMY] >= def.cost && supply.used + (def.supply || 0) <= supply.cap;
      });
      if (!options.length) continue;
      let pick = options[0];
      if (b.type === "landFactory") {
        pick = weightedPick([
          ["tank", 5],
          ["heavyTank", state.elapsed > 120 ? 2.5 : 0],
          ["heavyHover", state.elapsed > 145 ? 1.4 : 0],
          ["artillery", state.elapsed > 80 ? 2.3 : 0.6],
          ["aaTank", state.elapsed > 100 ? 1.6 : 0.4],
          ["missileTank", state.elapsed > 135 ? 1.7 : 0],
          ["laserTank", state.elapsed > 165 ? 1.15 : 0],
          ["repairTank", state.elapsed > 135 ? 0.9 : 0],
          ["shieldTank", state.elapsed > 155 ? 0.75 : 0],
          ["hover", 1.3],
        ]).find((type) => options.includes(type)) || options[0];
      } else if (b.type === "mechFactory") {
        pick = weightedPick([
          ["combatEngineer", 1.6],
          ["minigunMech", 3.2],
          ["artilleryMech", state.elapsed > 120 ? 2.3 : 0.7],
          ["plasmaMech", state.elapsed > 170 ? 1.8 : 0.25],
          ["teslaMech", state.elapsed > 210 ? 1.2 : 0.15],
        ]).find((type) => options.includes(type)) || options[0];
      } else if (b.type === "airFactory") {
        pick = weightedPick([
          ["interceptor", state.elapsed > 105 ? 2.4 : 0],
          ["gunship", 4],
          ["heavyGunship", state.elapsed > 175 ? 1.45 : 0],
          ["bomber", state.elapsed > 150 ? 1.5 : 0.2],
          ["spyDrone", 0.8],
        ]).find((type) => options.includes(type)) || options[0];
      } else if (b.type === "seaFactory") {
        pick = weightedPick([
          ["gunboat", 4],
          ["sub", 1.5],
          ["transportShip", state.elapsed > 170 ? 0.35 : 0],
          ["missileShip", state.elapsed > 145 ? 1.7 : 0],
          ["heavyAaShip", state.elapsed > 150 ? 1.3 : 0],
          ["battleship", state.elapsed > 170 ? 1.2 : 0.2],
          ["nautilus", state.elapsed > 240 ? 0.7 : 0],
        ]).find((type) => options.includes(type)) || options[0];
      } else if (b.type === "experimentalFactory") {
        pick = weightedPick([
          ["experimental", 3],
          ["experimentalTank", state.elapsed > 285 ? 1.2 : 0.25],
          ["spider", state.elapsed > 300 ? 1.4 : 0.35],
        ]).find((type) => options.includes(type)) || options[0];
      }
      const def = unitTypes[pick];
      if (spend(TEAM_ENEMY, def.cost)) {
        b.queue.push({ kind: "unit", type: pick, left: def.time, total: def.time });
      }
    }

    const nukes = state.buildings.filter((b) => !b.dead && b.team === TEAM_ENEMY && b.type === "nukeLauncher" && b.buildProgress >= 1);
    for (const b of nukes) {
      if (b.ammo === 0 && b.queue.length === 0 && state.metal[TEAM_ENEMY] > 1700) {
        state.metal[TEAM_ENEMY] -= 1600;
        b.queue.push({ kind: "nuke", type: "nuke", left: 34, total: 34 });
      } else if (b.ammo > 0 && Math.random() < 0.01) {
        const command = state.buildings.find((pb) => !pb.dead && pb.team === TEAM_PLAYER && pb.type === "command");
        if (command) {
          b.ammo -= 1;
          createNuke(b, command.x + randomRange(-150, 150), command.y + randomRange(-150, 150));
          addMessage("敌方核弹发射！", "danger");
        }
      }
    }

    const antiNukes = state.buildings.filter((b) => !b.dead && b.team === TEAM_ENEMY && b.type === "antiNuke" && b.buildProgress >= 1);
    for (const b of antiNukes) {
      const def = buildingCurrentDef(b);
      if ((b.interceptorAmmo || 0) < def.antiNuke.ammoMax && b.queue.length === 0 && state.metal[TEAM_ENEMY] > def.antiNuke.buildCost + 600) {
        state.metal[TEAM_ENEMY] -= def.antiNuke.buildCost;
        b.queue.push({ kind: "antiNuke", type: "antiNuke", left: def.antiNuke.buildTime, total: def.antiNuke.buildTime });
      }
    }
  }

  function weightedPick(entries) {
    const total = entries.reduce((sum, [, weight]) => sum + Math.max(0, weight), 0);
    const result = [];
    if (total <= 0) return entries.map(([name]) => name);
    let roll = Math.random() * total;
    for (const [name, weight] of entries) {
      roll -= Math.max(0, weight);
      if (roll <= 0) {
        result.push(name);
        break;
      }
    }
    return result.concat(entries.map(([name]) => name));
  }

  function aiAttackWave() {
    const playerCommand = state.buildings.find((b) => !b.dead && b.team === TEAM_PLAYER && b.type === "command");
    if (!playerCommand) return;
    const wave = state.units.filter((u) => {
      if (u.dead || u.team !== TEAM_ENEMY) return false;
      if (u.type === "builder" || u.type === "spyDrone" || isTransportUnit(u)) return false;
      const hasOrder = u.order && (u.order.type === "attackMove" || u.order.type === "attack");
      return !hasOrder || Math.random() < 0.45;
    });
    if (wave.length < 4 && state.elapsed < 100) return;
    const waveCap = Math.floor((18 + Math.floor(state.elapsed / 50)) * aiProfile().waveScale);
    const attackers = wave.slice(0, Math.min(wave.length, Math.max(4, waveCap)));
    for (const unit of attackers) {
      unit.order = {
        type: "attackMove",
        x: playerCommand.x + randomRange(-180, 180),
        y: playerCommand.y + randomRange(-170, 170),
      };
      if (unit.type === "spider") useAiSpiderModules(unit, playerCommand);
    }
    if (attackers.length) addMessage(`侦测到敌方进攻波：${attackers.length} 个单位。`, "danger");
  }

  function useAiSpiderModules(unit, target) {
    if (!unit || unit.dead || unit.carriedBy || unit.type !== "spider" || !target) return;
    activateSpeedModules([unit], false);
    const d = dist(unit.x, unit.y, target.x, target.y);
    if ((unit.blinkCooldown || 0) > 0 || d < 540) return;
    const a = angleTo(target.x, target.y, unit.x, unit.y);
    const tx = target.x + Math.cos(a) * 310 + randomRange(-85, 85);
    const ty = target.y + Math.sin(a) * 310 + randomRange(-85, 85);
    if (blinkSelectedUnits([unit.id], tx, ty, false)) {
      unit.order = {
        type: "attackMove",
        x: target.x + randomRange(-150, 150),
        y: target.y + randomRange(-150, 150),
      };
    }
  }

  function spawnSurvivalWave() {
    const playerCommand = state.buildings.find((b) => !b.dead && b.team === TEAM_PLAYER && b.type === "command");
    if (!playerCommand) return;
    state.ai.survivalWave += 1;
    const wave = state.ai.survivalWave;
    const profile = aiProfile();
    state.ai.survivalClock = Math.max(profile.survivalMin, 48 + profile.survivalDelay - wave * 1.2);
    const spawnPoints = [
      { x: 3660, y: 650 },
      { x: 3180, y: 1010 },
      { x: 2850, y: 1480 },
    ];
    const spawn = spawnPoints[wave % spawnPoints.length];
    const roster = [];
    const scaledWave = Math.max(1, wave * profile.survivalScale);
    const tankCount = 3 + Math.floor(scaledWave * 0.8);
    for (let i = 0; i < tankCount; i += 1) roster.push(wave > 7 && i % 3 === 0 ? "heavyTank" : "tank");
    if (wave > 2) for (let i = 0; i < Math.floor(scaledWave / 2); i += 1) roster.push("artillery");
    if (wave > 4) for (let i = 0; i < Math.floor(scaledWave / 3); i += 1) roster.push(i % 2 ? "gunship" : "interceptor");
    if (wave > 6) roster.push("aaTank", "hover");
    if (wave > 8) roster.push("missileTank");
    if (wave > 8) roster.push("repairTank");
    if (wave > 10) roster.push("shieldTank");
    if (wave > 11) roster.push("heavyHover");
    if (wave > 13) roster.push("heavyGunship");
    if (wave > 14) roster.push("laserTank");
    if (wave > 7) roster.push("minigunMech");
    if (wave > 9) roster.push("artilleryMech");
    if (wave > 12) roster.push("plasmaMech");
    if (wave > 15) roster.push("teslaMech");
    if (wave > 9) roster.push("experimental");
    if (wave > 17) roster.push("experimentalTank");

    const units = roster.map((type, i) => {
      const cols = Math.ceil(Math.sqrt(roster.length));
      const x = spawn.x + (i % cols) * 42 - cols * 21;
      const y = spawn.y + Math.floor(i / cols) * 42;
      return createUnit(type, TEAM_ENEMY, x, y);
    });
    for (const unit of units) {
      unit.order = {
        type: "attackMove",
        x: playerCommand.x + randomRange(-220, 220),
        y: playerCommand.y + randomRange(-210, 210),
      };
    }
    addMessage(`生存波次 ${wave}: ${units.length} 个敌军进入战场。`, "danger");
  }

  function updateFog(force = false, dt = 0) {
    state.fog.clock -= dt;
    if (!force && state.fog.clock > 0) return;
    state.fog.clock = 0.28;
    const fog = state.fog;
    for (let i = 0; i < fog.status.length; i += 1) {
      if (fog.status[i] === 2) fog.status[i] = 1;
    }

    const viewers = allEntities().filter((e) => !e.dead && e.team === TEAM_PLAYER && (e.kind === "unit" || e.buildProgress >= 1));
    for (const entity of viewers) {
      const radius = entityVision(entity);
      const minX = clamp(Math.floor((entity.x - radius) / FOG), 0, fog.cols - 1);
      const maxX = clamp(Math.floor((entity.x + radius) / FOG), 0, fog.cols - 1);
      const minY = clamp(Math.floor((entity.y - radius) / FOG), 0, fog.rows - 1);
      const maxY = clamp(Math.floor((entity.y + radius) / FOG), 0, fog.rows - 1);
      for (let y = minY; y <= maxY; y += 1) {
        for (let x = minX; x <= maxX; x += 1) {
          const cx = x * FOG + FOG / 2;
          const cy = y * FOG + FOG / 2;
          if (dist2(cx, cy, entity.x, entity.y) < radius * radius) {
            fog.status[y * fog.cols + x] = 2;
          }
        }
      }
    }
  }

  function isVisibleAt(x, y) {
    if (!state || !state.fog) return true;
    const cx = clamp(Math.floor(x / FOG), 0, state.fog.cols - 1);
    const cy = clamp(Math.floor(y / FOG), 0, state.fog.rows - 1);
    return state.fog.status[cy * state.fog.cols + cx] === 2;
  }

  function radarSources(team = TEAM_PLAYER) {
    return state.buildings.filter((b) => !b.dead && b.team === team && entityRadarRange(b) > 0);
  }

  function isRadarDetected(entity, team = TEAM_PLAYER) {
    if (!entity || entity.dead || entity.team === team) return false;
    if (entity.kind === "unit" && entity.carriedBy) return false;
    for (const radar of radarSources(team)) {
      const range = entityRadarRange(radar);
      if (dist2(entity.x, entity.y, radar.x, radar.y) <= range * range) return true;
    }
    return false;
  }

  function isExploredAt(x, y) {
    if (!state || !state.fog) return true;
    const cx = clamp(Math.floor(x / FOG), 0, state.fog.cols - 1);
    const cy = clamp(Math.floor(y / FOG), 0, state.fog.rows - 1);
    return state.fog.status[cy * state.fog.cols + cx] > 0;
  }

  function campaignObjectiveText() {
    const stage = state.campaign?.stage || 0;
    if (stage === 0) return `战役 01-${stage + 1}: 占领 2 个资源点`;
    if (stage === 1) return `战役 01-${stage + 1}: 集结 8 个作战单位`;
    if (stage === 2) return `战役 01-${stage + 1}: 摧毁前线炮塔`;
    return `战役 01-${stage + 1}: 摧毁红方指挥中心`;
  }

  function updateCampaign() {
    if (state.mode !== "campaign" || state.gameOver) return;
    const stage = state.campaign.stage;
    if (stage === 0) {
      const extractors = state.buildings.filter((b) => !b.dead && b.team === TEAM_PLAYER && b.type === "extractor" && b.buildProgress >= 1).length;
      if (extractors >= 2) completeCampaignStage("资源网络已建立。奖励 500 资源。", 500);
    } else if (stage === 1) {
      const combatUnits = state.units.filter((u) => !u.dead && u.team === TEAM_PLAYER && isCombatUnit(u)).length;
      if (combatUnits >= 8) completeCampaignStage("突击队已集结。奖励 700 资源。", 700);
    } else if (stage === 2) {
      if (!findEntity(state.campaign.frontTurretId)) completeCampaignStage("前线炮塔已摧毁。奖励 900 资源。", 900);
    } else if (stage === 3) {
      if (!findEntity(state.campaign.enemyCommandId)) {
        state.gameOver = "victory";
        addMessage("战役完成：红方基地已被清除。", "info");
      }
    }
  }

  function completeCampaignStage(message, reward) {
    state.campaign.stage += 1;
    state.metal[TEAM_PLAYER] += reward;
    addMessage(message, "info");
    if (state.campaign.stage === 1) addMessage("新目标：生产并集结作战单位。", "warn");
    else if (state.campaign.stage === 2) addMessage("新目标：攻击红方前线炮塔。", "warn");
    else if (state.campaign.stage === 3) addMessage("最终目标：摧毁红方指挥中心。", "danger");
    markUiDirty();
  }

  function checkWinLoss() {
    if (state.gameOver) return;
    if (state.mode === "sandbox") return;
    const playerCommand = state.buildings.some((b) => !b.dead && b.team === TEAM_PLAYER && b.type === "command");
    const enemyCommand = state.buildings.some((b) => !b.dead && b.team === TEAM_ENEMY && b.type === "command");
    if (!playerCommand) {
      state.gameOver = "defeat";
      addMessage("失败：指挥中心被摧毁。", "danger");
    } else if (state.mode === "challenge") {
      const remaining = state.challenge.targetIds.filter((id) => findEntity(id)).length;
      if (remaining === 0) {
        state.gameOver = "victory";
        addMessage("挑战完成：红方采集网络已被摧毁。", "info");
      } else if (state.challenge.timer <= 0) {
        state.gameOver = "defeat";
        addMessage("挑战失败：任务时间耗尽。", "danger");
      }
    } else if (state.mode !== "survival" && state.mode !== "campaign" && !enemyCommand) {
      state.gameOver = "victory";
      addMessage("胜利：红方指挥中心已被摧毁。", "info");
    }
  }

  function render() {
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, viewW, viewH);

    ctx.save();
    ctx.setTransform(
      dpr * camera.zoom,
      0,
      0,
      dpr * camera.zoom,
      dpr * (viewW / 2 - camera.x * camera.zoom),
      dpr * (viewH / 2 - camera.y * camera.zoom),
    );
    ctx.drawImage(terrainCanvas, 0, 0);
    drawWorldGrid();
    drawResources();
    drawWrecks();
    drawRallyLines();
    drawQueuedOrderLines();
    drawPatrolLines();
    drawGuardLines();
    drawBuildings();
    drawUnits();
    drawProjectiles();
    drawParticles();
    drawBuildGhost();
    drawFormationPreview();
    drawFog();
    drawRadarContacts();
    ctx.restore();

    drawSelectionBox();
    drawModeReticle();
    if (state.gameOver) drawGameOver();
    renderMinimap();
  }

  function drawWorldGrid() {
    if (camera.zoom < 0.7) return;
    ctx.save();
    ctx.strokeStyle = "rgba(255,255,255,0.035)";
    ctx.lineWidth = 1 / camera.zoom;
    const rect = getViewportWorldRect();
    const startX = Math.floor(rect.x / TILE) * TILE;
    const endX = rect.x + rect.w;
    const startY = Math.floor(rect.y / TILE) * TILE;
    const endY = rect.y + rect.h;
    for (let x = startX; x < endX; x += TILE) {
      ctx.beginPath();
      ctx.moveTo(x, rect.y);
      ctx.lineTo(x, endY);
      ctx.stroke();
    }
    for (let y = startY; y < endY; y += TILE) {
      ctx.beginPath();
      ctx.moveTo(rect.x, y);
      ctx.lineTo(endX, y);
      ctx.stroke();
    }
    ctx.restore();
  }

  function drawResources() {
    for (const node of state.resources) {
      if (!isExploredAt(node.x, node.y)) continue;
      const extractor = extractorOnNode(node.id);
      ctx.save();
      ctx.globalAlpha = isVisibleAt(node.x, node.y) ? 1 : 0.55;
      ctx.beginPath();
      ctx.arc(node.x, node.y, 30, 0, Math.PI * 2);
      ctx.fillStyle = extractor ? teamDark[extractor.team] : "rgba(190, 190, 160, 0.28)";
      ctx.fill();
      ctx.lineWidth = 3;
      ctx.strokeStyle = extractor ? teamColor[extractor.team] : "rgba(255, 230, 130, 0.72)";
      ctx.stroke();
      ctx.fillStyle = "rgba(255, 232, 125, 0.9)";
      for (let i = 0; i < 5; i += 1) {
        const a = (i / 5) * Math.PI * 2;
        ctx.fillRect(node.x + Math.cos(a) * 13 - 3, node.y + Math.sin(a) * 13 - 3, 6, 6);
      }
      ctx.restore();
    }
  }

  function drawWrecks() {
    for (const w of state.wrecks) {
      ctx.save();
      ctx.globalAlpha = clamp(w.ttl / 58, 0.15, 0.68);
      ctx.translate(w.x, w.y);
      ctx.rotate((w.x + w.y) * 0.01);
      ctx.fillStyle = "rgba(22, 24, 22, 0.75)";
      ctx.fillRect(-w.size / 2, -w.size / 3, w.size, w.size * 0.66);
      ctx.strokeStyle = "rgba(210, 190, 150, 0.22)";
      ctx.strokeRect(-w.size / 2, -w.size / 3, w.size, w.size * 0.66);
      if (w.maxMetal > 0) {
        const pct = clamp((w.metal || 0) / w.maxMetal, 0, 1);
        ctx.fillStyle = "rgba(255, 203, 97, 0.78)";
        ctx.fillRect(-w.size / 2, w.size * 0.42, w.size * pct, 3 / camera.zoom);
      }
      ctx.restore();
    }
  }

  function drawBuildings() {
    const buildings = state.buildings.slice().sort((a, b) => a.y - b.y);
    for (const b of buildings) {
      if (b.dead) continue;
      if (b.team === TEAM_ENEMY && !isVisibleAt(b.x, b.y)) continue;
      const def = buildingTypes[b.type];
      const half = def.size / 2;
      ctx.save();
      ctx.translate(b.x, b.y);
      ctx.globalAlpha = b.buildProgress < 1 ? 0.72 : 1;
      ctx.fillStyle = "rgba(0,0,0,0.28)";
      ctx.fillRect(-half + 5, -half + 7, def.size, def.size);
      ctx.fillStyle = teamDark[b.team];
      ctx.fillRect(-half, -half, def.size, def.size);
      ctx.strokeStyle = teamColor[b.team];
      ctx.lineWidth = 3;
      ctx.strokeRect(-half, -half, def.size, def.size);

      ctx.fillStyle = "rgba(255,255,255,0.13)";
      ctx.fillRect(-half + 8, -half + 8, def.size - 16, 9);
      ctx.fillRect(-half + 10, half - 17, def.size - 20, 7);

      if (b.type === "turret" || b.type === "aaTurret") {
        ctx.beginPath();
        ctx.arc(0, 0, half * 0.55, 0, Math.PI * 2);
        ctx.fillStyle = teamColor[b.team];
        ctx.fill();
        ctx.strokeStyle = "#111";
        ctx.stroke();
        ctx.fillStyle = "#20292b";
        ctx.fillRect(-4, -half * 0.9, 8, half);
      } else if (b.type === "laserDefence") {
        const current = buildingCurrentDef(b);
        const energyPct = current.shield ? clamp((b.shieldEnergy || 0) / current.shield.maxEnergy, 0, 1) : 0;
        ctx.beginPath();
        ctx.arc(0, 0, half * 0.6, 0, Math.PI * 2);
        ctx.fillStyle = "rgba(90, 220, 255, 0.72)";
        ctx.fill();
        ctx.strokeStyle = "#d9fbff";
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.arc(0, 0, half * 0.78, -Math.PI / 2, -Math.PI / 2 + energyPct * Math.PI * 2);
        ctx.stroke();
      } else if (b.type === "radar") {
        ctx.strokeStyle = "rgba(125, 225, 255, 0.7)";
        ctx.lineWidth = 3;
        for (let i = 0; i < 3; i += 1) {
          ctx.beginPath();
          ctx.arc(0, 0, half * (0.28 + i * 0.2), -0.35, 0.9);
          ctx.stroke();
        }
        ctx.beginPath();
        ctx.moveTo(0, half * 0.55);
        ctx.lineTo(0, -half * 0.46);
        ctx.stroke();
        ctx.fillStyle = "rgba(125, 225, 255, 0.7)";
        ctx.beginPath();
        ctx.arc(0, -half * 0.48, 5, 0, Math.PI * 2);
        ctx.fill();
      } else if (b.type === "antiNuke") {
        ctx.fillStyle = "#1b2427";
        ctx.fillRect(-10, -half * 0.62, 20, half * 1.24);
        ctx.fillStyle = "#ffd95e";
        for (let i = 0; i < Math.min(4, b.interceptorAmmo || 0); i += 1) {
          ctx.fillRect(-18 + i * 12, half * 0.42, 8, 10);
        }
      } else if (b.type === "extractor") {
        ctx.beginPath();
        ctx.arc(0, 0, half * 0.58, 0, Math.PI * 2);
        ctx.fillStyle = "#d9c068";
        ctx.fill();
        ctx.fillStyle = "#262b25";
        ctx.fillRect(-6, -half * 0.8, 12, half * 1.6);
      } else if (b.type === "nukeLauncher") {
        ctx.fillStyle = "#1b2427";
        ctx.fillRect(-8, -half * 0.65, 16, half * 1.3);
        ctx.fillStyle = "#f7d26a";
        ctx.fillRect(-11, -half * 0.76, 22, 8);
      } else {
        ctx.fillStyle = "#1c2426";
        ctx.fillRect(-half * 0.52, -half * 0.42, half * 1.04, half * 0.84);
      }

      ctx.fillStyle = "#f2f7f3";
      ctx.font = `${Math.max(12, def.size * 0.18)}px ui-sans-serif`;
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText(def.icon, 0, 1);
      if (buildingLevel(b) > 1) {
        ctx.fillStyle = "#b9f2ff";
        ctx.font = `${Math.max(9, def.size * 0.12)}px ui-sans-serif`;
        ctx.fillText(`T${buildingLevel(b)}`, 0, half - 9);
      }

      if (b.buildProgress < 1) {
        ctx.strokeStyle = "rgba(110, 220, 255, 0.85)";
        ctx.lineWidth = 5;
        ctx.beginPath();
        ctx.arc(0, 0, half + 8, -Math.PI / 2, -Math.PI / 2 + b.buildProgress * Math.PI * 2);
        ctx.stroke();
      }
      ctx.restore();
      drawHealthBar(b, b.x, b.y - half - 13, def.size);
      if (selectedIds.has(b.id) && buildingCurrentDef(b).radar) drawRadarRange(b);
    }
  }

  function drawUnits() {
    const units = state.units.slice().sort((a, b) => a.y - b.y);
    for (const u of units) {
      if (u.dead || u.carriedBy) continue;
      if (u.team === TEAM_ENEMY && !isVisibleAt(u.x, u.y)) continue;
      const def = unitTypes[u.type];
      ctx.save();
      ctx.translate(u.x, u.y);
      ctx.rotate(u.moveAngle || 0);
      ctx.fillStyle = "rgba(0,0,0,0.32)";
      ctx.beginPath();
      ctx.ellipse(2, 5, def.radius * 1.05, def.radius * 0.7, 0, 0, Math.PI * 2);
      ctx.fill();

      if (def.domain === "air") drawAirUnit(u, def);
      else if (def.domain === "sea") drawSeaUnit(u, def);
      else drawGroundUnit(u, def);

      ctx.restore();
      drawHealthBar(u, u.x, u.y - def.radius - 12, def.radius * 2.1);

      if (selectedIds.has(u.id)) {
        drawSelectionRing(u.x, u.y, def.radius + 7);
        drawUnitSupportAura(u, def);
        drawUnitModuleStatus(u, def);
      }
    }
  }

  function drawRadarRange(building) {
    const def = buildingCurrentDef(building);
    const radarRange = entityRadarRange(building);
    ctx.save();
    ctx.strokeStyle = "rgba(125, 225, 255, 0.18)";
    ctx.lineWidth = 2 / camera.zoom;
    ctx.setLineDash([12 / camera.zoom, 10 / camera.zoom]);
    ctx.beginPath();
    ctx.arc(building.x, building.y, radarRange || def.vision || 0, 0, Math.PI * 2);
    ctx.stroke();
    ctx.setLineDash([]);
    ctx.strokeStyle = "rgba(125, 225, 255, 0.34)";
    ctx.lineWidth = 1.5 / camera.zoom;
    ctx.beginPath();
    ctx.arc(building.x, building.y, def.vision || 0, 0, Math.PI * 2);
    ctx.stroke();
    ctx.restore();
  }

  function drawRadarContacts() {
    const contacts = allEntities().filter((entity) => entity.team === TEAM_ENEMY && !isVisibleAt(entity.x, entity.y) && isRadarDetected(entity));
    if (!contacts.length) return;
    ctx.save();
    ctx.strokeStyle = "rgba(125, 225, 255, 0.82)";
    ctx.fillStyle = "rgba(125, 225, 255, 0.22)";
    ctx.lineWidth = 2 / camera.zoom;
    for (const contact of contacts) {
      const r = contact.kind === "building" ? 13 : 9;
      ctx.beginPath();
      ctx.arc(contact.x, contact.y, r, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(contact.x - r - 5, contact.y);
      ctx.lineTo(contact.x - r + 2, contact.y);
      ctx.moveTo(contact.x + r - 2, contact.y);
      ctx.lineTo(contact.x + r + 5, contact.y);
      ctx.moveTo(contact.x, contact.y - r - 5);
      ctx.lineTo(contact.x, contact.y - r + 2);
      ctx.moveTo(contact.x, contact.y + r - 2);
      ctx.lineTo(contact.x, contact.y + r + 5);
      ctx.stroke();
    }
    ctx.restore();
  }

  function drawUnitModuleStatus(u, def) {
    if (!def.speedModule && !def.blinkModule) return;
    const r = def.radius + 14;
    ctx.save();
    ctx.lineWidth = 3 / camera.zoom;
    if (def.speedModule) {
      const pct = (u.speedBoost || 0) > 0 ? clamp((u.speedBoost || 0) / def.speedModule.duration, 0, 1) : 1 - clamp((u.speedCooldown || 0) / def.speedModule.cooldown, 0, 1);
      ctx.strokeStyle = (u.speedBoost || 0) > 0 ? "rgba(105, 255, 145, 0.88)" : "rgba(105, 255, 145, 0.34)";
      ctx.beginPath();
      ctx.arc(u.x, u.y, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * pct);
      ctx.stroke();
    }
    if (def.blinkModule) {
      const pct = 1 - clamp((u.blinkCooldown || 0) / def.blinkModule.cooldown, 0, 1);
      ctx.strokeStyle = "rgba(125, 225, 255, 0.5)";
      ctx.beginPath();
      ctx.arc(u.x, u.y, r + 5, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * pct);
      ctx.stroke();
    }
    ctx.restore();
  }

  function drawGroundUnit(u, def) {
    const r = def.radius;
    ctx.fillStyle = teamColor[u.team];
    if (u.type === "artillery") {
      ctx.fillRect(-r * 0.9, -r * 0.55, r * 1.8, r * 1.1);
      ctx.fillStyle = "#1c2528";
      ctx.fillRect(0, -3, r * 1.45, 6);
    } else if (u.type === "builder") {
      ctx.fillRect(-r * 0.9, -r * 0.75, r * 1.8, r * 1.5);
      ctx.fillStyle = "#1c2528";
      ctx.fillRect(r * 0.1, -r * 0.3, r * 0.8, r * 0.6);
      ctx.fillStyle = "#b9f2ff";
      ctx.fillRect(-r * 0.55, -3, r * 0.8, 6);
    } else if (u.type === "repairTank") {
      roundRect(-r, -r * 0.65, r * 2, r * 1.3, 4);
      ctx.fill();
      ctx.fillStyle = "#1c2528";
      ctx.fillRect(-r * 0.16, -r * 0.52, r * 0.32, r * 1.04);
      ctx.fillRect(-r * 0.52, -r * 0.16, r * 1.04, r * 0.32);
    } else if (u.type === "shieldTank") {
      roundRect(-r, -r * 0.68, r * 2, r * 1.36, 4);
      ctx.fill();
      ctx.fillStyle = "rgba(185, 242, 255, 0.42)";
      ctx.beginPath();
      ctx.arc(0, 0, r * 0.55, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = "#1c2528";
      ctx.fillRect(r * 0.1, -2.5, r * 0.92, 5);
    } else if (def.mech) {
      ctx.strokeStyle = "#142022";
      ctx.lineWidth = 4;
      for (const side of [-1, 1]) {
        ctx.beginPath();
        ctx.moveTo(-r * 0.25, side * r * 0.25);
        ctx.lineTo(-r * 0.72, side * r * 0.7);
        ctx.lineTo(-r * 0.95, side * r * 1.02);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(r * 0.25, side * r * 0.22);
        ctx.lineTo(r * 0.65, side * r * 0.66);
        ctx.lineTo(r * 0.9, side * r * 0.96);
        ctx.stroke();
      }
      ctx.fillStyle = teamColor[u.team];
      ctx.beginPath();
      ctx.ellipse(0, 0, r * 0.82, r * 0.62, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = u.type === "teslaMech" ? "rgba(130, 235, 255, 0.75)" : u.type === "plasmaMech" ? "rgba(255, 180, 100, 0.78)" : "#11191b";
      ctx.beginPath();
      ctx.arc(r * 0.08, 0, r * 0.34, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = "#11191b";
      ctx.fillRect(r * 0.05, -3, r * 1.05, 6);
    } else if (u.type === "spider") {
      ctx.strokeStyle = "#142022";
      ctx.lineWidth = 4;
      for (const side of [-1, 1]) {
        for (let i = -1.5; i <= 1.5; i += 1) {
          ctx.beginPath();
          ctx.moveTo(-r * 0.2, i * r * 0.22);
          ctx.lineTo(-r * 0.75, side * r * 0.65 + i * r * 0.18);
          ctx.lineTo(-r * 1.15, side * r * 0.9 + i * r * 0.18);
          ctx.stroke();
        }
      }
      ctx.fillStyle = teamColor[u.team];
      ctx.beginPath();
      ctx.ellipse(0, 0, r * 0.9, r * 0.62, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = "#11191b";
      ctx.fillRect(-r * 0.15, -r * 0.18, r * 1.1, r * 0.36);
    } else if (u.type === "experimental") {
      polygon([
        [-r * 0.9, -r * 0.7],
        [r * 0.65, -r * 0.95],
        [r, 0],
        [r * 0.65, r * 0.95],
        [-r * 0.9, r * 0.7],
      ]);
      ctx.fill();
      ctx.fillStyle = "#11191b";
      ctx.fillRect(-r * 0.2, -r * 0.28, r * 1.35, r * 0.56);
    } else {
      roundRect(-r, -r * 0.65, r * 2, r * 1.3, 4);
      ctx.fill();
      ctx.fillStyle = "#1c2528";
      ctx.fillRect(0, -2.5, r * 1.1, 5);
      ctx.beginPath();
      ctx.arc(-r * 0.1, 0, r * 0.46, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.strokeStyle = "#142022";
    ctx.lineWidth = 2;
    ctx.stroke();

    ctx.rotate(-(u.moveAngle || 0));
    ctx.fillStyle = "#f6fbf5";
    ctx.font = `${Math.max(9, r * 0.8)}px ui-sans-serif`;
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillText(def.icon, 0, 0);
  }

  function drawUnitSupportAura(u, def) {
    const support = def.shieldEmitter || (def.repairAura ? { range: def.repairAura, repair: true } : null) || def.antiNuke;
    if (!support) return;
    ctx.save();
    ctx.strokeStyle = def.antiNuke ? "rgba(255, 230, 110, 0.28)" : def.shieldEmitter ? "rgba(95, 225, 255, 0.32)" : "rgba(105, 255, 145, 0.28)";
    ctx.lineWidth = 2 / camera.zoom;
    ctx.setLineDash([8 / camera.zoom, 8 / camera.zoom]);
    ctx.beginPath();
    ctx.arc(u.x, u.y, support.range, 0, Math.PI * 2);
    ctx.stroke();
    ctx.restore();
  }

  function drawAirUnit(u, def) {
    const r = def.radius;
    ctx.fillStyle = teamColor[u.team];
    polygon([
      [r, 0],
      [-r * 0.55, -r * 0.8],
      [-r * 0.25, 0],
      [-r * 0.55, r * 0.8],
    ]);
    ctx.fill();
    ctx.strokeStyle = "#142022";
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.fillStyle = "rgba(220,245,255,0.38)";
    ctx.fillRect(-r * 0.1, -r * 0.35, r * 0.58, r * 0.7);
    if (def.transportCapacity) {
      const used = cargoLoad(u);
      ctx.fillStyle = "rgba(12,18,20,0.85)";
      ctx.fillRect(-r * 0.72, r * 0.5, r * 1.35, 5);
      ctx.fillStyle = "#9ee9ff";
      ctx.fillRect(-r * 0.7, r * 0.52, r * 1.3 * (used / def.transportCapacity), 3);
    }
    ctx.rotate(-(u.moveAngle || 0));
    ctx.fillStyle = "#f6fbf5";
    ctx.font = `${Math.max(9, r * 0.72)}px ui-sans-serif`;
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillText(def.icon, 0, 0);
  }

  function drawSeaUnit(u, def) {
    const r = def.radius;
    ctx.fillStyle = teamColor[u.team];
    polygon([
      [r * 1.2, 0],
      [r * 0.35, -r * 0.75],
      [-r, -r * 0.55],
      [-r * 1.15, 0],
      [-r, r * 0.55],
      [r * 0.35, r * 0.75],
    ]);
    ctx.fill();
    ctx.strokeStyle = "#142022";
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.fillStyle = "#1c2528";
    if (u.type === "heavyAaShip") {
      ctx.fillRect(-r * 0.45, -r * 0.38, r * 0.88, r * 0.24);
      ctx.fillRect(-r * 0.45, r * 0.14, r * 0.88, r * 0.24);
      ctx.fillStyle = "#ffd95e";
      ctx.fillRect(r * 0.05, -r * 0.48, r * 0.28, r * 0.2);
      ctx.fillRect(r * 0.05, r * 0.28, r * 0.28, r * 0.2);
    } else if (u.type === "nautilus") {
      ctx.fillStyle = "rgba(60, 180, 210, 0.42)";
      ctx.beginPath();
      ctx.ellipse(-r * 0.15, 0, r * 0.72, r * 0.36, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = "#10191d";
      ctx.fillRect(-r * 0.25, -r * 0.22, r * 1.05, r * 0.44);
      ctx.fillStyle = "#ffd95e";
      for (let i = 0; i < Math.min(2, u.interceptorAmmo || 0); i += 1) {
        ctx.fillRect(-r * 0.45 + i * r * 0.28, r * 0.45, r * 0.16, r * 0.22);
      }
    } else {
      ctx.fillRect(-r * 0.25, -r * 0.22, r * 0.9, r * 0.44);
    }
    if (def.transportCapacity) {
      const used = cargoLoad(u);
      ctx.fillStyle = "rgba(12,18,20,0.85)";
      ctx.fillRect(-r * 0.72, r * 0.55, r * 1.35, 5);
      ctx.fillStyle = "#9ee9ff";
      ctx.fillRect(-r * 0.7, r * 0.57, r * 1.3 * (used / def.transportCapacity), 3);
    }
    ctx.rotate(-(u.moveAngle || 0));
    ctx.fillStyle = "#f6fbf5";
    ctx.font = `${Math.max(9, r * 0.62)}px ui-sans-serif`;
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillText(def.icon, 0, 0);
  }

  function polygon(points) {
    ctx.beginPath();
    points.forEach(([x, y], index) => {
      if (index === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.closePath();
  }

  function roundRect(x, y, w, h, r) {
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.lineTo(x + w - r, y);
    ctx.quadraticCurveTo(x + w, y, x + w, y + r);
    ctx.lineTo(x + w, y + h - r);
    ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
    ctx.lineTo(x + r, y + h);
    ctx.quadraticCurveTo(x, y + h, x, y + h - r);
    ctx.lineTo(x, y + r);
    ctx.quadraticCurveTo(x, y, x + r, y);
    ctx.closePath();
  }

  function drawHealthBar(entity, x, y, w) {
    if (entity.hp >= entity.maxHp && entity.buildProgress >= 1 && !selectedIds.has(entity.id)) return;
    const pct = clamp(entity.hp / entity.maxHp, 0, 1);
    ctx.save();
    ctx.fillStyle = "rgba(0,0,0,0.55)";
    ctx.fillRect(x - w / 2, y, w, 5);
    ctx.fillStyle = pct > 0.55 ? "#6ce06f" : pct > 0.25 ? "#ffd15a" : "#ff6464";
    ctx.fillRect(x - w / 2, y, w * pct, 5);
    if (entity.buildProgress < 1) {
      ctx.fillStyle = "#65d7ff";
      ctx.fillRect(x - w / 2, y + 6, w * entity.buildProgress, 4);
    } else if (entity.maxShield) {
      ctx.fillStyle = "rgba(40, 120, 150, 0.65)";
      ctx.fillRect(x - w / 2, y + 6, w, 4);
      ctx.fillStyle = "#65d7ff";
      ctx.fillRect(x - w / 2, y + 6, w * clamp((entity.shield || 0) / entity.maxShield, 0, 1), 4);
    } else if (entity.kind === "unit" && unitTypes[entity.type].shieldEmitter) {
      const emitter = unitTypes[entity.type].shieldEmitter;
      ctx.fillStyle = "rgba(40, 120, 150, 0.65)";
      ctx.fillRect(x - w / 2, y + 6, w, 4);
      ctx.fillStyle = "#65d7ff";
      ctx.fillRect(x - w / 2, y + 6, w * clamp((entity.shieldEnergy || 0) / emitter.maxEnergy, 0, 1), 4);
    }
    ctx.restore();
  }

  function drawSelectionRing(x, y, r) {
    ctx.save();
    ctx.strokeStyle = "#d8ffe2";
    ctx.lineWidth = 2 / camera.zoom;
    ctx.beginPath();
    ctx.ellipse(x, y, r, r * 0.72, 0, 0, Math.PI * 2);
    ctx.stroke();
    ctx.restore();
  }

  function drawRallyLines() {
    for (const b of state.buildings) {
      if (b.dead || b.team !== TEAM_PLAYER || !selectedIds.has(b.id) || !b.rally) continue;
      ctx.save();
      ctx.strokeStyle = "rgba(100, 220, 255, 0.72)";
      ctx.setLineDash([12, 8]);
      ctx.lineWidth = 2 / camera.zoom;
      ctx.beginPath();
      ctx.moveTo(b.x, b.y);
      ctx.lineTo(b.rally.x, b.rally.y);
      ctx.stroke();
      ctx.fillStyle = "rgba(100, 220, 255, 0.9)";
      ctx.beginPath();
      ctx.arc(b.rally.x, b.rally.y, 8, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    }
  }

  function orderAnchor(order) {
    if (!order) return null;
    if (order.x !== undefined && order.y !== undefined) return { x: order.x, y: order.y };
    if (order.targetId) {
      const target = findEntity(order.targetId);
      if (target) return { x: target.x, y: target.y };
    }
    if (order.wreckId) {
      const wreck = getWreckById(order.wreckId);
      if (wreck) return { x: wreck.x, y: wreck.y };
    }
    return null;
  }

  function drawQueuedOrderLines() {
    for (const u of state.units) {
      if (u.dead || u.carriedBy || !selectedIds.has(u.id) || !u.orderQueue?.length) continue;
      ctx.save();
      ctx.strokeStyle = "rgba(180, 230, 255, 0.46)";
      ctx.fillStyle = "rgba(180, 230, 255, 0.72)";
      ctx.setLineDash([5 / camera.zoom, 7 / camera.zoom]);
      ctx.lineWidth = 1.6 / camera.zoom;
      let from = orderAnchor(u.order) || { x: u.x, y: u.y };
      for (const order of u.orderQueue) {
        const to = orderAnchor(order);
        if (!to) continue;
        ctx.beginPath();
        ctx.moveTo(from.x, from.y);
        ctx.lineTo(to.x, to.y);
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(to.x, to.y, 5 / camera.zoom, 0, Math.PI * 2);
        ctx.fill();
        from = to;
      }
      ctx.restore();
    }
  }

  function drawPatrolLines() {
    for (const u of state.units) {
      if (u.dead || u.carriedBy || !selectedIds.has(u.id)) continue;
      const patrol = u.order?.type === "patrol" ? u.order : u.order?.resume?.type === "patrol" ? u.order.resume : null;
      if (!patrol) continue;
      ctx.save();
      ctx.strokeStyle = "rgba(105, 215, 255, 0.7)";
      ctx.setLineDash([10 / camera.zoom, 7 / camera.zoom]);
      ctx.lineWidth = 2 / camera.zoom;
      ctx.beginPath();
      ctx.moveTo(patrol.fromX, patrol.fromY);
      ctx.lineTo(patrol.x, patrol.y);
      ctx.stroke();
      ctx.fillStyle = "rgba(105, 215, 255, 0.9)";
      for (const point of [
        { x: patrol.fromX, y: patrol.fromY },
        { x: patrol.x, y: patrol.y },
      ]) {
        ctx.beginPath();
        ctx.arc(point.x, point.y, 7 / camera.zoom, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.restore();
    }
  }

  function drawGuardLines() {
    for (const u of state.units) {
      if (u.dead || u.carriedBy || !selectedIds.has(u.id)) continue;
      const guard = u.order?.type === "guard" ? u.order : u.order?.resume?.type === "guard" ? u.order.resume : null;
      if (!guard) continue;
      const guarded = findEntity(guard.targetId);
      if (!guarded) continue;
      ctx.save();
      ctx.strokeStyle = "rgba(117, 229, 141, 0.72)";
      ctx.setLineDash([8 / camera.zoom, 7 / camera.zoom]);
      ctx.lineWidth = 2 / camera.zoom;
      ctx.beginPath();
      ctx.moveTo(u.x, u.y);
      ctx.lineTo(guarded.x, guarded.y);
      ctx.stroke();
      ctx.fillStyle = "rgba(117, 229, 141, 0.9)";
      ctx.beginPath();
      ctx.arc(guarded.x, guarded.y, Math.max(7, entityRadius(guarded) * 0.22), 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    }
  }

  function drawProjectiles() {
    for (const p of state.projectiles) {
      ctx.save();
      if (p.kind === "nuke") {
        ctx.strokeStyle = "rgba(255, 230, 110, 0.48)";
        ctx.lineWidth = 4 / camera.zoom;
        ctx.beginPath();
        ctx.moveTo(p.sx, p.sy);
        ctx.lineTo(p.x, p.y);
        ctx.stroke();
        ctx.fillStyle = "#fff08a";
        ctx.beginPath();
        ctx.arc(p.x, p.y, 10, 0, Math.PI * 2);
        ctx.fill();
      } else {
        ctx.strokeStyle = p.kind === "missile" ? "#ffd45f" : p.kind === "tesla" ? "#78ebff" : "#fff3a6";
        ctx.lineWidth = (p.kind === "tesla" ? 4 : 3) / camera.zoom;
        ctx.beginPath();
        ctx.moveTo(p.x, p.y);
        const a = angleTo(p.sx, p.sy, p.tx, p.ty);
        ctx.lineTo(p.x - Math.cos(a) * 12, p.y - Math.sin(a) * 12);
        ctx.stroke();
      }
      ctx.restore();
    }
  }

  function drawParticles() {
    for (const p of state.particles) {
      ctx.save();
      ctx.globalAlpha = clamp(p.life / p.maxLife, 0, 1);
      ctx.fillStyle = p.color;
      ctx.fillRect(p.x - p.size / 2, p.y - p.size / 2, p.size, p.size);
      ctx.restore();
    }
  }

  function drawBuildGhost() {
    if (!input.buildMode) return;
    const def = buildingTypes[input.buildMode];
    const snap = snapBuild(input.buildMode, input.worldX, input.worldY);
    const validation = validatePlacement(input.buildMode, snap.x, snap.y, TEAM_PLAYER, input.shift);
    ctx.save();
    ctx.globalAlpha = 0.58;
    ctx.fillStyle = validation.ok ? "rgba(90, 235, 125, 0.45)" : "rgba(255, 80, 80, 0.45)";
    ctx.strokeStyle = validation.ok ? "#8dff9a" : "#ff7373";
    ctx.lineWidth = 3 / camera.zoom;
    ctx.fillRect(snap.x - def.size / 2, snap.y - def.size / 2, def.size, def.size);
    ctx.strokeRect(snap.x - def.size / 2, snap.y - def.size / 2, def.size, def.size);
    if (def.weapon) {
      ctx.beginPath();
      ctx.arc(snap.x, snap.y, def.weapon.range, 0, Math.PI * 2);
      ctx.strokeStyle = "rgba(255,255,255,0.3)";
      ctx.stroke();
    }
    if (def.shield || def.antiNuke || def.radar) {
      const range = def.shield ? def.shield.range : def.antiNuke ? def.antiNuke.range : def.radarRange || def.vision;
      ctx.beginPath();
      ctx.arc(snap.x, snap.y, range, 0, Math.PI * 2);
      ctx.strokeStyle = def.shield || def.radar ? "rgba(95, 225, 255, 0.34)" : "rgba(255, 220, 95, 0.34)";
      ctx.stroke();
      if (def.radarRange && def.vision) {
        ctx.beginPath();
        ctx.arc(snap.x, snap.y, def.vision, 0, Math.PI * 2);
        ctx.strokeStyle = "rgba(180, 245, 255, 0.26)";
        ctx.stroke();
      }
    }
    ctx.restore();
  }

  function shouldDrawFormationPreview(selection) {
    if (state.mode === "sandbox" || input.isDown || input.pan || input.buildMode || input.guardMode || input.reclaimMode || input.nukeSourceId || input.unloadTransportIds || input.blinkUnitIds) return false;
    if (!movableUnits(selection).length) return false;
    if (input.attackMove || input.patrolMode) return true;
    const hoverTarget = topEntityAt(input.worldX, input.worldY, true);
    return !hoverTarget;
  }

  function drawFormationPreview() {
    const selection = currentSelection();
    if (!shouldDrawFormationPreview(selection)) return;
    const targets = formationTargets(selection, input.worldX, input.worldY);
    if (!targets.length) return;

    const color = input.attackMove ? "255, 105, 105" : input.patrolMode ? "105, 215, 255" : "120, 240, 135";
    ctx.save();
    ctx.strokeStyle = `rgba(${color}, 0.72)`;
    ctx.fillStyle = `rgba(${color}, 0.18)`;
    ctx.lineWidth = 1.8 / camera.zoom;
    ctx.setLineDash([7 / camera.zoom, 6 / camera.zoom]);
    for (const target of targets) {
      const radius = Math.max(10, unitTypes[target.unit.type].radius * 0.55);
      ctx.beginPath();
      ctx.ellipse(target.x, target.y, radius, radius * 0.7, 0, 0, Math.PI * 2);
      ctx.fill();
      ctx.stroke();
    }
    ctx.setLineDash([]);
    ctx.fillStyle = `rgba(${color}, 0.88)`;
    ctx.beginPath();
    ctx.arc(input.worldX, input.worldY, 7 / camera.zoom, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  function drawFog() {
    ctx.save();
    for (let y = 0; y < state.fog.rows; y += 1) {
      for (let x = 0; x < state.fog.cols; x += 1) {
        const status = state.fog.status[y * state.fog.cols + x];
        if (status === 2) continue;
        ctx.fillStyle = status === 1 ? "rgba(0,0,0,0.40)" : "rgba(0,0,0,0.84)";
        ctx.fillRect(x * FOG, y * FOG, FOG + 1, FOG + 1);
      }
    }
    ctx.restore();
  }

  function drawSelectionBox() {
    if (!input.dragSelect) return;
    ctx.save();
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    const x = Math.min(input.downX, input.mouseX);
    const y = Math.min(input.downY, input.mouseY);
    const w = Math.abs(input.mouseX - input.downX);
    const h = Math.abs(input.mouseY - input.downY);
    ctx.fillStyle = "rgba(95, 205, 255, 0.13)";
    ctx.strokeStyle = "rgba(150, 230, 255, 0.9)";
    ctx.lineWidth = 1.5;
    ctx.fillRect(x, y, w, h);
    ctx.strokeRect(x, y, w, h);
    ctx.restore();
  }

  function drawModeReticle() {
    if (!input.attackMove && !input.patrolMode && !input.guardMode && !input.reclaimMode && !input.nukeSourceId && !input.blinkUnitIds) return;
    ctx.save();
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    const color = input.blinkUnitIds ? "#7de1ff" : input.nukeSourceId || input.reclaimMode ? "#ffd766" : input.guardMode ? "#75e58d" : input.patrolMode ? "#6bd6ff" : "#ff6969";
    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(input.mouseX, input.mouseY, 16, 0, Math.PI * 2);
    ctx.moveTo(input.mouseX - 24, input.mouseY);
    ctx.lineTo(input.mouseX + 24, input.mouseY);
    ctx.moveTo(input.mouseX, input.mouseY - 24);
    ctx.lineTo(input.mouseX, input.mouseY + 24);
    ctx.stroke();
    ctx.restore();
  }

  function drawGameOver() {
    ctx.save();
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.fillStyle = "rgba(0,0,0,0.48)";
    ctx.fillRect(0, 0, viewW, viewH);
    ctx.fillStyle = "#f2f7f2";
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.font = "800 42px ui-sans-serif";
    ctx.fillText(state.gameOver === "victory" ? "VICTORY" : "DEFEAT", viewW / 2, viewH / 2 - 28);
    ctx.font = "700 16px ui-sans-serif";
    ctx.fillStyle = "#cbd5d2";
    ctx.fillText("按 R 或右上角重新开始", viewW / 2, viewH / 2 + 20);
    ctx.restore();
  }

  function renderMinimap() {
    const w = minimap.width;
    const h = minimap.height;
    mctx.clearRect(0, 0, w, h);
    if (terrainCanvas) mctx.drawImage(terrainCanvas, 0, 0, w, h);

    for (let y = 0; y < state.fog.rows; y += 1) {
      for (let x = 0; x < state.fog.cols; x += 1) {
        const status = state.fog.status[y * state.fog.cols + x];
        if (status === 2) continue;
        mctx.fillStyle = status === 1 ? "rgba(0,0,0,0.28)" : "rgba(0,0,0,0.76)";
        mctx.fillRect((x * FOG * w) / MAP_W, (y * FOG * h) / MAP_H, (FOG * w) / MAP_W + 1, (FOG * h) / MAP_H + 1);
      }
    }

    for (const node of state.resources) {
      if (!isExploredAt(node.x, node.y)) continue;
      mctx.fillStyle = "#ffd95e";
      mctx.fillRect((node.x * w) / MAP_W - 1.5, (node.y * h) / MAP_H - 1.5, 3, 3);
    }

    for (const e of allEntities()) {
      if (e.dead) continue;
      const visible = e.team !== TEAM_ENEMY || isVisibleAt(e.x, e.y);
      const radar = !visible && e.team === TEAM_ENEMY && isRadarDetected(e);
      if (!visible && !radar) continue;
      mctx.fillStyle = radar ? "#7de1ff" : teamColor[e.team];
      const size = radar ? 2.2 : e.kind === "building" ? 4 : 2.4;
      mctx.fillRect((e.x * w) / MAP_W - size / 2, (e.y * h) / MAP_H - size / 2, size, size);
    }

    const rect = getViewportWorldRect();
    mctx.strokeStyle = "#f4fbff";
    mctx.lineWidth = 1;
    mctx.strokeRect((rect.x * w) / MAP_W, (rect.y * h) / MAP_H, (rect.w * w) / MAP_W, (rect.h * h) / MAP_H);
  }

  function refreshUI() {
    uiDirty = false;
    ensureSandbox();
    const selection = currentSelection();
    const supply = teamSupply(TEAM_PLAYER);
    const enemies = state.units.filter((u) => !u.dead && u.team === TEAM_ENEMY).length + state.buildings.filter((b) => !b.dead && b.team === TEAM_ENEMY).length;

    ui.metal.textContent = Math.floor(state.metal[TEAM_PLAYER]).toString();
    ui.income.textContent = `+${incomeFor(TEAM_PLAYER).toFixed(1)}/s`;
    ui.supply.textContent = `${supply.used}/${supply.cap}`;
    ui.enemy.textContent = `${enemies} 个信号`;
    ui.ai.textContent = `AI ${aiProfile().label}`;
    ui.map.textContent = `MP ${mapLabel(state.mapKey)}`;
    const challengeTargets = state.challenge?.targetIds?.filter((id) => findEntity(id))?.length || 0;
    ui.objective.textContent =
      state.mode === "survival"
        ? `生存波次 ${state.ai.survivalWave} · 下波 ${Math.max(0, Math.ceil(state.ai.survivalClock))}s`
        : state.mode === "challenge"
          ? `剩余采集器 ${challengeTargets}/3 · ${Math.ceil(state.challenge.timer)}s`
          : state.mode === "campaign"
            ? campaignObjectiveText()
            : state.mode === "sandbox"
              ? sandboxObjectiveText()
              : "摧毁红方指挥中心";
    ui.campaign.classList.toggle("active", state.mode === "campaign");
    ui.skirmish.classList.toggle("active", state.mode === "skirmish");
    ui.survival.classList.toggle("active", state.mode === "survival");
    ui.challenge.classList.toggle("active", state.mode === "challenge");
    ui.sandbox.classList.toggle("active", state.mode === "sandbox");
    renderSandboxPanel();
    ui.pause.textContent = state.paused ? ">" : "II";
    ui.speed.textContent = `${state.speed}x`;
    renderStatsPanel();

    ui.badge.textContent = selection.length.toString();
    if (!selection.length) {
      ui.title.textContent = "未选择";
      ui.meta.textContent = "框选单位或建筑";
      ui.hpLabel.textContent = "-";
      ui.hpFill.style.width = "0%";
      ui.queue.innerHTML = "";
      renderCommands(selection);
      return;
    }

    const first = selection[0];
    const firstDef = entityDef(first);
    const sameType = selection.every((e) => e.kind === first.kind && e.type === first.type);
    const levelSuffix = first.kind === "building" && buildingLevel(first) > 1 ? ` T${buildingLevel(first)}` : "";
    ui.title.textContent = selection.length === 1 ? `${firstDef.name}${levelSuffix}` : sameType ? `${firstDef.name}${levelSuffix} x${selection.length}` : `混合编队 x${selection.length}`;
    if (selection.length === 1 && first.kind === "building") {
      const current = buildingCurrentDef(first);
      const incomeText = current.income ? `收入 +${current.income}/s` : "";
      const shieldText = current.shield ? `护盾 ${Math.floor(first.shieldEnergy || 0)}/${current.shield.maxEnergy}` : "";
      const antiText = current.antiNuke ? `反核 ${first.interceptorAmmo || 0}/${current.antiNuke.ammoMax}` : "";
      ui.meta.textContent = [firstDef.description, incomeText, shieldText, antiText].filter(Boolean).join(" · ");
    } else if (selection.length === 1 && first.kind === "unit" && isTransportUnit(first)) {
      ui.meta.textContent = `${firstDef.description} · 货舱 ${cargoLoad(first)}/${transportCapacity(first)}`;
    } else if (selection.length === 1 && first.kind === "unit" && unitTypes[first.type].antiNuke) {
      const def = unitTypes[first.type];
      const anti = def.antiNuke;
      const reload = (first.interceptorAmmo || 0) >= anti.ammoMax ? "已满" : `${Math.ceil(anti.reloadTime - (first.interceptorBuild || 0))}s`;
      const deploy = def.deploys ? `无人机 ${(first.deployCooldown || 0) > 0 ? `${Math.ceil(first.deployCooldown)}s` : "就绪"}` : "";
      ui.meta.textContent = [firstDef.description, `反核 ${first.interceptorAmmo || 0}/${anti.ammoMax}`, `补弹 ${reload}`, deploy].filter(Boolean).join(" · ");
    } else if (selection.length === 1 && first.kind === "unit" && unitTypes[first.type].shieldEmitter) {
      const shield = unitTypes[first.type].shieldEmitter;
      ui.meta.textContent = `${firstDef.description} · 护盾 ${Math.floor(first.shieldEnergy || 0)}/${shield.maxEnergy} · 半径 ${shield.range}`;
    } else if (selection.length === 1 && first.kind === "unit" && unitTypes[first.type].repairAura) {
      const def = unitTypes[first.type];
      ui.meta.textContent = `${firstDef.description} · 维修 ${def.repairPower}/s · 半径 ${def.repairAura}`;
    } else {
      ui.meta.textContent = selection.length === 1 ? firstDef.description || unitTypes[first.type]?.domain || "" : selectionSummary(selection);
    }
    const stanceText = stanceSummary(selection);
    if (stanceText) ui.meta.textContent = [ui.meta.textContent, stanceText].filter(Boolean).join(" · ");

    const hpTotal = selection.reduce((sum, e) => sum + e.hp, 0);
    const maxTotal = selection.reduce((sum, e) => sum + e.maxHp, 0);
    const pct = maxTotal ? hpTotal / maxTotal : 0;
    ui.hpLabel.textContent = `${Math.floor(hpTotal)}/${Math.floor(maxTotal)}`;
    ui.hpFill.style.width = `${pct * 100}%`;

    renderQueue(selection);
    renderCommands(selection);
  }

  function selectionSummary(selection) {
    const units = selection.filter((e) => e.kind === "unit").length;
    const buildings = selection.length - units;
    return `${units} 单位，${buildings} 建筑`;
  }

  function sandboxObjectiveText() {
    const sandbox = ensureSandbox();
    const [kind, type] = sandbox.type.split(":");
    const def = kind === "unit" ? unitTypes[type] : buildingTypes[type];
    const team = sandbox.team === TEAM_PLAYER ? "绿方" : "红方";
    const tool = sandbox.tool === "erase" ? "删除" : sandbox.tool === "select" ? "选择" : "放置";
    return `沙盒 ${tool} · ${team} · ${def?.name || "对象"} · ${sandbox.combat ? "战斗运行" : "战斗冻结"}`;
  }

  function renderSandboxPanel() {
    ui.sandboxPanel.hidden = state.mode !== "sandbox";
    if (ui.sandboxPanel.hidden) return;
    const sandbox = ensureSandbox();
    ui.sandboxModeLabel.textContent = sandbox.combat ? "运行" : "冻结";
    ui.sandboxSelect.classList.toggle("active", sandbox.tool === "select");
    ui.sandboxPlace.classList.toggle("active", sandbox.tool === "place");
    ui.sandboxErase.classList.toggle("active", sandbox.tool === "erase");
    ui.sandboxPlayer.classList.toggle("active", sandbox.team === TEAM_PLAYER);
    ui.sandboxEnemy.classList.toggle("active", sandbox.team === TEAM_ENEMY);
    ui.sandboxCombat.textContent = sandbox.combat ? "战斗:开" : "战斗:停";
    ui.sandboxReveal.textContent = sandbox.reveal ? "普通视野" : "全图视野";
    if (ui.sandboxType.value !== sandbox.type) ui.sandboxType.value = sandbox.type;
  }

  function renderQueue(selection) {
    ui.queue.innerHTML = "";
    const queueHost = selection.find((e) => e.kind === "building" && ((e.queue && e.queue.length) || e.repeatUnit || e.ammo > 0 || e.interceptorAmmo > 0));
    if (!queueHost) {
      const empty = document.createElement("span");
      empty.className = "queue-empty";
      empty.textContent = "无队列";
      empty.style.color = "#8f9b98";
      empty.style.fontSize = "12px";
      empty.style.fontWeight = "700";
      ui.queue.appendChild(empty);
      return;
    }
    if (queueHost.repeatUnit) {
      const repeat = document.createElement("div");
      repeat.className = "queue-item";
      repeat.textContent = `R${unitTypes[queueHost.repeatUnit]?.icon || ""}`;
      repeat.style.setProperty("--progress", "100%");
      ui.queue.appendChild(repeat);
    }
    for (const item of queueHost.queue) {
      const div = document.createElement("div");
      div.className = "queue-item";
      if (item.kind === "nuke") div.textContent = "NK";
      else if (item.kind === "antiNuke") div.textContent = "AN";
      else if (item.kind === "upgrade") div.textContent = `T${item.level}`;
      else div.textContent = unitTypes[item.type].icon;
      div.style.setProperty("--progress", `${((item.total - item.left) / item.total) * 100}%`);
      ui.queue.appendChild(div);
    }
    if (queueHost.type === "nukeLauncher" && queueHost.ammo > 0) {
      const div = document.createElement("div");
      div.className = "queue-item";
      div.textContent = `NK${queueHost.ammo}`;
      div.style.setProperty("--progress", "100%");
      ui.queue.appendChild(div);
    }
    if (queueHost.type === "antiNuke" && queueHost.interceptorAmmo > 0) {
      const div = document.createElement("div");
      div.className = "queue-item";
      div.textContent = `AN${queueHost.interceptorAmmo}`;
      div.style.setProperty("--progress", "100%");
      ui.queue.appendChild(div);
    }
  }

  function renderCommands(selection) {
    ui.commands.innerHTML = "";
    if (state.mode === "sandbox") {
      renderSandboxCommands(selection);
      return;
    }
    const buttons = [];
    const units = selection.filter((e) => e.kind === "unit");
    const builders = units.filter(canBuildWith);
    const transports = units.filter(isTransportUnit);
    const deployers = units.filter((unit) => deployConfig(unit));
    const speedModuleUnits = units.filter((unit) => unitTypes[unit.type]?.speedModule);
    const blinkModuleUnits = units.filter((unit) => unitTypes[unit.type]?.blinkModule);
    const combatUnits = selectedCombatUnits(selection);
    const buildings = selection.filter((e) => e.kind === "building");
    const producer = buildings.find((b) => buildingProduces(b).length);
    const nuke = buildings.find((b) => b.type === "nukeLauncher");
    const upgradeTarget = buildings.find((b) => nextUpgrade(b));
    const antiNuke = buildings.find((b) => b.type === "antiNuke");
    const laser = buildings.find((b) => b.type === "laserDefence");
    const queueTarget = buildings.find((b) => b.queue?.length);

    buttons.push(
      {
        label: "空闲工程",
        icon: "E",
        meta: "E 选择",
        action: () => selectMacroGroup("idleBuilders"),
      },
      {
        label: "屏幕作战",
        icon: "F",
        meta: "F 选择",
        action: () => selectMacroGroup("screenCombat"),
      },
      {
        label: "全部作战",
        icon: "ALL",
        meta: "Ctrl+A",
        action: () => selectMacroGroup("allCombat"),
      },
    );
    if (units.length) {
      buttons.push({
        label: "同类单位",
        icon: "TYPE",
        meta: "Alt+A",
        action: () => selectMacroGroup("sameType"),
      });
    }

    if (units.length) {
      buttons.push({
        label: "移动",
        icon: "M",
        meta: "右键也可移动",
        action: () => {
          input.attackMove = false;
          input.patrolMode = false;
          input.guardMode = false;
          input.reclaimMode = false;
          input.nukeSourceId = null;
          input.unloadTransportIds = null;
          input.blinkUnitIds = null;
          updatePlaceHint();
          addMessage("右键地图下达移动。", "info");
        },
      });
      buttons.push({
        label: "攻击移动",
        icon: "A",
        meta: "下一次左键目标点",
        action: () => {
          input.attackMove = true;
          input.patrolMode = false;
          input.guardMode = false;
          input.reclaimMode = false;
          input.nukeSourceId = null;
          input.unloadTransportIds = null;
          input.blinkUnitIds = null;
          updatePlaceHint("攻击移动：左键选择目标点，Esc 取消");
          addMessage("选择攻击移动目标点。", "warn");
        },
      });
      buttons.push({
        label: "巡逻",
        icon: "P",
        meta: "下一次左键端点",
        action: () => {
          input.patrolMode = true;
          input.attackMove = false;
          input.guardMode = false;
          input.reclaimMode = false;
          input.buildMode = null;
          input.nukeSourceId = null;
          input.unloadTransportIds = null;
          input.blinkUnitIds = null;
          updatePlaceHint("选择巡逻端点。");
        },
      });
      buttons.push({
        label: "护航",
        icon: "GD",
        meta: "下一次左键友军",
        action: () => {
          input.guardMode = true;
          input.attackMove = false;
          input.patrolMode = false;
          input.reclaimMode = false;
          input.buildMode = null;
          input.nukeSourceId = null;
          input.unloadTransportIds = null;
          input.blinkUnitIds = null;
          updatePlaceHint("护航：左键选择友方目标，Esc 取消");
        },
      });
      buttons.push({
        label: "停止",
        icon: "S",
        meta: "清空当前命令",
        action: () => issueStop(currentSelection()),
      });
      if (combatUnits.length) {
        const selectedStances = new Set(combatUnits.map(unitStance));
        for (const stanceKey of unitStanceOrder) {
          const stance = unitStances[stanceKey];
          buttons.push({
            label: stance.label,
            icon: stance.icon,
            meta: `${stance.hotkey} · ${stance.meta}`,
            active: selectedStances.size === 1 && selectedStances.has(stanceKey),
            action: () => setUnitStance(currentSelection(), stanceKey),
          });
        }
      }
      if (builders.length) {
        buttons.push({
          label: "回收残骸",
          icon: "RC",
          meta: "下一次左键残骸",
          action: () => {
            input.reclaimMode = true;
            input.attackMove = false;
            input.patrolMode = false;
            input.guardMode = false;
            input.buildMode = null;
            input.nukeSourceId = null;
            input.unloadTransportIds = null;
            input.blinkUnitIds = null;
            updatePlaceHint("回收：左键选择残骸，Esc 取消");
          },
        });
        for (const type of buildMenu) {
          const def = buildingTypes[type];
          buttons.push({
            label: def.name,
            icon: def.icon,
            meta: `${def.cost} 资源`,
            disabled: !canAfford(TEAM_PLAYER, def.cost),
            action: () => {
              input.buildMode = type;
              input.attackMove = false;
              input.patrolMode = false;
              input.guardMode = false;
              input.reclaimMode = false;
              input.nukeSourceId = null;
              input.unloadTransportIds = null;
              input.blinkUnitIds = null;
              updatePlaceHint();
            },
          });
        }
      }
    }

    if (transports.length) {
      const used = transports.reduce((sum, transport) => sum + cargoLoad(transport), 0);
      const cap = transports.reduce((sum, transport) => sum + transportCapacity(transport), 0);
      buttons.push({
        label: "装载附近",
        icon: "IN",
        meta: `货舱 ${used}/${cap}`,
        disabled: used >= cap,
        action: () => loadNearbyTransports(currentSelection().filter(isTransportUnit)),
      });
      buttons.push({
        label: "卸载到点",
        icon: "OUT",
        meta: `货舱 ${used}/${cap}`,
        disabled: used <= 0,
        action: () => {
          input.unloadTransportIds = currentSelection().filter(isTransportUnit).map((unit) => unit.id);
          input.buildMode = null;
          input.attackMove = false;
          input.patrolMode = false;
          input.guardMode = false;
          input.reclaimMode = false;
          input.nukeSourceId = null;
          input.blinkUnitIds = null;
          updatePlaceHint("选择卸载地点。");
        },
      });
    }

    if (deployers.length) {
      const ready = deployers.filter((unit) => (unit.deployCooldown || 0) <= 0);
      const nextReady = Math.min(...deployers.map((unit) => Math.ceil(unit.deployCooldown || 0)));
      buttons.push({
        label: "发射侦察",
        icon: "DR",
        meta: ready.length ? `${ready.length}/${deployers.length} 就绪` : `冷却 ${nextReady}s`,
        disabled: ready.length === 0,
        action: () => launchScoutDrones(currentSelection().filter((unit) => deployConfig(unit))),
      });
    }

    if (speedModuleUnits.length) {
      const ready = speedModuleUnits.filter((unit) => (unit.speedCooldown || 0) <= 0);
      const active = speedModuleUnits.filter((unit) => (unit.speedBoost || 0) > 0).length;
      const nextReady = Math.min(...speedModuleUnits.map((unit) => Math.ceil(unit.speedCooldown || 0)));
      buttons.push({
        label: "加速模块",
        icon: "SP+",
        meta: active ? `${active} 个加速中` : ready.length ? `${ready.length}/${speedModuleUnits.length} 就绪` : `冷却 ${nextReady}s`,
        disabled: ready.length === 0,
        action: () => activateSpeedModules(currentSelection().filter((unit) => unitTypes[unit.type]?.speedModule)),
      });
    }

    if (blinkModuleUnits.length) {
      const ready = blinkModuleUnits.filter((unit) => (unit.blinkCooldown || 0) <= 0);
      const nextReady = Math.min(...blinkModuleUnits.map((unit) => Math.ceil(unit.blinkCooldown || 0)));
      buttons.push({
        label: "闪现模块",
        icon: "BL",
        meta: ready.length ? `${ready.length}/${blinkModuleUnits.length} 就绪` : `冷却 ${nextReady}s`,
        disabled: ready.length === 0,
        action: () => startBlinkTarget(currentSelection().filter((unit) => unitTypes[unit.type]?.blinkModule)),
      });
    }

    if (producer) {
      const upgrade = nextUpgrade(producer);
      if (upgrade) {
        buttons.push({
          label: upgrade.name,
          icon: `T${buildingLevel(producer) + 1}`,
          meta: `${upgrade.cost} 资源 / ${upgrade.time}s`,
          disabled: !canAfford(TEAM_PLAYER, upgrade.cost) || producer.queue.some((item) => item.kind === "upgrade") || producer.buildProgress < 1,
          action: () => enqueueUpgrade(producer),
        });
      }
      for (const type of buildingProduces(producer)) {
        const def = unitTypes[type];
        const supply = teamSupply(TEAM_PLAYER);
        const disabled = !canAfford(TEAM_PLAYER, def.cost) || supply.used + (def.supply || 0) > supply.cap || producer.buildProgress < 1;
        buttons.push({
          label: def.name,
          icon: def.icon,
          meta: `${def.cost} 资源 / ${def.time}s`,
          disabled,
          action: () => enqueueUnit(producer, type),
        });
      }
      buttons.push({
        label: "设置集结",
        icon: "R",
        meta: "右键地图设置",
        action: () => addMessage("选中工厂后右键地图设置集结点。", "info"),
      });
      buttons.push({
        label: "重复生产",
        icon: "LOOP",
        meta: producer.repeatUnit ? unitTypes[producer.repeatUnit]?.name || "已开启" : "关闭",
        action: () => cycleRepeatUnit(producer),
      });
    }

    if (queueTarget) {
      const item = queueTarget.queue.at(-1);
      const refund = Math.floor(queueItemCost(queueTarget, item) * 0.75);
      buttons.push({
        label: "取消队列",
        icon: "X",
        meta: `${queueItemLabel(item)} / 约返 ${refund}`,
        action: () => cancelLastQueueItem(queueTarget),
      });
    }

    if (upgradeTarget && upgradeTarget !== producer) {
      const upgrade = nextUpgrade(upgradeTarget);
      buttons.push({
        label: upgrade.name,
        icon: `T${buildingLevel(upgradeTarget) + 1}`,
        meta: `${upgrade.cost} 资源 / ${upgrade.time}s`,
        disabled: !canAfford(TEAM_PLAYER, upgrade.cost) || upgradeTarget.queue.some((item) => item.kind === "upgrade") || upgradeTarget.buildProgress < 1,
        action: () => enqueueUpgrade(upgradeTarget),
      });
    }

    if (nuke) {
      buttons.push({
        label: "制造核弹",
        icon: "NK",
        meta: "1600 资源",
        disabled: !canAfford(TEAM_PLAYER, 1600) || nuke.queue.length > 1 || nuke.buildProgress < 1,
        action: () => enqueueNuke(nuke),
      });
      buttons.push({
        label: "发射核弹",
        icon: "!",
        meta: `${nuke.ammo} 枚可用`,
        disabled: nuke.ammo < 1 || nuke.buildProgress < 1,
        action: () => {
          input.nukeSourceId = nuke.id;
          input.attackMove = false;
          input.patrolMode = false;
          input.guardMode = false;
          input.reclaimMode = false;
          input.buildMode = null;
          input.unloadTransportIds = null;
          updatePlaceHint("选择核弹打击坐标。");
        },
      });
    }

    if (antiNuke) {
      const def = buildingCurrentDef(antiNuke);
      buttons.push({
        label: "制造拦截弹",
        icon: "AN",
        meta: `${antiNuke.interceptorAmmo || 0}/${def.antiNuke.ammoMax} 枚`,
        disabled:
          antiNuke.buildProgress < 1 ||
          (antiNuke.interceptorAmmo || 0) >= def.antiNuke.ammoMax ||
          !canAfford(TEAM_PLAYER, def.antiNuke.buildCost),
        action: () => enqueueAntiNuke(antiNuke),
      });
    }

    if (laser) {
      const def = buildingCurrentDef(laser);
      buttons.push({
        label: "护盾能量",
        icon: "LD",
        meta: `${Math.floor(laser.shieldEnergy || 0)}/${def.shield.maxEnergy}`,
        disabled: true,
        action: () => {},
      });
    }

    for (const item of buttons) {
      const button = document.createElement("button");
      button.className = "cmd";
      button.classList.toggle("active", Boolean(item.active));
      button.disabled = Boolean(item.disabled);
      button.innerHTML = `<div class="icon">${item.icon}</div><div><strong>${item.label}</strong><span>${item.meta || ""}</span></div>`;
      button.addEventListener("click", item.action);
      ui.commands.appendChild(button);
    }
  }

  function renderSandboxCommands(selection) {
    const sandbox = ensureSandbox();
    const toolLabel = sandbox.tool === "select" ? "选择工具" : sandbox.tool === "place" ? "放置画笔" : "删除画笔";
    const toolIcon = sandbox.tool === "select" ? "SEL" : sandbox.tool === "place" ? "+" : "X";
    const toolMeta = sandbox.tool === "select" ? "框选对象" : sandbox.tool === "place" ? "左键放置" : "左/右键删除";
    const buttons = [
      {
        label: toolLabel,
        icon: toolIcon,
        meta: toolMeta,
        action: () => setSandboxTool(sandbox.tool === "select" ? "place" : sandbox.tool === "place" ? "erase" : "select"),
      },
      {
        label: sandbox.team === TEAM_PLAYER ? "当前绿方" : "当前红方",
        icon: sandbox.team === TEAM_PLAYER ? "G" : "R",
        meta: "切换队伍",
        action: () => setSandboxTeam(sandbox.team === TEAM_PLAYER ? TEAM_ENEMY : TEAM_PLAYER),
      },
      {
        label: sandbox.combat ? "冻结战斗" : "运行战斗",
        icon: sandbox.combat ? "II" : ">",
        meta: "编辑/测试切换",
        action: () => {
          sandbox.combat = !sandbox.combat;
          markUiDirty();
        },
      },
      {
        label: "资源+5000",
        icon: "$",
        meta: "双方资源",
        action: () => {
          state.metal[TEAM_PLAYER] += 5000;
          state.metal[TEAM_ENEMY] += 5000;
          addMessage("沙盒：双方资源 +5000。", "info");
          markUiDirty();
        },
      },
      {
        label: "清弹药",
        icon: "CL",
        meta: "残骸/命令",
        action: clearSandboxDebris,
      },
    ];
    if (selection.length) {
      buttons.push({
        label: "删除选中",
        icon: "DEL",
        meta: `${selection.length} 个对象`,
        action: () => {
          let deleted = 0;
          for (const entity of currentSelection()) if (deleteSandboxEntity(entity)) deleted += 1;
          if (deleted) addMessage(`沙盒：已删除 ${deleted} 个对象。`, "info");
          sampleStats(true);
          markUiDirty();
        },
      });
      const first = selection[0];
      buttons.push({
        label: "吸取对象",
        icon: "P",
        meta: entityDef(first).name,
        action: () => {
          sandbox.type = `${first.kind}:${first.type}`;
          sandbox.team = first.team;
          sandbox.tool = "place";
          updatePlaceHint();
          markUiDirty();
        },
      });
      buttons.push({
        label: "停止选中",
        icon: "S",
        meta: "清当前命令",
        action: () => issueStop(currentSelection()),
      });
    }
    for (const item of buttons.slice(0, 12)) {
      const button = document.createElement("button");
      button.className = "cmd";
      button.innerHTML = `<div class="icon">${item.icon}</div><div><strong>${item.label}</strong><span>${item.meta || ""}</span></div>`;
      button.addEventListener("click", item.action);
      ui.commands.appendChild(button);
    }
  }

  function updatePlaceHint(customText = null) {
    if (customText) {
      ui.placeHint.hidden = false;
      ui.placeHint.textContent = customText;
      return;
    }
    if (state?.mode === "sandbox") {
      const sandbox = ensureSandbox();
      const [kind, type] = sandbox.type.split(":");
      const def = kind === "unit" ? unitTypes[type] : buildingTypes[type];
      const team = sandbox.team === TEAM_PLAYER ? "绿方" : "红方";
      ui.placeHint.hidden = false;
      ui.placeHint.textContent =
        sandbox.tool === "erase"
          ? "沙盒删除：左键或右键删除对象"
          : sandbox.tool === "select"
            ? "沙盒选择：左键选择，拖拽框选，右键删除"
            : `沙盒放置：${team} ${def?.name || "对象"}，左键放置，右键删除`;
      return;
    }
    if (input.patrolMode) {
      ui.placeHint.hidden = false;
      ui.placeHint.textContent = "巡逻：左键选择巡逻端点，Esc 取消";
      return;
    }
    if (input.guardMode) {
      ui.placeHint.hidden = false;
      ui.placeHint.textContent = "护航：左键选择友方目标，Esc 取消";
      return;
    }
    if (input.reclaimMode) {
      ui.placeHint.hidden = false;
      ui.placeHint.textContent = "回收：左键选择残骸，Esc 取消";
      return;
    }
    if (input.blinkUnitIds) {
      ui.placeHint.hidden = false;
      ui.placeHint.textContent = "闪现模块：左键选择落点，Esc 取消";
      return;
    }
    if (!input.buildMode) {
      ui.placeHint.hidden = true;
      return;
    }
    const def = buildingTypes[input.buildMode];
    ui.placeHint.hidden = false;
    ui.placeHint.textContent = `${def.name}: 左键放置，Shift 连续排队，Esc 取消`;
  }

  function snapBuild(type, x, y) {
    if (buildingTypes[type].requiresNode) {
      const node = nearestResource(x, y, 100);
      if (node) return { x: node.x, y: node.y };
    }
    return {
      x: Math.round(x / 22) * 22,
      y: Math.round(y / 22) * 22,
    };
  }

  function issueActiveWorldCommand(x, y) {
    if (input.blinkUnitIds) {
      blinkSelectedUnits(input.blinkUnitIds, x, y);
      if (!input.shift) input.blinkUnitIds = null;
      updatePlaceHint();
      return true;
    }

    if (input.buildMode) return false;

    if (input.unloadTransportIds) {
      const transports = input.unloadTransportIds.map(findEntity).filter(isTransportUnit);
      unloadTransports(transports, x, y);
      input.unloadTransportIds = null;
      updatePlaceHint();
      return true;
    }

    if (input.nukeSourceId) {
      const launcher = findEntity(input.nukeSourceId);
      if (launcher && launcher.ammo > 0) {
        launcher.ammo -= 1;
        createNuke(launcher, x, y);
        addMessage("核弹已发射。", "danger");
      }
      input.nukeSourceId = null;
      updatePlaceHint();
      markUiDirty();
      return true;
    }

    if (input.reclaimMode) {
      const wreck = nearestWreck(x, y, 95);
      if (wreck) {
        const assigned = issueReclaim(currentSelection(), wreck, input.shift);
        if (!input.shift) {
          input.reclaimMode = false;
          updatePlaceHint();
        }
        addMessage(assigned ? `回收残骸：预计 ${Math.ceil(wreck.metal)} 资源。` : "需要选择工程单位才能回收。", assigned ? "info" : "warn");
      } else {
        addMessage("附近没有可回收残骸。", "warn");
      }
      return true;
    }

    if (input.guardMode) {
      const target = topEntityAt(x, y, true);
      if (target && target.team === TEAM_PLAYER) {
        const guarded = issueGuard(currentSelection(), target, input.shift);
        if (!input.shift) {
          input.guardMode = false;
          updatePlaceHint();
        }
        addMessage(guarded ? `护航 ${entityDef(target).name}。` : "没有可护航的单位。", guarded ? "info" : "warn");
      } else {
        addMessage("护航需要选择友方单位或建筑。", "warn");
      }
      return true;
    }

    if (input.patrolMode) {
      issuePatrol(currentSelection(), x, y, input.shift);
      if (!input.shift) {
        input.patrolMode = false;
        updatePlaceHint();
      }
      addMessage("巡逻命令已下达。", "info");
      return true;
    }

    if (input.attackMove) {
      issueMove(currentSelection(), x, y, true, input.shift);
      if (!input.shift) {
        input.attackMove = false;
        updatePlaceHint();
      }
      addMessage("攻击移动命令已下达。", "warn");
      return true;
    }

    return false;
  }

  function onPointerDown(event) {
    const pos = pointerPos(event);
    input.mouseX = pos.x;
    input.mouseY = pos.y;
    const world = screenToWorld(pos.x, pos.y);
    input.worldX = world.x;
    input.worldY = world.y;
    input.downX = pos.x;
    input.downY = pos.y;
    input.downWorldX = world.x;
    input.downWorldY = world.y;
    input.shift = event.shiftKey;

    if (event.button === 1 || (event.button === 0 && event.altKey)) {
      input.pan = true;
      canvas.setPointerCapture(event.pointerId);
      return;
    }

    if (event.button === 2) {
      event.preventDefault();
      if (state.mode === "sandbox") {
        eraseSandboxObject(world.x, world.y);
        return;
      }
      issueContextCommand(world.x, world.y);
      return;
    }

    if (event.button !== 0) return;

    if (state.mode === "sandbox") {
      const tool = ensureSandbox().tool;
      if (tool === "erase") eraseSandboxObject(world.x, world.y);
      else if (tool === "place") placeSandboxObject(world.x, world.y);
      else {
        input.isDown = true;
        input.dragSelect = false;
        canvas.setPointerCapture(event.pointerId);
      }
      return;
    }

    if (issueActiveWorldCommand(world.x, world.y)) return;

    if (input.buildMode) {
      const snap = snapBuild(input.buildMode, world.x, world.y);
      placeBuilding(input.buildMode, snap.x, snap.y, TEAM_PLAYER, input.shift);
      return;
    }

    input.isDown = true;
    input.dragSelect = false;
    canvas.setPointerCapture(event.pointerId);
  }

  function onPointerMove(event) {
    const pos = pointerPos(event);
    const world = screenToWorld(pos.x, pos.y);
    input.shift = event.shiftKey;
    if (input.pan) {
      const dx = pos.x - input.mouseX;
      const dy = pos.y - input.mouseY;
      camera.x -= dx / camera.zoom;
      camera.y -= dy / camera.zoom;
      clampCamera();
    }
    input.mouseX = pos.x;
    input.mouseY = pos.y;
    input.worldX = world.x;
    input.worldY = world.y;

    if (input.isDown && Math.hypot(input.mouseX - input.downX, input.mouseY - input.downY) > 5) {
      input.dragSelect = true;
    }
  }

  function onPointerUp(event) {
    if (input.pan) {
      input.pan = false;
      return;
    }
    if (!input.isDown) return;
    input.isDown = false;
    const up = screenToWorld(input.mouseX, input.mouseY);

    if (input.dragSelect) {
      const from = screenToWorld(input.downX, input.downY);
      const entities = getEntitiesInRect(from.x, from.y, up.x, up.y);
      selectEntities(entities, input.shift);
      input.dragSelect = false;
      return;
    }

    const clicked = topEntityAt(up.x, up.y, true);
    const now = performance.now();
    const isDouble = now - input.lastClickTime < 320;
    input.lastClickTime = now;
    if (clicked && (clicked.team === TEAM_PLAYER || state.mode === "sandbox")) {
      if (isDouble) {
        const same = state.units.filter(
          (u) =>
            !u.dead &&
            !u.carriedBy &&
            (u.team === clicked.team || state.mode !== "sandbox") &&
            u.type === clicked.type &&
            dist2(u.x, u.y, clicked.x, clicked.y) < 760 * 760,
        );
        selectEntities(clicked.kind === "unit" ? same : [clicked], input.shift);
      } else {
        selectEntities([clicked], input.shift);
      }
    } else if (!input.shift) {
      clearSelection();
    }
  }

  function issueContextCommand(x, y) {
    input.buildMode = null;
    input.attackMove = false;
    input.patrolMode = false;
    input.guardMode = false;
    input.reclaimMode = false;
    input.nukeSourceId = null;
    input.unloadTransportIds = null;
    input.blinkUnitIds = null;
    updatePlaceHint();
    const selection = currentSelection();
    if (!selection.length) return;
    const target = topEntityAt(x, y, true);
    const builders = selection.filter(canBuildWith);

    if (target && target.team !== TEAM_PLAYER) {
      issueAttack(selection, target, input.shift);
      addMessage(`攻击 ${entityDef(target).name}。`, "warn");
      return;
    }

    if (target && target.team === TEAM_PLAYER && builders.length && target.kind === "building" && target.buildProgress < 1) {
      const assigned = issueBuild(builders, target, input.shift);
      if (assigned) {
        addMessage(`协助建造 ${entityDef(target).name}。`, "info");
        return;
      }
    }

    if (target && target.team === TEAM_PLAYER && builders.length && target.hp < target.maxHp) {
      issueRepair(builders, target, input.shift);
      addMessage(`维修 ${entityDef(target).name}。`, "info");
      return;
    }

    if (target && target.team === TEAM_PLAYER && isTransportUnit(target)) {
      const cargo = selection.filter((unit) => unit.kind === "unit" && !isTransportUnit(unit));
      if (cargo.length) {
        issueLoadIntoTransport(cargo, target);
        return;
      }
    }

    if (target && target.team === TEAM_PLAYER && target.kind === "unit" && !isTransportUnit(target)) {
      const transports = selection.filter(isTransportUnit);
      if (transports.length) {
        issueTransportPickup(transports, target);
        return;
      }
    }

    if (target && target.team === TEAM_PLAYER) {
      const guarded = issueGuard(selection, target, input.shift);
      if (guarded) {
        addMessage(`护航 ${entityDef(target).name}。`, "info");
        return;
      }
    }

    const factories = selection.filter((e) => e.kind === "building" && buildingProduces(e).length);
    if (factories.length && selection.every((e) => e.kind === "building")) {
      for (const factory of factories) {
        factory.rally = { x, y };
      }
      addMessage("集结点已设置。", "info");
      markUiDirty();
      return;
    }

    const wreck = nearestWreck(x, y, 95);
    if (wreck && builders.length) {
      const assigned = issueReclaim(builders, wreck, input.shift);
      if (assigned) {
        addMessage(`回收残骸：预计 ${Math.ceil(wreck.metal)} 资源。`, "info");
        return;
      }
    }

    issueMove(selection, x, y, false, input.shift);
  }

  function pointerPos(event) {
    const rect = canvas.getBoundingClientRect();
    return {
      x: event.clientX - rect.left,
      y: event.clientY - rect.top,
    };
  }

  function onWheel(event) {
    event.preventDefault();
    const before = screenToWorld(event.offsetX, event.offsetY);
    const factor = event.deltaY < 0 ? 1.12 : 0.89;
    camera.targetZoom = clamp(camera.targetZoom * factor, 0.34, 1.65);
    camera.zoom = clamp(camera.zoom * factor, 0.34, 1.65);
    const after = screenToWorld(event.offsetX, event.offsetY);
    camera.x += before.x - after.x;
    camera.y += before.y - after.y;
    clampCamera();
  }

  function onKeyDown(event) {
    input.keys.add(event.code);
    if (event.code === "Escape") {
      input.buildMode = null;
      input.attackMove = false;
      input.patrolMode = false;
      input.guardMode = false;
      input.reclaimMode = false;
      input.nukeSourceId = null;
      input.unloadTransportIds = null;
      input.blinkUnitIds = null;
      updatePlaceHint();
    }
    if (event.code === "KeyP") togglePause();
    if (event.code === "KeyR") restart();
    if (state.mode !== "sandbox" && event.code === "KeyE" && !event.metaKey && !event.ctrlKey && !event.altKey) {
      selectMacroGroup("idleBuilders");
      return;
    }
    if (state.mode !== "sandbox" && event.code === "KeyF" && !event.metaKey && !event.ctrlKey && !event.altKey) {
      selectMacroGroup("screenCombat");
      return;
    }
    if (state.mode !== "sandbox" && event.code === "KeyA" && (event.ctrlKey || event.metaKey)) {
      event.preventDefault();
      selectMacroGroup("allCombat");
      return;
    }
    if (state.mode !== "sandbox" && event.code === "KeyA" && event.altKey) {
      event.preventDefault();
      selectMacroGroup("sameType");
      return;
    }
    if (state.mode !== "sandbox" && !event.metaKey && !event.ctrlKey && !event.altKey && ["KeyZ", "KeyX", "KeyV"].includes(event.code)) {
      const stanceKey = event.code === "KeyZ" ? "aggressive" : event.code === "KeyX" ? "defensive" : "holdFire";
      const combatUnits = selectedCombatUnits();
      if (combatUnits.length) {
        setUnitStance(combatUnits, stanceKey);
        return;
      }
    }
    if (event.code === "KeyA" && currentSelection().some((e) => e.kind === "unit")) {
      input.attackMove = true;
      input.patrolMode = false;
      input.guardMode = false;
      input.reclaimMode = false;
      input.buildMode = null;
      input.nukeSourceId = null;
      input.unloadTransportIds = null;
      input.blinkUnitIds = null;
      updatePlaceHint("攻击移动：左键选择目标点，Esc 取消");
      addMessage("选择攻击移动目标点。", "warn");
    }
    if (event.code === "KeyG" && currentSelection().some((e) => e.kind === "unit")) {
      input.patrolMode = true;
      input.attackMove = false;
      input.guardMode = false;
      input.reclaimMode = false;
      input.buildMode = null;
      input.nukeSourceId = null;
      input.unloadTransportIds = null;
      input.blinkUnitIds = null;
      updatePlaceHint("选择巡逻端点。");
      addMessage("选择巡逻端点。", "info");
    }
    if (event.code === "KeyH" && currentSelection().some((e) => e.kind === "unit")) {
      input.guardMode = true;
      input.attackMove = false;
      input.patrolMode = false;
      input.reclaimMode = false;
      input.buildMode = null;
      input.nukeSourceId = null;
      input.unloadTransportIds = null;
      input.blinkUnitIds = null;
      updatePlaceHint("护航：左键选择友方目标，Esc 取消");
      addMessage("选择护航目标。", "info");
    }
    if (event.code === "KeyC" && currentSelection().some(canBuildWith)) {
      input.reclaimMode = true;
      input.attackMove = false;
      input.patrolMode = false;
      input.guardMode = false;
      input.buildMode = null;
      input.nukeSourceId = null;
      input.unloadTransportIds = null;
      input.blinkUnitIds = null;
      updatePlaceHint("回收：左键选择残骸，Esc 取消");
      addMessage("选择可回收残骸。", "info");
    }
    if (event.code === "KeyS" && !event.metaKey && !event.ctrlKey) issueStop(currentSelection());
    if (event.code === "Space") focusBase();
    if (/^Digit[1-9]$/.test(event.code)) {
      const group = Number(event.code.replace("Digit", ""));
      if (event.ctrlKey || event.metaKey) {
        controlGroups.set(group, [...selectedIds]);
        addMessage(`编队 ${group} 已保存。`, "info");
      } else {
        const ids = controlGroups.get(group) || [];
        selectEntities(ids.map(findEntity).filter(Boolean), false);
      }
    }
  }

  function onKeyUp(event) {
    input.keys.delete(event.code);
  }

  function focusBase() {
    const command = state.buildings.find((b) => !b.dead && b.team === TEAM_PLAYER && b.type === "command");
    if (command) {
      camera.x = command.x;
      camera.y = command.y;
      clampCamera();
    }
  }

  function togglePause() {
    state.paused = !state.paused;
    markUiDirty();
  }

  function cycleSpeed() {
    const speeds = [1, 2, 3];
    const index = speeds.indexOf(state.speed);
    state.speed = speeds[(index + 1) % speeds.length];
    markUiDirty();
  }

  function cycleAiDifficulty() {
    const current = state?.ai?.difficulty || preferredAiDifficulty || "normal";
    const index = aiDifficultyOrder.includes(current) ? aiDifficultyOrder.indexOf(current) : aiDifficultyOrder.indexOf("normal");
    const next = aiDifficultyOrder[(index + 1) % aiDifficultyOrder.length] || "normal";
    preferredAiDifficulty = next;
    if (state?.ai) {
      state.ai.difficulty = next;
      syncAiDifficulty();
    }
    writeAiPreference(next);
    ui.ai.textContent = `AI ${aiDifficulties[next].label}`;
    renderStatsPanel();
    addMessage(`AI 难度：${aiDifficulties[next].label}。`, ["hard", "veryHard", "impossible"].includes(next) ? "warn" : "info");
    markUiDirty();
  }

  function cycleMap() {
    const current = normalizeMapKey(selectedMapKey);
    const next = mapOrder[(mapOrder.indexOf(current) + 1) % mapOrder.length] || "coast";
    selectedMapKey = next;
    initGame(state?.mode || "skirmish");
    resetCommandModes();
    addMessage(`地图：${mapLabel(next)}。`, "info");
  }

  function restart() {
    initGame(state?.mode || "skirmish");
    resetCommandModes();
  }

  function startMode(mode) {
    initGame(mode);
    resetCommandModes();
  }

  function resetCommandModes() {
    input.buildMode = null;
    input.attackMove = false;
    input.patrolMode = false;
    input.guardMode = false;
    input.reclaimMode = false;
    input.nukeSourceId = null;
    input.unloadTransportIds = null;
    input.blinkUnitIds = null;
    updatePlaceHint();
  }

  function saveGame() {
    try {
      const data = {
        state,
        idSeq,
        camera: { x: camera.x, y: camera.y, zoom: camera.zoom, targetZoom: camera.targetZoom },
      };
      localStorage.setItem(SAVE_KEY, JSON.stringify(data));
      addMessage("游戏已保存。", "info");
    } catch (error) {
      addMessage("保存失败：浏览器存储不可用。", "danger");
    }
  }

  function loadGame() {
    try {
      const raw = localStorage.getItem(SAVE_KEY);
      if (!raw) {
        addMessage("没有可读取的存档。", "warn");
        return;
      }
      const data = JSON.parse(raw);
      state = data.state;
      state.mode ||= "skirmish";
      state.mapKey = normalizeMapKey(state.mapKey);
      selectedMapKey = state.mapKey;
      state.challenge ||= { timer: 0, targetIds: [] };
      state.challenge.timer ??= 0;
      state.challenge.targetIds ||= [];
      state.campaign ||= { stage: 0, frontTurretId: null, enemyCommandId: null };
      state.campaign.stage ??= 0;
      state.campaign.frontTurretId ??= null;
      state.campaign.enemyCommandId ??= null;
      state.wrecks ||= [];
      for (const [index, wreck] of state.wrecks.entries()) {
        wreck.id ??= `wreck-${index}-${Math.round(wreck.x || 0)}-${Math.round(wreck.y || 0)}`;
        wreck.maxMetal ??= Math.max(18, Math.round((wreck.size || 40) * 1.8));
        wreck.metal ??= wreck.maxMetal;
      }
      state.ai ||= {};
      state.ai.difficulty = aiDifficulties[state.ai.difficulty] ? state.ai.difficulty : preferredAiDifficulty;
      state.ai.difficultyIncome ??= aiIncomeMultiplier(state.mode);
      state.ai.reclaimClock ??= 2.5;
      state.ai.survivalClock ??= 40;
      state.ai.survivalWave ??= 0;
      ensureStats();
      ensureSandbox();
      for (const u of state.units || []) {
        const def = unitTypes[u.type];
        u.carriedBy ??= null;
        u.orderQueue = Array.isArray(u.orderQueue) ? u.orderQueue : [];
        u.cargoIds = def?.transportCapacity ? u.cargoIds || [] : null;
        u.stance = normalizeUnitStance(u.stance);
        if (u.order?.type === "attack" && u.order.auto && unitStanceDef(u).autoRange <= 0) resumeAfterAttackOrder(u);
        if (!(u.order?.type === "attack" && !u.order.auto) && u.stance !== UNIT_STANCE_DEFAULT) u.targetId = null;
        u.deployCooldown ??= 0;
        u.speedBoost ??= 0;
        u.speedCooldown ??= 0;
        u.blinkCooldown ??= 0;
        if (def?.antiNuke) {
          u.interceptorAmmo ??= Math.min(1, def.antiNuke.ammoMax);
          u.interceptorBuild ??= 0;
        }
        if (def?.shieldEmitter) u.shieldEnergy ??= def.shieldEmitter.energy;
      }
      for (const u of state.units || []) {
        if (u.carriedBy && !getUnitById(u.carriedBy)) u.carriedBy = null;
      }
      for (const u of state.units || []) {
        if (isTransportUnit(u)) {
          u.cargoIds = (u.cargoIds || []).filter((id) => {
            const cargo = getUnitById(id);
            return cargo && cargo.carriedBy === u.id;
          });
        }
      }
      for (const b of state.buildings || []) {
        b.level ||= 1;
        const def = buildingTypes[b.type];
        if (b.repeatUnit && !buildingProduces(b).includes(b.repeatUnit)) b.repeatUnit = null;
        b.repeatUnit ??= null;
        if (def?.shield) b.shieldEnergy ??= def.shield.energy;
        if (def?.antiNuke) b.interceptorAmmo ??= Math.min(1, def.antiNuke.ammoMax);
      }
      idSeq = data.idSeq || 1;
      camera.x = data.camera?.x || 820;
      camera.y = data.camera?.y || 2020;
      camera.zoom = data.camera?.zoom || 0.82;
      camera.targetZoom = data.camera?.targetZoom || camera.zoom;
      selectedIds = new Set();
      syncAiDifficulty();
      rebuildTerrainCanvas();
      renderFeed();
      updateFog(true);
      if (state.mode === "sandbox" && state.sandbox.reveal) revealMap();
      sampleStats(true);
      updatePlaceHint();
      markUiDirty();
      addMessage("存档已读取。", "info");
    } catch (error) {
      addMessage("读取失败：存档数据损坏。", "danger");
    }
  }

  function onMinimapPointer(event) {
    const rect = minimap.getBoundingClientRect();
    const x = ((event.clientX - rect.left) / rect.width) * MAP_W;
    const y = ((event.clientY - rect.top) / rect.height) * MAP_H;
    input.shift = event.shiftKey;
    if (event.button === 2) {
      event.preventDefault();
      issueContextCommand(x, y);
      return;
    }
    if (event.button === 0 && state.mode !== "sandbox" && issueActiveWorldCommand(x, y)) return;
    camera.x = x;
    camera.y = y;
    clampCamera();
  }

  function loop(now) {
    const rawDt = Math.min(0.05, (now - lastTime) / 1000 || 0.016);
    lastTime = now;
    if (!state.paused && !state.gameOver) {
      update(rawDt * state.speed);
    } else {
      updateCamera(rawDt);
    }
    uiClock -= rawDt;
    if (uiDirty || uiClock <= 0) {
      refreshUI();
      uiClock = 0.18;
    }
    render();
    requestAnimationFrame(loop);
  }

  function bindEvents() {
    window.addEventListener("resize", resize);
    canvas.addEventListener("pointerdown", onPointerDown);
    canvas.addEventListener("pointermove", onPointerMove);
    canvas.addEventListener("pointerup", onPointerUp);
    canvas.addEventListener("pointercancel", onPointerUp);
    canvas.addEventListener("contextmenu", (event) => event.preventDefault());
    canvas.addEventListener("wheel", onWheel, { passive: false });
    window.addEventListener("keydown", onKeyDown);
    window.addEventListener("keyup", onKeyUp);
    minimap.addEventListener("pointerdown", onMinimapPointer);
    minimap.addEventListener("contextmenu", (event) => event.preventDefault());
    ui.pause.addEventListener("click", togglePause);
    ui.speed.addEventListener("click", cycleSpeed);
    ui.map.addEventListener("click", cycleMap);
    ui.ai.addEventListener("click", cycleAiDifficulty);
    ui.stats.addEventListener("click", () => toggleStatsPanel());
    ui.statsClose.addEventListener("click", () => toggleStatsPanel(false));
    ui.restart.addEventListener("click", restart);
    ui.campaign.addEventListener("click", () => startMode("campaign"));
    ui.skirmish.addEventListener("click", () => startMode("skirmish"));
    ui.survival.addEventListener("click", () => startMode("survival"));
    ui.challenge.addEventListener("click", () => startMode("challenge"));
    ui.sandbox.addEventListener("click", () => startMode("sandbox"));
    ui.save.addEventListener("click", saveGame);
    ui.load.addEventListener("click", loadGame);
    bindSandboxEvents();
  }

  function populateSandboxTypeOptions() {
    ui.sandboxType.innerHTML = "";
    const groups = [
      ["单位", "unit", Object.keys(unitTypes)],
      ["建筑", "building", Object.keys(buildingTypes)],
    ];
    for (const [label, kind, keys] of groups) {
      const group = document.createElement("optgroup");
      group.label = label;
      for (const type of keys) {
        const def = kind === "unit" ? unitTypes[type] : buildingTypes[type];
        const option = document.createElement("option");
        option.value = `${kind}:${type}`;
        option.textContent = `${def.icon} ${def.name}`;
        group.appendChild(option);
      }
      ui.sandboxType.appendChild(group);
    }
    ui.sandboxType.value = sandboxDefaultType;
  }

  function bindSandboxEvents() {
    populateSandboxTypeOptions();
    ui.sandboxSelect.addEventListener("click", () => setSandboxTool("select"));
    ui.sandboxPlace.addEventListener("click", () => setSandboxTool("place"));
    ui.sandboxErase.addEventListener("click", () => setSandboxTool("erase"));
    ui.sandboxPlayer.addEventListener("click", () => setSandboxTeam(TEAM_PLAYER));
    ui.sandboxEnemy.addEventListener("click", () => setSandboxTeam(TEAM_ENEMY));
    ui.sandboxType.addEventListener("change", () => {
      ensureSandbox().type = isSandboxType(ui.sandboxType.value) ? ui.sandboxType.value : sandboxDefaultType;
      updatePlaceHint();
      markUiDirty();
    });
    ui.sandboxCombat.addEventListener("click", () => {
      const sandbox = ensureSandbox();
      sandbox.combat = !sandbox.combat;
      addMessage(sandbox.combat ? "沙盒战斗已运行。" : "沙盒战斗已冻结。", sandbox.combat ? "warn" : "info");
      markUiDirty();
    });
    ui.sandboxFunds.addEventListener("click", () => {
      state.metal[TEAM_PLAYER] += 5000;
      state.metal[TEAM_ENEMY] += 5000;
      addMessage("沙盒：双方资源 +5000。", "info");
      markUiDirty();
    });
    ui.sandboxClear.addEventListener("click", clearSandboxDebris);
    ui.sandboxReveal.addEventListener("click", () => {
      const sandbox = ensureSandbox();
      sandbox.reveal = !sandbox.reveal;
      if (sandbox.reveal) revealMap();
      else updateFog(true);
      markUiDirty();
    });
    ui.sandboxExport.addEventListener("click", exportSandboxScenario);
    ui.sandboxImport.addEventListener("click", () => ui.sandboxImportFile.click());
    ui.sandboxImportFile.addEventListener("change", importSandboxScenarioFile);
  }

  function setSandboxTool(tool) {
    ensureSandbox().tool = ["select", "place", "erase"].includes(tool) ? tool : "place";
    updatePlaceHint();
    markUiDirty();
  }

  function setSandboxTeam(team) {
    ensureSandbox().team = team === TEAM_ENEMY ? TEAM_ENEMY : TEAM_PLAYER;
    updatePlaceHint();
    markUiDirty();
  }

  function sandboxUnitSnapshot(unit) {
    return {
      type: unit.type,
      team: unit.team,
      x: Math.round(unit.x),
      y: Math.round(unit.y),
      hp: Math.round(unit.hp),
      shield: Math.round(unit.shield || 0),
      stance: unitStance(unit),
      moveAngle: unit.moveAngle || 0,
    };
  }

  function sandboxBuildingSnapshot(building) {
    return {
      type: building.type,
      team: building.team,
      x: Math.round(building.x),
      y: Math.round(building.y),
      hp: Math.round(building.hp),
      buildProgress: clamp(building.buildProgress ?? 1, 0, 1),
      level: buildingLevel(building),
      ammo: building.ammo || 0,
      interceptorAmmo: building.interceptorAmmo || 0,
      rally: building.rally ? { x: Math.round(building.rally.x), y: Math.round(building.rally.y) } : null,
      repeatUnit: building.repeatUnit || null,
    };
  }

  function createSandboxScenarioData() {
    return {
      format: "rustwar-sandbox-scenario",
      version: 1,
      mapKey: normalizeMapKey(state.mapKey),
      metal: {
        [TEAM_PLAYER]: Math.floor(state.metal[TEAM_PLAYER]),
        [TEAM_ENEMY]: Math.floor(state.metal[TEAM_ENEMY]),
      },
      camera: { x: Math.round(camera.x), y: Math.round(camera.y), zoom: camera.targetZoom || camera.zoom },
      sandbox: { ...ensureSandbox() },
      units: state.units.filter((u) => !u.dead && !u.carriedBy).map(sandboxUnitSnapshot),
      buildings: state.buildings.filter((b) => !b.dead).map(sandboxBuildingSnapshot),
    };
  }

  function exportSandboxScenario() {
    if (state.mode !== "sandbox") {
      addMessage("请先进入沙盒模式再导出场景。", "warn");
      return;
    }
    const data = createSandboxScenarioData();
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `rustwar-sandbox-${data.mapKey}-${Date.now()}.json`;
    document.body.appendChild(link);
    link.click();
    link.remove();
    URL.revokeObjectURL(url);
    addMessage("沙盒场景已导出。", "info");
  }

  function restoreSandboxBuilding(snapshot) {
    if (!buildingTypes[snapshot.type]) return null;
    const building = createBuilding(snapshot.type, snapshot.team === TEAM_ENEMY ? TEAM_ENEMY : TEAM_PLAYER, Number(snapshot.x) || 0, Number(snapshot.y) || 0, true);
    const def = buildingTypes[building.type];
    building.buildProgress = clamp(Number(snapshot.buildProgress ?? 1), 0.02, 1);
    building.level = clamp(Math.floor(Number(snapshot.level) || 1), 1, (def.upgrades?.length || 0) + 1);
    building.maxHp = buildingCurrentDef(building).hp || def.hp;
    building.hp = clamp(Number(snapshot.hp) || building.maxHp, 1, building.maxHp);
    building.ammo = Math.max(0, Math.floor(Number(snapshot.ammo) || 0));
    building.interceptorAmmo = Math.max(0, Math.floor(Number(snapshot.interceptorAmmo) || 0));
    building.rally = snapshot.rally ? { x: Number(snapshot.rally.x) || building.x, y: Number(snapshot.rally.y) || building.y } : building.rally;
    building.repeatUnit = buildingProduces(building).includes(snapshot.repeatUnit) ? snapshot.repeatUnit : null;
    if (building.type === "extractor") {
      const node = nearestResource(building.x, building.y, 80);
      if (node) {
        node.claimedBy = building.team;
        building.nodeId = node.id;
      }
    }
    return building;
  }

  function restoreSandboxUnit(snapshot) {
    if (!unitTypes[snapshot.type]) return null;
    const seed = { type: snapshot.type, x: Number(snapshot.x) || 0, y: Number(snapshot.y) || 0 };
    const point = findReachablePoint(seed, seed.x, seed.y);
    const unit = createUnit(snapshot.type, snapshot.team === TEAM_ENEMY ? TEAM_ENEMY : TEAM_PLAYER, point.x, point.y);
    unit.hp = clamp(Number(snapshot.hp) || unit.maxHp, 1, unit.maxHp);
    unit.shield = clamp(Number(snapshot.shield) || 0, 0, unit.maxShield || 0);
    unit.stance = normalizeUnitStance(snapshot.stance);
    unit.moveAngle = Number(snapshot.moveAngle) || 0;
    return unit;
  }

  function restoreSandboxScenario(data) {
    if (!data || data.format !== "rustwar-sandbox-scenario" || data.version !== 1) throw new Error("Unsupported scenario format");
    selectedMapKey = normalizeMapKey(data.mapKey);
    initGame("sandbox");
    idSeq = 1;
    state.units = [];
    state.buildings = [];
    state.projectiles = [];
    state.particles = [];
    state.wrecks = [];
    state.messages = [];
    state.stats = createStats();
    state.resources = createResources(currentMap());
    state.metal[TEAM_PLAYER] = finiteOr(data.metal?.[TEAM_PLAYER], 5000);
    state.metal[TEAM_ENEMY] = finiteOr(data.metal?.[TEAM_ENEMY], 5000);
    state.sandbox = { ...createSandboxState(), ...(data.sandbox || {}) };
    ensureSandbox();
    selectedIds = new Set();
    for (const snapshot of data.buildings || []) restoreSandboxBuilding(snapshot);
    for (const snapshot of data.units || []) restoreSandboxUnit(snapshot);
    camera.x = finiteOr(data.camera?.x, currentMap().camera.x);
    camera.y = finiteOr(data.camera?.y, currentMap().camera.y);
    camera.zoom = clamp(finiteOr(data.camera?.zoom, currentMap().camera.zoom), 0.34, 1.65);
    camera.targetZoom = camera.zoom;
    clampCamera();
    idSeq = Math.max(1, ...allEntities().map((e) => e.id || 0)) + 1;
    rebuildTerrainCanvas();
    updateFog(true);
    if (state.sandbox.reveal) revealMap();
    sampleStats(true);
    resetCommandModes();
    if (isSandboxType(state.sandbox.type)) ui.sandboxType.value = state.sandbox.type;
    markUiDirty();
    addMessage("沙盒场景已导入。", "info");
  }

  function importSandboxScenarioFile(event) {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) return;
    file
      .text()
      .then((text) => restoreSandboxScenario(JSON.parse(text)))
      .catch(() => addMessage("导入失败：场景文件无效。", "danger"));
  }

  function clearSandboxDebris() {
    if (state.mode !== "sandbox") return;
    state.projectiles = [];
    state.particles = [];
    state.wrecks = [];
    for (const unit of state.units) {
      if (unit.dead) continue;
      unit.order = null;
      unit.orderQueue = [];
      unit.targetId = null;
      unit.reload = 0;
    }
    for (const building of state.buildings) {
      if (building.dead) continue;
      building.targetId = null;
      building.reload = 0;
    }
    addMessage("沙盒：弹药、残骸和当前命令已清理。", "info");
    markUiDirty();
  }

  function initialModeFromLocation() {
    const params = new URLSearchParams(window.location.search);
    selectedMapKey = normalizeMapKey(params.get("map") || selectedMapKey);
    const mode = params.get("mode");
    return ["campaign", "skirmish", "survival", "challenge", "sandbox"].includes(mode) ? mode : "skirmish";
  }

  bindEvents();
  preferredAiDifficulty = readAiPreference();
  resize();
  initGame(initialModeFromLocation());
  requestAnimationFrame(loop);
})();
