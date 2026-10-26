// main.cpp
//
// Write main() in this file. It must:
//   - read the command line (Section 7 of the handout),
//   - read and parse the input file, calling appendNode once per line (Section 6),
//   - sort the list, remove duplicates, print the full or filtered list,
//     and free the list (Sections 3, 4, and 8),
//   - print the exact error messages in Section 8 to std::cerr and return 1 on errors.
//
// You may add helper functions in this file. Mark each one `static` and define
// it above the function that uses it. Do not add anything to movies.h.
//
// Allowed headers: <string>, <iostream>, <fstream>, <sstream>,
// <cstring>, <cstdlib>, and "movies.h".

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include "movies.h"

// returns a copy of s without spaces, tabs, '\r', or '\n' at either end
static std::string trim(const std::string& s) {
    size_t start = s.find_first_not_of(" \t\r\n");
    if (start == std::string::npos) {
        return "";
    }
    size_t end = s.find_last_not_of(" \t\r\n");
    return s.substr(start, end - start + 1);
}

// turns one "Year | Title | Actor" line into a Movie
static Movie parseLine(const std::string& line) {
    std::stringstream ss(line);
    std::string yearText, title, actor;
    std::getline(ss, yearText, '|');
    std::getline(ss, title, '|');
    std::getline(ss, actor);
    Movie m;
    m.year = std::stoi(trim(yearText));
    m.title = trim(title);
    m.actor = trim(actor);
    return m;
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: ./LinkedList <input_file> [--year <year> | --actor \"<name>\" | --title \"<title>\"]\n";
        return 1;
    }

    // read the optional filter
    int year = 0;
    std::string actor, title;
    bool filtered = false;
    if (argc == 4) {
        std::string option = argv[2];
        std::string value = argv[3];
        if (option == "--year") {
            year = std::stoi(value);
        } else if (option == "--actor") {
            actor = value;
        } else if (option == "--title") {
            title = value;
        } else {
            std::cerr << "Error: invalid arguments\n";
            return 1;
        }
        filtered = true;
    } else if (argc != 2) {
        std::cerr << "Error: invalid arguments\n";
        return 1;
    }

    std::ifstream infile(argv[1]);
    if (!infile.is_open()) {
        std::cerr << "Error: cannot open file\n";
        return 1;
    }

    // read the file one line at a time, skipping blank lines
    MovieList list;
    std::string line;
    while (std::getline(infile, line)) {
        if (trim(line).empty()) {
            continue;
        }
        appendNode(list, parseLine(line));
    }
    infile.close();

    sortList(list);
    removeDuplicates(list);
    if (filtered) {
        printFiltered(list, year, actor, title);
    } else {
        printList(list);
    }
    clearList(list);
    return 0;
}
