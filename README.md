## Оглавление

* Терминалогия
* Цель
* Вступление
* Подготовка
* Описание
* Заметки
* Помощь

## Терминалогия

[ASR](https://en.wikipedia.org/wiki/Speech_recognition) (automatic or asynchronous speech recognition ) - распознавание речи, автоматический процесс преобразования речевого сигнала в цифровую информацию. 

[Kaldi](https://github.com/kaldi-asr/kaldi) - написанный на c++ движок для распознавания речи от компании Alpha Cephei

[Vosk-API](https://github.com/alphacep/vosk-api) — библиотека для распознавания речи.

[Модель](https://alphacephei.com/vosk/models) — набор файлов, определяющих акустическую (фонемы и трифоны) и языковую модель (грамматика, список кортежей слов — н-грамм) разговорного языка.

Акустическая модель — задает способ отображения потока речи (представленных так называемыми кепстральными коэффициентами ) в фонемы (обозначения звуков речи, которые используются в словарях произношения).

Словарь произношения — лексикон, содержащий транскрипцию произношения слов. Отображает слово в набор фонем.

Языковая модель — задает вероятности разных слов и словосочетаний, которые будут встречаться в произносимом тексте. Очень сильно зависит от тематики текста.

Аллофон — это реализация фонемы (звука) в конкретном звуковом окружении. Вместо фонем берутся пары и тройки фонем, называемые «дифонами» и «трифонами».

## Цель

Расширить, адаптировать словарь имеющейся модели для улучшения качества распознавания речи.

## Вступление

О Kaldi можно почитать [тут](https://eleanorchodroff.com/tutorial/kaldi/index.html) и [тут](http://kaldi-asr.org/doc/kaldi_for_dummies.html).

Презентации на тему [Kaldi](https://sites.google.com/site/dpovey/kaldi-lectures) и ASR [лекция №1](https://ocw.mit.edu/courses/electrical-engineering-and-computer-science/6-345-automatic-speech-recognition-spring-2003/lecture-notes/lecture1.pdf) и так [далее](https://ocw.mit.edu/courses/electrical-engineering-and-computer-science/6-345-automatic-speech-recognition-spring-2003/lecture-notes/lecture2.pdf).

Нативное добавление слов в модель для Vosk-API описано авторами на [этой](https://alphacephei.com/vosk/lm#update-process) странице.

Далее излагается в переработанном виде материал описанный [тут](https://alphacephei.com/vosk/adaptation) и [тут](https://chrisearch.wordpress.com/2017/03/11/speech-recognition-using-kaldi-extending-and-using-the-aspire-model/).

Помимо этого, предлагается воспользоваться контейнером, который уже настроен на обновление словаря для модели 0.10:
[Dockerfile.kaldi-vosk-model-ru](https://github.com/va-stepanov/vosk-model-ru-adaptation/blob/main/Dockerfile.kaldi-vosk-model-ru):

```lang="bash"
git clone https://github.com/va-stepanov/vosk-model-ru-adaptation.git
cd vosk-model-ru-adaptation
docker build --file Dockerfile.kaldi-vosk-model-ru --tag alphacep/kaldi-vosk-model-ru:latest .
docker run -d -p 2700:2700 alphacep/kaldi-vosk-model-ru:latest
```
Последняя команда стартует скрипт /opt/vosk-model-ru/model/new/update_corpus.sh, запускающий asr server:
```lang="bash"
python3 /opt/vosk-server/websocket/asr_server.py /opt/vosk-model-ru/model &
```
А также начинает отлавливать появление файла corpus.txt в директории:
/opt/vosk-model-ru/model/new/data/corpus .
Для проброса корпуса нужно воспользоваться командой вида:
```lang="bash"
docker cp ./corpus.txt (container_id):/opt/vosk-model-ru/model/new/data/corpus
```
При этом за ходом обновления словаря можно следить по запущенным в контейнере процессам:
```lang="bash"
docker container top (container_id)
```
А также по логам:
```lang="bash"
docker logs -n 10 (container_id)
```
Или в собранном контейнере запускаем скрипт самостоятельно из командной строки, и получаем на консоль полный вывод.
Скрипт написан частично по описанному ниже, частично по данным [этой](https://habr.com/ru/company/cft/blog/558824/) публикации.

Для обновления 0.22 модели предлагается воспользоваться контейнером, использующим нативный пакет обновления:
[Dockerfile.kaldi-vosk-model-022-ru](https://github.com/va-stepanov/vosk-model-ru-adaptation/blob/main/Dockerfile.kaldi-vosk-model-022-ru),
[пакет обновления](https://alphacephei.com/vosk/models/vosk-model-ru-0.22-compile.zip)

```lang="bash"
git clone https://github.com/va-stepanov/vosk-model-ru-adaptation.git
cd vosk-model-ru-adaptation
docker build --file Dockerfile.kaldi-vosk-model-022-ru --tag alphacep/kaldi-vosk-model-022-ru:latest .
docker run -d -p 2722:2700 alphacep/kaldi-vosk-model-022-ru:latest
```
В данном примере обращаться нужно будет на 2722 порт хоста.

Последняя команда стартует скрипт /opt/vosk-model-ru-compile/update_corpus_022.sh, запускающий asr server:
```lang="bash"
python3 /opt/vosk-server/websocket/asr_server.py /opt/vosk-model-ru/model &
```
А также начинает отлавливать появление файла extra.txt в директории:
/opt/vosk-model-ru-compile/db .
Для проброса корпуса нужно воспользоваться командой вида: 
```lang="bash"
docker cp ./extra.txt (container_id):/opt/vosk-model-ru-compile/db
```
Использование контейнера на основе предложенного docker-файла сработает при отсутствии новых фонем.
## Подготовка

Для распознавания речи потребуется вебсокетный сервер на Kaldi и Vosk библиотека с моделью для русского языка. 
Подготовленная среда доступна из [Docker-образа](https://hub.docker.com/r/alphacep/kaldi-ru).
Изменим исходный образ так, чтобы остался закачиваемый движок и бинарники дополнительных инструментов, которые позволят проверить работу движка из командной строки. Пример, для 0.10 модели: [Dockerfile.kaldi-ext-ru](https://github.com/va-stepanov/vosk-model-ru-adaptation/blob/main/Dockerfile.kaldi-ext-ru).
Выполняем билд образа:
```lang="bash"
docker build --file Dockerfile.kaldi-ext-ru --tag alphacep/kaldi-ext-ru:latest .
```
Заходим внутрь образа:
```lang="bash"
sudo docker run -it -p 2700:2700 alphacep/kaldi-ext-ru:latest /bin/bash
```
Перемещаемся в директорию модели:
```lang="bash"
cd /opt/vosk-model-ru/model
```
Создаем папку new и размещаем в ней скрипты [decode_new.sh](https://github.com/va-stepanov/vosk-model-ru-adaptation/blob/main/decode_new.sh) и [path.sh](https://github.com/va-stepanov/vosk-model-ru-adaptation/blob/main/path.sh). Из контейнера:
```lang="bash"
mkdir new
```
с локального хоста:
```lang="bash"
sudo docker cp ./decode_new.sh (container_id):/opt/vosk-model-ru/model/new
sudo docker cp ./path.sh (container_id):/opt/vosk-model-ru/model/new
```
Для проверки работоспособности движка выполняем:
```lang="bash"
./new/decode_new.sh
```
Должны получить, что-то наподобие:\
...\
    decoder-test родион потапыч высчитывал каждой новой вершок углубления и давно определил про себя\
    ….\
    decoder-test 1 0.09 0.42 родион 1.00\
    decoder-test 1 0.51 0.78 потапыч 1.00\
    decoder-test 1 1.50 0.81 высчитывал 0.87\
    decoder-test 1 2.31 0.57 каждый 1.00\
    decoder-test 1 2.88 0.33 новый 1.00\
    …\
Возможно повление ошибки, если не хватит памяти.

## Описание

Для обновления словаря модели нужно обновить граф, для этого потребуется:
1) Подготовить лексикон в kaldi формате. Пример: words.txt

    журавлев\
    попов\
    пригожин\
    серебрянников\
    чичваркин\
    шестаков\
    щебуняев\
    щеглов

2) Подготовить общую языковую модуль интерполированную с предметной.
Есть разные [языковые модели](https://cmusphinx.github.io/wiki/tutoriallm/#language-models), говорящие о том, какую последовательность слов можно распознать. В этом примере, рассматривается статистическая языковая модель, основанная на вероятностной комбинаторике слов и их комбинаций.
Для построения языковой модели потребуется обученная модель произношения (g2p ), которая способна озвучить словарь. Возьмем готовую и с её помощью получим words.dic. Далее будем использовать [SRILM](https://github.com/BitSpeech/SRILM).

3) Собрать фонетический словарь.

4) Собрать и заменить имеющийся граф модели.

### Адаптация модели

Предположим, что в /opt/vosk-model-ru/model создана директория new, в которой будем располагать свои файлы.

/opt/vosk-model-ru/model/extra/db - в этой директории у нас должен располагаться словарь (ru.dic) и архивы исходной моделей (ru-small.lm.gz и ru.lm.gz).

#### Подготовка словаря

1) Подготавливаем corpus.txt, в котором вводим по предложению на строку или слово на строку.

2) Исполняем команду:
```lang="bash"
grep -oE "[А-Яа-я\\-]{3,}" corpus.txt | tr '[:upper:]' '[:lower:]' | sort | uniq > words.txt
```
либо, если tr не работает:
```lang="bash"
grep -oE "[А-Яа-я\\-]{3,}" corpus.txt | sed 's/[А-Я]/\L&/g' | sort | uniq > words.txt
```
В результате получим отсортированный набор уникальных слов `words.txt`. Возможны проблемы с обработкой кириллицы, проверям локализацию командой `locale -a`. Если в контейнере локализацию починить не удается, можно скопировать готовый файл с локального хоста.

#### Подготовка языковой модели

1) Устанавливаем программу [phonetisaurus](https://github.com/AdolfVonKleist/Phonetisaurus). 
Например, так:
```lang="bash"
pip install pybindgen phonetisaurus
```
Альтернативный вариант представлен в конце описания.

2) Качаем какую-нибудь g2p модель.
Например, её можно взять из нативного [пакета обновления](https://alphacephei.com/vosk/models/vosk-model-ru-0.10-compile.zip)
```lang="bash"
wget https://alphacephei.com/vosk/models/vosk-model-ru-0.10-compile.zip
unzip vosk-model-ru-0.10-compile.zip
cp /vosk-model-ru-0.10-compile/db/ru-g2p/ru.fst ./ru.dic.fst
```

3) Форматируем исходный словарь /opt/vosk-model-ru/model/extra/db/ru.dic
```lang="bash"
        cat /opt/vosk-model-ru/model/extra/db/ru.dic \
          | perl -pe 's/\([0-9]+\)//;
              s/\s+/ /g; s/^\s+//;
              s/\s+$//; @_ = split (/\s+/);
              $w = shift (@_);
              $_ = $w."\t".join (" ", @_)."\n";' \
          > ru.formatted.dic
```
Получаем файл `ru.formatted.dic`.

4) Генерируем произношения для нового словаря:
```lang="bash"
phonetisaurus-apply --model ./ru.dic.fst --word_list words.txt -l ru.formatted.dic > words.dic
```
Получаем файл `words.dic`. В случае ошибки `/usr/bin/env: 'python': No such file or directory` делаем симлинк: `ln -s /usr/bin/python3.7 /usr/bin/python`, проверив расположение python: `whereis python`.
g2p модель может не дать результата по отдельным словам. В этом случае можно использовать другую (натренировать свою) или воспользоваться скриптом: [dictionary.py](https://github.com/va-stepanov/vosk-model-ru-adaptation/blob/main/dictionary.py).

5) [Качаем](http://www.speech.sri.com/projects/srilm/download.html) SRILM утилиту ([зеркало](https://github.com/BitSpeech/SRILM/releases)) и устанавливаем по [инструкции](https://hovinh.github.io/blog/2016-04-22-install-srilm-ubuntu/).

Примерный порядок команд:
```lang="bash"
mkdir srilm
wget https://github.com/BitSpeech/SRILM/archive/refs/tags/1.7.3.tar.gz
mv 1.7.3.tar.gz ./srilm/
cd ./srilm/
tar xvf 1.7.3.tar.gz
cp -R ./SRILM-1.7.3/* ./
sed -i 's:# SRILM = /home/speech/stolcke/project/srilm/devel:SRILM = /opt/vosk-model-ru/model/new/srilm:g' Makefile
apt-get update
apt-get install tcsh
make NO_TCL=1 MACHINE_TYPE=i686-m64 World
#./bin/i686-m64/ngram-count -help
```

6) Компилируем языковую модель:
```lang="bash"
./bin/i686-m64/ngram-count -order 3 -limit-vocab -vocab ../words.txt -map-unk "" -kndiscount -interpolate -lm ../lm.arpa
```
в случае ошибки маленького словаря `one of required modified KneserNey count-of-counts is zero` необходимо опустить -kndiscount.
Получаем файл `/opt/vosk-model-ru/model/new/lm.arpa` примерно такого содержимого:
```lang="bash"
\data\
ngram 1=10
ngram 2=0
ngram 3=0

\1-grams:
-0.9542425	</s>
-99	<s>
-0.9542425	журавлев
-0.9542425	попов
-0.9542425	пригожин
-0.9542425	серебрянников
-0.9542425	чичваркин
-0.9542425	шестаков
-0.9542425	щебуняев
-0.9542425	щеглов

\2-grams:

\3-grams:

\end\
```
[arpa](https://cmusphinx.github.io/wiki/arpaformat/) [n-gram](https://www.w3.org/TR/ngram-spec/) [языковые модели](https://habr.com/ru/post/499064/) 

8) Выполняем слияние входных файлов (полученных и исходной модели):

Распаковываем файл языковой модели:
```lang="bash"
gunzip -k /opt/vosk-model-ru/model/extra/db/ru-small.lm.gz
```
Мержуем с помощью скрипта [mergedicts.py](https://github.com/va-stepanov/vosk-model-ru-adaptation/blob/main/mergedicts.py) из директории /opt/vosk-model-ru/model/new:
```lang="bash"
cd ..
python ./mergedicts.py ../extra/db/ru.dic ../extra/db/ru-small.lm words.dic lm.arpa merged-words.txt merged-lm.arpa
```
Скрипт делает простое "слияние" сущностей модели. При этом не меняется статистическая вероятность слов. Но, даже в этом случае, будет улучшение в распознавании новых слов/предложений.

#### Сборка фонетического словаря
О понятиях фонетического словаря и графа можно почитать [тут](http://jrmeyer.github.io/asr/2016/02/01/Kaldi-notes.html).

1) Подготовляем с помощью скрипта [dict_prep.sh](https://github.com/va-stepanov/vosk-model-ru-adaptation/blob/main/dict_prep.sh) директорию `data/local/dict` с файлами на основе нового словаря:

2) Собирам словарь:
```lang="bash"
mkdir dict dict_tmp
cd /opt/kaldi/egs/mini_librispeech/s5

phones_src=/opt/vosk-model-ru/model/graph/phones.txt
dict_src=/opt/vosk-model-ru/model/new/data/local/dict

dict=/opt/vosk-model-ru/model/new/dict
dict_tmp=/opt/vosk-model-ru/model/new/dict_tmp

./utils/prepare_lang.sh --phone-symbol-table $phones_src $dict_src "" $dict_tmp $dict
```
Получаем файл `/opt/vosk-model-ru/model/new/dict/L.fst`.

#### Обновление графа

Необходимо собрать новый HCLG.fst граф и заменить старый:
/opt/vosk-model-ru/model/graph/HCLG.fst

1) Подготавливаем входные файлы и переменные:
```lang="bash"
mkdir /opt/vosk-model-ru/model/new/lang

model=/opt/vosk-model-ru/model/am
lm_src=/opt/vosk-model-ru/model/new/merged-lm.arpa
 
lang=/opt/vosk-model-ru/model/new/lang
graph=/opt/vosk-model-ru/model/new/graph
```

2) Собираем грамматику (G.fst):
```lang="bash"
gzip $lm_src
utils/format_lm.sh $dict $lm_src.gz $dict_src/lexicon.txt $lang
```
Получаем файл `/opt/vosk-model-ru/model/new/lang/G.fst`.

3) Собираем HCLG граф:
```lang="bash"
cd /opt/vosk-model-ru/model/new
cp /opt/kaldi/egs/mini_librispeech/s5/utils/mkgraph.sh . 
./mkgraph.sh --self-loop-scale 1.0 $lang $model $graph
```
Получаем файл `/opt/vosk-model-ru/model/new/graph/HCLG.fst`.

4) Обновляем файлы rnnlm:
```lang="bash"
mkdir /opt/vosk-model-ru/model/new/rnnlm 

rnnlm=/opt/vosk-model-ru/model/new/rnnlm

cd /opt/kaldi/egs/wsj/s5
cat /dev/null > /opt/vosk-model-ru/model/rnnlm/unigram_probs.txt
/opt/vosk-model-ru/model/new/change_vocab.sh $graph/words.txt /opt/vosk-model-ru/model/rnnlm $rnnlm
cd $rnnlm
cat special_symbol_opts.txt | sed 's/\s\+/\n/g' | sed '/^$/d' > special_symbol_opts.conf
```

5) Для использования новой модели заменим исходные файлы:
```lang="bash"
mv $graph/HCLG.fst /opt/vosk-model-ru/model/graph/HCLG.fst
mv $graph/words.txt /opt/vosk-model-ru/model/graph/words.txt
mv $lang/G.fst /opt/vosk-model-ru/model/rescore/G.fst
mv $rnnlm/word_feats.txt /opt/vosk-model-ru/model/rnnlm/word_feats.txt
mv $rnnlm/feat_embedding.final.mat /opt/vosk-model-ru/model/rnnlm/feat_embedding.final.mat
mv $rnnlm/special_symbol_opts.conf /opt/vosk-model-ru/model/rnnlm/special_symbol_opts.conf
```
## Заметки
Каталоги rnnlm и rescore можно удалить. Будет быстрее, но менее точно.

Командой наподобие ниже можно построить конфигурацию декодирования, текущая строка сделает это в директорию new/conf:
```lang="bash"
steps/online/nnet3/prepare_online_decoding.sh --mfcc-config conf/mfcc_hires.conf $dict exp/nnet3/extractor exp/chain/tdnn_7b new
```
Для инсталирования srilm и Phonetisaurus, можно воспользоваться скриптами из директории /opt/kaldi/tools/extras/:
`install_srilm.sh` и `install_phonetisaurus.sh`.

При установке srilm с помощью скрипта:
```lang="bash"
./install_srilm.sh
```
При получении сообщения:
`This script cannot install SRILM in a completely automatic way because you need to put your address in a download form.`, необходимо:
- go to http://www.speech.sri.com/projects/srilm/download.html

- download srilm...

- put file in ./tools/srilm.tgz (it should be renamed)

```lang="bash"
sudo apt-get install gawk

./install_srilm.sh
```
При ручной установке phonetisaurus:
Возможно, потребуется установить и OpenFst-1.6.2, так как с предустановленной в образе OpenFst-1.8.0 на май 2021 проблемы в [совместимости компиляторов](https://www.gnu.org/software/autoconf/manual/autoconf-2.69/html_node/Present-But-Cannot-Be-Compiled.html).

```lang="bash"
wget http://www.openfst.org/twiki/pub/FST/FstDownload/openfst-1.6.2.tar.gz
tar -xvzf openfst-1.6.2.tar.gz
cd openfst-1.6.2
// Minimal configure, compatible with current defaults for Kaldi
./configure --enable-static --enable-shared --enable-far --enable-ngram-fsts
make -j 4
// Now wait a while...
make install
cd
#Extend your LD_LIBRARY_PATH .bashrc:
echo 'export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib:/usr/local/lib/fst' \
     >> ~/.bashrc
source ~/.bashrc
```
Получаем путь:
/opt/vosk-model-ru/model/new/openfst-1.6.2

Для установки phonetisaurus:
```lang="bash"
git clone https://github.com/AdolfVonKleist/Phonetisaurus.git
cd Phonetisaurus
./configure --with-openfst-libs=/opt/vosk-model-ru/model/new/openfst-1.6.2/src/lib \
         --with-openfst-includes=/opt/vosk-model-ru/model/new/openfst-1.6.2/src/include
make -j 2 all
make install
```
либо с python3 зависимостями:
```lang="bash"
git clone https://github.com/AdolfVonKleist/Phonetisaurus.git
cd Phonetisaurus
pip3 install pybindgen
PYTHON=python3 ./configure --enable-python
make
make install
cd python
cp ../.libs/Phonetisaurus.so .
python3 setup.py install
```
Получаем путь:
/opt/vosk-model-ru/model/new/Phonetisaurus

Для запуска модели изнутри, возращаемся в директорию `/opt/vosk-server/websocket` и выполняем команду:

```lang="bash"
python3 ./asr_server.py /opt/vosk-model-ru/model
```
