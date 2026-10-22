-- Blackthornes Pets -- Locale/zhCN.lua
-- Simplified Chinese: the words players see, on a Simplified Chinese client.
--
-- Each line is the English key (exactly as the code writes it) and its
-- Chinese. A key with no line here shows in English. The Chinese uses the
-- game's own words (宠物, 野兽, 驯服, 野兽训练, 食物, 等级, 码). A line may name
-- its values by place ("%2$s ... %1$s") where Chinese word order needs it;
-- L.Format puts them in order.
--
-- Beast, family, zone and skill names stay as the data or the client gives
-- them. tools/check_locale.py lists keys with no line here and lines no
-- longer used.

local _, ns = ...
local L = ns.L

local ok, locale = pcall(function() return GetLocale() end)
if not (ok and locale == "zhCN") then return end

-- Core
L["Saved for Claude, /reload to write it."] = "已为 Claude 保存，输入 /reload 写入。"
L["module %s:%s failed"] = "模块 %s:%s 出错"
L["show this list"] = "显示这个列表"
L["unknown command: %s"] = "未知命令：%s"
L["/bpet %s failed: %s"] = "/bpet %s 出错：%s"

-- The sister note
L["and"] = "和"
L["works with other Blackthornes addons you don't have yet: %s. %s on CurseForge."] = "可以和你还没有的其他 Blackthornes 插件一起使用：%s。%s 在 CurseForge 上。"
L["It's"] = "它"
L["They're"] = "它们都"
L["This note shows once."] = "这条提示只显示一次。"
L["turn the once-only note about the other Blackthornes addons on or off"] =
    "打开或关闭关于其他 Blackthornes 插件的一次性提示"
L["the note about the other Blackthornes addons is on. It shows once for any you don't have."] =
    "关于其他 Blackthornes 插件的提示已打开。你还没有的插件，每个只提示一次。"
L["the note about the other Blackthornes addons is off, in all of them."] =
    "关于其他 Blackthornes 插件的提示已在所有插件中关闭。"
L["where to farm any material"] = "去哪里刷任何材料"
L["auction prices, crafting profits and a craft queue"] =
    "拍卖价格、制造利润和制造队列"
L["which gear is an upgrade for you, and where to get it"] =
    "哪些装备对你是升级，以及去哪里拿到"
L["feeding and taming for hunter and warlock pets"] =
    "猎人和术士宠物的喂食与驯服"
L["what to do with every item in your bags"] = "背包里每样物品该怎么处理"

-- Diets
L["Meat"] = "肉"
L["Fish"] = "鱼"
L["Bread"] = "面包"
L["Cheese"] = "奶酪"
L["Fruit"] = "水果"
L["Fungus"] = "蘑菇"

-- The beast arrow
L["you tamed %s, so the arrow is put away."] = "你驯服了%s，所以箭头收起来了。"
L["your beast"] = "你的野兽"
L["%d,%03d yd"] = "%d,%03d码"
L["%d yd"] = "%d码"
L["Inside a raid"] = "在团队副本里"
L["Inside a dungeon"] = "在地下城里"
L["Far from here. Head for %s"] = "离这里很远。前往%s"
L["it"] = "它"
L["No exact spot for it in this zone yet"] = "这个区域里还没有它的准确位置"
L["The middle of the zone, since there's no exact spot yet"] =
    "区域的中间，因为还没有准确位置"
L["Where it lived in Classic"] = "它在经典旧世里的位置"
L["Far away"] = "很远"
L["In %s"] = "在%s"
L["this zone"] = "这个区域"
L["You're there"] = "你到了"
L["beast arrow on, pointing at %s."] = "野兽箭头已打开，指向%s。"
L["beast arrow on. Shift-click a beast in the Pet Compendium to aim it."] =
    "野兽箭头已打开。在宠物图鉴里按住 Shift 点击一只野兽，箭头就会指向它。"
L["beast arrow off. /bpet arrow on shows it."] = "野兽箭头已关闭。输入 /bpet arrow on 可以再显示。"
L["an arrow to a beast from the Pet Compendium (on, off, clear, check, tomtom, route, reset)"] =
    "指向宠物图鉴里一只野兽的箭头（on, off, clear, check, tomtom, reset）"
