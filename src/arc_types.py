from typing import TypedDict

class IoPair(TypedDict):
    input: list[list[int]]
    output: list[list[int]]
    
class Task(TypedDict):
    train: list[IoPair]
    test: list[IoPair]

class Entity(TypedDict):
    id: str
    type: str
    
    # cell properties
    x: int
    y: int
    color: int

    #variable, argument, functionCall
    lineNum: int
    
    #variable
    isVariable: bool
    varType: str

    #arg
    isArgument: bool
    argPos: int

    #var instance
    isVarInstance: bool

    # grid property contains is list[cell_id]
    contains: list[str]
