#const numIOPairs=4.
% inputGrid(inputOutputNum, x, y, colorVal)
% outputGrid(inputOutputNum, x, y, colorVal)

% train[0]
inputGrid(0, 0, 0, 0).
inputGrid(0, 1, 0, 1).
inputGrid(0, 2, 0, 0).
inputGrid(0, 0, 1, 0).
inputGrid(0, 1, 1, 0).
inputGrid(0, 2, 1, 0).
inputGrid(0, 0, 2, 0).
inputGrid(0, 1, 2, 0).
inputGrid(0, 2, 2, 0).

outputGrid(0, 0, 0, 0).
outputGrid(0, 1, 0, 0).
outputGrid(0, 2, 0, 0).
outputGrid(0, 0, 1, 0).
outputGrid(0, 1, 1, 1).
outputGrid(0, 2, 1, 0).
outputGrid(0, 0, 2, 0).
outputGrid(0, 1, 2, 0).
outputGrid(0, 2, 2, 0).


% train[1]
inputGrid(1, 0, 0, 0).
inputGrid(1, 1, 0, 0).
inputGrid(1, 2, 0, 0).
inputGrid(1, 0, 1, 1).
inputGrid(1, 1, 1, 0).
inputGrid(1, 2, 1, 0).
inputGrid(1, 0, 2, 0).
inputGrid(1, 1, 2, 0).
inputGrid(1, 2, 2, 0).

outputGrid(1, 0, 0, 0).
outputGrid(1, 1, 0, 0).
outputGrid(1, 2, 0, 0).
outputGrid(1, 0, 1, 0).
outputGrid(1, 1, 1, 0).
outputGrid(1, 2, 1, 0).
outputGrid(1, 0, 2, 1).
outputGrid(1, 1, 2, 0).
outputGrid(1, 2, 2, 0).

% train[2]
inputGrid(2, 0, 0, 0).
inputGrid(2, 1, 0, 0).
inputGrid(2, 2, 0, 1).
inputGrid(2, 0, 1, 0).
inputGrid(2, 1, 1, 0).
inputGrid(2, 2, 1, 1).
inputGrid(2, 0, 2, 0).
inputGrid(2, 1, 2, 0).
inputGrid(2, 2, 2, 0).

outputGrid(2, 0, 0, 0).
outputGrid(2, 1, 0, 0).
outputGrid(2, 2, 0, 0).
outputGrid(2, 0, 1, 0).
outputGrid(2, 1, 1, 0).
outputGrid(2, 2, 1, 0).
outputGrid(2, 0, 2, 0).
outputGrid(2, 1, 2, 0).
outputGrid(2, 2, 2, 0).

% test[0]
inputGrid(3, 0, 0, 0).
inputGrid(3, 1, 0, 0).
inputGrid(3, 2, 0, 0).
inputGrid(3, 0, 1, 0).
inputGrid(3, 1, 1, 0).
inputGrid(3, 2, 1, 1).
inputGrid(3, 0, 2, 0).
inputGrid(3, 1, 2, 0).
inputGrid(3, 2, 2, 0).

% Encoding
variable(T) :- T=0..5.

variableType(0,grid).

variableCell(TaskInstance, 0, X, Y, C):- inputGrid(TaskInstance, X, Y, C).

functionName(parseObjects; moveDown).

1 = {functionCall(T, F) : functionName(F)} :- T=1..5.

color(C) :- inputGrid(_, _, _, C).
color(C) :- outputGrid(_, _, _, C).

variableHasColor(TaskInstance, T, C) :- variableCell(TaskInstance, T, _, _, C).
variableNumColor(TaskInstance, T, C, N) :- N = #count{cell(X,Y) : variableCell(TaskInstance, T, X, Y, C)}, variableHasColor(TaskInstance, T, C), N=1..10.
variableNotMostColor(TaskInstance, T, C1) :- 
    variableNumColor(TaskInstance, T, C1, N1), 
    variableNumColor(TaskInstance, T, C2, N2), 
    C1 != C2,
    N1<N2.

variableMostColor(TaskInstance, T, C) :- not variableNotMostColor(TaskInstance, T, C), variableHasColor(TaskInstance, T, C). 

%%%%%%%% parseObjects Definition %%%%%%%%

% parseObjects takes 1 argument that must be a variable that is a grid
{argumentVariable(T,0,V) : variable(V)} = 1 :- functionCall(T, parseObjects).
variableType(V, grid) :- functionCall(T, parseObjects), argumentVariable(T, 0, V), variable(V).

% parseObjects returns a set of objects
variableType(T+1, setObjects) :- functionCall(T, parseObjects).

% 
{variableObj(TaskInstance, T+1, Obj, X, Y, C)}=1 :- 
    functionCall(T, parseObjects), 
    argumentVariable(T, 0, V), 
    variable(V), 
    variableCell(TaskInstance, T, X, Y, C),
    Obj=0..1.

% Objects with same color are part of same object
variableObj(TaskInstance, T+1, Obj, X2, Y2, C) :- 
    functionCall(T, parseObjects), 
    argumentVariable(T, 0, V), 
    variable(V), 
    variableCell(TaskInstance, T, X1, Y1, C),
    variableCell(TaskInstance, T, X2, Y2, C),
    variableObj(TaskInstance, T+1, Obj, X1, Y1, C),
    not variableMostColor(TaskInstance, T, C).


%%%%%%%% Move(gridVar, objVar, argumentVal) Definition %%%%%%%%
% move takes 2 arguments, a grid and a number
{argumentVariable(T,0,V) : variable(V)} = 1 :- functionCall(T, move).

variableType(V, grid) :- 
    functionCall(T, move), 
    argumentVariable(T, 0, V), 
    variable(V).

1={argumentalValue(T, 1, N) : N=1..2} :- functionCall(T, move).




% variables must be used after they are calculated
:- argumentVariable(T, Position, V), variable(V), V>=T.



%%%%%%%% Parse Objects Definition %%%%%%%%
i1_v0_MostColor(C) :- variableMostColor(1,0,C).
i1_v0_NumColor(C, N) :- variableNumColor(1,0,C,N).

#show color/1.
#show i1_v0_MostColor/1.
#show i1_v0_NumColor/2.