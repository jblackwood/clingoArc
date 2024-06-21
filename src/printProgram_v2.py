import sys
import json
from clingo_output_types import ClingoResult
import pprint
from typing import TypedDict

class Atom(TypedDict):
    propertyName: str
    literals: list[str]

class Program(TypedDict):
    programStr: list[str]
    values: list[dict]

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

def functionCallEntities(s: list[Atom]) -> list[dict]:
    calls = [a['literals'] 
            for a in s if a['propertyName'] == 'functionCall']
    entities = []
    for call in calls:
        entities.append({
            'lineNum': int(call[0]),
            'returnVar': call[1],
            'functionId': call[2],
            'args': call[3:]
        })
    return entities


idKeys = ['instanceId', 'variableId', 'valueId']
def entitiesForAtoms(s: list[Atom]) -> list[dict]:
    ids = [a['literals'][0] 
           for a in s if a['propertyName'] in idKeys]
    entities = functionCallEntities(s)
    for id in ids:
        e = {}
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
                and not(a['propertyName'] in idKeys)
            ):
                e[a['propertyName']] = True
            
            if (a['propertyName'] in idKeys
                 and a['literals'][0] == id
            ):
                e[a['propertyName']] = id
            
            if (
                a['propertyName'] in ['cellList', 'objList']
                and a['literals'][0] == id
            ):
                propName = a['propertyName']
                index = int(a['literals'][1])
                propValue = a['literals'][2]
                if not(propName in e):
                    e[propName] = []
                e[propName].append({'index': index, 'val': propValue})

        if 'cellList' in e:
            sortedList = sorted(e['cellList'], key=lambda c: c['index'])
            for idx, c in enumerate(sortedList):
                assert c['index'] == idx
            e['cellList'] = [c['val'] for c in sortedList]

        if 'objList' in e:
            sortedList = sorted(e['objList'], key=lambda c: c['index'])
            for idx, c in enumerate(sortedList):
                assert c['index'] == idx
            e['objList'] = [c['val'] for c in sortedList]
        entities.append(e)
    return entities


def programFromAnswerSetEntities(s : list[dict]) -> list[str]:
    functionCalls = [e for e in s if e.get('functionId')]
    functionCalls.sort(key=lambda f: f['lineNum'])
   
    lineCount = 1
    for f in functionCalls:
        assert f['lineNum'] == lineCount
        lineCount += 1
    
    lines = []
    variables = [e for e in s if e.get('variableId')]
    for f in functionCalls:
        returnVarId = f['returnVar']
        returnVar = [v for v in variables if v['variableId'] == returnVarId][0] 
        argStr = ", ".join(f['args'])
        lineStr = f"{returnVarId} : {returnVar['type']} = {f['functionId']}({argStr})"
        lines.append(lineStr)
    return lines

def cellValue(e: dict) -> dict:
    e = e.copy()
    if not (e.get('isPopulated')):
        return None
    if 'cellList' in e: del e['cellList']
    if 'objList' in e : del e['objList']
    return e

def objectValue(e: dict, s: list[dict]) -> dict:
    e = e.copy()
    if not (e.get('isPopulated')):
        return None
    if 'objList' in e: del e['objList']
    e['cellEntities'] = []
    for cellId in e['cellList']:
        cell = [e for e in s if e.get('valueId') == cellId][0]
        e['cellEntities'].append(cellValue(cell))
    del e['cellList']
    return e

def listObjectValue(e: dict, s: list[dict]) -> dict:
    if 'cellList' in e: del e['cellList']
    e['objEntities'] = []
    for objId in e['objList']:
        obj = [e for e in s if  e.get('valueId')  == objId][0]        
        e['objEntities'].append(objectValue(obj, s))
    del e['objList']
    return e


def varValuesForAnswerSet(s : list[dict]) -> list[dict]:
    varValues = [e for e in s if e.get('assignedToVar') and e.get('type')]
    nestedValues = []
    for vi in varValues:
        if vi['type'] == 'cell':
            nestedValues.append(cellValue(vi))

        if vi['type'] == 'object':
            nestedValues.append(objectValue(vi, s))

        if vi['type'] == 'listObjects':
            nestedValues.append(listObjectValue(vi, s))
    nestedValues = [e for e in nestedValues if e is not None]
    return sorted(nestedValues, key=lambda e: e['partOfInstance'] + str(e['assignedToVar']))


 

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
    # p[f'values'] = varValuesForAnswerSet(s)
    programs.append(p)


print(json.dumps(programs, indent=4))