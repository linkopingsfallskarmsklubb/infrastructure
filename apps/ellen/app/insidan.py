from typing import Annotated, Literal, Optional, Union

import niquests
from pydantic import BaseModel, Field

from app.config import logger


class MemberWeight(BaseModel):
    weight: Optional[int] = None
    unit: Optional[str] = None


class PilotMember(BaseModel):
    name: Optional[str] = None
    member_weight: Optional[MemberWeight] = Field(default=None, alias="memberWeight")


class Pilot(BaseModel):
    id: Optional[str] = None
    member_id: Optional[int] = Field(default=None, alias="internalNo")
    member: Optional[PilotMember] = None


class JumpLeader(BaseModel):
    id: Optional[str] = None
    member_id: Optional[int] = Field(default=None, alias="internalNo")
    member: Optional[PilotMember] = None


class LoadChildMember(BaseModel):
    name: Optional[str] = None
    member_no: Optional[str] = Field(default=None, alias="memberNo")


class LoadChildJump(BaseModel):
    child_type: Literal["Jump"] = Field(alias="childType")
    id: Optional[str] = None
    request_no: Optional[int] = Field(default=None, alias="jumpNo")
    member_id: Optional[int] = Field(default=None, alias="internalNo")
    group_no: Optional[int] = Field(default=None, alias="groupNo")
    member: Optional[LoadChildMember] = None
    time_for_request: Optional[str] = Field(default=None, alias="timeForRequest")
    jumptype: str = ""
    jumptype_name: str = Field(default="", alias="jumptypeName")
    altitude: Optional[int] = None
    student_jump_no: Optional[int] = Field(default=None, alias="studentJumpNo")
    weight: Optional[int] = None


class WishlistGroup(BaseModel):
    child_type: Literal["Group"] = Field(alias="childType")
    children: Optional[list["LoadChild"]] = None
    group_name: Optional[str] = Field(default=None, alias="groupName")
    group_no: Optional[int] = Field(default=None, alias="groupNo")
    id: Optional[str] = None
    time_for_request: Optional[str] = Field(default=None, alias="timeForRequest")


LoadChild = Annotated[
    Union[LoadChildJump, WishlistGroup], Field(discriminator="child_type")
]


class Load(BaseModel):
    load_id: int = Field(default=0, alias="loadId")
    load_no: int = Field(default=0, alias="loadNo")
    load_status: int = Field(default=0, alias="loadStatus")
    load_status_name: str = Field(default="", alias="loadStatusName")
    plane_reg: str = Field(default="", alias="planeReg")
    plane_config: str = Field(default="", alias="planeConfig")
    max_pass: int = Field(default=0, alias="maxPass")
    max_weight: int = Field(default=0, alias="maxWeight")
    slots_available: Optional[int] = Field(default=None, alias="slotsAvailable")
    weight_available: Optional[int] = Field(default=None, alias="weightAvailable")
    pilots: list[Pilot] = Field(default_factory=list)
    jump_leaders: list[JumpLeader] = Field(default_factory=list, alias="jumpLeaders")
    children: list[LoadChild] = Field(default_factory=list)


class Skyview(BaseModel):
    jump_date: str = Field(default="", alias="jumpDate")
    location: str = ""
    jump_queue_count: int = Field(default=0, alias="jumpQueueCount")
    message: Optional[str] = None
    loads: list[Load] = Field(default_factory=list)


WishlistGroup.model_rebuild()
Load.model_rebuild()
Skyview.model_rebuild()


async def get_skyview(base_url: str, token: str) -> Optional[Skyview]:
    url = f"{base_url}/skywin/view"
    logger.debug("Fetching skyview from %s", url)
    r = await niquests.aget(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
        },
        timeout=30,
    )
    if r.status_code != 200:
        logger.error("Failed to fetch skyview (%s): %s", r.status_code, r.text)
        return None

    return Skyview.model_validate_json(r.text)
