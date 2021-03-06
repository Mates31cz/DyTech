data:extend(
{
  {
    type = "recipe",
    name = "metallurgy-iron-plate",
	enabled = false,
	category = "forge",
    energy_required = 0.2,
    subgroup = "metallurgy-plates",
    ingredients =
    {
      {type="fluid", name="molten-iron", amount=0.75},
      {type="fluid", name="water", amount=1},
    },
    results = 
	{
      {type="item", name="iron-plate", amount=1}
    },
  },
  {
    type = "recipe",
    name = "metallurgy-copper-plate",
	enabled = false,
	category = "forge",
    energy_required = 0.2,
    subgroup = "metallurgy-plates",
    ingredients =
    {
      {type="fluid", name="molten-copper", amount=0.75},
      {type="fluid", name="water", amount=1},
    },
    results =
	{
      {type="item", name="copper-plate", amount=1}
    },
  },
  {
    type = "recipe",
    name = "metallurgy-steel-plate",
	enabled = false,
	category = "forge",
    energy_required = 0.4,
    subgroup = "metallurgy-plates",
    ingredients =
    {
      {type="fluid", name="molten-carbonated-iron", amount=3.75},
      {type="fluid", name="water", amount=5},
    },
    results =
	{
      {type="item", name="steel-plate", amount=1}
    },
  },
}
)