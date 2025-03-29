RC := resources/rpv-web.rc
RES := resources/rpv-web.res
ICON := resources/rpv-web.ico
ICON86 := resources/rpv-web-x86.ico
ICON64 := resources/rpv-web-x64.ico
Options := -os windows -prod -cflags $(shell pwd)/${RES}
DebugOptions := ${Options} -d debug

rpv-web-x64 x64: ${RC}
	cp ${ICON64} ${ICON}
	x86_64-w64-mingw32-windres ${RC} -O coff -o ${RES}
	v ${Options} . -o ${@}.exe

rpv-web-x64-debug debug: ${RC}
	cp ${ICON64} ${ICON}
	x86_64-w64-mingw32-windres ${RC} -O coff -o ${RES}
	v ${DebugOptions} . -o ${@}.exe

rpv-web-x86 x86: ${RC}
	cp ${ICON86} ${ICON}
	i686-w64-mingw32-windres ${RC} -O coff -o ${RES}
	v -m32 ${Options} . -o ${@}.exe

rpv-web-x86-debug x86-debug: ${RC}
	cp ${ICON86} ${ICON}
	i686-w64-mingw32-windres ${RC} -O coff -o ${RES}
	v -m32 ${DebugOptions} . -o ${@}.exe

resources/rpv-web.rc:
	bash resources/adjust.sh > ${RC}

clean:
	rm -f *.exe ${RC} ${RES}
