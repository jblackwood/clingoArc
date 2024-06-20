#include "moveBlueSquaresv2_inst.lp".

% copy input grid children properties into var0
type(Child, T) :- 
    type(CellId, T),
    child(G, N, CellId),
    isInputGrid(G),
    instance(G, I),
    isVarInstance(VarInst),
    instance(VarInst, I),
    lineNum(VarInst, 0),
    child(VarInst, N, Child).

y(Child, Y) :- 
    y(CellId, Y),
    child(G, N, CellId),
    isInputGrid(G),
    instance(G, I),
    isVarInstance(VarInst),
    instance(VarInst, I),
    lineNum(VarInst, 0),
    child(VarInst, N, Child).

x(Child, X) :- 
    x(CellId, X),
    child(G, N, CellId),
    isInputGrid(G),
    instance(G, I),
    isVarInstance(VarInst),
    instance(VarInst, I),
    lineNum(VarInst, 0),
    child(VarInst, N, Child).

color(Child, C) :- 
    color(CellId, C),
    child(G, N, CellId),
    isInputGrid(G),
    instance(G, I),
    isVarInstance(VarInst),
    instance(VarInst, I),
    lineNum(VarInst, 0),
    child(VarInst, N, Child).

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

% Variables must be used after calculation
% :- 
%     argVal(ArgId, VarId),
%     lineNum(ArgId, N1),
%     lineNum(VarId, N2),
%     N1 <= N2.





% show
var0_train0_numColor(C, N) :- 
    numColor(var0_train0, C, N).

var0_train0_mostColor(C) :- mostColor(var0_train0, C).

#show var0_train0_numColor/2.
#show var0_train0_mostColor/1.


% Variables must be used after calculation
% :- 
%     argVal(ArgId, VarId),
%     lineNum(ArgId, N1),
%     lineNum(VarId, N2),
%     N1 <= N2.

% Each functionCall must be associated with 1 function
% {functionId(CallId, FunId): type(FunId, function)}=1 :- 
%     id(CallId),
%     type(CallId, functionCall).






% %% Anon entities
% isAnonEntity(1..500).

% % Anon entities populated in ascending order
% :- 
%     isAnonEntity(E1), 
%     isAnonEntity(E2),
%     E2 > E1,
%     not contains(E1, _),
%     contains(E2, _).

% % Anon entities must contain entities of same instance
% :- 
%     isAnonEntity(E1),
%     contains(E1, Id1),
%     contains(E1, Id2),
%     instance(Id1, I1),
%     instance(Id2, I2),
%     I1 !=I2.

% % Anon entities must have same instance as their container
% instance(E1, I) :- 
%     isAnonEntity(E1),
%     contains(Id, E1),
%     instance(Id, I).

% % Anon entities must be used in order of instance
% :- 
%     isAnonEntity(E1),
%     isAnonEntity(E2),
%     E2 > E1,
%     instance(E1, I1),
%     instance(E2, I2),
%     I2<I1.

% % Anon entities in same instance must be used in order of lineNum
% :- 
%     isAnonEntity(E1),
%     isAnonEntity(E2),
%     E2 > E1,
%     instance(E1, I),
%     instance(E2, I),
%     contains(VarInstanceId1, E1),
%     contains(VarInstanceId2, E2),
%     varId(VarInstanceId1, VarId1),
%     varId(VarInstanceId2, VarId2),
%     lineNum(VarId1, LineNum1),
%     lineNum(VarId2, LineNum2),
%     LineNum2 < LineNum1.


% %% parseObjects
% id(parseObjects).
% type(parseObjects, function).

% % parseObjects first arg is a grid variable
% {argVal(ArgId, VarId) : isVariable(VarId), type(VarId, grid)} = 1 :-  
%     functionId(CallId, parseObjects),
%     type(CallId, functionCall),
%     lineNum(CallId, LineNum),
%     isArgument(ArgId),
%     lineNum(ArgId, LineNum),
%     argPos(ArgId, 0).

% % parseObjects returns a list of objects
% type(VarId, listObjects) :-  
%     functionId(CallId, parseObjects),
%     type(CallId, functionCall),
%     lineNum(CallId, LineNum),
%     isVariable(VarId),
%     lineNum(VarId, LineNum).

% % parseObjects must put all cells that aren't the mostColor in an object
% {contains(ObjId, CellId) : isAnonEntity(ObjId)} = 1 :-  
%     functionId(CallId, parseObjects),
%     type(CallId, functionCall),
%     lineNum(CallId, LineNum),
%     isArgument(ArgId),
%     lineNum(ArgId, LineNum),
%     argPos(ArgId, 0),
%     argVal(ArgId, VarId),
%     varId(VarInstanceId, VarId),
%     contains(VarInstanceId, CellId),
%     color(CellId, C1),
%     mostColor(VarInstanceId, C2),
%     C1 != C2.

% % parseObjects puts cells in objects contained in output var
% contains(VarInstanceId2, Obj):-  
%     functionId(CallId, parseObjects),
%     type(CallId, functionCall),
%     lineNum(CallId, LineNum),
%     isArgument(ArgId),
%     lineNum(ArgId, LineNum),
%     argPos(ArgId, 0),
%     argVal(ArgId, VarId1),
%     varId(VarInstanceId1, VarId1),
%     contains(VarInstanceId1, CellId),
%     lineNum(VarId2, LineNum),
%     varId(VarInstanceId2, VarId2),
%     instance(VarInstanceId1, I),
%     instance(VarInstanceId2, I),
%     isAnonEntity(Obj),
%     contains(Obj, CellId).

% % parseObjects puts cells of same color in same object
% contains(Obj, CellId2):-  
%     functionId(CallId, parseObjects),
%     type(CallId, functionCall),
%     lineNum(CallId, LineNum),
%     isArgument(ArgId),
%     lineNum(ArgId, LineNum),
%     argPos(ArgId, 0),
%     argVal(ArgId, VarId),
%     varId(VarInstanceId, VarId),
%     contains(VarInstanceId, CellId1),
%     isAnonEntity(Obj),
%     contains(Obj, CellId1),
%     contains(VarInstanceId, CellId2),
%     color(CellId1, C),
%     color(CellId2, C).

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


