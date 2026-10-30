/// @description Crown & Crucible - Knight's Retinue Character Data & Personality Definitions
/// @module scr_retinue_data
///
/// PURPOSE:
///   Houses authoritative definitions for all 8 retinue companions and sellswords:
///   1. Companions: Dunstan the Poacher, Margery of the Mire, Sir Galahalt the Disgraced, Sister Isolde.
///   2. Sellswords: Agnes of the High Sward (halberdier), Cormac Iron-Hand (man-at-arms),
///      Brant the Fowler (scout), Maud the Herbalist (chirurgeon).
///   Contains personality tags (likes/dislikes), combat weapon classes, baseline stats,
///   daily routines by time of day, voice lines, dialogue greetings, and refusals.
///
/// STATE OWNERSHIP:
///   - Pure template data registry (read-only definitions cloned into runtime member structs).
///   - Defines world coordinates for routines in retinue_places().

#macro RET_KIND_COMPANION "COMPANION"
#macro RET_KIND_MERC "MERCENARY"
#macro RET_KIND_ALLY "ALLY"

/// Named spots used by routines: [x, y, place name shown in the ledger].
function retinue_places() {
    static _p = {
        tavern_hearth: [300, 2700, "The Boar & Flagon, by the hearth"],
        tavern_dice:   [372, 2800, "The Boar & Flagon, at the dice table"],
        tavern_loft:   [490, 2846, "The Boar & Flagon, asleep in a corner"],
        tavern_bar:    [420, 2706, "The Boar & Flagon, propping up the bar"],
        tavern_supper: [236, 2706, "The Boar & Flagon, at the long table"],
        square:        [1708, 1318, "Stonecross square, busking by the stalls"],
        chapel_altar:  [1304, 2668, "Eastern Chapel, at the altar"],
        chapel_aisle:  [1304, 2760, "Eastern Chapel, keeping vigil"],
        chapel_cot:    [1400, 2858, "Eastern Chapel, on a sickbed"],
        chapel_yard:   [2640, 1382, "Chapel yard, tending the brew vats"],
        bakery:        [1290, 1176, "Beatrice's bakery, 'helping'"],
        camp:          [846, 1884, "Watchtower camp, by the fire"],
        camp_drill:    [884, 1932, "Watchtower camp, drilling at dawn"],
        guard_yard:    [1420, 1412, "Guardhouse yard, sparring with the militia"],
        range:         [1286, 1214, "Militia archery range"],
        stable:        [2296, 862, "The stables, dicing with the grooms"],
        notice:        [1724, 1160, "Stonecross square, reading the proclamations"],
        shrine:        [2440, 1270, "The wayside shrine"],
        alden_door:    [1455, 1112, "Elder Alden's door, petitioning"],
    };
    return _p;
}

