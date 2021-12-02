#include <iostream>
#include <fstream>
#include <string>
#include <sstream>

using namespace std;

int main(int argc, char** argv)
{
    uint64_t part1 = 0;
    std::string part2;

    uint64_t input = 0;
    bool nested = false;

    ofstream myfile;
    if (argc != 2)
    {
        cout << "Provide filename argument" << endl;
    }

    string filename = argv[1];
    myfile.open(filename);

    stringstream ss;

    do
    {
        part1 = 0;
        part2 = "";
        input = 0;
        nested = false;
        ss.str(std::string());

        cout << "Field ID: ";
        cin >> input;
        // Send lower 29 bits of input to upper 29 bits of part1
        part1 |= ((0x1fffffff & input) << 35);


        input = 0;
        cout << "Wire type: ";
        cin >> input;
        // Set bits 34 to 30 of part1 to lower 5 bits of input
        part1 |= ((0x1f & input) << 30);

        input = 0;
        cout << "Offset: ";
        cin >> input;
        // Set bits 29 to 16 of part1 to lower 14 bits of input
        part1 |= ((0x3fff & input) << 16);

        input = 0;
        cout << "Size: ";
        cin >> input;
        // Set bits 15 to 1 of part1 to lower 15 bits of input
        part1 |= ((0x7fff & input) << 1);

        input = 0;
        cout << "Nested?: ";
        cin >> input;
        // Set bit 0 of part1 to input
        part1 |= (0x1 & input);

        if (input)
        {
            nested = true;
            input = 0;
            cout << "Nested Table Address: ";
            cin >> part2;
        }

        cout << "final value: " << hex << part1 << endl;

        ss << hex << part1; 
        string s = ss.str();
        int missing_zeros = 16 - s.length();
        string z = "";
        for (int i = 0; i < missing_zeros; i++)
        {
            z += "0";
        }

        s = z + s;
        for (int i = s.length()-2; i >= 0; i-=2)
        {
            myfile << s[i] << s[i+1] << " "; 
        }

        if (nested)
        {
            s = part2;
            for (int i = s.length()-2; i >= 0; i-=2)
            {
                myfile << s[i] << s[i+1] << " "; 
            }
        }
        myfile << endl;
    }
    while(part1 != 0);

    myfile.close();
    return 0;
}
