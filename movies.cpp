// movies.cpp
//
// Implement every function declared in movies.h in this file. Each function's
// required behavior is described in Section 2.3 of the handout.
//
// You may add helper functions in this file (for example, a merge function for
// merge sort). Mark each one `static` and define it above the function that
// uses it. Do not add anything to movies.h.
//
// Allowed headers: <string>, <iostream>, <fstream>, <sstream>,
// <cstring>, <cstdlib>, and "movies.h".

#include <iostream>
#include <string>
#include "movies.h"

// adds a new node holding m at the tail
void appendNode(MovieList& list, const Movie& m) {
    Node* n = new Node;
    n->data = m;
    n->prev = list.tail;
    if (list.tail) {
        list.tail->next = n;
    } else {
        list.head = n;
    }
    list.tail = n;
    list.size++;
}

bool comesBefore(const Movie& a, const Movie& b) {
    // TODO
    (void)a;
    (void)b;
    return false;
}

void sortList(MovieList& list) {
    // TODO
    (void)list;
}

void removeDuplicates(MovieList& list) {
    // TODO
    (void)list;
}

void printList(const MovieList& list) {
    // TODO
    (void)list;
}

void printFiltered(const MovieList& list, int year, const std::string& actor,
                   const std::string& title) {
    // TODO
    (void)list;
    (void)year;
    (void)actor;
    (void)title;
}

void clearList(MovieList& list) {
    // TODO
    (void)list;
}
