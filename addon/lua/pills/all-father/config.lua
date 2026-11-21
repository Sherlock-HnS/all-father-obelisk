--
/*
    @Author: FVJohnny  http://steamcommunity.com/id/FVJohnny/
*/
if not FVJOHNNY_PILLS then return end
FVJOHNNY_PILLS.AllFather = FVJOHNNY_PILLS.AllFather or {}

FVJOHNNY_PILLS.AllFather.CFG = FVJOHNNY_PILLS.AllFather.CFG or {}

FVJOHNNY_PILLS.AllFather.CFG.PillName = "pill_allfather" // Do not change this
FVJOHNNY_PILLS.AllFather.CFG.Name = "All Father" 
FVJOHNNY_PILLS.AllFather.CFG.Model = "models/whynotboi/pills/allfather/allfather.mdl"
FVJOHNNY_PILLS.AllFather.CFG.ModelScale = "1"
FVJOHNNY_PILLS.AllFather.CFG.EddyGar_propperties = {
    ["All-Father_invisperms"] = true
}
FVJOHNNY_PILLS.AllFather.CFG.Anims = {
    default = {
        idle="idle",
        walk="walk",
        run="run",
        ability="ability",
        exitinvis="exitinvis",
        kill="kill",
    }
}
FVJOHNNY_PILLS.AllFather.CFG.Noragdoll = true
FVJOHNNY_PILLS.AllFather.CFG.MoveSpeed = {
    walk = 70,
    run = 560,
    ducked = 100,
}
FVJOHNNY_PILLS.AllFather.CFG.Camera = {
    dist = 150,
}
FVJOHNNY_PILLS.AllFather.CFG.JumpPower = 0
FVJOHNNY_PILLS.AllFather.CFG.Health = 250000
FVJOHNNY_PILLS.AllFather.CFG.MovePoseMode = "xy"
FVJOHNNY_PILLS.AllFather.CFG.Aim = {
    xPose = "aim_yaw",
    yPose = "aim_pitch",
    nocrosshair = true
}
FVJOHNNY_PILLS.AllFather.CFG.CanAim = function(ply, ent)
    return ent.active
end

FVJOHNNY_PILLS.AllFather.CFG.StepSounds = {
    walk = {
        isLoop = false,
        distance = 50,
        sounds = {
            "pills/allfather/step1.wav",
            "pills/allfather/step2.wav",
            "pills/allfather/step3.wav",
            "pills/allfather/step4.wav",
        }
    },
    run = {
        isLoop = true,
        distance = 200,
        sounds = {
            "pills/allfather/sprintfly_loop.wav",
        }
    },
}

FVJOHNNY_PILLS.AllFather.CFG.Init = function(ply, entity)
end

FVJOHNNY_PILLS.AllFather.CFG.Think = function(ply, ent)
    if CLIENT then
        FVJOHNNY_PILLS.AllFather:MarkPlayerThink()
    end
end

FVJOHNNY_PILLS.AllFather.CFG.LeftClick = {
    anim = {
        sequence = "kill",
        speed = 0.75
    },
    failAnim = {
        sequence = "kill",
        speed = 0.75
    },
    sound = {
        name = "pills/allfather/killanim.wav",
        delay = 0.25
    },
    failSound = {
        name = "",
        delay = 0
    },
    onPress = function(ply, ent)
        local bloodTimers = {0.25, 0.5, 0.75, 1}
        local speed = 2
        return FVJOHNNY_PILLS:DoKillAttack(ply, ent, speed, bloodTimers)
    end,
    onRelease = function(ply, ent)
    end,
}