L["the beast arrow isn't following a beast right now."] = "野兽箭头现在没有跟随任何野兽。"
L["beast arrow put back where it started."] = "野兽箭头已放回原来的位置。"
L["/bpet arrow on, off, clear, check, tomtom, route or reset."] = "/bpet arrow on、off、clear、check、tomtom、route 或 reset。"

-- The compendium's data
L["Rare"] = "稀有"
L["Rare elite"] = "稀有精英"
L["Elite"] = "精英"
L["hours"] = "小时"
L["minutes"] = "分钟"
L["%d %s to %d %s"] = "%d%s到%d%s"
L["dungeon"] = "地下城"
L["raid"] = "团队副本"
L["Seen on Forever"] = "在 Forever 上见过"
L["Tamed on Forever"] = "在 Forever 上驯服过"
L["Found on Forever"] = "在 Forever 上找到过"
L["You tamed it on Forever"] = "你在 Forever 上驯服过它"
L["Beast %d"] = "野兽 %d"

-- Food
L["%s, which it doesn't eat"] = "%s，它不吃"
L["too low level"] = "等级太低"
L["buff food, which you've chosen not to feed"] = "增益食物，你选了不喂这种"
L["full"] = "满"
L["half"] = "一半"
L["little"] = "很少"
L["refused"] = "拒绝"
L["None in your bags"] = "背包里没有"
L["%s (%s), %d in bags"] = "%s（%s），背包里有%d个"
L["running low"] = "快没了"
L["You have no food %s will eat."] = "你没有%s愿意吃的食物。"
L["your pet"] = "你的宠物"
L["Only %d food left that %s will eat."] = "%2$s愿意吃的食物只剩%1$d份了。"
L["food: no pet out."] = "食物：没有召唤宠物。"
L["food: %s (level %s) eats %s"] = "食物：%s（等级%s）吃%s"
L["item %s"] = "物品 %s"
L[" (level %s)"] = "（等级%s）"
L[", buff food (fed last)"] = "，增益食物（最后才喂）"
L["not in the food list:"] = "不在食物列表里："
L["food: %d items in %d slots, %d pieces your pet will eat."] =
    "食物：%d件物品在%d个格子里，你的宠物愿意吃其中%d份。"
L["food: %s."] = "食物：%s。"
L["food: %s"] = "食物：%s"
L["list the food in your bags and whether your pet will eat it"] =
    "列出背包里的食物，以及你的宠物吃不吃"

-- The pet's status
L["%s (%d%% damage)"] = "%s（%d%%伤害）"
L["falling"] = "下降中"
L["rising"] = "上升中"
L["%s free (%d total, %d spent)"] = "剩余%s（共%d，已用%d）"
L["Unhappy"] = "不高兴"
L["Content"] = "满意"
L["Happy"] = "高兴"
L["Your pet"] = "你的宠物"
L["%s is %s. Feed it."] = "%s%s。该喂它了。"

-- Tames and pet skills
L["noted what %s teaches: %s"] = "已记下%s能教的技能：%s"
L["the beast"] = "这只野兽"
L["nothing"] = "无"
L["list the beasts you have tamed and what each taught"] =
    "列出你驯服过的野兽，以及每只教了什么"
L["no tamed beasts yet. Tame one and it shows up here."] =
    "还没有驯服过野兽。驯服一只，它就会出现在这里。"
L["beasts you've tamed (%d):"] = "你驯服过的野兽（%d）："
L["list the pet skills this hunter knows"] = "列出这个猎人会的宠物技能"
L["no pet skills known yet. Open Beast Training once so Pets can read the list."] =
    "还不知道任何宠物技能。打开一次野兽训练，让 Pets 读取列表。"
L["pet skills known (%d): %s"] = "已会的宠物技能（%d）：%s"
L["You haven't opened Beast Training on this character yet."] =
    "你还没有在这个角色上打开过野兽训练。"
L["%s (Rank %d)"] = "%s（等级%d）"

-- TomTom
L["TomTom is off. The beast arrow shows its own dial."] = "TomTom 已关闭。野兽箭头显示自己的指针。"
L["TomTom is on. Its arrow points where the beast arrow would."] =
    "TomTom 已打开。它的箭头会指向野兽箭头要指的地方。"
