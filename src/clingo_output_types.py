from typing import TypedDict

class Witness(TypedDict):
    Value: list[str]

class CallInfo(TypedDict):
    Witnesses: list[Witness]

class ModelInfo(TypedDict):
    Number: int
    More: str

class TimeInfo(TypedDict):
    Total: float
    Solve: float
    Model: float
    Unsat: float
    CPU: float

class ClingoResult(TypedDict):
    Solver: str
    Input: list[str]
    Call: list[CallInfo]
    Result: str
    Models: ModelInfo
    Calls: int
    Time: TimeInfo