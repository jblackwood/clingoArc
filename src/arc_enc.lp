% copyCell
type(Id2, cell) :- 
    copyCell(_, Id2).

y(Id2, Val) :-
    copyCell(Id1, Id2),
    y(Id1, Val).

x(Id2, Val) :-
    copyCell(Id1, Id2),
    x(Id1, Val).

color(Id2, Val) :-
    copyCell(Id1, Id2),
    color(Id1, Val).

% copyCellXY
type(Id2, cell) :- 
    copyCellXY(_, Id2).

y(Id2, Val) :-
    copyCellXY(Id1, Id2),
    y(Id1, Val).

x(Id2, Val) :-
    copyCellXY(Id1, Id2),
    x(Id1, Val).

% % copyCellColor
% type(Id2, cell) :- 
%     copyCellColor(_, Id2).

% color(Id2, Val) :-
%     copyCellXY(Id1, Id2),
%     color(Id1, Val).

% mostColor
hasColor(Id, C) :- 
    child(Id, _, SubId),
    color(SubId, C).

numColor(Id, C, N) :- 
    hasColor(Id, C), 
    N = #count{SubId : child(Id, _, SubId), color(SubId, C)}.

notMostColor(Id, C1) :-
    numColor(Id, C1, N1),
    numColor(Id, C2, N2),
    C1 != C2,
    N2 > N1.

mostColor(Id, C) :- 
    hasColor(Id, C),
    not notMostColor(Id, C).

% copy input grid cells into var0
copyCell(CellId, NewCellId) :- 
    child(G, N, CellId),
    isInputGrid(G),
    instance(G, I),
    isVarInstance(VarInst),
    instance(VarInst, I),
    lineNum(VarInst, 0),
    child(VarInst, N, NewCellId).

% copy type from variable to varInstances
type(VarInstance, T) :-
    type(VarId, T),
    isVariable(VarId),
    varId(VarInstance, VarId).

% copy lineNum from variable to varInstances
lineNum(VarInstance, L) :-
    lineNum(VarId, L),
    isVariable(VarId),
    varId(VarInstance, VarId).

% Each functionCall must be associated with 1 function
{functionId(CallId, FunId): type(FunId, function)}=1 :- 
    id(CallId),
    type(CallId, functionCall).

% Variables must be used after calculation
:- 
    argVal(ArgId, VarId),
    lineNum(ArgId, N1),
    lineNum(VarId, N2),
    N1 <= N2.



%%%%%%%%%%%%%%%%%%%% parseObjects %%%%%%%%%%%%%%%%%%%%%
id(parseObjects).
type(parseObjects, function).

% parseObjects first arg is a grid variable
{argVal(ArgId, VarId) : isVariable(VarId), type(VarId, grid)} = 1 :-  
    functionId(CallId, parseObjects),
    type(CallId, functionCall),
    lineNum(CallId, LineNum),
    isArgument(ArgId),
    lineNum(ArgId, LineNum),
    argPos(ArgId, 0).

% parseObjects returns a list of objects
type(VarId, listObjects) :-  
    functionId(CallId, parseObjects),
    type(CallId, functionCall),
    lineNum(CallId, LineNum),
    isVariable(VarId),
    lineNum(VarId, LineNum).

% Any child that's not the most color must be copied to a a child object
% of the output var inst
{copyToObject_parseObjects(LineNum, I, InputChildId, OutputObjId) 
: child(OutVarInst, _, OutputObjId) }=1 :- 
    functionId(CallId, parseObjects),
    type(CallId, functionCall),
    lineNum(CallId, LineNum),
    lineNum(ArgId, LineNum),
    argVal(ArgId, VarId),
    isVarInstance(ArgVarInst),
    varId(ArgVarInst, VarId),
    instance(ArgVarInst, I),
    child(ArgVarInst, N, InputChildId),
    color(InputChildId, C),
    mostColor(ArgVarInst, MostC),
    C != MostC,
    isVarInstance(OutVarInst),
    instance(OutVarInst, I),
    lineNum(OutVarInst, LineNum).
    
% Input children with same color must be copied to same child object
:- 
    copyToObject_parseObjects(LineNum, I, ChildId_1, OutputObjId_1),
    copyToObject_parseObjects(LineNum, I, ChildId_2, OutputObjId_2),
    ChildId_1 != ChildId_2,
    color(ChildId_1, C),
    color(ChildId_2, C),
    OutputObjId_1 != OutputObjId_2.

