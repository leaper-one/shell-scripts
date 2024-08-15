#!/bin/bash

# 该脚本需要搭配 standard-version 使用
# 安装 standard-version: npm install --save-dev standard-version
# 参考：https://juejin.cn/post/7359203560166768650#heading-42

# 使用方法说明
usage() {
  echo "Usage: $0 [-b <branch name>] [-t <tag type>]"
  echo "  -b <branch name>       Branch name to tag from. Default is 'main'."
  echo "  -t <tag type>          Tag type: major, minor, patch. Default is 'patch'."
  exit 1
}

# 默认值
branch="main"
tag_type="patch"

# 解析命令行参数
while getopts ":b:t:" opt; do
  case ${opt} in
    b )
      branch=$OPTARG
      ;;
    t )
      tag_type=$OPTARG
      ;;
    \? )
      usage
      ;;
  esac
done

# 切换到指定分支并更新
git checkout "$branch"
git pull
git fetch --tags

# 记录当前的版本、标签和未推送的提交
original_version=$(npm pkg get version | tr -d '"')
original_tag=$(git tag --sort=-creatordate | head -n 1)
uncommitted_files=$(git status --porcelain | awk '{print $2}')

# 计算新版本号
IFS='.' read -r major minor patch <<< "$original_version"
case $tag_type in
  major)
    major=$((major + 1))
    minor=0
    patch=0
    ;;
  minor)
    minor=$((minor + 1))
    patch=0
    ;;
  patch)
    patch=$((patch + 1))
    ;;
  *)
    echo "未知的标签类型: $tag_type"
    exit 1
    ;;
esac

new_version="$major.$minor.$patch"
new_tag="v-$new_version"

# 打印新版本和标签
echo "原始版本: $original_version"
echo "生成的新版本: $new_version"
echo "生成的标签: $new_tag"

# 提示用户确认
read -p "确认要更新到新版本 '$new_version' 并生成标签 '$new_tag' 吗？(Y/n): " confirm

# 默认情况下选择 "Y"
confirm=${confirm:-Y}

if [[ $confirm =~ ^[Yy]$ ]]; then
  # 使用 standard-version 发布新版本
  pnpm run release -- --release-as $new_version

  # 提交并推送标签到远程仓库
  git push --follow-tags origin "$branch"
  echo "标签 '$new_tag' 已提交并推送到远程仓库。"
else
  echo "操作已取消。"
  
  # # 恢复到原始版本
  # npm pkg set version="$original_version"
  
  # # 撤销未推送的提交
  # git reset --hard HEAD~1

  # # 还原未提交的文件
  # if [[ -n $uncommitted_files ]]; then
  #   git checkout -- $uncommitted_files
  # fi
  
  # echo "状态已恢复到之前的版本。"
fi
