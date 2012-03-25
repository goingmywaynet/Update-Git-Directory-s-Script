#! /bin/bash

#
# Auto git update tool
#  2011/06/05 Ver:1.3 joey chen
#

#
# check depend commands
#
_dependCommands="git expect"
for _COMMAND in ${_dependCommands}; do
 if [ ! `whereis ${_COMMAND} |grep ${_COMMAND}` ]; then
  echo "ERROR!! 必要なコマンドが見つかりません : ${_COMMAND}"
  exit 1
 fi
done

#
# check args
#
if [ $# -eq 0 ]; then
  cat <<_EOF_

  Auto git pull/push Tool 

  実行中のディレクトリ配下にある複数あるgitディレクトリを一気に
  更新(commit/pull/push)するツールです。
  
  使い方
   sh ./updateGit.sh [commit|pull|push|status] [remote name] [branch name]
    各ディレクトリの ./*/.git を探して、有る場合に指定の git のコマンドを実行します。
    オプションは以下のいずれかを選ぶ必要があります。
    commit : 自動で add を実行してから commit します。
    status : git status 処理を実施します。
    pull   : 自動で 指定した remote からpullします。初回のみパスワード入力を促されます。
    push   : 自動で 指定した remote からpushします。初回のみパスワード入力を促されます。
    ※ branch name を指定していない場合は、自動で master で処理します。

_EOF_
  exit 1
fi

#
# check args 2nd
#
if [ \( $1 != 'pull' \) -a \( $1 != 'push' \) -a \( $1 != 'commit' \) -a \( $1 != 'status' \) ]; then
  echo "ERROR!! 正しい引数を指定してください。"
  exit 1
fi

if [ \( \( $1 = 'pull' \) -o \( $1 = 'push' \) \) -a \( $# -eq 1 \) ]; then
  echo "ERROR!! push か pull を実行する際は、第２引数(remote 識別子)を指定してください。"
  exit 1
fi


#
# Get git dirs
#
_GITDIRS=`find . -type d -name ".git" | sed "s/\(\.\/.*\)\/.git/\1/g"`

#
# show status
#
if [ $1 == 'status' ]; then
  for _DIRS in ${_GITDIRS}; do
    echo -e "\n  -- ${_DIRS} -- ";
    cd $_DIRS;
    git status;
    cd ../
  done
fi


#
# Update Git Dirs
#

## COMMIT
if [ $1 == 'commit' ]; then
  # update dirs
  for _DIRS in ${_GITDIRS}; do
    echo -e "\n  -- ${_DIRS} -- ";
    cd $_DIRS;
     git add -u;
     git add .;
     git commit -m "auto Update by Script at `date`";
    cd ../
  done
fi

## PUSH or PULL
if [ \( $1 == 'push' \) -o \( $1 == 'pull' \) ]; then
  if [ $# -eq 2 ]; then
    _COMMAND=$1
    _REMOTE=$2
    _BRANCH="master"
  fi
  if [ $# -eq 3 ]; then
    _COMMAND=$1
    _REMOTE=$2
    _BRANCH=$3
  fi
  # get password
  stty -echo
  read -p "Password: " _PW; echo
  stty echo

  # update dirs
  for _DIRS in ${_GITDIRS}; do 
    echo -e "\n  -- ${_DIRS} -- ";
    cd $_DIRS;
    expect -c "
      set timeout 10
      spawn git ${_COMMAND} ${_REMOTE} ${_BRANCH}
      expect password:\  ; send \"${_PW}\r\"
      interact
    "
    cd ../
  done
fi
