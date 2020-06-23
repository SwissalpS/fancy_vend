
globals = {
	"fancyvend",
	"minetest",
	"mail"
}

read_globals = {
	-- Stdlib
	string = {fields = {"split"}},
	table = {fields = {"copy", "getn"}},

	-- Minetest
	"vector", "ItemStack",
	"dump", "VoxelArea",

	-- deps
	"pipeworks", "digilines", "awards",
	"email", "tell", "default", "hopper"
}