L["TomTom takes over once it's installed."] = "装好 TomTom 后，它会接手指路。"

-- Map pins
L["there's no exact spot for that one"] = "那个没有准确位置"
L["this client can't put a pin on the map"] = "这个游戏不能在地图上放标记"
L["couldn't find the map for that zone"] = "找不到那个区域的地图"
L["pinned %s on your map: %s (%s, %s)"] = "已在地图上标记%s：%s（%s, %s）"
L["can't pin %s%s: %s"] = "无法标记%s%s：%s"
L["that"] = "那个"

-- The arrow's window
L["beast arrow off. The Arrow button in the Pet Compendium, /bpet arrow or Settings brings it back."] =
    "野兽箭头已关闭。点宠物图鉴里的箭头按钮、输入 /bpet arrow 或在设置里都能找回它。"
L["Beast arrow"] = "野兽箭头"
L["Click to open the Pet Compendium."] = "点击打开宠物图鉴。"
L["Drag to move it."] = "拖动可以移动它。"
L["Can't see you here"] = "这里看不到你的位置"
L["The game won't say where you are"] = "游戏没有说你在哪里"

-- The compendium window
L["Click a beast to pin it on your map, or Shift-click to point the arrow at it. %s marks what WoW: Forever has shown."] =
    "点击一只野兽就会在地图上标记它，按住 Shift 点击就让箭头指向它。%s 表示 WoW: Forever 里见过的。"
L["Settings"] = "设置"
L["Arrow"] = "箭头"
L["All families"] = "所有种类"
L["Search beasts, zones or skills"] = "搜索野兽、区域或技能"
L["Tameable now"] = "现在能驯服"
L["Only beasts at or below your level."] = "只显示不高于你等级的野兽。"
L["Rares only"] = "只看稀有"
L["Teaches me something new"] = "能教我新技能"
L["Only beasts that teach a skill you don't have yet."] = "只显示能教你还没有的技能的野兽。"
L["Only beasts known to live on WoW: Forever."] = "只显示确定在 WoW: Forever 上有的野兽。"
L["Click again to flip it, and once more to go back."] = "再点一次反过来排，再点一次恢复原样。"
L["Beast"] = "野兽"
L["Sort by beast"] = "按野兽排序"
L["Family"] = "种类"
L["Sort by family"] = "按种类排序"
L["Level"] = "等级"
L["Sort by level"] = "按等级排序"
L["Speed"] = "速度"
L["Sort by speed"] = "按速度排序"
L["Seconds between its attacks. Lower is faster."] = "两次攻击之间的秒数。越小越快。"
L["Where"] = "位置"
L["Sort by where"] = "按位置排序"
L["Teaches"] = "能教"
L["Not known yet"] = "还不知道"
L["Raid"] = "团队副本"
L["Dungeon"] = "地下城"
L["tamed"] = "已驯服"
L["Nothing"] = "无"
L["beast arrow pointing at %s. Hide it with its red gem, /bpet arrow off or Settings."] =
    "野兽箭头正指向%s。点它的红宝石、输入 /bpet arrow off 或在设置里都可以隐藏它。"
L["where %s lives isn't known yet, so the arrow can't point at it."] =
    "还不知道%s住在哪里，所以箭头没法指向它。"
L["Family not known yet"] = "还不知道种类"
L["Eats %s"] = "吃%s"
L["Level %s. You can tame it now."] = "等级%s。你现在就能驯服它。"
L["Level %s. You can tame it from level %d."] = "等级%s。你到%d级就能驯服它。"
L["Level %s"] = "等级%s"
L["Attack speed %s"] = "攻击速度%s"
L["Attack speed %s (seen on Forever)"] = "攻击速度%s（在 Forever 上见过）"
L["Where it lives is not known yet."] = "还不知道它住在哪里。"
L["Shift-click to point the arrow at it."] = "按住 Shift 点击，让箭头指向它。"
L["Also in %s"] = "也在%s"
L["Found in %d spots. This one is near the middle."] = "在%d个地方出现过。这个位置靠近中间。"
L["Comes back after %s"] = "%s后重新出现"
L["Taming it teaches nothing new."] = "驯服它学不到新技能。"
L["Taming it teaches"] = "驯服它能学到"
L["(known)"] = "（已会）"
L["(not known)"] = "（未会）"
L["Click to pin it on your map."] = "点击在地图上标记它。"
L["No exact spot to pin. Shift-click to point the arrow at its zone."] =
    "没有准确位置可以标记。按住 Shift 点击，让箭头指向它所在的区域。"
