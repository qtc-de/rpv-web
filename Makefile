RC := resources/rpv-web.rc
RES := resources/rpv-web.res
Options := -os windows -prod -enable-globals -cflags $(shell pwd)/${RES}
DebugOptions := ${Options} -d debug

rpv-web-x64 x64: ${RC}
	x86_64-w64-mingw32-windres ${RC} -O coff -o ${RES}
	v ${Options} . -o ${@}.exe

rpv-web-x64-debug debug: ${RC}
	x86_64-w64-mingw32-windres ${RC} -O coff -o ${RES}
	v ${DebugOptions} . -o ${@}.exe

rpv-web-x86 x86: ${RC}
	i686-w64-mingw32-windres ${RC} -O coff -o ${RES}
	v -m32 ${Options} . -o ${@}.exe

rpv-web-x86-debug x86-debug: ${RC}
	i686-w64-mingw32-windres ${RC} -O coff -o ${RES}
	v -m32 ${DebugOptions} . -o ${@}.exe

resources/rpv-web.rc:
	bash resources/adjust.sh > ${RC}

clean:
	rm -f *.exe ${RC} ${RES}
