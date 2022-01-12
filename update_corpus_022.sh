#!/bin/bash

set -o pipefail -o nounset

WORK_DIR="/opt/vosk-model-ru-compile"

CORPUS_DIR="$WORK_DIR/db"
CORPUS_NAME="extra.txt"

MODEL_DIR="/opt/vosk-model-ru/model"

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
    cd $WORK_DIR || return 1
    ./compile-graph.sh || return 1
    cp -a ./exp/chain/tdnn/graph/. $MODEL_DIR/graph/ || return 1
    mv ./data/lang_test_rescore/G.fst $MODEL_DIR/rescore || return 1
    #mv ./data/lang_test_rescore/G.carpa $MODEL_DIR/rescore || return 1
    cp -a ./exp/rnnlm_out/. $MODEL_DIR/rnnlm/ || return 1
    restart_web_socket
    echo "successful update"
    return 0
}

shopt -s extglob
restart_web_socket
inotifywait -m $CORPUS_DIR -e create -e moved_to | parse_file_events || __panic "failed make_action"