L["No place to pin yet."] = "还没有可以标记的地方。"
L["Beasts a hunter can tame. You are level %d."] = "猎人能驯服的野兽。你现在%d级。"
L["Beasts a hunter can tame."] = "猎人能驯服的野兽。"
L["No beast matches. Untick a box or clear the search."] =
    "没有符合的野兽。取消一个勾选，或清空搜索。"
L["%d beasts"] = "%d只野兽"
L["open the Pet Compendium: every beast you can tame"] =
    "打开宠物图鉴：所有你能驯服的野兽"

-- The Feed buttons
L["Feed"] = "喂食"
L["Feed %s"] = "喂%s"
L["%s is %s."] = "%s%s。"
L["hungry"] = "饿了"

-- The Pet care key
L["the Pet care key feeds a hunter's pet."] = "宠物照料键用来喂猎人的宠物。"
L["you have no pet out."] = "你没有召唤宠物。"
L["the game did not say what your pet eats."] = "游戏没有说你的宠物吃什么。"
L["your bags are still loading. Try again in a moment."] =
    "你的背包还在加载。稍等一下再试。"
L["you have no food in your bags that %s will eat."] = "你的背包里没有%s愿意吃的食物。"
L["your pet can't be fed in combat."] = "战斗中不能喂宠物。"
L["your demon is already out."] = "你的恶魔已经召唤出来了。"
L["nothing to feed your pet yet."] = "还没有东西可以喂你的宠物。"
L["Pet care key (%s)"] = "宠物照料键（%s）"
L["Pet care key (not set yet, find it under Options, Keybindings, AddOns)"] =
    "宠物照料键（还没设置，在选项、按键设置、插件里可以找到）"
L["calls your pet when none is out"] = "没有宠物时召唤宠物"
L["revives your pet"] = "复活你的宠物"
L["summons your demon when none is out"] = "没有恶魔时召唤恶魔"
L[", and "] = "，并且"
L["mends it in combat"] = "战斗中治疗它"
L["%s feeds %s%s."] = "%s喂%s%s。"
L["%s has nothing to feed: %s"] = "%s没有东西可喂：%s"
L["not checked yet."] = "还没检查。"
L["Pet care (call, revive, feed or mend)"] = "宠物照料（召唤、复活、喂食或治疗）"
L["Dismiss pet"] = "解散宠物"

-- The pets window
L["FOOD"] = "食物"
L["IN A FIGHT"] = "战斗中"
L["Damage a second"] = "每秒伤害"
L["Damage a hit"] = "每次伤害"
L["%s, level %s"] = "%s，等级%s"
L["1 training point free"] = "剩余1点训练点数"
L["%d training points free"] = "剩余%d点训练点数"
L["%d training points over"] = "训练点数超出%d点"
L["%d in your bags (%s)"] = "背包里有%d个（%s）"
L["No food"] = "没有食物"
L["Enough food for about %.1f hours"] = "食物够吃大约%.1f小时"
L["Not enough food to keep it happy"] = "食物不够让它保持高兴"
L["Happiness"] = "快乐度"
L["Loyalty"] = "忠诚度"
L["Experience"] = "经验"
L["Hunter"] = "猎人"
L["Warlock"] = "术士"
L["Training points"] = "训练点数"
L["Pets is for hunters and warlocks."] = "Pets 是给猎人和术士用的。"
L["Eats"] = "食性"
L["Health"] = "生命值"
L["Attack speed"] = "攻击速度"
L["Attack power"] = "攻击强度"
L["Armor"] = "护甲"
L["Resistances"] = "抗性"
L["Fire"] = "火焰"
L["Nature"] = "自然"
L["Frost"] = "冰霜"
L["Shadow"] = "暗影"
L["Arcane"] = "奥术"
L["%.2f seconds"] = "%.2f秒"
L["%d to %d (%.1f a second)"] = "%d到%d（每秒%.1f）"
L["%d to %d"] = "%d到%d"
L["%s %d"] = "%s %d"
L["open the pets window (so does /bpet on its own)"] = "打开宠物窗口（只输入 /bpet 也可以）"
L["No pet out."] = "没有召唤宠物。"