/// Every person the retinue knows about. Order is the ledger order.
function retinue_defs() {
    return [
        // ------------------------------------------------------------------ SIR GALAHALT
        {
            id: "GALAHALT", kind: RET_KIND_COMPANION, visual: "galahalt", body_id: "GALAHALT",
            name: "Sir Galahalt", title: "The Rust-Worn Knight", specialty: "Knight",
            col: make_color_rgb(148, 163, 184),
            traits: ["Honorable", "Cynical", "Stubborn"],
            blurb: "Last knight of the broken Order of the Ashen Lance. Keeps every oath, trusts no crown, and has opinions about your footwork.",
            likes: ["DUTY", "VALOR", "OATH", "COMMONS"], dislikes: ["DECEIT", "SMUGGLING", "BETRAYAL", "COWARDICE", "SPARE_BANDIT"],
            refuses: ["SMUGGLE", "BETRAYAL"],
            approval: 5, loyalty: 40, morale: 60,
            stats: { max_hp: 34, atk: 8, def: 6, spd: 3, crit: 5 },
            equipment: { weapon: "ashen_lance_longsword", weapon_name: "Ashen Lance Longsword", armor: "dented_plate", armor_name: "Dented Order Plate", relic: "", relic_name: "Broken Order Seal" },
            combat: { weapon_class: "SWORD", can_fight: true,
                support: { id: "SHIELD_WALL", name: "Shield Wall", trigger: "SOUL_HIT", power: 3, desc: "Steps in front of the first blow each defense: -3 damage." },
                acts: [{ id: "CHALLENGE", name: "Formal Challenge", desc: "Galahalt names the foe a coward. Lowers its defense." }] },
            home: "camp",
            routine: ["camp_drill", "guard_yard", "camp", "camp"],
            fee: 0, wage: 0, term: 0,
            quest: { id: "FALLEN_BANNER", title: "The Fallen Banner", unlock_approval: 25,
                desc: "The banner of the Ashen Lance was lost in the Barrows when the Order fell. The thing that guards the crypt took it.",
                goal: "Defeat the Barrow Renegade Warden with Galahalt at your side." },
            greet_first: "* (The scarred knight does not look up from the fire.) 'Another fighting man on the road. Sit, if you like. The barrows will still be there tomorrow, and so will I.'",
            greet: ["* Sir Galahalt: 'Rowan. Your guard is still too low.'", "* Sir Galahalt: 'You came back. Most don't.'", "* Sir Galahalt nods, once. From him, that is a speech."],
            join: ["* Sir Galahalt buckles his sword belt. 'Lead on. I'll tell you when you're wrong.'", "* Sir Galahalt: 'An oath is an oath. My shield is yours until the road ends.'"],
            leave: ["* Sir Galahalt: 'Understood. You know where my fire is.'", "* Sir Galahalt: 'Go carefully. I mean it.'"],
            refuse_low: "* Sir Galahalt: 'I've ridden with oathbreakers before. Never again. Prove you're better and we'll talk.'",
            barks: {
                travel: ["A knight walks the road so the farmer doesn't have to.", "Keep your shield arm up. No, higher.", "I had a horse once. Better company than most knights.", "Every lord says he's fighting for the realm. Watch which way the coin runs."],
                night: ["Night roads belong to wolves and worse. Stay close.", "I don't sleep much. Habit from the siege."],
                barrows: ["My brothers are buried somewhere under this. Mind your step.", "The air goes cold here. The Order fell on ground like this."],
                tavern: ["Balin's here again. Drinking his knighthood one cup at a time.", "I'll have water. Someone has to remember tonight."],
                chapel: ["I stopped praying the day the Order fell. I still come for the quiet."],
                low_morale: ["My knee aches. So does my patience.", "We march for coin now. Is that what we've become?"],
                rain: ["Rust weather. Of course."],
            },
        },
        // ------------------------------------------------------------------ MARGERY
        {
            id: "MARGERY", kind: RET_KIND_COMPANION, visual: "margery", body_id: "MARGERY",
            name: "Margery", title: "Minstrel & Opportunist", specialty: "Minstrel",
            col: make_color_rgb(244, 63, 94),
            traits: ["Witty", "Reckless", "Generous"],
            blurb: "A wandering minstrel who sings for her supper, gambles for her breakfast and gives the winnings away by lunch.",
            likes: ["GAMBLE", "ADVENTURE", "MERCY", "COMMONS", "VICTORY"], dislikes: ["TYRANNY", "CROWN_TAX", "BORING", "CRUELTY"],
            refuses: ["TAX"],
            approval: 15, loyalty: 35, morale: 75,
            stats: { max_hp: 22, atk: 6, def: 2, spd: 5, crit: 20 },
            equipment: { weapon: "twin_daggers", weapon_name: "Twin Daggers (\"Left\" and \"Also Left\")", armor: "leather_doublet", armor_name: "Patched Leather Doublet", relic: "loaded_die", relic_name: "A Suspiciously Lucky Die" },
            combat: { weapon_class: "DAGGER", can_fight: true,
                support: { id: "ROUSING_BALLAD", name: "Rousing Ballad", trigger: "BATTLE_START", power: 10, desc: "Opens every fight with a verse: +10% crit for Rowan." },
                acts: [{ id: "TAUNT_SONG", name: "Insulting Ditty", desc: "Margery mocks the foe in rhyme. Makes MERCY easier." }] },
            home: "tavern_hearth",
            routine: ["tavern_loft", "square", "tavern_dice", "tavern_hearth"],
            fee: 0, wage: 0, term: 0,
            quest: { id: "SONG_WORTH_SINGING", title: "A Song Worth Singing", unlock_approval: 0,
                desc: "Margery wants to write a ballad that will still be sung when she's dead. She needs deeds to sing about.",
                goal: "Let Margery witness three great deeds (victories, quests, contracts), then visit her at the tavern." },
            greet_first: "* (Margery plays a lively lute chord.) 'A proper man-at-arms! With all the clanking. Buy me a drink and I'll tell you which roads are worth dying on.'",
            greet: ["* Margery: 'My favourite tin can! Come to rescue me from honest work?'", "* Margery: 'Rowan! I was just telling these good people you're nine feet tall.'", "* Margery tunes a string. 'Adventure or ale? I'm flexible.'"],
            join: ["* Margery slings her lute. 'Finally! Somewhere with fewer debts and more dragons.'", "* Margery: 'I'll come. Someone has to make you sound heroic.'"],
            leave: ["* Margery: 'Fine, fine. I'll be at the Flagon, winning back what I lost last week.'", "* Margery blows a kiss. 'Don't get famous without me.'"],
            refuse_low: "* Margery: 'You know what, love? Not this time. I've songs about men like you, and none are kind.'",
            barks: {
                travel: ["I'm composing. Something rhymes with 'Rowan'. Probably 'groan'.", "If we find treasure, I get first pick. Minstrel's rights.", "Bet you a crown I can hit that fencepost from here.", "You walk like a man carrying a cathedral."],
                night: ["Night's the best time. Everyone's honest after the third cup.", "Stars are out. Somewhere a fool's writing poetry. Oh, it's me."],
                barrows: ["This place is giving me a terrible verse. Something about bones.", "Dead things don't tip. Let's be quick."],
                tavern: ["Wulf owes me a song and four crowns. Don't tell him I said that.", "Ah, home. Smells of spilled ale and broken promises."],
                chapel: ["Dunstan says I sing like an angel. A fallen one, but still."],
                low_morale: ["Even I'm out of jokes, Rowan. That's bad.", "I could be warm right now. Just saying."],
                rain: ["Rain's ruining my strings. I'll bill the Crown."],
            },
        },
        // ------------------------------------------------------------------ BROTHER DUNSTAN
        {
            id: "DUNSTAN", kind: RET_KIND_COMPANION, visual: "dunstan", body_id: "DUNSTAN",
            name: "Brother Dunstan", title: "Brewer of the Eastern Chapel", specialty: "Friar",
            col: make_color_rgb(217, 119, 6),
            traits: ["Jovial", "Gluttonous", "Devout"],
            blurb: "A friar who believes in mercy, mead and a second helping. Swings a staff like a man who has broken up a great many tavern fights.",
            likes: ["MERCY", "CHARITY", "FEAST", "PIETY", "COMMONS"], dislikes: ["CRUELTY", "SACRILEGE", "BETRAYAL", "HUNGER"],
            refuses: ["SACRILEGE"],
            approval: 10, loyalty: 45, morale: 70,
            stats: { max_hp: 30, atk: 5, def: 4, spd: 2, crit: 5 },
            equipment: { weapon: "oak_staff", weapon_name: "Oaken Pilgrim Staff", armor: "friar_habit", armor_name: "Well-Fed Friar's Habit", relic: "abbey_rosary", relic_name: "Abbey Rosary" },
            combat: { weapon_class: "SPEAR", can_fight: true,
                support: { id: "BLESSED_MEAD", name: "Blessed Mead", trigger: "PLAYER_TURN", power: 4, desc: "Once per fight, a swig of abbey mead: heals Rowan 4 HP." },
                acts: [{ id: "BLESS", name: "Bless the Foe", desc: "Dunstan blesses the enemy. The truly lost become easier to spare." }] },
            home: "chapel_altar",
            routine: ["chapel_altar", "chapel_yard", "tavern_supper", "chapel_aisle"],
            fee: 0, wage: 0, term: 0,
            quest: { id: "ALMSHOUSE", title: "Bread for the Almshouse", unlock_approval: 15,
                desc: "Dunstan dreams of an almshouse beside the chapel, where no traveller goes hungry. He needs help, and coin, and mercy.",
                goal: "Show mercy or charity three times while Dunstan is with you (spare foes, feed the poor)." },
            greet_first: "* (Brother Dunstan pauses from stirring his ale vat.) 'Peace, friend! You look half-starved. Sit, have a cup, and tell me who you're fighting for.'",
            greet: ["* Brother Dunstan: 'Rowan! Have you eaten? You haven't. I can tell.'", "* Brother Dunstan: 'Blessings, my friend. And bread. Mostly bread.'", "* Brother Dunstan raises a mug. 'To the road, and whatever's at the end of it!'"],
            join: ["* Brother Dunstan takes up his staff. 'Someone must keep your soul in one piece. And your stomach.'", "* Brother Dunstan: 'I'll come. The Lord walks with the merciful, and I walk with snacks.'"],
            leave: ["* Brother Dunstan: 'Go with God, and come back hungry.'", "* Brother Dunstan: 'The chapel door's never barred to you.'"],
            refuse_low: "* Brother Dunstan sighs. 'I pray for you, Rowan. I just can't walk beside you right now.'",
            barks: {
                travel: ["Is that a pie shop? No? A pity.", "Every road leads somewhere holy, if you walk it kindly.", "My feet hurt, my belly growls and my heart is full. A good day.", "Mercy costs nothing, Rowan. Well. Sometimes an arm."],
                night: ["Compline was an hour ago. The Lord will understand.", "Night watch? I'll pray. Loudly. Keeps the wolves off."],
                barrows: ["These dead were someone's children. Tread softly.", "I'll bless the stones as we pass. It can't hurt."],
                tavern: ["Strictly for the mead, you understand. Theological research.", "Margery's singing again. Lord, give me patience. And earplugs."],
                chapel: ["Home. Kneel with me a moment, Rowan. Just a moment."],
                low_morale: ["I haven't had a proper meal in two days. My faith is being tested.", "Even saints grumble, Rowan. Quietly."],
                rain: ["Rain's a blessing for the barley. Less so for my sandals."],
            },
        },
        // ------------------------------------------------------------------ ISOLDE VENN (new)
        {
            id: "ISOLDE", kind: RET_KIND_COMPANION, visual: "isolde", body_id: "ISOLDE",
            name: "Isolde Venn", title: "Exiled Herald of High Cairn", specialty: "Herald",
            col: make_color_rgb(140, 96, 196),
            traits: ["Proud", "Principled", "Sharp-tongued"],
            blurb: "Royal herald stripped of her tabard for refusing to read a false proclamation. Believes in the Crown, if not in the man wearing it.",
            likes: ["CROWN", "ORDER", "OATH", "DUTY"], dislikes: ["DECEIT", "SMUGGLING", "CHAOS", "BETRAYAL"],
            refuses: ["SMUGGLE"],
            approval: 0, loyalty: 30, morale: 55,
            stats: { max_hp: 24, atk: 7, def: 3, spd: 4, crit: 10 },
            equipment: { weapon: "herald_sabre", weapon_name: "Herald's Sabre", armor: "faded_tabard", armor_name: "Faded Royal Tabard", relic: "torn_writ", relic_name: "The Torn Writ" },
            combat: { weapon_class: "SWORD", can_fight: true,
                support: { id: "PARLEY", name: "Herald's Parley", trigger: "BATTLE_START", power: 15, desc: "Announces terms before blades are drawn: the foe starts 15% closer to MERCY." },
                acts: [{ id: "PROCLAIM", name: "Proclaim Terms", desc: "Isolde reads the foe its rights. Honorable foes listen." }] },
            home: "notice",
            routine: ["alden_door", "notice", "shrine", "tavern_hearth"],
            fee: 0, wage: 0, term: 0,
            join_gate: { min_level: 2, min_crown: 20 },
            quest: { id: "HERALD_WITHOUT_HOUSE", title: "A Herald Without a House", unlock_approval: 10,
                desc: "Isolde wants her name cleared. Not her post back. Just the truth on record.",
                goal: "Raise your standing with the Crown to 40, or with Stonecross to 60, while Isolde rides with you." },
            greet_first: "* (A woman in a faded royal tabard is copying the proclamations, correcting the spelling.) 'You read? Good. Most fighting men move their lips. Isolde Venn. Formerly of the King's voice.'",
            greet: ["* Isolde: 'Rowan. Your reputation precedes you. Barely.'", "* Isolde: 'News from High Cairn. None of it good. Walk with me.'", "* Isolde inclines her head with exact courtesy."],
            join: ["* Isolde: 'Very well. Someone ought to keep a true record of what you do.'", "* Isolde: 'I'll ride with you. Try to deserve it.'"],
            leave: ["* Isolde: 'As you command. I'll be where the news is.'", "* Isolde: 'Noted. In ink.'"],
            refuse_low: "* Isolde: 'I refused to lie for a king, Rowan. I won't do it for you.'",
            refuse_gate: "* Isolde: 'I don't follow hedge-knights nobody has heard of. Earn a name (reach level 2, or Crown favor 20), then ask again.'",
            barks: {
                travel: ["Every milestone on this road was paid for by a tax someone resented.", "Rumour says the river lords are arming. Rumour is usually right.", "Walk straighter. People are watching, and some of them write things down.", "I counted the toll gates. There are too many."],
                night: ["Proclamations are posted at night so nobody reads them till it's too late.", "In High Cairn the bells would be ringing now. I miss the bells."],
                barrows: ["Old kings are buried here. They were not good kings."],
                tavern: ["Gossip is just history that hasn't been checked.", "That man by the fire is a crown informer. Smile."],
                chapel: ["Dunstan's chapel keeps better records than the royal archive."],
                low_morale: ["We are drifting, Rowan. I don't like drifting.", "I left one master who wasted me. Don't make me leave two."],
                rain: ["Ink runs in the rain. So do lies, eventually."],
            },
        },
        // ------------------------------------------------------------------ MERCENARIES
        {
            id: "HOB", kind: RET_KIND_MERC, visual: "hob", body_id: "MERC_HOB",
            name: "Hob Ashby", title: "Sellsword, Two Pints Deep", specialty: "Soldier",
            col: make_color_rgb(184, 134, 46),
            traits: ["Boastful", "Steady", "Loyal to coin"],
            blurb: "Fought in three wars and won two of them, he says. Holds a line like a stone wall, as long as the wall is paid on Fridays.",
            likes: ["VICTORY", "FEAST", "PAY"], dislikes: ["UNPAID", "COWARDICE", "BORING"],
            refuses: [],
            approval: 0, loyalty: 30, morale: 55,
            stats: { max_hp: 32, atk: 7, def: 5, spd: 3, crit: 5 },
            equipment: { weapon: "militia_spear", weapon_name: "Militia Spear", armor: "rusty_mail", armor_name: "Rusty Mail", relic: "", relic_name: "Lucky Bottle Cork" },
            combat: { weapon_class: "SPEAR", can_fight: true,
                support: { id: "HOLD_THE_LINE", name: "Hold the Line", trigger: "SOUL_HIT", power: 2, desc: "Braces his spear: -2 damage from the first hit each defense." },
                acts: [] },
            home: "tavern_bar",
            routine: ["tavern_loft", "tavern_bar", "tavern_bar", "tavern_dice"],
            fee: 40, wage: 6, term: 5,
            found: "drinking at the Boar & Flagon bar",
            greet_first: "* (A big man in rusty mail raises his tankard.) 'Hob Ashby. Spear for hire. Forty crowns to sign, six a day, five days' service. Fair as a vicar.' (Talk again to hire.)",
            greet: ["* Hob: 'Captain! Need a wall? I'm a wall.'", "* Hob burps with great dignity. 'At your service.'"],
            join: ["* Hob: 'Signed and sealed! Point me at something.'", "* Hob drains his tankard. 'Right. Who are we hitting?'"],
            leave: ["* Hob: 'Fair enough. Bar's this way if you need me.'"],
            refuse_low: "* Hob: 'Not for any money, Captain. Well. Not for your money.'",
            barks: {
                travel: ["Did I tell you about the siege of Dunhollow? I won it.", "Six a day. Very reasonable. Just saying.", "Good weather for a fight. Any weather is."],
                night: ["Night march. Double pay in civilised companies."],
                barrows: ["Don't like barrows. Things in barrows don't stay dead."],
                tavern: ["Home sweet home. Barkeep! The usual. Captain's paying."],
                chapel: ["Do I take my helmet off in here? I never know."],
                low_morale: ["Coin's thin and the road's long, Captain.", "A man starts thinking about other employers."],
                rain: ["Rain gets in your mail. Then you're a rusty wall."],
            },
        },
        {
            id: "WENNA", kind: RET_KIND_MERC, visual: "wenna", body_id: "MERC_WENNA",
            name: "Wenna Fletch", title: "Longbow for Hire", specialty: "Archer",
            col: make_color_rgb(78, 140, 74),
            traits: ["Quiet", "Precise", "Proud"],
            blurb: "A forester's daughter who outshot the King's own archers at the Midsummer fair and was paid in a ribbon. She now charges.",
            likes: ["VICTORY", "PAY", "ARCHERY", "COMMONS"], dislikes: ["UNPAID", "CRUELTY", "TYRANNY"],
            refuses: [],
            approval: 0, loyalty: 30, morale: 60,
            stats: { max_hp: 22, atk: 8, def: 2, spd: 5, crit: 15 },
            equipment: { weapon: "ash_shortbow", weapon_name: "Yew Longbow", armor: "forester_leathers", armor_name: "Forester's Leathers", relic: "", relic_name: "Midsummer Ribbon" },
            combat: { weapon_class: "BOW", can_fight: true,
                support: { id: "COVERING_VOLLEY", name: "Covering Volley", trigger: "BATTLE_START", power: 6, desc: "An arrow before the fight begins: 6 damage to the foe." },
                acts: [] },
            home: "range",
            routine: ["range", "range", "tavern_hearth", "tavern_loft"],
            fee: 55, wage: 8, term: 5,
            found: "practising alone at the militia archery range",
            greet_first: "* (An archer puts three arrows in the same knot of the target without looking at you.) 'Fifty-five to sign. Eight a day. I don't miss, and I don't work for free.' (Talk again to hire.)",
            greet: ["* Wenna: 'Rowan.'", "* Wenna nods and checks her fletching."],
            join: ["* Wenna strings her bow. 'Keep them in front of me.'", "* Wenna: 'Contract's signed. Don't make me regret it.'"],
            leave: ["* Wenna: 'I'll be at the range.'"],
            refuse_low: "* Wenna: 'No. You know why.'",
            barks: {
                travel: ["Wind's from the west. Good for shooting.", "That crow's been following us. I could fix that.", "Quiet's good. Quiet means nobody's sneaking."],
                night: ["Can't shoot what I can't see. Stay on the road."],
                barrows: ["Something moved behind that stone. Don't look."],
                tavern: ["Too loud in here."],
                chapel: ["My mother prayed. Didn't help her aim."],
                low_morale: ["Pay day was yesterday.", "I'm good at leaving quietly too."],
                rain: ["Wet string. Wonderful."],
            },
        },
        {
            id: "TAM", kind: RET_KIND_MERC, visual: "tam", body_id: "MERC_TAM",
            name: "Tam Reedy", title: "Scout & Pathfinder", specialty: "Scout",
            col: make_color_rgb(120, 140, 80),
            traits: ["Cheerful", "Nosy", "Light-fingered"],
            blurb: "Knows every sheep track between here and Oakhaven and the name of every dog on them. Usually back before you notice he left.",
            likes: ["ADVENTURE", "GAMBLE", "PAY"], dislikes: ["UNPAID", "BORING", "CROWN_TAX"],
            refuses: [],
            approval: 5, loyalty: 30, morale: 70,
            stats: { max_hp: 18, atk: 5, def: 2, spd: 6, crit: 10 },
            equipment: { weapon: "walking_staff", weapon_name: "Ash Walking Staff", armor: "oiled_cloak", armor_name: "Oiled Hooded Cloak", relic: "", relic_name: "A Map of Very Few Roads" },
            combat: { weapon_class: "SPEAR", can_fight: false,
                support: { id: "AMBUSH_WARNING", name: "Ambush Warning", trigger: "BATTLE_START", power: 1, desc: "Spots trouble first: the first enemy wave starts slower." },
                acts: [] },
            home: "stable",
            routine: ["stable", "stable", "tavern_dice", "tavern_loft"],
            fee: 30, wage: 4, term: 6,
            found: "dicing with the grooms behind the stables",
            greet_first: "* (A small hooded fellow scoops up a pile of dice and someone else's coins.) 'Tam Reedy, guide, scout, honest man. Thirty to sign and four a day. I'll find you roads the map forgot.' (Talk again to hire.)",
            greet: ["* Tam: 'Boss! Found a shortcut. Probably.'", "* Tam: 'You look lost. Good thing I'm not.'"],
            join: ["* Tam pockets the dice. 'Off we go! Left at the dead tree, as always.'"],
            leave: ["* Tam: 'I'll be about. I'm always about.'"],
            refuse_low: "* Tam: 'Nah. Word gets round, boss.'",
            barks: {
                travel: ["There's a ford two miles down. Saves a bridge toll.", "Smell that? Rain by supper.", "Shepherd up there owes me money. Wave!"],
                night: ["Owls are out. That's good, owls only mind mice."],
                barrows: ["Nobody maps the barrows. Now I know why."],
                tavern: ["Don't play Wulf. His dice are worse than mine."],
                chapel: ["I'll wait outside. Saints and I have an understanding."],
                low_morale: ["Getting itchy feet, boss.", "There's other roads, you know."],
                rain: ["Told you. Rain by supper."],
            },
        },
        {
            id: "AGNES", kind: RET_KIND_MERC, visual: "agnes", body_id: "MERC_AGNES",
            name: "Sister Agnes", title: "Field Healer, Recovering", specialty: "Healer",
            col: make_color_rgb(200, 190, 170),
            traits: ["Brisk", "Unflappable", "Dry"],
            blurb: "Patched up soldiers at the Battle of the Reeds until a crossbow bolt patched her to a wagon. Wants to be useful again, and cheap until she's whole.",
            likes: ["MERCY", "CHARITY", "PAY", "PIETY"], dislikes: ["UNPAID", "CRUELTY", "SACRILEGE"],
            refuses: [],
            approval: 5, loyalty: 35, morale: 45,
            stats: { max_hp: 18, atk: 3, def: 3, spd: 3, crit: 5 },
            equipment: { weapon: "", weapon_name: "Bone Saw (for emergencies)", armor: "nursing_habit", armor_name: "Bloodstained Habit", relic: "", relic_name: "Field Surgeon's Kit" },
            combat: { weapon_class: "", can_fight: false,
                support: { id: "FIELD_DRESSING", name: "Field Dressing", trigger: "AFTER_BATTLE", power: 6, desc: "After each fight, binds Rowan's wounds: heals 6 HP." },
                acts: [] },
            home: "chapel_cot",
            routine: ["chapel_cot", "chapel_cot", "chapel_aisle", "chapel_cot"],
            fee: 25, wage: 5, term: 5, starts_injured: true,
            found: "recovering from a crossbow wound in the chapel",
            greet_first: "* (A nun on a sickbed is re-bandaging her own shoulder.) 'Agnes. Field healer. I'm on the mend and bored to tears. Twenty-five to sign, five a day. Cheap, because I limp.' (Talk again to hire.)",
            greet: ["* Sister Agnes: 'Sit still. You're bleeding on my floor.'", "* Sister Agnes: 'Ah. The walking injury.'"],
            join: ["* Sister Agnes snaps her kit shut. 'Right. Try not to need me.'"],
            leave: ["* Sister Agnes: 'I'll be at the chapel. Bring the wounded, not excuses.'"],
            refuse_low: "* Sister Agnes: 'I've nursed better men than you who paid on time.'",
            barks: {
                travel: ["Walk evenly. You're favouring your left.", "Yarrow on the verge. Stops bleeding. Remember it.", "My shoulder says rain."],
                night: ["Night's when the fevers come. Keep warm."],
                barrows: ["Grave dust in a wound is a death sentence. Don't get cut here."],
                tavern: ["Half these men will be my patients by morning."],
                chapel: ["Back where I started. Let's not make a habit of it."],
                low_morale: ["I didn't leave a sickbed to be ignored.", "Pay me or patch yourself."],
                rain: ["Damp makes old wounds talk."],
            },
        },
    ];
}