FVJOHNNY_PILLS.AllFather.CFG.RightClick = {
    anim = {
        sequence = "ability",
        speed = 1
    },
    -- sound = {
    --     "pills/allfather/distortionloop.wav",
    -- },
    soundWhileUsingRightClick = "pills/allfather/distortionloop.wav",
    soundOnMarking = "pills/allfather/lockon.wav",
    soundOnFuckedUpPlayer = "pills/allfather/ability_wavywavy.wav",
    playersTurnIntoColor = Color(255, 255, 0, 200),
    markedPlayerColor = Color(255, 0, 0, 200),
    markAimTimeRequired = 2, // How long you must be aiming at a player to mark him
    markDuration = 5, // How long a player stays marked (in seconds)
    cooldownAfterMarking = 30, // How long the cooldown is after marking a player (in seconds)
    cooldown = 0, // How long the cooldown is after using the right click (in seconds)
    onPress = function(ply, ent)
        print("Start Spectre Vision")
        return FVJOHNNY_PILLS.AllFather:StartSpectreVision(ply)
    end,
    onRelease = function(ply, ent)
        return FVJOHNNY_PILLS.AllFather:StopSpectreVision(ply)
    end,
}


// RELOAD ABILITY (Invisibility)
FVJOHNNY_PILLS.AllFather.CFG.Reload = {
    anim = {
        sequence = "exitinvis",
        speed = 1
    },
    stunDuration = 2, // How long to stun nearby players when becoming visible (in seconds)
    stunRadius = 300, // Radius to stun players when becoming visible (in units)
    stunMoveSpeedMultiplier = 0.4, // Movement speed multiplier for stunned players (0.4 = 40% speed)
    cooldownWhenBecomingVisible = 5, // Cooldown when becoming visible (in seconds)
    soundOnEnteringInvisibility = "pills/allfather/teleport_enter.wav",
    soundOnExitingInvisibility = "pills/allfather/teleport_exit.wav",
    onPress = function(ply, ent)
        return FVJOHNNY_PILLS.AllFather:ToggleInvisibility(ply)
    end,
    onRelease = function(ply, ent)
    end,
}

FVJOHNNY_PILLS.AllFather.CFG.Flashlight = {
    onPress = function(ply, ent)
    end,
    onRelease = function(ply, ent)
    end,
}

FVJOHNNY_PILLS.AllFather.CFG.Jump = {
    onPress = function(ply, ent)
    end,
    onRelease = function(ply, ent)
    end,
}

// ABILITIES GUI
FVJOHNNY_PILLS.AllFather.CFG.AbilitiesGUI_confic = {
    
}

FVJOHNNY_PILLS.AllFather.CFG.AbilitiesGUI = {
    {
        button = "RightClick",
        material = "all-father/ability_right_click.png",
        name = "Spectre Vision",
        keybind = "RMB",
        uioffsetx = -0.1,
        uioffsety = 0
    },
    {
        button = "Reload",
        material = "all-father/ability_r.png",
        name = "Invisibility",
        keybind = "R",
        uioffsetx = -0.2,
        uioffsety = 0
    }
}

// PASSIVE - PEEKING IMAGE
FVJOHNNY_PILLS.AllFather.CFG.Peek = {
    interval = 35, // How often (in seconds) to attempt showing the peeking image to nearby players
    chance = 80, // Chance to show the peeking image to nearby players (0-100)
    showToMyself = false, // Whether to show the peeking image to myself (for testing purposes)
    distance = 0, // Distance required to show the peeking image to other players
    lastsFor = 3, // How long the peek will last for in seconds
    image = "all-father/allfather.png",   // Path to the image (inside materials folder)
    size = {
        w = 500, // Width of the image
        h = 500, // Height of the image
    },
    texts = { // Texts to show (will choose a random one every time)
        "I am watching you.",
        "Your time is running out.",
        "You cannot hide from me.",
        "I will find you.",
        "In my world, you're just a pawn.",
        "Don't bore me now.",
        "I will make you suffer.",
        "My patience is running thin.",
        "I will make you cry for your sins.",
        "You can't run.",
        "I will make you beg for your life.",
    },
    fuckedVisionTexts = {
        "I'm gonna get you.",
        "You can't hide.",
        "I'm in your head.",
        "You'll be a perfect fit in my eden.",
        "Don't get cold feet now.",
        "Let's see how long you can last.",
    },
    textColor = Color(255, 0, 0), // Color of the text
    textFont = "ChatFont", // Font of the text
}



FVJOHNNY_PILLS:RegisterPill(FVJOHNNY_PILLS.AllFather.CFG)
