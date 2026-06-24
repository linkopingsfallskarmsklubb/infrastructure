from typing import Optional

from app.insidan import Load, LoadChildJump, Skyview, WishlistGroup

COLUMNS = [
    "jumpDate",
    "location",
    "planeReg",
    "config",
    "loadNo",
    "ellenLoadNo",
    "loadStatusName",
    "pilots",
    "jumpLeaders",
    "maxPax",
    "pax",
    "maxWeight",
    "totalWeight",
    "weightAvailable",
    "totalPaxWeight",
    "totalPilotsWeight",
    "noPaxOver104",
    "paxOver104",
    "noPaxOver135",
    "paxOver135",
    "altitudes",
]


def count_people(group: WishlistGroup) -> int:
    if not group.children:
        return 0
    return sum(_count_child(c) for c in group.children)


def _count_child(child) -> int:
    if isinstance(child, LoadChildJump):
        return 1
    if isinstance(child, WishlistGroup):
        return count_people(child)
    return 0


def _weight_child(child) -> int:
    if isinstance(child, LoadChildJump):
        return child.weight or 0
    if isinstance(child, WishlistGroup):
        return sum(_weight_child(c) for c in (child.children or []))
    return 0


def _names_over_weight(child, threshold: int) -> list[str]:
    if isinstance(child, LoadChildJump):
        if (child.weight or 0) > threshold and child.member and child.member.name:
            return [child.member.name]
        return []
    if isinstance(child, WishlistGroup):
        names: list[str] = []
        for c in child.children or []:
            names.extend(_names_over_weight(c, threshold))
        return names
    return []


def _altitudes_child(child, acc: set[int]) -> None:
    if isinstance(child, LoadChildJump):
        if child.altitude is not None:
            acc.add(child.altitude)
    elif isinstance(child, WishlistGroup):
        for c in child.children or []:
            _altitudes_child(c, acc)


def _join_names(members) -> str:
    names = [m.member.name for m in members if m.member and m.member.name]
    return ", ".join(names)


def flatten_load(load: Load, jump_date: str, location: str, ellen_load_no: int) -> list:
    pax = sum(_count_child(c) for c in load.children)
    pax_weight = sum(_weight_child(c) for c in load.children)
    over_104 = [n for c in load.children for n in _names_over_weight(c, 104)]
    over_135 = [n for c in load.children for n in _names_over_weight(c, 135)]
    pilots_weight = sum(
        p.member.member_weight.weight or 0
        for p in load.pilots
        if p.member and p.member.member_weight and p.member.member_weight.weight
    )

    altitudes: set[int] = set()
    for c in load.children:
        _altitudes_child(c, altitudes)

    return [
        jump_date,
        location,
        load.plane_reg,
        load.plane_config,
        load.load_no,
        ellen_load_no,
        load.load_status_name,
        _join_names(load.pilots),
        _join_names(load.jump_leaders),
        load.max_pass,
        pax,
        load.max_weight,
        pax_weight + pilots_weight,
        load.weight_available,
        pax_weight,
        pilots_weight,
        len(over_104),
        ", ".join(over_104),
        len(over_135),
        ", ".join(over_135),
        ", ".join(str(a) for a in sorted(altitudes)),
    ]


def flatten(skyview: Optional[Skyview]) -> list[list]:
    if not skyview:
        return []

    loads_by_plane: dict[str, list[int]] = {}
    for load in skyview.loads:
        loads_by_plane.setdefault(load.plane_reg, []).append(load.load_id)
    ellen_load_no: dict[int, int] = {}
    for plane_reg, load_ids in loads_by_plane.items():
        for i, lid in enumerate(sorted(load_ids), start=1):
            ellen_load_no[lid] = i

    sorted_loads = sorted(skyview.loads, key=lambda l: l.load_id)
    rows = [
        flatten_load(load, skyview.jump_date, skyview.location, ellen_load_no[load.load_id])
        for load in sorted_loads
    ]
    return rows
