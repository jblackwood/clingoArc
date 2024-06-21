import sys
import json
from clingo_output_types import ClingoResult
import pprint
from typing import TypedDict

class Atom(TypedDict):
    propertyName: str
    literals: list[str]

class Program(TypedDict):
    programStr: str

def atomToDict(aStr: str) -> Atom:
    if not('(' in aStr):
        return {'propertyName': aStr}
    
    rightParenIdx = aStr.index('(')
    propertyName = aStr[0:rightParenIdx]
    literalStr : str = aStr[rightParenIdx +1 : aStr.index(')')]
    literals = [s.strip() for s in literalStr.split(',')]
    return {
        'propertyName': propertyName,
        'literals': literals
    }

def childrenOfEntity(id: str, s: list[Atom]) -> list[str]:
    childrenAtoms = []
    for a in s:
        if (a['propertyName'] == 'child'
            and a['literals'][0] == id
            ):
            childrenAtoms.append(a)
    childrenAtoms.sort(key=lambda a: a['literals'][1])
    for idx, a in enumerate(childrenAtoms):
        assert idx == int(a['literals'][1])
    return [a['literals'][2] for a in childrenAtoms]


def entitiesForAtoms(s: list[Atom]) -> list[dict]:
    ids = [a['literals'][0] 
           for a in s if a['propertyName']=='id']
    entities = []
    for id in ids:
        e = {'id': id}
        children = childrenOfEntity(id, s)
        if(len(children) > 0):
            e['child'] = children
        for a in s:
            if ('literals' in a
                and len(a['literals']) == 2
                and a['literals'][0] == id
            ):
                propName = a['propertyName']
                propValue = a['literals'][1]
                if propValue.isdigit():
                    propValue = int(propValue)
                if propName not in e:
                    e[propName] = propValue
                elif type(e[propName]) == list: 
                    e[propName].append(propValue)
                else:
                    e[propName] = [e[propName]]
                    e[propName].append(propValue)

            if ('literals' in a
                and len(a['literals']) == 1
                and a['literals'][0] == id
                and a['propertyName'] != 'id'
            ):
                e[a['propertyName']] = True
            
        entities.append(e)
    return entities


def programFromAnswerSetEntities(s : list[dict]) -> str:
    variables = [e for e in s if e.get('isVariable')]
    functionCalls = [e for e in s if e.get('type') == 'functionCall']
    args = [e for e in s if e.get('isArgument')]
    numLines = max([f['lineNum'] 
                for f in functionCalls if f.get('functionId')
                ])

    lines = []
    for l in range(1,numLines+1):
        v = [v for v in variables if v['lineNum']==l]
        assert len(v) == 1
        v = v[0]

        f = [f for f in functionCalls if f['lineNum']==l]
        assert len(f) == 1
        f = f[0]

        lineArgs = [a for a in args if a['lineNum']==l and 'argVal' in a]
        lineArgsSorted = []
        for i in range(0, len(lineArgs)):
            a = [a for a in lineArgs if a['argPos'] == i]
            assert len(a)==1
            a = a[0]
            lineArgsSorted.append(a['argVal'])
        argStr = ', '.join(lineArgsSorted)
        lineStr = f"{v['id']} : {v['type']} = {f['functionId']}({argStr})"
        lines.append(lineStr)
    return '\n'.join(lines)

def varValuesForAnswerSet(s : list[dict]) -> list[dict]:
    varInstances = [e.copy() for e in s if e.get('isVarInstance')]
    for vi in varInstances:
        vi['children'] = []
        for c1Id in vi['child']:
            c1 = [e.copy() for e in s if e['id'] == c1Id][0]
            if len(c1) <= 2:
                continue
            c1['children'] = []
            for c2Id in c1['child']:
                c2 = [e for e in s if e['id'] == c2Id][0]
                if len(c2) <= 1:
                    continue
                c1['children'].append(c2)
            del c1['child']
            vi['children'].append(c1)
        del vi['child']
        


    return sorted(varInstances, key=lambda e: e['instance'] + str(e['lineNum']))


 

arg : str = sys.stdin.read()
result : ClingoResult= json.loads(arg)

if result['Result'] != "SATISFIABLE":
    print(result)
    sys.exit()

witnesses = result['Call'][0]['Witnesses']

answerSets : list[list[dict]] = []

for w in witnesses:
    atoms = [atomToDict(a) for a in w['Value']]
    entities : list[dict] = entitiesForAtoms(atoms)
    answerSets.append(entities)

programs : list[Program] = [] 
for s in answerSets:
    p = {'programStr': programFromAnswerSetEntities(s)}
    p['values'] = varValuesForAnswerSet(s)
    programs.append(p)

for i in range(0, len(programs)):
    print(f'Answer set {i+1} program:')
    print(programs[i]['programStr'])
    print('')

print('')

for i in range(0, len(programs)):
    print(f'Answer set {i+1} var values:')
    pprint.pp(programs[i]['values'])
    print('')
