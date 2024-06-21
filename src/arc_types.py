from typing import TypedDict

class IoPair(TypedDict):
    input: list[list[int]]
    output: list[list[int]]
    
class Task(TypedDict):
    train: list[IoPair]
    test: list[IoPair]