/// Temporary mission allies: templates only; they join through retinue_add_temp_ally().
function retinue_ally_templates() {
    return {
        MILITIA_HALE: {
            id: "MILITIA_HALE", kind: RET_KIND_ALLY, visual: "donald",
            name: "Corporal Hale", title: "Stonecross Militia, on Loan", specialty: "Militia",
            col: make_color_rgb(178, 58, 52), traits: ["Dutiful", "Nervous"],
            blurb: "Sent by the militia to see the Barrows road made safe. Has never fought anything bigger than a goose.",
            likes: ["DUTY", "VICTORY"], dislikes: ["COWARDICE"], refuses: [],
            approval: 0, loyalty: 50, morale: 50,
            stats: { max_hp: 20, atk: 5, def: 4, spd: 3, crit: 5 },
            equipment: { weapon: "militia_spear", weapon_name: "Militia Spear", armor: "militia_mail", armor_name: "Militia Mail", relic: "", relic_name: "" },
            combat: { weapon_class: "SPEAR", can_fight: false,
                support: { id: "MILITIA_BRACE", name: "Militia Brace", trigger: "SOUL_HIT", power: 1, desc: "-1 damage from the first hit." }, acts: [] },
            home: "guard_yard", routine: ["guard_yard", "guard_yard", "guard_yard", "guard_yard"],
            fee: 0, wage: 0, term: 0,
            greet_first: "", greet: ["* Corporal Hale salutes, badly."],
            join: ["* Corporal Hale: 'Militia orders, sir! I'm to see you safe to the Barrows. Or you're to see me safe. It wasn't clear.'"],
            leave: ["* Corporal Hale: 'Back to the guardhouse! I'll tell them you were very brave. I was also brave.'"],
            refuse_low: "",
            barks: { travel: ["Is it always this quiet before?", "My mum says hello. She doesn't know you."], night: ["I'm not scared. It's just cold."],
                barrows: ["Sir. Sir. Did that stone move?"], tavern: [], chapel: [], low_morale: ["I want to go home, sir."], rain: ["Wet."] },
        },
    };
}