% Input children with different color must be copied to different object
:- 
    copyToObject_parseObjects(LineNum, I, ChildId_1, OutputObjId_1),
    copyToObject_parseObjects(LineNum, I, ChildId_2, OutputObjId_2),
    ChildId_1 != ChildId_2,
    color(ChildId_1, C1),
    color(ChildId_2, C2),
    C1 != C2,
    OutputObjId_1 = OutputObjId_2.

% Output children are populated in ascending order
 :- 
    copyToObject_parseObjects(LineNum, I, _, OutputObjId_1),
    child(P, N1, OutputObjId_1),
    child(P, N2, OutputObjId_2),
    N1 > N2,
    not copyToObject_parseObjects(LineNum, I, _, OutputObjId_2).
    

% Copy cells to same index
copyCell(InputChildId, OutputCellId):- 
    child(_, N, InputChildId),
    copyToObject_parseObjects(LineNum, I, InputChildId, OutputObjId),
    child(OutputObjId, N, OutputCellId).

% Type of output object is object
type(OutputObjId, object):- 
    copyToObject_parseObjects(_, _, _, OutputObjId).


%%%%%%%%%%%%%%%%%%%% moveDown %%%%%%%%%%%%%%%%%%%%%
id(moveDown).
type(moveDown, function).

% moveDown first arg is a grid variable
{argVal(ArgId, VarId) : isVariable(VarId), type(VarId, grid)} = 1 :-  
    functionId(CallId, moveDown),
    type(CallId, functionCall),
    lineNum(CallId, LineNum),
    isArgument(ArgId),
    lineNum(ArgId, LineNum),
    argPos(ArgId, 0).

% moveDown 2nd arg is a listObject variable
{argVal(ArgId, VarId) : isVariable(VarId), type(VarId, listObjects)} = 1 :-  
    functionId(CallId, moveDown),
    type(CallId, functionCall),
    lineNum(CallId, LineNum),
    isArgument(ArgId),
    lineNum(ArgId, LineNum),
    argPos(ArgId, 1).

% moveDown returns a grid
type(VarId, grid) :- 
    functionId(CallId, moveDown),
    type(CallId, functionCall),
    lineNum(CallId, LineNum),
    isVariable(VarId),
    lineNum(VarId, LineNum).

% moveDown bind variable instances
moveDown(FirstArgInst, SecondArgInst, OutputVarInst):- 
    functionId(CallId, moveDown),
    type(CallId, functionCall),
    lineNum(CallId, LineNum),
    argPos(FirstArg, 0),
    lineNum(FirstArg, LineNum),
    argVal(FirstArg, FirstArgVarId),
    isVarInstance(FirstArgInst),
    varId(FirstArgInst, FirstArgVarId),
    instance(FirstArgInst, I),
    argPos(SecondArg, 1),
    lineNum(SecondArg, LineNum),
    argVal(SecondArg, SecondArgVarId),
    isVarInstance(SecondArgInst),
    varId(SecondArgInst, SecondArgVarId),
    instance(SecondArgInst, I),
    isVariable(VarId),
    lineNum(OutputVarInst, LineNum),
    instance(OutputVarInst, I).

% moveDown copy coordinates from input to output
copyCellXY(InputCell, OutputCell):- 
    moveDown(InputGrid, ListObjects, OutputGrid),
    child(InputGrid, N, InputCell),
    child(OutputGrid, N, OutputCell).

% moveDown copies color of object cell with Y-1 coord to output grid
moveDown_case1_color(OutputCell, C) :- 
    moveDown(InputGrid, ListObjects, OutputGrid),
    child(InputGrid, N, InputGridCell),
    child(OutputGrid, N, OutputCell),
    child(ListObjects, _, Obj),
    child(Obj, _, InputObjCell),
    x(OutputCell, X),
    y(OutputCell, Y),
    x(InputObjCell, X),
    y(InputObjCell, Y-1),
    color(InputObjCell, C).

color(Id, C) :- moveDown_case1_color(Id, C).

% moveDown fills with mostColor if cell was occupied by obj and 
% isn't occupied by obj in output grid . 
moveDown_case2_color(OutputCell, C) :- 
    moveDown(InputGrid, ListObjects, OutputGrid),
    child(InputGrid, N, InputGridCell),
    child(OutputGrid, N, OutputCell),
    child(ListObjects, _, Obj),
    child(Obj, _, InputObjCell),
    x(OutputCell, X),
    y(OutputCell, Y),
    x(InputObjCell, X),
    y(InputObjCell, Y),
    not moveDown_case1_color(_, OutputCell),
    mostColor(InputGrid,C).

