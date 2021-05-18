import io
import re
import sys
import collections
 
if len(sys.argv) != 7:
    print(sys.argv[0] + "      ")
    sys.exit(2)
 
[basedic, baselm, extdic, extlm, outdic, outlm] = sys.argv[1:7]
 
print("Merging dictionaries...")
 
words = collections.OrderedDict()
for dic in [basedic, extdic]:
    with io.open(dic, 'r+') as Fdic:
        for line in Fdic:
            arr = line.strip().replace("\t", " ").split(" ", 1) # Sometimes tabs are used
            [word, pronunciation] = arr
            word = word.lower()
            if word not in words:
                words[word] = set([pronunciation.lower()])
            else:
                words[word].add(pronunciation.lower())
 
with io.open(outdic, 'w', newline='\n') as Foutdic:
    for word in words:
        for pronunciation in words[word]:
            Foutdic.write(word + " " + pronunciation + "\n")
 
print("Merging language models...")
 
# Read LM entries - works only on 3-gram models at most
grams = [[], [], []]
for lm in [baselm, extlm]:
    with io.open(lm, 'r+') as Flm:
        mode = 0
        for line in Flm:
            line = line.strip()
            if line == "\\1-grams:": mode = 1
            if line == "\\2-grams:": mode = 2
            if line == "\\3-grams:": mode = 3
            arr = line.split()
            if mode > 0 and len(arr) > 1:
                if mode == 1 or mode == 2:
                    word = " ".join(arr[2:-1] if mode < 3 else arr[2:])
                    word = word.lower()
                grams[mode - 1].append(line.lower())
 
with io.open(outlm, 'w', newline='\n') as Foutlm:
    Foutlm.write(
       u"\\data\\\n" +
       u"ngram 1=" + str(len(grams[0])) + "\n"
       u"ngram 2=" + str(len(grams[1])) + "\n"
       u"ngram 3=" + str(len(grams[2])) + "\n"
    )
    for i in range(3):
        Foutlm.write(u"\n\\" + str(i+1) + u"-grams:\n")
        for g in grams[i]:
            Foutlm.write(g + "\n")
 
    Foutlm.write(u"\n\\end\\\n")