-- The minimap button
L["Click to open"] = "点击打开"
L["Right-click for settings"] = "右键点击打开设置"
L["Click for settings"] = "点击打开设置"
L["Drag to move it round the minimap"] = "拖动可以绕着小地图移动它"

-- Settings
L["Changes save as you make them."] = "改动会马上保存。"
L["Reload"] = "重新加载"
L["FEEDING"] = "喂食"
L["TAMING"] = "驯服"
L["PET COMPENDIUM"] = "宠物图鉴"
L["BEAST ARROW"] = "野兽箭头"
L["Check"] = "检查"
L["Clear"] = "清除"
L["WINDOWS"] = "窗口"
L["HUNTER PET"] = "猎人宠物"
L["ADVANCED"] = "高级"
L["Feeding warnings, the Feed button and taming skills on tooltips"] =
    "喂食提醒、喂食按钮和鼠标提示里的驯服技能"
L["COMPENDIUM"] = "图鉴"
L["The Pet Compendium, the beast arrow and TomTom"] = "宠物图鉴、野兽箭头和 TomTom"
L["GENERAL"] = "常规"
L["Pets' settings have a window of their own."] = "Pets 的设置有自己的窗口。"
L["Open Pets settings"] = "打开 Pets 设置"
L["Or type /bpet settings, or click the minimap button."] =
    "也可以输入 /bpet settings，或点击小地图按钮。"
L["open the settings window"] = "打开设置窗口"

-- The settings pages
L["Show descriptions"] = "显示说明"
L["Find a setting"] = "查找设置"
L["Normal"] = "正常"
L["Large"] = "大"
L["Larger"] = "更大"

-- The taming tooltip
L["Taming teaches"] = "驯服能学到"
L["Known"] = "已会"
L["Not known"] = "未会"
L["Open Beast Training once to see which you know"] = "打开一次野兽训练，就能看到你会哪些"

-- The house frame
L["Close"] = "关闭"

-- UI/WhatsNew.lua (the same lines in every addon) and its Settings rows.
L["What's New"] = "更新内容"
L["BLACKTHORNES ADDONS"] = "BLACKTHORNES 插件"
L["Here's what changed since you last played."] = "这是你上次玩之后的改动。"
L["The newest changes in each of your Blackthornes addons."] = "你每个 Blackthornes 插件的最新改动。"
L["Show after updates"] = "更新后显示"
L["Motion"] = "动画"
L["Got it"] = "知道了"
L["there is no news to show yet."] = "还没有可以显示的更新。"
L["open the What's New window for every Blackthornes addon"] = "打开所有 Blackthornes 插件的更新内容窗口"

-- ======================================================================
-- Settings rows
L["On"] = "开启"
L["Show"] = "显示"
L["Open"] = "打开"
L["Feed Warning:"] = "喂食提醒："
L["Only When Unhappy"] = "只在不高兴时"
L["Warns you when your pet isn't happy. Only When Unhappy waits until it's unhappy."] =
    "宠物不高兴时提醒你。选了只在不高兴时，就等它真的不高兴了才提醒。"
L["Low Food Warning:"] = "食物不足提醒："
L["Warns you in chat when you have fewer than %d food your pet will eat."] =
    "宠物愿意吃的食物少于%d份时，在聊天框提醒你。"
L["Never Feed Buff Food:"] = "不喂增益食物："
L["Food that gives a buff is always fed last. Tick this to never feed it."] =
    "带增益效果的食物总是最后才喂。勾选这里就永远不喂。"
L["Feed Button:"] = "喂食按钮："
L["A Feed button above your quests while your pet is hungry."] =
    "宠物饿了时，在任务列表上方显示一个喂食按钮。"