color(Id, C) :- moveDown_case2_color(Id, C).

% moveDown fills with existing color otherwise
color(OutputCell, C) :- 
    moveDown(InputGrid, ListObjects, OutputGrid),
    child(InputGrid, N, InputGridCell),
    child(OutputGrid, N, OutputCell),
    not moveDown_case1_color(OutputCell, _),
    not moveDown_case2_color(OutputCell, _),
    color(InputGridCell, C).
    




% Output grid must be equal to var2 instance
gridEqual(OutputGrid, VarInst):- 
    isOutputGrid(OutputGrid),
    instance(OutputGrid, I),
    isVarInstance(VarInst),
    instance(VarInst, I),
    lineNum(VarInst, 2).

gridEqual_hasCellValue(G, X, Y, C):-
    gridEqual(G, _),
    child(G, _, Cell),
    x(Cell, X),
    y(Cell, Y),
    color(Cell, C).

gridEqual_hasCellValue(G, X, Y, C):-
    gridEqual(_, G),
    child(G, _, Cell),
    x(Cell, X),
    y(Cell, Y),
    color(Cell, C).

:- 
    gridEqual(G1, G2),
    gridEqual_hasCellValue(G1, X, Y, C),
    not gridEqual_hasCellValue(G2, X, Y, C).

:- 
    gridEqual(G1, G2),
    gridEqual_hasCellValue(G2, X, Y, C),
    not gridEqual_hasCellValue(G1, X, Y, C).








% functionId(call1, parseObjects).
% functionId(call2, moveDown).

varTypes(VarId, T) :- 
    isVariable(VarId),
    type(VarId, T).

var1_train0_child_numColors(Id, C,N) :- 
    child(var1_train0, _, Id),
    numColor(Id, C, N).

var2_train0_child(Child, Type, X, Y, C) :- 
    child(var2_train0, _ , Child),
    type(Child, Type),
    x(Child, X),
    y(Child, Y),
    color(Child, C).

% #show var2_train0_child/5.
#show varTypes/2.
#show argVal/2.
#show functionId/2.
% #show var1_train0_child_numColors/3.
% #show moveDown/3.

% show var0_train0 num colors
% var0_train0_numColor(C, N) :- 
%     numColor(var0_train0, C, N).
% var0_train0_mostColor(C) :- mostColor(var0_train0, C).
% #show var0_train0_numColor/2.
% #show var0_train0_mostColor/1.






% %% moveDown
% id(moveDown).
% type(moveDown, function).

% % moveDown 1st arg is a grid
% {argVal(ArgId, VarId) : isVariable(VarId), type(VarId, grid)} = 1 :-  
%     functionId(CallId, moveDown),
%     type(CallId, functionCall),
%     lineNum(CallId, LineNum),
%     isArgument(ArgId),
%     lineNum(ArgId, LineNum),
%     argPos(ArgId, 0).

% % moveDown 2nd arg is a listObjects
% {argVal(ArgId, VarId) : isVariable(VarId), type(VarId, listObjects)} = 1 :-  
%     functionId(CallId, moveDown),
%     type(CallId, functionCall),
%     lineNum(CallId, LineNum),
%     isArgument(ArgId),
%     lineNum(ArgId, LineNum),
%     argPos(ArgId, 1).

% % moveDown returns a grid
% type(VarId, grid) :-  
%     functionId(CallId, moveDown),
%     type(CallId, functionCall),
%     lineNum(CallId, LineNum),
%     isVariable(VarId),
%     lineNum(VarId, LineNum).

% moveDown 



% require parseObjects and moveDown order
% functionId(call1, parseObjects).
% functionId(call2, moveDown).

% varTypes(V, T) :- isVariable(V), type(V, T).

% % Show program calls and args
% #show argVal/2.
% #show functionId/2.
% #show varTypes/2.

% var0_train0_numColor(C, N) :- numColor(var0_train0, C, N).
% var0_train0_mostColor(C) :- mostColor(var0_train0, C).
% var1_train0_obj(E1) :- contains(var1_train0, E1).
% var1_train0_cellId(CellId) :- var1_train0_obj(E1), contains(E1, CellId).
% e1NumColor(C, N) :- var1_train0_obj(E1), numColor(E1, C, N).
% #show var1_train0_obj/1.
% #show var0_train0_numColor/2.
% #show var0_train0_mostColor/1.
% #show var1_train0_cellId/1.
% #show e1NumColor/2.


