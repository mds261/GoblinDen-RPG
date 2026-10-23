extends RefCounted
## Shared stack/transfer model. Mutations are atomic when a destination is full.
var slots: Array = []
var capacity: int
var definitions: Dictionary

func _init(limit: int = 24, items: Dictionary = {}) -> void:
	capacity = limit
	definitions = items

func add(id: String, count: int = 1) -> bool:
	if count <= 0 or not definitions.has(id):
		return false
	var trial: Array = slots.duplicate(true)
	var remaining := count
	var stack_max: int = int(definitions[id].get("stack", 1))
	for entry in trial:
		if entry.id == id:
			var moved := mini(remaining, stack_max - int(entry.count))
			entry.count += moved
			remaining -= moved
	while remaining > 0 and trial.size() < capacity:
		var moved := mini(remaining, stack_max)
		trial.append({"id": id, "count": moved})
		remaining -= moved
	if remaining > 0:
		return false
	slots = trial
	return true

func transfer(index: int, target: RefCounted, count: int = -1) -> bool:
	if index < 0 or index >= slots.size() or target == self:
		return false
	var entry: Dictionary = slots[index]
	var amount := int(entry.count) if count < 0 else mini(count, int(entry.count))
	if not target.add(str(entry.id), amount):
		return false
	entry.count -= amount
	if entry.count == 0:
		slots.remove_at(index)
	return true

func count_item(id: String) -> int:
	var total := 0
	for entry in slots:
		if entry.id == id:
			total += int(entry.count)
	return total

func remove(id: String, count: int) -> bool:
	if count < 0 or count_item(id) < count:
		return false
	for i in range(slots.size() - 1, -1, -1):
		if slots[i].id == id:
			var amount := mini(count, int(slots[i].count))
			slots[i].count -= amount
			count -= amount
			if slots[i].count == 0:
				slots.remove_at(i)
	return true

func restore(records: Array) -> void:
	slots.clear()
	for record in records:
		if record is Dictionary and definitions.has(str(record.get("id", ""))):
			add(str(record.id), maxi(1, int(record.get("count", 1))))
