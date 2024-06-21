import os
import json
from arc_types import Task
import sys
import pprint

taskName: str = sys.argv[1]
taskFilepath : str = os.path.abspath(f'myTasks/json/{taskName}.json')
outputFilepath = os.path.abspath(f'myTasks/lp/{taskName}.lp')

with open(taskFilepath, 'r') as f:
    taskDataStr : str = f.read()

task : Task = json.loads(taskDataStr)

entities : list[dict] = []

maxProgramLength = 3
maxNumCellsInObject = 9
maxNumObjectInList = 9

# There is a variable for the input grid
entities.append({
    'variableId': 'varInputGrid',
    'type': 'object'
})

# Instance, InputGrid Value, OutputGrid Value 
for instanceType in ['train', 'test']:
    for idx, ioPair in enumerate(task[instanceType]):
        instanceId = f'{instanceType}{idx}'
        instance = {
            'instanceId': instanceId,
            'instanceType': instanceType,
            'instanceIndex': idx
        }
        entities.append(instance)
        inputGridId = f'varInputGrid_{instanceId}'
        inputGrid = {
            'valueId': inputGridId,
            'partOfInstance': instanceId,
            'assignedToVar': 'varInputGrid',
            'type': 'object',
            'cellList': []
        }
        entities.append(inputGrid)
        outputGridId = f'outputGrid_{instanceId}'
        outputGrid = {
            'valueId': outputGridId,
            'partOfInstance': instanceId,
            'isOutputGrid': True,
            'type': 'object',
            'cellList': []
        }
        entities.append(outputGrid)
        gridKeysToInspect = ['input', 'output'] if instanceType=='train' else ['input']
        for gridKey in gridKeysToInspect:
            gridEntity = inputGrid if gridKey=='input' else outputGrid
            gridId = gridEntity['valueId']
            for yCoord, row in enumerate(ioPair[gridKey]):
                for xCoord, color in enumerate(row):
                    cellId = f'{gridId}_x{xCoord}_y{yCoord}'
                    gridEntity['cellList'].append(cellId)
                    entities.append({
                        'valueId': cellId,
                        'partOfInstance': instanceId,
                        'type': 'cell',
                        'x': xCoord,
                        'y': yCoord,
                        'color': color
                    })

instanceIds = [e['instanceId'] for e in entities if 'instanceId' in e]

# Variables and Variable Values
for i in range(1, maxProgramLength+1):
    varId = f'var{i}'
    entities.append({
        'variableId': varId,
        'lineNum': i
    })
    for instanceId in instanceIds:
        valId = f'{varId}_{instanceId}'
        # type is assigned at solve time for top level value, as are x,y, color values if cell
        valEntity = {
            'valueId': valId,
            'assignedToVar': varId,
            'partOfInstance': instanceId,
            'cellList': [],
            'objList': []
        }
        entities.append(valEntity)
        # Cells if value is object
        for i in range(0, maxNumCellsInObject):
            cellId = f'{valId}_cell{i}'
            valEntity['cellList'].append(cellId)
            # x, y, xolor assigned at solve time
            cellEntity = {
            'valueId': cellId,
            'partOfInstance': instanceId,
            'type': 'cell'
            }
            entities.append(cellEntity)

        # Objects if value is list of objects
        for i in range(0, maxNumObjectInList):
            objId = f'{valId}_obj{i}'
            valEntity['objList'].append(objId)
            objEntity = {
                'valueId': objId,
                'partOfInstance': instanceId,
                'type': 'object',
                'cellList': []
            }
            entities.append(objEntity)
            # Cells for each subObject
            for i in range(0, maxNumCellsInObject):
                objCellId = f'{objId}_cell{i}'
                objEntity['cellList'].append(objCellId)
                # x, y, xolor assigned at solve time
                objCellEntity = {
                    'valueId': objCellId,
                    'partOfInstance': instanceId,
                    'type': 'cell'
                }
                entities.append(objCellEntity)

    

idKeys = ['instanceId', 'variableId', 'valueId']
def atomsOfEntity(e: dict) -> list[str]:
    atoms : list[str] = []

    # Get id for entity
    id : str = ''
    for idKey in idKeys:
        if idKey in e:
            id = e[idKey]
            break

    for key, value in e.items():
        if key in idKeys:
            atoms.append(f'{key}({id}).')
        elif type(value) == list:
            for idx, childId in enumerate(value):
                atoms.append(f'{key}({id}, {idx}, {childId}).')
        elif type(value) == bool and value == True:
            atoms.append(f'{key}({id}).')
        else:
            atoms.append(f'{key}({id}, {value}).')
    
    # add empty string to create newline between entities
    atoms.append('') 
    return atoms

# print(json.dumps(entities, indent=4))

allAtoms : list[str] = [a for e in entities for a in atomsOfEntity(e)]
allAtoms = [f'#const maxProgramLength={maxProgramLength}.'] + allAtoms
with open(outputFilepath, 'w') as f:
    f.write('\n'.join(allAtoms))