/// Two-line exchanges between people travelling together: [speaker_a, line_a, speaker_b, line_b].
function retinue_banter_pairs() {
    return [
        ["GALAHALT", "Must you sing while we walk, minstrel?", "MARGERY", "Must you clank? We all have our music, Sir Grumbles."],
        ["MARGERY", "Galahalt, if you smiled, would your face crack?", "GALAHALT", "It did once. Siege of Aldmere. Never again."],
        ["DUNSTAN", "Sir Galahalt, when did you last eat something warm?", "GALAHALT", "Before the Order fell, Brother. Leave it."],
        ["GALAHALT", "Mercy gets good men killed, friar.", "DUNSTAN", "And cruelty gets them damned. I'll take my chances."],
        ["MARGERY", "Dunstan, back me up: drinking is a sacrament.", "DUNSTAN", "It is not. ...It is very nearly."],
        ["DUNSTAN", "Margery, you lost the alms money at dice again.", "MARGERY", "Borrowed, Brother! Invested! I'll pay it back double."],
        ["ISOLDE", "Your ballads slander the King, Margery.", "MARGERY", "Only the true verses, darling."],
        ["MARGERY", "Isolde, have you ever done one disreputable thing?", "ISOLDE", "I am travelling with you. Note it down."],
        ["ISOLDE", "The Order of the Ashen Lance was dissolved by royal decree.", "GALAHALT", "It was murdered by royal decree. Say it right, herald."],
        ["GALAHALT", "You still believe in the Crown, Venn?", "ISOLDE", "I believe in what it's meant to be. Someone has to."],
        ["DUNSTAN", "Isolde, you'd make a fine abbess. Strict, clever, terrifying.", "ISOLDE", "And sober, Brother. You'd hate it."],
        ["HOB", "Sir Galahalt! Fought at Dunhollow myself, you know.", "GALAHALT", "I was there, Ashby. You were in the baggage train."],
        ["TAM", "Margery, fancy a quick game? Low stakes.", "MARGERY", "Tam, I've seen your dice. They have opinions."],
        ["WENNA", "You talk a lot, minstrel.", "MARGERY", "And you shoot a lot, archer. We all have gifts."],
        ["AGNES", "Brother, that's your third pie.", "DUNSTAN", "Medicinal, Sister. You of all people should approve."],
        ["HOB", "Six a day, Captain, I'm worth eight.", "WENNA", "You're worth the bar tab. Which is eight."],
    ];
}

