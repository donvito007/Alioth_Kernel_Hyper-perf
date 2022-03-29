git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 gcc64
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 gcc32
git clone --depth=1 https://github.com/Farizmaul/android_prebuilts_clang_host_linux-x86_clang-r437112 clang
git clone --depth=1 https://github.com/farizmaul/AnyKernel3.git

IMAGE=$(pwd)/out/arch/arm64/boot/Image
DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img
START=$(date +"%s")
BRANCH=$(git rev-parse --abbrev-ref HEAD)
VERSION=perf
TANGGAL=$(TZ=Asia/Jakarta date "+%Y%m%d-%H%M")
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_HOST="android"
export KBUILD_BUILD_USER="ricoayuba"
#main group
export chat_id="-1001726996867"
#channel
export chat_id2="-1001608547174"
export DEF="vendor/alioth_defconfig"
TC_DIR=${PWD}
GCC64_DIR="${PWD}/gcc64"
GCC32_DIR="${PWD}/gcc32"
export PATH="${PWD}/clang/bin:$GCC64_DIR/bin:$GCC32_DIR/bin:${PATH}"
curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d text="Buckle up bois livina-perf build has started" -d chat_id=${chat_id} -d parse_mode=HTML

# make defconfig
    make ARCH=arm64 \
        O=out \
        $DEF \
        -j"$(nproc --all)"

# make olddefconfig
cd out
make O=out \
	ARCH=arm64 \
	olddefconfig
cd ../

# compiling
    make -j$(nproc --all) O=out \
				ARCH=arm64 \
				AR=llvm-ar \
				OBJDUMP=llvm-objdump \
				STRIP=llvm-strip \
				CC=clang \
				LOCALVERSION=-${TANGGAL} \
				CLANG_TRIPLE=aarch64-linux-gnu- \
				CROSS_COMPILE=aarch64-linux-android- \
				CROSS_COMPILE_ARM32=arm-linux-androideabi- \
				LD=ld.lld 2>&1 | tee build.log

END=$(date +"%s")
DIFF=$((END - START))

if [ -f $(pwd)/out/arch/arm64/boot/Image ]
	then
# Post to CI channel
curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d text="Branch: <code>$(git rev-parse --abbrev-ref HEAD)</code>
Compiler Used : <code>AOSP Clang 14.0.0 (based on r437112) LLD 14.0.0</code>
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code>
<i>Build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</i>" -d chat_id=${chat_id} -d parse_mode=HTML

cp ${IMAGE} $(pwd)/AnyKernel3
cp ${DTBO} $(pwd)/AnyKernel3

        cd AnyKernel3
        zip -r9 livina-perf-${TANGGAL}.zip * --exclude *.jar

        curl -F chat_id="${chat_id}"  \
                    -F caption="sha1sum: $(sha1sum Hyp*.zip | awk '{ print $1 }')" \
                    -F document=@"$(pwd)/livina-perf-${TANGGAL}.zip" \
                    https://api.telegram.org/bot${TOKEN}/sendDocument

        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendSticker" \
        -d sticker="CAACAgUAAxkBAAJi017AAw5j25_B3m8IP-iy98ffcGHZAAJAAgACeV4XIusNfRHZD3hnGQQ" \
        -d chat_id="$chat_id"

	curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d text="hi guys, the latest update is available on @HyperX_Archive !" -d chat_id=${chat_id2} -d parse_mode=HTML

cd ..
else
        curl -F chat_id="${chat_id}"  \
                    -F caption="Build ended with an error, F in the chat plox" \
                    -F document=@"build.log" \
                    https://api.telegram.org/bot${TOKEN}/sendDocument

        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendSticker" \
        -d sticker="CAACAgUAAxkBAAK74mCvV3W62vmSIcqQo61RtBxEK0dVAALGAgACw2B4VehbCiKmZwTjHwQ" \
        -d chat_id="$chat_id"

fi