L["Taming Skills:"] = "驯服技能："
L["A beast's tooltip shows what it teaches. Green you know, red you don't."] =
    "野兽的鼠标提示会显示它能教什么。绿色是你会的，红色是你不会的。"
L["Pet Compendium:"] = "宠物图鉴："
L["Beast Arrow:"] = "野兽箭头："
L["Points the way to a beast. Shift-click one in the compendium to aim it."] =
    "给你指向一只野兽的路。在图鉴里按住 Shift 点击一只来指向它。"
L["Check the Arrow:"] = "检查箭头："
L["Lists in chat what the arrow can read here."] = "在聊天框列出箭头在这里能读到什么。"
L["Stop Following:"] = "停止跟随："
L["Use TomTom:"] = "使用 TomTom："
L["With TomTom installed, its arrow shows the way instead."] = "装了 TomTom 的话，就由它的箭头来指路。"
L["Pets:"] = "Pets："
L["Window Position:"] = "窗口位置："
L["Reset the UI windows to their defaults."] = "把窗口放回默认位置。"
L["Set Default"] = "恢复默认"
L["UI windows set to defaults."] = "窗口已放回默认位置。"
L["Text Size:"] = "文字大小："
L["Window Style:"] = "窗口样式："
L["Debug:"] = "调试："
L["Extra chat messages to help track down a problem."] = "额外的聊天信息，帮忙找出问题。"
L["Sister Addons:"] = "姊妹插件："
L["Says once in chat which Blackthornes addons you don't have."] = "在聊天框说一次你还没有哪些 Blackthornes 插件。"
L["What's New:"] = "更新内容："
L["What's New After Updates:"] = "更新后显示更新内容："
L["Opens What's New the first time you play after an update."] = "更新后第一次玩时打开更新内容。"
L["What's New Motion:"] = "更新内容动画："
L["Client Check:"] = "游戏检查："
L["Lists in chat what the game tells Pets about your pet."] = "在聊天框列出游戏告诉 Pets 的宠物信息。"
L["Window position, text size and debug output"] = "窗口位置、文字大小和调试信息"

-- About (UI/About.lua) and the note in What's New
-- ======================================================================
L["A few of you have asked if AI is used in the creation of my AddOns. It is."] = "有些朋友问我做插件时有没有用 AI。是的，有用。"
L["I've spent 25 years developing software and working in IT, and I recommend developers today use it, but with care and intention. For me that means I decide what gets built, I set the rules the code has to follow, I review the code, and I test changes in game myself. AI helps me write the code, run the tests and track down bugs."] = "我做软件开发和 IT 工作已经 25 年了，我建议现在的开发者使用 AI，但要用心、有目的地用。对我来说，这意味着由我决定做什么，由我定下代码必须遵守的规则，由我检查代码，也由我亲自在游戏里测试改动。AI 帮我写代码、跑测试和找出 bug。"
L["Used well, it means more features, faster bug fixes and quicker turnaround on your requests. A lot of what's in these addons started as an idea or a bug report from a player."] = "用得好，就能有更多功能、更快修好 bug，也能更快完成你们的请求。这些插件里很多东西，最早都来自玩家的一个想法或一份 bug 报告。"
L["If you have an idea or something isn't working, come find me on my Discord at discord.gg/f2geDecrw2. I read every comment and report."] = "如果你有想法，或者有东西不好用，来我的 Discord 找我：discord.gg/f2geDecrw2。每条留言和报告我都会看。"
L["%s, version %s"] = "%s，版本 %s"
L["DISCORD"] = "DISCORD"
L["Click the box, then press Ctrl+C to copy the link."] = "点击方框，然后按 Ctrl+C 复制链接。"
L["REPORT A BUG"] = "报告 BUG"
L["Post it on my Discord with what you were doing when it happened. I read every comment and report."] = "在我的 Discord 上发出来，说说出问题时你在做什么。每条留言和报告我都会看。"
L["THANK YOU"] = "谢谢"
L["A lot of what's here started as a player's idea or bug report. Thank you to everyone who sent one in."] = "这里很多东西最早都来自玩家的想法或 bug 报告。谢谢每一位发来的朋友。"
L["installed"] = "已安装"
L["turned off"] = "已关闭"
L["not installed"] = "未安装"
L["%s (%s)"] = "%s（%s）"
L["How these addons are made"] = "这些插件是怎么做的"
L["A note from Blackthornes."] = "来自 Blackthornes 的一段话。"
L["ABOUT"] = "关于"
L["HOW THESE ADDONS ARE MADE"] = "这些插件是怎么做的"
L["How these addons are made, the version, the Discord and the other Blackthornes addons"] = "这些插件是怎么做的、版本、Discord 和其他 Blackthornes 插件"

