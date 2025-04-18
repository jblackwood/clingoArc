import sys
import json
import pprint
from clingo_output_types import ClingoResult

arg : str = sys.stdin.read()
result : ClingoResult= json.loads(arg)

if result['Result'] != "SATISFIABLE":
    print(result)
    sys.exit()

witnesses = result['Call'][0]['Witnesses']

witnessSets = [set(w['Value']) for w in witnesses]

firstSet = witnessSets[0]

diff = [sorted(s.symmetric_difference(firstSet)) for s in witnessSets]
pprint.pp(diff)
