CXXFLAGS += -std=c++11 -I ../../
VPATH = ..

.PHONY: all clean

tests = test_json \
    test_map \
    test_zip \
    test_range \
    test_hashmap

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

test_map: test_map.o libebt.a
	$(CXX) $(CXXFLAGS) -o $@ $^

test_zip: test_zip.o libebt.a
	$(CXX) $(CXXFLAGS) -o $@ $^

test_range: test_range.o libebt.a
	$(CXX) $(CXXFLAGS) -o $@ $^

test_hashmap: test_hashmap.o libebt.a
	$(CXX) $(CXXFLAGS) -o $@ $^
