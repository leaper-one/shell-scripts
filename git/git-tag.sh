#!/bin/bash

# 使用方法说明
usage() {
  echo "Usage: $0 [-m <commit message>] [-b <branch name>] [-p <tag prefix>] [-t <tag type>]"
  echo "  -m <commit message>    Commit message for the tag."
  echo "  -b <branch name>       Branch name to tag from. Default is 'main'."
  echo "  -p <tag prefix>        Tag prefix. Default is 'v-'. Set to '' for no prefix."
  echo "  -t <tag type>          Tag type: major, minor, patch. Default is 'patch'."
  exit 1
}

# 默认值
branch="main"
prefix="v-"
tag_type="patch"
message=""

# 解析命令行参数
while getopts ":m:b:p:t:" opt; do
  case ${opt} in
    m )
      message=$OPTARG
      ;;
    b )
      branch=$OPTARG
      ;;
    p )
      prefix=$OPTARG
      ;;
    t )
      tag_type=$OPTARG
      ;;
    \? )
      usage
      ;;
  esac
done

# 检查必要的参数
if [ -z "$message" ]; then
    echo "Commit message (-m) is required"
    usage
fi

git checkout "$branch"

git push

git fetch --tags
# 获取最新的标签名并赋值给变量tag
tag=$(git fetch --tags && git tag --sort=-creatordate | grep "^$prefix" | head -n 1)

# 打印原始标签
echo "原始标签: $tag"

# 使用正则表达式分离版本号。假设标签格式为前缀-主版本号.次版本号.小版本号
regex="$prefix([0-9]+)\.([0-9]+)\.([0-9]+)"
if [[ $tag =~ $regex ]]; then
    major=${BASH_REMATCH[1]}
    minor=${BASH_REMATCH[2]}
    patch=${BASH_REMATCH[3]}

    # 根据 tag_type 递增版本号
    case $tag_type in
      major)
        new_tag="${prefix}$((major + 1)).0.0"
        ;;
      minor)
        new_tag="${prefix}${major}.$((minor + 1)).0"
        ;;
      patch)
        new_tag="${prefix}${major}.${minor}.$((patch + 1))"
        ;;
      *)
        echo "未知的标签类型: $tag_type"
        exit 1
        ;;
    esac

    # 打印新的标签
    echo "新的标签: $new_tag"
else
    echo "标签格式不匹配"
    exit 1
fi

git tag -a "$new_tag" -m "$message"

git push origin --tags
