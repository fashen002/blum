#!/bin/bash

# 检查参数个数
if [ "$#" -lt 3 ] || [ "$#" -gt 5 ]; then
    echo "Usage: $0 <json_file> <key> <access_token> <refresh_token> [<operation>]"
    exit 1
fi

# 参数
JSON_FILE=$1
KEY=$2
ACCESS=$3
REFRESH=$4
OPERATION=${5:-"update"}  # 默认操作为 "update"，也可以设置为 "add" 或 "delete"

# 检查 jq 是否已安装
if ! command -v jq &> /dev/null; then
    echo "jq command not found. Please install jq to use this script."
    exit 1
fi

# 读取现有 JSON 文件
if ! [ -f "$JSON_FILE" ]; then
    echo "File not found: $JSON_FILE"
    exit 1
fi

# 输出调试信息
echo "Operation: $OPERATION"
echo "Key: $KEY"
echo "Access: $ACCESS"
echo "Refresh: $REFRESH"

# 根据操作类型进行处理
case "$OPERATION" in
    add)
        # 添加新的键值对
        jq --arg key "$KEY" --arg newAccess "$ACCESS" --arg newRefresh "$REFRESH" '
            .[$key] = { access: $newAccess, refresh: $newRefresh }
        ' "$JSON_FILE" > tmp.json
        if [ $? -eq 0 ]; then
            mv tmp.json "$JSON_FILE"
            echo "Added $KEY in $JSON_FILE"
        else
            echo "Error during add operation"
            exit 1
        fi
        ;;
    update)
        # 更新现有键值对
        jq --arg key "$KEY" --arg newAccess "$ACCESS" --arg newRefresh "$REFRESH" '
            .[$key].access = $newAccess |
            .[$key].refresh = $newRefresh
        ' "$JSON_FILE" > tmp.json
        if [ $? -eq 0 ]; then
            mv tmp.json "$JSON_FILE"
            echo "Updated $KEY in $JSON_FILE"
        else
            echo "Error during update operation"
            exit 1
        fi
        ;;
    delete)
        # 删除指定键值对
        jq --arg key "$KEY" '
            del(.[$key])
        ' "$JSON_FILE" > tmp.json
        if [ $? -eq 0 ]; then
            # Verify if tmp.json is correctly created and non-empty
            if [ -s tmp.json ]; then
                mv tmp.json "$JSON_FILE"
                echo "Deleted $KEY from $JSON_FILE"
            else
                echo "Error: Resulting JSON is empty. No changes made."
                rm tmp.json
                exit 1
            fi
        else
            echo "Error during delete operation"
            exit 1
        fi
        ;;
    *)
        echo "Invalid operation: $OPERATION"
        echo "Valid operations are: add, update, delete"
        exit 1
        ;;
esac

