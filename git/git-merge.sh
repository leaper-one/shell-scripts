#!/bin/bash

# 使用方法说明
usage() {
  echo "Usage: $0 [-s <source branch>] [-d <destination branch>] [-a]"
  echo "  -s <source branch>      The source branch you want to merge from. Default is 'dev'."
  echo "  -d <destination branch> The destination branch you want to merge into. Default is 'main'."
  echo "  -a                      Automatically resolve merge conflicts by preferring source branch's changes."
  exit 1
}

# 设置默认分支
SOURCE_BRANCH="dev"
DEST_BRANCH="main"
AUTO_RESOLVE_CONFLICTS=false

# 解析命令行参数
while getopts ":s:d:a" opt; do
  case ${opt} in
    s )
      SOURCE_BRANCH=$OPTARG
      ;;
    d )
      DEST_BRANCH=$OPTARG
      ;;
    a )
      AUTO_RESOLVE_CONFLICTS=true
      ;;
    \? | * )
      usage
      ;;
  esac
done

# 切换到目标分支
git checkout "$DEST_BRANCH"

# 拉取最新的目标分支更改
git pull origin "$DEST_BRANCH"

# 尝试合并源分支
if ! git merge --squash "$SOURCE_BRANCH"; then
  if [ "$AUTO_RESOLVE_CONFLICTS" = true ]; then
    echo "Resolving merge conflicts, preferring changes from $SOURCE_BRANCH..."

    # 获取所有冲突的文件
    conflicted_files=$(git diff --name-only --diff-filter=U)

    # 对每个有冲突的文件使用源分支的版本
    for file in $conflicted_files; do
      git checkout --theirs "$file"
      git add "$file"
    done

    # 现在所有冲突应该都解决了，可以提交合并
    git commit -m "Merge branch '$SOURCE_BRANCH' into '$DEST_BRANCH', resolving conflicts by preferring '$SOURCE_BRANCH''s changes."
  else
    echo "Merge conflicts detected. Please resolve them manually."
    exit 1
  fi
fi

# 将合并后的更改推送到远程目标分支
# git push origin "$DEST_BRANCH"
