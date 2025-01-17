# clingoARC: Exploring ARC Program Search with First-Order Logic Metaprogramming

This repository is a proof-of-concept for encoding the program search required to solve tasks in the [**ARC-AGI benchmark**](https://arcprize.org/arc) as first-order logic metaprogramming. 
The first-order logic encoding is then fed into [**clingo**](https://potassco.org/clingo/), a popular tool for Answer Set Programming (ASP). ASP is a logic programming paradigm that compiles first-order logic programs into ground SAT problems that are then solved using conflict-driven clause learning (CDCL) and other modern SAT heuristics. 

This repository reflects my passion for building AGI, as I think the ARC benchmark is a key tool for pushing research in the right direction. My research interests are centered around solving ARC and AGI, not any of the specific techniques I am using. 

I took 2 weeks vacation in July 2024 to work on this project. I plan to pursue the approaches discussed in the [**Future Directions**](#future-directions) section for my next vacaction.


## Motivations and vision

My approach in this repository is motivated by the following thinking:

1. **Program Search is Key**  
   Solving the ARC benchmark requires finding the abstract rules (aka programs) that transform the training input grids into the output grids.
   The task boils down to an **NP-complete problem**: while verifying the correctness of a program for the training examples is trivial, finding such a program is computationally challenging.

2. **Beyond Deep Learning Alone**  
   While deep learning excels at pattern recognition, in my opinion solving ARC requires **search algorithms** that can generate and verify candidate programs. Popular approaches to solve ARG-AGI are already trying to integrate traditional deep learning with program search, including:
   - Test-time data augmentation and gradient descent.  
   - Reinforcement Learning (RL) and Monte Carlo Tree Search (MCTS) similar to AlphaGo.  
   - Chain-of-thought natural language program synthesis (e.g. recently OpenAI's `o3`).  

3. **The Potential of SAT Solvers and Theorem Provers**  
   My intuition is that techniques from **SAT solving** and **automated theorem proving** (e.g., **CDCL**, **superposition calculus**, and **Knuth-Bendix completion**) may have valuable insights.
   These algorithms are well-suited for certain types of NP-complete problems, and my intuition is that the **symmetry-breaking techniques** in these algorithms might be useful for solving ARC-like tasks.
   Although there has been progress in combining deep learning with theorem provers, the focus has been primarily on mathematical theorems rather than benchmarks like ARC.
   I believe deeper integration of deep learning and these algorithms might have untapped potential for program search in ARC-like tasks.


## Details of the approach

**clingoARC** is a proof-of-concept implementation for encoding ARC program search into first-order logic metaprogramming and then attempting to solve with clingo. 
  
### First-Order Logic Metaprogramming Representation  
  ARC tasks and candidate programs are encoded in first-order logic and fed into clingo. The encoding follows metaprogramming techniques common in logic programming and assumes a DSL similar to [Michael Hodel's Published ARC DSL](https://github.com/michaelhodel/arc-dsl). It can take some time to wrap your head around metaprogramming in first-order logic as the candidate program itself is encoded as first-order logic facts. For example, function calls and intermediate variables are all encoded as first-order logic relations. Below is an excerpt for the encoding of function calls in [arc_enc_v2.lp](https://github.com/jblackwood/clingoArc/blob/a7adb4fe1055d283572f35ae704bf1079b0a415b/src/arc_enc_v2.lp#L148).

```
%%%%%%%%%%%%%%%%%%%% functionCall constraints. %%%%%%%%%%%%%%%%%%%%%

% Each functionCall must be associated with at most 1 function
{functionCall(LN, R, F, A1, A2): variableId(R), functionId(F), variableId(A1), variableId(A2)} 1 :- 
    LN=1..maxProgramLength.

% must have at least 1 function call
:- #count{LN : functionCall(LN, _, _, _, _)} = 0.

% functions must be called sequentially
:-
    functionCall(LN, _, _, _, _),
    not functionCall(LN-1, _, _, _, _),
    LN > 1.

% track number of function calls
numFunctionCalls(N) :-
    N=#count{LN : functionCall(LN, _, _, _, _)},
    N=1..maxProgramLength.

% Don't allow function calls with exact same args. 
% Shouldn't be needed since variables are immutable.
:-
    functionCall(LN1, _, F, A1, A2),
    functionCall(LN2, _, F, A1, A2),
    LN1 != LN2.

% Functions return the variable for that line number
:-
    functionCall(LN1, R, F, A1, A2),
    lineNum(R, LN2),
    LN1 != LN2.

:-
    functionCall(LN1, R, F, A1, A2),
    not lineNum(R, _).


% Variables must be used after they are calculated
:- 
    functionCall(LN1, R, F, A1, A2),
    lineNum(A1, LN2),
    LN1 <= LN2.

:- 
    functionCall(LN1, R, F, A1, A2),
    lineNum(A2, LN2),
    LN1 <= LN2.

% copy type from variable to assignedValues
type(ValId, T) :-
    variableId(VarId),
    type(VarId, T),
    assignedToVar(ValId, VarId).

```

### Python Translation  
Python is used to pre-process ARC tasks, encode them into first-order logic facts, and decode solution facts back into interpretable programs.

## Learnings
Despite demonstrating the feasibility of encoding ARC tasks in first-order logic metaprogramming, the current approach with clingo suffers from the **grounding bottleneck** of Answer Set Programming. The propositional logic formulas generated by clingo become too large for computer memory, preventing them from being fed into a SAT solver. I ran into the grounding bottleneck quickly with a very limited DSL that consists of simple operations like *parseObjects* and *moveDown*.


## Future Directions

The issue with the grounding bottleneck in ASP motivates me to explore alternative techniques for first-order logic program search. In the future, I plan to pursue:

1. **Automated Theorem Proving Techniques**  
   Program search can be encoded into first-order-logic theorem proving as this repository demonstrates. Tools like the [**E-Theorem Prover**](https://wwwlehre.dhbw-stuttgart.de/~sschulz/E/E.html) and [**Vampire**](https://vprover.github.io/), which operate directly on first-order logic without grounding, can potentially bypass the grounding bottleneck I encountered with clingo. The tradeoff with these tools is they might never halt as first-order logic theorem proving is semidecidable. I anticipate I might need to implement my own basic theorem prover to specialize the heuristics for ARC-like tasks.

2. **Integrate Deep Learning**  
   Use neural networks to guide the search process by narrowing the candidate space. This might involve suggesting lemmas learned from previous ARC tasks (similar to hammers in automated proof assistants) or using LLMs to directly add lemmas to the proof search.
