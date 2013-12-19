CXXFLAGS += -std=c++11 -I ../
VPATH = ..

.PHONY: all clean

tests = test_json

all: $(tests)
	@for t in $(tests); do \
            echo $$t;          \
            ./$$t;             \
        done

clean:
	-rm *.o
	-rm $(tests)

test_json: test_json.o libebt.a
	$(CXX) $(CXXFLAGS) -o $@ $^
