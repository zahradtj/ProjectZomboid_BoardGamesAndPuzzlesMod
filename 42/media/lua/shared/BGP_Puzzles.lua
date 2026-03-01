BGP_Puzzles = BGP_Puzzles or {}

local MOD = "BoardGamesAndPuzzlesMod"

BGP_Puzzles.Size = {
  Mini   = { key="mini",   pieces=20,   baseMinutes=10,  xp=1  , icon="Puzzle_20"   },
  Small  = { key="small",  pieces=500,  baseMinutes=45,  xp=6  , icon="Puzzle_500"  },
  Medium = { key="medium", pieces=1000, baseMinutes=90,  xp=10 , icon="Puzzle_1000" },
  Large  = { key="large",  pieces=2000, baseMinutes=180, xp=16 , icon="Puzzle_2000" },
}

-- Map sizeKey -> fullType prefix used in scripts
BGP_Puzzles.SizePrefix = {
  mini   = MOD .. ".Puzzle20_",
  small  = MOD .. ".Puzzle500_",
  medium = MOD .. ".Puzzle1000_",
  large  = MOD .. ".Puzzle2000_",
}

BGP_Puzzles.Design = {
  -- 20-piece (Mini)
  Alpaca_20   = { key="Alpaca_20",   size="mini",   human="Alpaca",        fullType=MOD..".Puzzle20_Alpaca",     worldTex="20_puzzle_box_alpaca"     },
  Blocks_20   = { key="Blocks_20",   size="mini",   human="Blocks",        fullType=MOD..".Puzzle20_Blocks",     worldTex="20_puzzle_box_blocks"     },
  Fruits_20   = { key="Fruits_20",   size="mini",   human="Fruits",        fullType=MOD..".Puzzle20_Fruits",     worldTex="20_puzzle_box_fruits"     },
  Puppy_20    = { key="Puppy_20",    size="mini",   human="Puppy",         fullType=MOD..".Puzzle20_Puppy",      worldTex="20_puzzle_box_puppy"      },
  RedPanda_20 = { key="RedPanda_20", size="mini",   human="Red Panda",     fullType=MOD..".Puzzle20_RedPanda",   worldTex="20_puzzle_box_redpanda"   },
  Smiles_20   = { key="Smiles_20",   size="mini",   human="Smiley Faces",  fullType=MOD..".Puzzle20_Smiles",     worldTex="20_puzzle_box_smiles"     },
  Space_20    = { key="Space_20",    size="mini",   human="Space",         fullType=MOD..".Puzzle20_Space",      worldTex="20_puzzle_box_space"      },

  -- 500-piece (Small)
  Boat_500       = { key="Boat_500",       size="small",  human="Boat",        fullType=MOD..".Puzzle500_Boat",       worldTex="500_puzzle_box_boat"       },
  Flowers_500    = { key="Flowers_500",    size="small",  human="Flowers",     fullType=MOD..".Puzzle500_Flowers",    worldTex="500_puzzle_box_flowers"    },
  Horse_500      = { key="Horse_500",      size="small",  human="Horse",       fullType=MOD..".Puzzle500_Horse",      worldTex="500_puzzle_box_horse"      },
  Kingfisher_500 = { key="Kingfisher_500", size="small",  human="Kingfisher",  fullType=MOD..".Puzzle500_Kingfisher", worldTex="500_puzzle_box_kingfisher" },
  Landscape_500  = { key="Landscape_500",  size="small",  human="Landscape",   fullType=MOD..".Puzzle500_Landscape",  worldTex="500_puzzle_box_landscape"  },
  Panda_500      = { key="Panda_500",      size="small",  human="Panda",       fullType=MOD..".Puzzle500_Panda",      worldTex="500_puzzle_box_panda"      },
  Tree_500       = { key="Tree_500",       size="small",  human="Tree",        fullType=MOD..".Puzzle500_Tree",       worldTex="500_puzzle_box_tree"       },

  -- 1000-piece (Medium)
  Blossoms_1000  = { key="Blossoms_1000",  size="medium", human="Blossoms",   fullType=MOD..".Puzzle1000_Blossoms",  worldTex="1000_puzzle_box_blossoms"  },
  Butterfly_1000 = { key="Butterfly_1000", size="medium", human="Butterfly",  fullType=MOD..".Puzzle1000_Butterfly", worldTex="1000_puzzle_box_butterfly" },
  Marina_1000    = { key="Marina_1000",    size="medium", human="Marina",     fullType=MOD..".Puzzle1000_Marina",    worldTex="1000_puzzle_box_marina"    },
  Mountains_1000 = { key="Mountains_1000", size="medium", human="Mountains",  fullType=MOD..".Puzzle1000_Mountains", worldTex="1000_puzzle_box_mountains" },
  Space_1000     = { key="Space_1000",     size="medium", human="Space",      fullType=MOD..".Puzzle1000_Space",     worldTex="1000_puzzle_box_space"     },
  Sunflower_1000 = { key="Sunflower_1000", size="medium", human="Sunflower",  fullType=MOD..".Puzzle1000_Sunflower", worldTex="1000_puzzle_box_sunflower" },
  Windmill_1000  = { key="Windmill_1000",  size="medium", human="Windmill",   fullType=MOD..".Puzzle1000_Windmill",  worldTex="1000_puzzle_box_windmill"  },

  -- 2000-piece (Large)
  Aurora_2000      = { key="Aurora_2000",      size="large",  human="Aurora",        fullType=MOD..".Puzzle2000_Aurora",      worldTex="2000_puzzle_box_aurora"      },
  Elephant_2000    = { key="Elephant_2000",    size="large",  human="Elephant",      fullType=MOD..".Puzzle2000_Elephant",    worldTex="2000_puzzle_box_elephant"    },
  Lavender_2000    = { key="Lavender_2000",    size="large",  human="Lavender",      fullType=MOD..".Puzzle2000_Lavender",    worldTex="2000_puzzle_box_lavender"    },
  Mountains_2000   = { key="Mountains_2000",   size="large",  human="Mountains",     fullType=MOD..".Puzzle2000_Mountains",   worldTex="2000_puzzle_box_mountains"   },
  Swirls_2000      = { key="Swirls_2000",      size="large",  human="Swirls",        fullType=MOD..".Puzzle2000_Swirls",      worldTex="2000_puzzle_box_swirls"      },
  Waterfall_2000   = { key="Waterfall_2000",   size="large",  human="Waterfall",     fullType=MOD..".Puzzle2000_Waterfall",   worldTex="2000_puzzle_box_waterfall"   },
  WinterTrees_2000 = { key="WinterTrees_2000", size="large",  human="Winter Trees",  fullType=MOD..".Puzzle2000_WinterTrees", worldTex="2000_puzzle_box_wintertrees" },
}

