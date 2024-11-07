import datetime
from typing import List, Tuple
from dataclasses import dataclass
from enum import Enum
from stacks.clarity.types import Principal

class VoteStatus(Enum):
    PENDING = 0
    APPROVED = 1
    REJECTED = 2

@dataclass
class GameProject:
    id: str
    title: str
    description: str
    requested_funding: int
    vote_start: datetime.datetime
    vote_end: datetime.datetime

@dataclass
class Vote:
    id: str
    project_id: str
    voter: Principal
    status: VoteStatus

class DAO:
    def __init__(self):
        self.game_projects: List[GameProject] = []
        self.votes: List[Vote] = []

    def submit_project(self, project: GameProject) -> str:
        self.game_projects.append(project)
        return project.id

    def cast_vote(self, voter: Principal, project_id: str, vote_status: VoteStatus) -> str:
        vote = Vote(
            id=f"vote_{len(self.votes) + 1}",
            project_id=project_id,
            voter=voter,
            status=vote_status
        )
        self.votes.append(vote)
        return vote.id

    def get_project_votes(self, project_id: str) -> Tuple[int, int, int]:
        approved = 0
        rejected = 0
        pending = 0

        for vote in self.votes:
            if vote.project_id == project_id:
                if vote.status == VoteStatus.APPROVED:
                    approved += 1
                elif vote.status == VoteStatus.REJECTED:
                    rejected += 1
                else:
                    pending += 1

        return approved, rejected, pending

    def get_funding_allocation(self) -> List[Tuple[str, int]]:
        allocations = []
        for project in self.game_projects:
            approved, rejected, pending = self.get_project_votes(project.id)
            if approved > rejected:
                allocations.append((project.title, project.requested_funding))

        return sorted(allocations, key=lambda x: x[1], reverse=True)