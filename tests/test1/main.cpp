#include <iostream>
#include <fstream>
#include <iomanip>
#include <string>
#include "test1.pb.h"
using namespace std;

static void printObj(string seq)
{
	unsigned int zero = 0;
	for (int i = 0; i < seq.length(); i++) {
		zero |= uint8_t(seq[i]);
		cout << hex << zero << " ";
		zero = 0;
	}
	cout << endl;
}

int main()
{
	GOOGLE_PROTOBUF_VERIFY_VERSION;
	tutorial::Test1 t1;
	t1.set_id(42);
	t1.set_name("Rohan");

	printObj(t1.SerializeAsString());
	return 0;
}