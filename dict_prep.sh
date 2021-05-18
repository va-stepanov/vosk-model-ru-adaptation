#!/bin/bash
dir=data/local/dict
mkdir -p $dir

srcdict=merged-words.txt

cat $srcdict | sed 's:([0-9])::g' | LANG= LC_ALL= sort | uniq \
   > $dir/lexicon_words.txt 

cat $dir/lexicon_words.txt | awk '{ for(n=2;n<=NF;n++){ phones[$n] = 1; }} END{for (p in phones) print p;}' | \
  grep -v SIL | sort > $dir/nonsilence_phones.txt

( echo SIL; echo GBG) > $dir/silence_phones.txt

echo SIL > $dir/optional_silence.txt

# No "extra questions" in the input to this setup, as we don't
# have stress or tone.
echo -n >$dir/extra_questions.txt

# Add to the lexicon the silences, noises etc.
(echo '!SIL SIL';
 echo '[unk] GBG' ) | \
 cat - $dir/lexicon_words.txt  > $dir/lexicon.txt