-- Off, Shift or Always for a tooltip line (UI/TooltipShift.lua).
L["Off"] = "关"
L["Shift"] = "Shift"
L["Always"] = "总是"
L["Hold Shift for more."] = "按住 Shift 查看更多。"
L["Drag to make the window bigger or smaller."] = "拖动可以把窗口变大或变小。"
L["Right-click to go back to normal size."] = "右键点击恢复正常大小。"
L["EFFECTS"] = "效果"
L["Effects:"] = "效果："
L["Full"] = "完整"
L["Subtle"] = "轻微"
L["Couldn't tell what your pet eats yet."] = "还不知道你的宠物吃什么。"
L["Couldn't read your bags. Try again in a moment."] = "无法读取你的背包。请稍后再试。"
L["Name not loaded yet"] = "名称尚未载入"
L["Your filters hide 1 beast."] = "筛选隐藏了 1 只野兽。"
L["Your filters hide %d beasts."] = "筛选隐藏了 %d 只野兽。"

-- The way there (Logic/Travel.lua, the same in every addon).
L["Fly to %s"] = "飞往%s"
L["Talk to the flight master"] = "和飞行管理员对话"
L["Wait here for the boat to %s"] = "在这里等前往%s的船"
L["Get on when it stops"] = "它停下时上去"
L["Take the boat to %s"] = "乘船前往%s"
L["Wait here for the zeppelin to %s"] = "在这里等前往%s的飞艇"
L["Take the zeppelin to %s"] = "乘坐飞艇前往%s"
L["Use your Hearthstone"] = "使用你的炉石"
L["It takes you to %s"] = "它会把你带到%s"
L["Walk to %s"] = "走到%s"
L["toward %s"] = "朝%s方向"
L["Next: %s."] = "下一步：%s。"
L["Your Way There"] = "前往路线"
L["Show on Map"] = "在地图上显示"
L["Stop"] = "停止"
L["Done"] = "完成"
L["Now"] = "现在"
L["About 1 minute"] = "大约 1 分钟"
L["About %d minutes"] = "大约 %d 分钟"
L["Guide Me:"] = "为我引路："
L["Step %d of %d"] = "第 %d 步，共 %d 步"
L["The arrow leads you step by step to places far away."] = "箭头会一步一步带你去远处的地点。"
L["The arrow points straight at places far away."] = "箭头会直接指向远处的地点。"
L["When the place is in another zone or across the sea, the arrow leads you there step by step."] = "目的地在别的区域或海的另一边时，箭头会一步一步带你过去。"

-- The Skills card and the window's tabs.
L["%d point"] = "%d点"
L["%d points"] = "%d点"
L["%s Rank %d"] = "%s 等级%d"
L["CAN LEARN NOW"] = "现在可学"
L["COST"] = "花费"
L["Click to see the beasts that teach it."] = "点击查看会教这个技能的野兽。"
L["Compendium"] = "图鉴"
L["LATER"] = "以后"
L["Pet"] = "宠物"
L["Pet level %d"] = "宠物等级%d"
L["Pet trainer"] = "宠物训练师"
L["Pet trainer: %s"] = "宠物训练师：%s"
L["RANK"] = "等级"
L["Rank %d"] = "等级%d"
L["SKILLS"] = "技能"
L["Show the Way"] = "指路"
L["Tame a beast that knows it"] = "驯服一只会这个技能的野兽"
L["WHEN"] = "何时"
L["YOUR PET KNOWS"] = "你的宠物会"
L["from a pet trainer"] = "来自宠物训练师"
L["from your Beast Training"] = "来自你的野兽训练"
