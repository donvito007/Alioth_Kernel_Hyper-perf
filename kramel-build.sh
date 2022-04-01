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
KBUILD_COMPILER_STRING=$(clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
KBUILD_LINKER_STRING=$(clang/bin/ld.lld --version  | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//' | sed 's/(compatible with [^)]*)//')

# Set Kernel Version
KERNELVER=$(make kernelversion)

# Include argument
ARGS="ARCH=arm64 \
        O=out \
        LLVM=1 \
	CC=clang \
	LOCALVERSION=-${TANGGAL} \
        CLANG_TRIPLE=aarch64-linux-gnu- \
        CROSS_COMPILE=aarch64-linux-android- \
        CROSS_COMPILE_COMPAT=arm-linux-androideabi- \
        -j48"

# Build Kernel
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_HOST="android"
export KBUILD_BUILD_USER="ricoayuba"
export KBUILD_COMPILER_STRING
export KBUILD_LINKER_STRING
#main group
export chat_id="-1001726996867"
#channel
export chat_id2="-1001608547174"
export DEF="vendor/alioth_defconfig"
TC_DIR=${PWD}
GCC64_DIR="${PWD}/gcc64"
GCC32_DIR="${PWD}/gcc32"
export PATH="${PWD}/clang/bin:$GCC64_DIR/bin:$GCC32_DIR/bin:${PATH}"

# Post to CI channel
curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d text="Buckle up bois HyperX kernel build has started" -d chat_id=${chat_id} -d parse_mode=HTML
curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d text="Branch: <code>$(git rev-parse --abbrev-ref HEAD)</code>
Kernel Version : <code>${KERNELVER}</code>
Compiler Used : <code>${KBUILD_COMPILER_STRING}</code>
Latest Commit: <code>$(git log --pretty=format:'%h : %s' -1)</code>
Starting..." -d chat_id=${chat_id} -d parse_mode=HTML

# make defconfig
    make -j48 ${ARGS} ${DEF}

# Make olddefconfig
cd out || exit
make -j48 ${ARGS} olddefconfig
cd ../ || exit

# compiling
    make -j$(nproc --all) ${ARGS} 2>&1 | tee build.log

END=$(date +"%s")
DIFF=$((END - START))

if [ -f $(pwd)/out/arch/arm64/boot/Image ]
	then
	curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d text="<i>Build compiled successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</i>" -d chat_id=${chat_id} -d parse_mode=HTML
        cp ${IMAGE} $(pwd)/AnyKernel3
        cp ${DTBO} $(pwd)/AnyKernel3
        cd AnyKernel3
        zip -r9 HyperX-perf-${TANGGAL}.zip * --exclude *.jar

        curl -F chat_id="${chat_id}"  \
                    -F caption="sha1sum: $(sha1sum Hyp*.zip | awk '{ print $1 }')" \
                    -F document=@"$(pwd)/HyperX-perf-${TANGGAL}.zip" \
                    https://api.telegram.org/bot${TOKEN}/sendDocument

        curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d text="hi guys, the latest update is available on @HyperX_Archive !" -d chat_id=${chat_id2} -d parse_mode=HTML

cd ..
else
        curl -F chat_id="${chat_id}"  \
                    -F caption="Build ended with an error !!" \
                    -F document=@"build.log" \
                    https://api.telegram.org/bot${TOKEN}/sendDocument

fi
