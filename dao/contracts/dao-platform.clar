import datetime
from typing import List, Tuple, Dict
from dataclasses import dataclass
from enum import Enum
from stacks.clarity.types import Principal
from stacks.clarity.contract import Contract
from stacks.clarity.types import (
    ResponseType, OptionalType, TupleType, StringType, IntegerType
)
from stacks.clarity.functions import 
    (
        create_trait, create_map, create_list, create_option,
        contract_call
    )

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

class DAOContract(Contract):
    """
    Clarity smart contract for the DAO platform.
    """
    def __init__(self):
        self.game_projects = create_map("game_projects")
        self.votes = create_list("votes")
        self.treasury = create_map("treasury")

    def submit_project(self, project: GameProject) -> ResponseType:
        """
        Submit a new game development project proposal to the DAO.
        """
        project_id = f"project_{len(self.game_projects) + 1}"
        self.game_projects[project_id] = (
            project.title,
            project.description,
            project.requested_funding,
            project.vote_start,
            project.vote_end
        )
        return ResponseType.ok(project_id)

    def cast_vote(self, voter: Principal, project_id: str, vote_status: VoteStatus) -> ResponseType:
        """
        Cast a vote on a game development project proposal.
        """
        vote_id = f"vote_{len(self.votes) + 1}"
        self.votes.append((vote_id, project_id, voter, vote_status))
        return ResponseType.ok(vote_id)

    def get_project_votes(self, project_id: str) -> ResponseType:
        """
        Get the vote counts for a specific game development project.
        """
        approved = 0
        rejected = 0
        pending = 0

        for vote in self.votes:
            if vote[1] == project_id:
                if vote[3] == VoteStatus.APPROVED:
                    approved += 1
                elif vote[3] == VoteStatus.REJECTED:
                    rejected += 1
                else:
                    pending += 1

        return ResponseType.ok((approved, rejected, pending))

    def get_funding_allocation(self) -> ResponseType:
        """
        Determine the final funding allocation based on approved projects.
        """
        allocations = []
        for project_id, project_data in self.game_projects.items():
            approved, rejected, pending = self.get_project_votes(project_id)
            if approved > rejected:
                allocations.append((project_data[0], project_data[2]))

        allocations = sorted(allocations, key=lambda x: x[1], reverse=True)
        return ResponseType.ok(allocations)

    def deposit_to_treasury(self, amount: int) -> ResponseType:
        """
        Deposit funds to the DAO treasury.
        """
        caller = Contract.caller()
        self.treasury[caller] = self.treasury.get(caller, 0) + amount
        return ResponseType.ok(())

    def withdraw_from_treasury(self, amount: int) -> ResponseType:
        """
        Withdraw funds from the DAO treasury.
        """
        caller = Contract.caller()
        if self.treasury.get(caller, 0) < amount:
            return ResponseType.err("Insufficient funds in treasury")
        self.treasury[caller] = self.treasury.get(caller, 0) - amount
        return ResponseType.ok(())