function BGP_Puzzles.sizeKeyFromFullType(fullType)
  if type(fullType) ~= "string" then return nil end
  if fullType:find(MOD..".Puzzle20_", 1, true) then return "mini" end
  if fullType:find(MOD..".Puzzle500_", 1, true) then return "small" end
  if fullType:find(MOD..".Puzzle1000_", 1, true) then return "medium" end
  if fullType:find(MOD..".Puzzle2000_", 1, true) then return "large" end
  return nil
end

function BGP_Puzzles.isPuzzle(fullType)
  return BGP_Puzzles.sizeKeyFromFullType(fullType) ~= nil
end

-- Build lookups once (safe if file reloads)
BGP_Puzzles.DesignByFullType = BGP_Puzzles.DesignByFullType or {}
BGP_Puzzles.DesignsBySize = BGP_Puzzles.DesignsBySize or { mini={}, small={}, medium={}, large={} }

-- Clear then rebuild (prevents duplicates if reloaded)
for k in pairs(BGP_Puzzles.DesignByFullType) do BGP_Puzzles.DesignByFullType[k] = nil end
for _, t in pairs(BGP_Puzzles.DesignsBySize) do
  for i = #t, 1, -1 do table.remove(t, i) end
end

for _, d in pairs(BGP_Puzzles.Design) do
  if d.fullType then
    BGP_Puzzles.DesignByFullType[d.fullType] = d
  end
  if d.size and BGP_Puzzles.DesignsBySize[d.size] then
    table.insert(BGP_Puzzles.DesignsBySize[d.size], d)
  end
end

function BGP_Puzzles.getSizeDefByFullType(fullType)
  local size = BGP_Puzzles.sizeKeyFromFullType(fullType)
  if size == 'mini' then
    return BGP_Puzzles.Size.Mini
  elseif size == 'small' then
    return BGP_Puzzles.Size.Small
  elseif size == 'medium' then
    return BGP_Puzzles.Size.Medium
  elseif size == 'large' then
    return BGP_Puzzles.Size.Large
  end
  return nil
end

-- Return the design def for an item's fullType (or nil)
function BGP_Puzzles.getDesignDefByFullType(fullType)
  return BGP_Puzzles.DesignByFullType[fullType]
end

-- Convenience: return the human name for an item's fullType
function BGP_Puzzles.getHumanNameByFullType(fullType)
  local d = BGP_Puzzles.getDesignDefByFullType(fullType)
  return d and d.human or nil
end

-- Convenience: list all design defs for a size ("mini"/"small"/"medium"/"large")
function BGP_Puzzles.getDesignsForSize(sizeKey)
  return BGP_Puzzles.DesignsBySize[sizeKey] or {}
end

return BGP_Puzzles