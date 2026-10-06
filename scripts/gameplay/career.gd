class_name CourierCareer
extends RefCounted
## Deterministic progression and workshop rules, shared by gameplay and UI.

const RANKS = [
	{"name": "New Courier", "deliveries": 0, "pay": 1.0, "milestone": 0},
	{"name": "Local Partner", "deliveries": 3, "pay": 1.05, "milestone": 125},
	{"name": "Harbor Specialist", "deliveries": 8, "pay": 1.10, "milestone": 250},
	{"name": "Master Dispatcher", "deliveries": 15, "pay": 1.15, "milestone": 500}
]
const UPGRADES = {
	"efficiency": {"name": "Economy tune", "price": 500, "description": "25% less fuel consumption", "rank": 0},
	"reinforcement": {"name": "Protective bumpers", "price": 700, "description": "25% less vehicle impact damage", "rank": 1},
	"cargo_rack": {"name": "Padded cargo rack", "price": 900, "description": "35% less cargo impact damage", "rank": 1}
}

static func rank_index(completed: int) -> int:
	var result = 0
	for i in RANKS.size():
		if completed >= int(RANKS[i].deliveries):
			result = i
	return result

static func rank_name(completed: int) -> String:
	return RANKS[rank_index(completed)].name

static func next_goal(completed: int) -> String:
	var rank = rank_index(completed)
	if rank == RANKS.size() - 1:
		return "Top rank reached • keep building your business"
	return "%d more deliveries to %s" % [int(RANKS[rank + 1].deliveries) - completed, RANKS[rank + 1].name]

static func milestone_reward(before: int, after: int) -> int:
	var reward = 0
	for rank in RANKS:
		if before < int(rank.deliveries) and after >= int(rank.deliveries):
			reward += int(rank.milestone)
	return reward

static func can_purchase(id: String, progress: ProgressStore) -> bool:
	return UPGRADES.has(id) and not progress.upgrades.has(id) and rank_index(progress.completed) >= int(UPGRADES[id].rank) and progress.money >= int(UPGRADES[id].price)

static func purchase(id: String, progress: ProgressStore) -> bool:
	if not can_purchase(id, progress):
		return false
	progress.money -= int(UPGRADES[id].price)
	progress.upgrades[id] = true
	return true
