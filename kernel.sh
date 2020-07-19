#!/usr/bin/env bash
# Circle CI/CD - Simple kernel build script
# Copyright (C) 2019, 2020, Raphielscape LLC (@raphielscape)
# Copyright (C) 2019, 2020, Dicky Herlambang (@Nicklas373)
# Copyright (C) 2020, Muhammad Fadlyas (@fadlyas07)
git clone --depth=1 https://github.com/anggialansori404/anykernel-3
git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-9.0.0_r49 gcc
git clone --depth=1 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b android-9.0.0_r49 gcc32
git clone --depth=1 https://github.com/fabianonline/telegram.sh telegram
mkdir $(pwd)/temp
export parse_branch=$(git rev-parse --abbrev-ref HEAD)
export device="Xiaomi Redmi 5A"
export config_device=riva_defconfig
export ARCH=arm64
export TEMP=$(pwd)/temp
export TELEGRAM_TOKEN=$token
export pack=$(pwd)/anykernel-3
export product_name=Element
export KBUILD_BUILD_USER=Anggialansori
export KBUILD_BUILD_HOST=WarBoss
export kernel_img=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
export TELEGRAM_ID=$chat_id
tg_sendstick() {
   curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker" \
	-d sticker="CAACAgUAAx0CS4p2tAACAUNe-yNggJ4EEV-rwHK7NJ2ot-7ZQAAC9AADwZuBCDz6W81nGewzGgQ" \
	-d chat_id="$TELEGRAM_ID"
}
tg_channelcast() {
    curl -s -X POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage -d chat_id=$TELEGRAM_ID -d "disable_web_page_preview=true" -d "parse_mode=html" -d text="$(
           for POST in "$@"; do
               echo "$POST"
           done
    )"
}
build_start=$(date +"%s")
date=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
make ARCH=arm64 O=out "$config_device" && \
PATH=$(pwd)/gcc/bin:$(pwd)/gcc32/bin:$PATH \
make -j$(nproc) O=out \
                    ARCH=arm64 \
                    CROSS_COMPILE=aarch64-linux-android- \
                    CROSS_COMPILE_ARM32=arm-linux-androideabi- 
              
if ! [[ -f "$kernel_img" ]]; then
    build_end=$(date +"%s")
    build_diff=$(($build_end - $build_start))
    grep -iE 'not|empty|in file|waiting|crash|error|fail|fatal' "$(echo $TEMP/*.log)" &> "$TEMP/trimmed_log.txt"
    curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
    curl -F document=@$(echo $TEMP/*.txt) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
    tg_channelcast "<b>$product_name</b> for <b>$device</b> on branch '<b>$parse_branch</b>' Build errors in $(($build_diff / 60)) minutes and $(($build_diff % 60)) seconds."
    exit 1
fi
curl -F document=@$(echo $TEMP/*.log) "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="784548477"
mv $kernel_img $pack/zImage && cd $pack
zip -r9q $product_name-$parse_branch-riva-$date.zip * -x .git README.md LICENCE $(echo *.zip)
cd ..
build_end=$(date +"%s")
build_diff=$(($build_end - $build_start))
kernel_ver=$(cat $(pwd)/out/.config | grep Linux/arm64 | cut -d " " -f3)
toolchain_ver=$(cat $(pwd)/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
tg_sendstick
tg_channelcast "⚠️ <i>Warning: New build is available!</i> working on <b>$parse_branch</b> in <b>Linux $kernel_ver</b> using <b>$toolchain_ver</b> for <b>$device</b> at commit <b>$(git log --pretty=format:'%s' -1)</b> build complete in $(($build_diff / 60)) minutes and $(($build_diff % 60)) seconds."
curl -F document=@$pack/$product_name-$parse_branch-riva-$date.zip "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" -F chat_id="$TELEGRAM_ID"
