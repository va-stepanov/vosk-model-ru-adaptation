#!/bin/bash

set -o pipefail -o nounset

MODEL_DIR="/opt/vosk-model-ru/model"
WORK_DIR="$MODEL_DIR/new"
DATA_DIR="$WORK_DIR/data"
GRAPH_DIR="$DATA_DIR/graph"
LANG_DIR="$DATA_DIR/lang"
RNNLM_DIR="$DATA_DIR/rnnlm"

CORPUS_DIR="$DATA_DIR/corpus"
CORPUS_NAME="corpus.txt"
PHONES_SRC="$MODEL_DIR/graph/phones.txt"

DICT_DIR="$DATA_DIR/local/dict"
DICT_OUT="$DATA_DIR/dict"
DICT_TMP="$DATA_DIR/dict_tmp"

RECIPE_DIR="/opt/kaldi/egs/mini_librispeech"

WORDS_SRC="$WORK_DIR/merged-words.txt"
LM_SRC="$CORPUS_DIR/merged-lm.arpa"

parse_file_events(){
    local path action file
    while read path action file; do
        if [ "$file" == "$CORPUS_NAME" ]; then
            make_action || return 1
        fi
    done 
    return 0
}

restart_web_socket(){
    kill $(pgrep -f 'python3 /opt/vosk-server/websocket/asr_server.py')
    python3 /opt/vosk-server/websocket/asr_server.py $MODEL_DIR &
    return 0
}

make_action(){
    cd $CORPUS_DIR || return 1
    rm -f $(ls | grep -v $CORPUS_NAME) || return 1
    cd $WORK_DIR || return 1
    rm -f *.txt || return 1
    rm -rf $DICT_DIR/* || return 1
    rm -rf $DICT_OUT/* || return 1
    rm -rf $LANG_DIR/* || return 1
    rm -rf $GRAPH_DIR/* || return 1
    rm -rf $RNNLM_DIR/* || return 1
    grep -oE "[А-Яа-я\\-]{3,}" $CORPUS_DIR/$CORPUS_NAME | sed "s/[А-Я]/\L&/g" | sort | uniq > $CORPUS_DIR/words.txt || return 1
    #cd ./russian_g2p_neuro || return 1
    #/opt/ve/bin/python3 -m src.generate_transcriptions $CORPUS_DIR/words.txt $CORPUS_DIR/words.dic || return 1
    #cd $WORK_DIR || return 1
    python3 ./dictionary.py $CORPUS_DIR/words.txt > $CORPUS_DIR/words.dic || return 1
    cd $WORK_DIR/kenlm/build/bin || return 1
    lmplz -o 3 --discount_fallback < $CORPUS_DIR/words.txt > $CORPUS_DIR/lm.arpa || return 1
    sed -i "s/<unk>/[unk]/g" $CORPUS_DIR/lm.arpa || return 1
    cd $WORK_DIR || return 1
    python3 ./mergedicts.py ../extra/db/ru.dic ../extra/db/ru-small.lm $CORPUS_DIR/words.dic $CORPUS_DIR/lm.arpa $WORDS_SRC $LM_SRC || return 1
    ./dict_prep.sh || return 1
    cd $RECIPE_DIR/s5 || return 1
    ./utils/prepare_lang.sh --phone-symbol-table $PHONES_SRC $DICT_DIR "[unk]" $DICT_TMP $DICT_OUT || return 1
    # Собираем грамматику (G.fst)
    gzip $LM_SRC || return 1
    ./utils/format_lm.sh $DICT_OUT $LM_SRC.gz $DICT_DIR/lexicon.txt $LANG_DIR || return 1
    # Собираем и заменяем HCLG граф
    cd $WORK_DIR || return 1
    ./mkgraph.sh --self-loop-scale 1.0 $LANG_DIR $MODEL_DIR/am $GRAPH_DIR || return 1
    cd /opt/kaldi/egs/wsj/s5 || return 1
    cat /dev/null > /opt/vosk-model-ru/model/rnnlm/unigram_probs.txt || return 1
    $WORK_DIR/change_vocab.sh $GRAPH_DIR/words.txt $MODEL_DIR/rnnlm $RNNLM_DIR || return 1
    cd $RNNLM_DIR || return 1
    cat special_symbol_opts.txt | sed 's/\s\+/\n/g' | sed '/^$/d' > special_symbol_opts.conf || return 1
    mv $GRAPH_DIR/HCLG.fst $MODEL_DIR/graph/HCLG.fst || return 1
    mv $GRAPH_DIR/words.txt $MODEL_DIR/graph/words.txt || return 1
    mv $WORDS_SRC $MODEL_DIR/extra/db/ru.dic || return 1
    mv $LANG_DIR/G.fst $MODEL_DIR/rescore/G.fst || return 1
    mv $RNNLM_DIR/word_feats.txt $MODEL_DIR/rnnlm/word_feats.txt || return 1
    mv $RNNLM_DIR/feat_embedding.final.mat $MODEL_DIR/rnnlm/feat_embedding.final.mat || return 1
    mv $RNNLM_DIR/special_symbol_opts.conf $MODEL_DIR/rnnlm/special_symbol_opts.conf || return 1
    restart_web_socket
    echo "successful update"
    return 0
}

shopt -s extglob
restart_web_socket
inotifywait -m $CORPUS_DIR -e create -e moved_to | parse_file_events || __panic "failed make_action"