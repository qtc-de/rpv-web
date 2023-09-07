Options := -os windows -enable-globals
DebugOptions := ${Options} -d debug

rpv-web-x64 x64:
	v ${Options} . -o ${@}.exe

rpv-web-x64-debug debug:
	v ${DebugOptions} . -o ${@}.exe

rpv-web-x86 x86:
	v -m32 ${Options} . -o ${@}.exe

rpv-web-x86-debug x86-debug:
	v -m32 ${DebugOptions} . -o ${@}.exe

clean:
	rm -f *.exe
