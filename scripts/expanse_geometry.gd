extends RefCounted
## Traced in source-image coordinates (1585x992), scaled once to world space.
## Body footprints, banks and cliff tops; the diagonal wooden bridge stays open.
const SOURCE_SIZE := Vector2(1585, 992)
const WORLD_SIZE := Vector2(2304, 1440)
const SHAPES := [
	# Old-growth trunk/root mass, away from the western trail.
	[[650,0],[970,0],[1005,165],[968,290],[990,346],[900,380],[760,360],[695,293],[670,170]],
	# Western grove, thorn fence and rocks beside the upper path.
	[[0,230],[135,220],[245,260],[330,310],[402,355],[425,408],[350,438],[230,422],[125,360],[0,325]],
	# Full shrine plinth and front steps, rather than just the rear masonry.
	[[440,363],[525,350],[581,380],[630,425],[662,490],[632,531],[574,550],[500,526],[440,482],[414,425]],
	# Hunter camp fixtures; clear approach south of the camp remains open.
	[[960,168],[1110,168],[1170,235],[1147,282],[1065,296],[982,267]],
	# Upstream water to the north edge of the bridge deck.
	[[1228,322],[1282,350],[1228,394],[1170,419],[1152,456],[1122,492],[1091,552],[1047,542],[996,524],[1011,477],[1074,427],[1113,389],[1165,363]],
	# Downstream starts at the SOUTH edge of the bridge, leaving only its deck.
	[[1015,588],[1080,609],[1024,660],[965,701],[919,730],[978,763],[1052,800],[1015,869],[934,856],[877,812],[810,779],[795,730],[855,679],[923,635],[975,604]],
	# Forest along the lower-left route and fallen-root arch.
	[[0,662],[176,670],[274,724],[365,808],[495,920],[525,992],[0,992]],
	# Lower-central forest / cliff rim beside the western bank.
	[[517,844],[654,790],[785,813],[853,866],[960,924],[980,992],[510,992]],
	# Cliff-top contour: overlook remains land, ravine and waterfall do not.
	[[1450,0],[1585,0],[1585,992],[980,992],[980,815],[1015,760],[1100,735],[1170,680],[1295,660],[1330,620],[1410,575],[1460,500],[1500,460],[1540,412],[1525,365],[1435,340],[1335,348],[1310,325],[1340,255],[1400,170],[1450,80]],
	# Eastern high rocks keep the overlook approach on the painted trail.
	[[1030,0],[1305,0],[1370,75],[1325,114],[1223,157],[1195,211],[1170,201],[1140,153],[1070,120]]
]
static func polygons() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for points in SHAPES:
		var polygon := PackedVector2Array()
		for point in points:
			polygon.append(Vector2(point[0], point[1]) * WORLD_SIZE / SOURCE_SIZE)
		result.append(polygon)
	return result
