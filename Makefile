Options := -os windows -prod -enable-globals -cflags $(shell pwd)/resources/rpv-web.res
DebugOptions := ${Options} -d debug
Resources := resources/rpv-web.rc resources/rpv-web.res

rpv-web-x64 x64: ${Resources}
	v ${Options} . -o ${@}.exe

rpv-web-x64-debug debug: ${Resources}
	v ${DebugOptions} . -o ${@}.exe

rpv-web-x86 x86: ${Resources}
	v -m32 ${Options} . -o ${@}.exe

rpv-web-x86-debug x86-debug: ${Resources}
	v -m32 ${DebugOptions} . -o ${@}.exe

resources/rpv-web.rc:
	bash resources/adjust.sh
	x86_64-w64-mingw32-windres resources/rpv-web.rc -O coff -o resources/rpv-web.res

clean:
	rm -f *.exe ${Resources}
