#!/bin/bash

echo "🚀 PrismNg 启动脚本"
echo "===================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 清理
echo -e "${YELLOW}步骤 1: 清理旧的构建文件...${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/prismNg-*/
killall xcodebuild 2>/dev/null

# 2. 检查模拟器
echo -e "${YELLOW}步骤 2: 检查模拟器状态...${NC}"
DEVICE_ID=$(xcrun simctl list devices | grep "iPhone 16 Pro" | grep -v "Max" | head -1 | grep -o "[A-F0-9\-]*" | head -1)

if [ -z "$DEVICE_ID" ]; then
    echo -e "${RED}错误: 找不到 iPhone 16 Pro 模拟器${NC}"
    exit 1
fi

echo "找到设备: $DEVICE_ID"

# 3. 启动模拟器
echo -e "${YELLOW}步骤 3: 启动模拟器...${NC}"
xcrun simctl boot $DEVICE_ID 2>/dev/null || echo "模拟器已启动"
open -a Simulator

# 4. 构建项目
echo -e "${YELLOW}步骤 4: 构建项目...${NC}"
xcodebuild -project prismNg.xcodeproj \
           -scheme prismNg \
           -destination "id=$DEVICE_ID" \
           -configuration Debug \
           build

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 构建成功！${NC}"
    
    # 5. 安装应用
    echo -e "${YELLOW}步骤 5: 安装应用到模拟器...${NC}"
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/prismNg-*/Build/Products -name "prismNg.app" -type d | head -1)
    
    if [ -n "$APP_PATH" ]; then
        xcrun simctl install $DEVICE_ID "$APP_PATH"
        echo -e "${GREEN}✅ 安装成功！${NC}"
        
        # 6. 启动应用
        echo -e "${YELLOW}步骤 6: 启动应用...${NC}"
        xcrun simctl launch $DEVICE_ID com.panfeng.prismNg
        
        echo -e "${GREEN}🎉 PrismNg 已启动！${NC}"
        echo ""
        echo "提示："
        echo "- 在模拟器中测试所有功能"
        echo "- 查看 Xcode 控制台了解调试信息"
        echo "- 按 Command+S 截图"
    else
        echo -e "${RED}错误: 找不到构建的应用${NC}"
    fi
else
    echo -e "${RED}❌ 构建失败！${NC}"
    echo "请在 Xcode 中打开项目查看详细错误："
    echo "open prismNg.xcodeproj"
fi