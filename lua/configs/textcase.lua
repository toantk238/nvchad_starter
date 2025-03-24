local map = vim.keymap.set

local textCaseWordMapping = {
  {
    "gas",
    "to_snake_case",
    "Convert current word to snake case",
  },
  {
    "gac",
    "to_camel_case",
    "Convert current word to camel case",
  },
  {
    "gap",
    "to_pascal_case",
    "Convert current word to pascal case",
  },
}

local textCaseOperatorMapping = {
  {
    "geu",
    "to_upper_case",
    "Operator to upper case",
  },
  {
    "ges",
    "to_snake_case",
    "Operator to snake case",
  },
}

for _, v in ipairs(textCaseWordMapping) do
  map("n", v[1], function()
    require("textcase").current_word(v[2])
  end, {
    desc = v[3],
  })
end

for _, v in ipairs(textCaseOperatorMapping) do
  map("n", v[1], function()
    require("textcase").operator(v[2])
  end, {
    desc = v[3],
  })
end

