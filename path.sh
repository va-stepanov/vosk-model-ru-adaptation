#!/bin/bash

export KALDI_ROOT=/opt/kaldi
#echo ls $KALDI_ROOT
#ls $KALDI_ROOT

# additional paths for building HCLGa.fst 
export PATH=$KALDI_ROOT/src/bin:$KALDI_ROOT/src/fstbin:$PATH

export PATH=$KALDI_ROOT/src/latbin:$KALDI_ROOT/src/online2bin:$KALDI_ROOT/src/lmbin:$KALDI_ROOT/src/rnnlmbin:$KALDI_ROOT/egs/wsj/s5/utils:$KALDI_ROOT/tools/openfst/bin:$PWD:$PATH
#echo PATH=$PATH

#export LC_ALL=C.UTF-8
