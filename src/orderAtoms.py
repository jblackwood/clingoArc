import os

outputStr = '''
Answer: 1
color(red) color(black) background(black) inputColor(1,1,red) inputColor(1,2,black) inputColor(2,1,red) inputColor(2,2,black) color(1,1,1,red) color(1,2,1,black) color(2,1,1,red) color(2,2,1,black) color(1,1,2,black) color(1,2,2,red) color(2,1,2,black) color(2,2,2,red) outputColor(1,1,black) outputColor(1,2,red) outputColor(2,1,black) outputColor(2,2,red) obj(a) occupiedBy(1,1,1,a) occupiedBy(2,1,1,a) occupiedBy(1,2,2,a) occupiedBy(2,2,2,a) moveRight(a,1)
'''
lines = outputStr.splitlines()

def sortLine(l : str) -> list[str]:
    if(l.startswith("Answer:")):
        return ['\n'+l]
    atoms = l.split(' ')
    atoms = [a.strip() for a in atoms]
    atoms = [a for a in atoms if a!=""]
    atoms.sort()
    return atoms    

# list[list[str]]
sortedLines : list[list[str]] = [sortLine(l) for l in lines]

outputFile = os.path.abspath('tmp/scratch.txt')
with open(outputFile, 'w') as f:
    for l in sortedLines:
        for s in l:
            f.write(f"{s}\n")