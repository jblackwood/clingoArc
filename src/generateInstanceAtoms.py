import os
import json
from arc_types import Task, Entity
import pprint

taskFilepath : str = os.path.abspath('myTasks/moveBlueSquare.json')
outputFilepath = os.path.abspath('src/moveBlueSquaresv2_inst.lp')

with open(taskFilepath, 'r') as f:
    taskDataStr : str = f.read()

task : Task = json.loads(taskDataStr)

entities : list[Entity] = []

for idx, ioPair in enumerate(task['train']):
    instanceID = f'train{idx}'
    inputGridId : str = f'grid_train{idx}_input'
    inputGrid = {
        'id': inputGridId,
        'isInputGrid': True,
        'type': 'grid',
        'child': [],
        'instance': instanceID
    }
    entities.append(inputGrid)
    outputGridId : str = f'grid_train{idx}_output'
    outputGrid = {
        'id': outputGridId,
        'isOutputGrid': True,
        'type': 'grid',
        'child': [],
        'instance': instanceID
    }
    entities.append(outputGrid)
    for gridKey in ['input', 'output']:
        gridEntity = inputGrid if gridKey=='input' else outputGrid
        for yCoord, row in enumerate(ioPair[gridKey]):
            for xCoord, color in enumerate(row):
                cellId = f'cell_train{idx}_{gridKey}_y{yCoord}_x{xCoord}'
                entities.append({
                    'id': cellId,
                    'type': 'cell',
                    'y': yCoord,
                    'x': xCoord,
                    'color': color
                })
                gridEntity['child'].append(cellId)


# program parameters
programLength = 2
maxNumArgs = 2

# var0 is the inputGrid
var0Id = 'var0'
entities.append({
    'id': var0Id,
    'type': 'grid',
    'lineNum': 0,
    'isVariable': True
})

for lineNum in range(1, programLength+1):
    entities.append({
        'id': f'call{lineNum}',
        'type': 'functionCall',
        'lineNum': lineNum
    })

    entities.append({
        'id': f'var{lineNum}',
        'isVariable': True,
        'lineNum': lineNum
    })
    for argPos in range(0,maxNumArgs):
        entities.append({
            'id': f'line{lineNum}_arg{argPos}',
            'isArgument': True,
            'lineNum': lineNum,
            'argPos': argPos
        })

allVariables : list[Entity] = [e for e in entities if e.get('isVariable')]


# variable instances
for idx, ioPair in enumerate(task['train']):
    for var in allVariables:
        e = {
            'id': f"{var['id']}_train{idx}",
            'isVarInstance': True,
            'instance': f'train{idx}',
            'varId': var['id'],
            'child': []
        }
        entities.append(e)


# Todo - in future consider having constant for NumObjects
# and only allow children 0..NumObjects to have sub-children
GRID_SIZE = 9

# variable instance children
allVarInstances : list[Entity] = [e for e in entities if e.get('isVarInstance')]
for i in allVarInstances:
    for c1 in range(0, GRID_SIZE):
        l1_childId = f"{i['id']}_child{c1}"
        l1_child = {
            'id': l1_childId,
            'child': []
        }
        entities.append(l1_child)
        i['child'].append(l1_childId)
        for c2 in range(0, GRID_SIZE):
            l2_childId = f"{l1_childId}_child{c2}"
            l2_child = {
                'id': l2_childId,
            }
            entities.append(l2_child)
            l1_child['child'].append(l2_childId)
        



def atomsOfEntity(e: Entity) -> list[str]:
    atoms : list[str] = []
    id = e['id']
    for key, value in e.items():
        if key == 'id':
            atoms.append(f'id({id}).')
        elif key == 'child':
            for idx, c in enumerate(value):
                atoms.append(f'child({id}, {idx}, {c}).')
        elif type(value) == bool and value == True:
            atoms.append(f'{key}({id}).')
        else:
            atoms.append(f'{key}({id}, {value}).')
    
    # add empty string to create newline between entities
    atoms.append('') 
    return atoms

allAtoms : list[str] = [a for e in entities for a in atomsOfEntity(e)]

with open(outputFilepath, 'w') as f:
    f.write('\n'.join(allAtoms))