/// What each quest or contract type means to the people who hear about it.
function retinue_quest_tags(_qid) {
    switch (_qid) {
        case "QUEST_PIG": return ["COMMONS", "CHARITY"];
        case "QUEST_GAMBLER": return ["GAMBLE", "COMMONS"];
        case "QUEST_COUNTERFEIT": return ["PIETY", "DECEIT"];
        case "QUEST_DRUNKEN_KNIGHT": return ["DUTY", "VALOR"];
        case "QUEST_MISSING_WINE": return ["COMMONS", "ORDER"];
        case "QUEST_SMUGGLER_RUN": return ["SMUGGLING", "CHAOS"];
    }
    return ["ADVENTURE"];
}

function retinue_contract_tags(_type, _faction) {
    var _t = ["ADVENTURE"];
    switch (_type) {
        case "BOUNTY": _t = ["VALOR", "ORDER"]; break;
        case "SMUGGLE": _t = ["SMUGGLING", "CHAOS", "SMUGGLE"]; break;
        case "ESCORT": _t = ["DUTY", "COMMONS"]; break;
        case "DEFENSE": _t = ["DUTY", "VALOR", "COMMONS"]; break;
        case "RECON": _t = ["ADVENTURE"]; break;
        case "TAX": _t = ["CROWN_TAX", "TAX", "ORDER"]; break;
    }
    if (_faction == "crown") array_push(_t, "CROWN");
    return _t;
}

/// Approval tier names, from estranged to devoted.
function retinue_tier_name(_approval) {
    if (_approval <= -60) return "Estranged";
    if (_approval <= -25) return "Resentful";
    if (_approval < 10) return "Wary";
    if (_approval < 30) return "Cordial";
    if (_approval < 55) return "Friendly";
    if (_approval < 80) return "Trusted";
    return "Devoted";
}
