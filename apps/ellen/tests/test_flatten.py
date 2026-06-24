from app.flatten import COLUMNS, flatten
from app.insidan import Skyview


def _skyview_json():
    return {
        "jumpDate": "2026-06-23",
        "location": "Bjärred",
        "jumpQueueCount": 3,
        "loads": [
            {
                "loadId": 101,
                "loadNo": 1,
                "loadStatus": 2,
                "loadStatusName": "Open",
                "planeReg": "SE-ABC",
                "planeConfig": "SE-ABC 42",
                "maxPass": 14,
                "maxWeight": 1700,
                "slotsAvailable": 7,
                "weightAvailable": 850,
                "pilots": [
                    {
                        "internalNo": 5001,
                        "member": {
                            "name": "Alice Pilot",
                            "memberWeight": {"weight": 70, "unit": "kg"},
                        },
                    }
                ],
                "jumpLeaders": [],
                "children": [
                    {
                        "childType": "Jump",
                        "jumpNo": 11,
                        "internalNo": 1001,
                        "jumptype": "FS",
                        "jumptypeName": "Formation Skydive",
                        "altitude": 4000,
                        "weight": 80,
                        "member": {"name": "Bob Jumper"},
                    },
                    {
                        "childType": "Jump",
                        "jumpNo": 12,
                        "internalNo": 1002,
                        "jumptype": "FF",
                        "jumptypeName": "Free Fly",
                        "altitude": 4000,
                        "weight": 65,
                        "member": {"name": "Carol Jumper"},
                    },
                    {
                        "childType": "Group",
                        "groupNo": 5,
                        "groupName": "Team 1",
                        "children": [
                            {
                                "childType": "Jump",
                                "jumpNo": 13,
                                "internalNo": 1003,
                                "jumptype": "RW",
                                "jumptypeName": "Relative Work",
                                "altitude": 3000,
                                "weight": 90,
                                "member": {"name": "Dave Jumper"},
                            },
                            {
                                "childType": "Jump",
                                "jumpNo": 14,
                                "internalNo": 1004,
                                "jumptype": "RW",
                                "jumptypeName": "Relative Work",
                                "altitude": 3000,
                                "weight": 75,
                                "member": {"name": "Eve Jumper"},
                            },
                        ],
                    },
                ],
            },
            {
                "loadId": 102,
                "loadNo": 2,
                "loadStatus": 3,
                "loadStatusName": "Lifted",
                "planeReg": "SE-XYZ",
                "maxPass": 10,
                "maxWeight": 1200,
                "slotsAvailable": 0,
                "weightAvailable": 100,
                "pilots": [],
                "jumpLeaders": [
                    {
                        "internalNo": 5002,
                        "member": {"name": "Frank Lead"},
                    }
                ],
                "children": [
                    {
                        "childType": "Jump",
                        "jumpNo": 20,
                        "internalNo": 2001,
                        "jumptype": "T",
                        "jumptypeName": "Tandem",
                        "altitude": 4000,
                        "weight": 200,
                        "member": {"name": "Grace Tandem"},
                    },
                ],
            },
        ],
    }


def test_flatten_row_count_and_order():
    sv = Skyview.model_validate_json(__import__("json").dumps(_skyview_json()))
    rows = flatten(sv)
    assert len(rows) == 2
    assert [r[COLUMNS.index("loadNo")] for r in rows] == [1, 2]
    assert [r[COLUMNS.index("ellenLoadNo")] for r in rows] == [1, 1]


def test_flatten_aggregates_jumpers_weight_altitudes():
    sv = Skyview.model_validate_json(__import__("json").dumps(_skyview_json()))
    rows = flatten(sv)
    load1 = rows[0]

    # COLUMNS order: ..., jumpers, totalJumpersWeight, totalPilotsWeight, totalWeight, altitudes
    assert load1[COLUMNS.index("pax")] == 4
    assert load1[COLUMNS.index("totalPaxWeight")] == 80 + 65 + 90 + 75
    assert load1[COLUMNS.index("totalPilotsWeight")] == 70
    assert load1[COLUMNS.index("totalWeight")] == 80 + 65 + 90 + 75 + 70
    assert load1[COLUMNS.index("altitudes")] == "3000, 4000"

    # No pax over 104 or 135 on load 1
    assert load1[COLUMNS.index("noPaxOver104")] == 0
    assert load1[COLUMNS.index("paxOver104")] == ""
    assert load1[COLUMNS.index("noPaxOver135")] == 0
    assert load1[COLUMNS.index("paxOver135")] == ""

    # Load 2 has one pax at 200kg
    load2 = rows[1]
    assert load2[COLUMNS.index("noPaxOver104")] == 1
    assert load2[COLUMNS.index("paxOver104")] == "Grace Tandem"
    assert load2[COLUMNS.index("noPaxOver135")] == 1
    assert load2[COLUMNS.index("paxOver135")] == "Grace Tandem"


