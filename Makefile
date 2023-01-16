#Pasat Ionut 334CC
build:
	flex -o tema.cpp tema.l
	g++ tema.cpp -o tema
run: 
	./tema input
.PHONY clean:
	rm -f tema tema.cpp
