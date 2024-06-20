import sys
import json
from typing import TypedDict
import pprint

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


arg : str = sys.stdin.read()
result : ClingoResult= json.loads(arg)

if result['Result'] != "SATISFIABLE":
    print(result)
    sys.exit()

witnesses = result['Call'][0]['Witnesses']

witnessSets = [set(w['Value']) for w in witnesses]

firstSet = witnessSets[0]

diff = [sorted(s.difference(firstSet)) for s in witnessSets]
pprint.pp(diff)