def test_flatten_pilots_and_jump_leaders_names():
    sv = Skyview.model_validate_json(__import__("json").dumps(_skyview_json()))
    rows = flatten(sv)
    load1 = rows[0]
    load2 = rows[1]

    assert load1[COLUMNS.index("pilots")] == "Alice Pilot"
    assert load1[COLUMNS.index("jumpLeaders")] == ""
    assert load1[COLUMNS.index("planeReg")] == "SE-ABC"
    assert load1[COLUMNS.index("config")] == "SE-ABC 42"
    assert load2[COLUMNS.index("pilots")] == ""
    assert load2[COLUMNS.index("jumpLeaders")] == "Frank Lead"


def test_flatten_ellen_load_no_increments_per_plane_reg():
    sv = Skyview.model_validate(
        {
            "jumpDate": "2026-06-23",
            "location": "Bjärred",
            "loads": [
                {
                    "loadId": 300,
                    "loadNo": 3,
                    "planeReg": "SE-ABC",
                    "planeConfig": "SE-ABC",
                    "children": [],
                },
                {
                    "loadId": 100,
                    "loadNo": 1,
                    "planeReg": "SE-ABC",
                    "planeConfig": "SE-ABC",
                    "children": [],
                },
                {
                    "loadId": 200,
                    "loadNo": 2,
                    "planeReg": "SE-ABC",
                    "planeConfig": "SE-ABC",
                    "children": [],
                },
                {
                    "loadId": 500,
                    "loadNo": 1,
                    "planeReg": "SE-XYZ",
                    "planeConfig": "SE-XYZ",
                    "children": [],
                },
            ],
        }
    )
    rows = flatten(sv)
    by_plane = {r[COLUMNS.index("planeReg")]: r for r in rows}
    # SE-ABC: loadIds 100, 200, 300 -> ellenLoadNo 1, 2, 3 (by loadNo 1, 2, 3)
    abc = [r for r in rows if r[COLUMNS.index("planeReg")] == "SE-ABC"]
    abc.sort(key=lambda r: r[COLUMNS.index("loadNo")])
    assert abc[0][COLUMNS.index("ellenLoadNo")] == 1
    assert abc[1][COLUMNS.index("ellenLoadNo")] == 2
    assert abc[2][COLUMNS.index("ellenLoadNo")] == 3
    # SE-XYZ: single load -> ellenLoadNo 1
    xyz = [r for r in rows if r[COLUMNS.index("planeReg")] == "SE-XYZ"][0]
    assert xyz[COLUMNS.index("ellenLoadNo")] == 1


def test_flatten_empty_skyview():
    assert flatten(None) == []
    assert flatten(Skyview()) == []


def test_flatten_handles_missing_weights_and_altitudes():
    sv = Skyview.model_validate(
        {
            "jumpDate": "2026-06-23",
            "location": "Bjärred",
            "loads": [
                {
                    "loadId": 1,
                    "loadNo": 1,
                    "children": [
                        {"childType": "Jump", "jumptype": "FS", "jumptypeName": "FS"},
                    ],
                }
            ],
        }
    )
    rows = flatten(sv)
    assert rows[0][COLUMNS.index("pax")] == 1
    assert rows[0][COLUMNS.index("totalPaxWeight")] == 0
    assert rows[0][COLUMNS.index("totalPilotsWeight")] == 0
    assert rows[0][COLUMNS.index("totalWeight")] == 0
    assert rows[0][COLUMNS.index("altitudes")] == ""
