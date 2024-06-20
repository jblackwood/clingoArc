import sys
import json
from clingo_output_types import ClingoResult
import pprint

arg : str = sys.stdin.read()
result : ClingoResult= json.loads(arg)

if result['Result'] != "SATISFIABLE":
    print(result)
    sys.exit()

witnesses = result['Call'][0]['Witnesses']

answerSets = [set(w['Value']) for w in witnesses]


def extractLiterals(atom: str) -> list[str]:
    literalStr : str = atom[atom.index('(') +1 : atom.index(')')]
    literals = [s.strip() for s in literalStr.split(',')]
    return literals

def extractVar(a: str) -> dict :
    literals = extractLiterals(a)
    e = {
        'id': literals[0],
        'type': literals[1]
    }
    e['lineNum'] = int(e['id'][3:])
    return e

def extractFunctionCall(a: str) -> dict :
    literals = extractLiterals(a)
    e = {
        'id': literals[0],
        'functionName': literals[1]
    }
    e['lineNum'] = int(e['id'][4:])
    return e

def extractArgVal(a: str) -> dict :
    literals = extractLiterals(a)
    e = {
        'id': literals[0],
        'value': literals[1]
    }
    first_underscore = e['id'].index('_')
    e['lineNum'] = int(e['id'][4:first_underscore])
    gCharIndex = e['id'].index('g')
    e['pos'] = int(e['id'][gCharIndex+1:])
    return e


def programForAnswerSet(s : set[str]) -> str:
    varTypes = [extractVar(a) 
                for a in s 
                if a.startswith('varType')
                ]
    functionCalls = [extractFunctionCall(a) 
                     for a in s 
                     if a.startswith('functionId')
                     ]
    args = [extractArgVal(a) 
            for a in s 
            if a.startswith('argVal')]
    
    numLines = max([v['lineNum'] for v in varTypes])

    lines = []
    for l in range(1,numLines+1):
        v = [v for v in varTypes if v['lineNum']==l]
        assert len(v) == 1
        v = v[0]

        f = [f for f in functionCalls if f['lineNum']==l]
        assert len(f) == 1
        f = f[0]

        lineArgs = [a for a in args if a['lineNum']==l]
        lineArgsSorted = []
        for i in range(0, len(lineArgs)):
            a = [a for a in lineArgs if a['pos'] == i]
            assert len(a)==1
            lineArgsSorted.append(a[0]['value'])
        argStr = ', '.join(lineArgsSorted)
        lineStr = f"{v['id']} = {f['functionName']}({argStr})"
        lines.append(lineStr)
    return '\n'.join(lines)
 
programs = [programForAnswerSet(s) for s in answerSets]
for i in range(0, len(programs)):
    print(f'Answer set {i+1} program:')
    print(programs[i])
    print()
