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

// true if a sorts before b: by year, then title, then actor
bool comesBefore(const Movie& a, const Movie& b) {
    if (a.year != b.year) {
        return a.year < b.year;
    }
    if (a.title != b.title) {
        return a.title < b.title;
    }
    return a.actor < b.actor;
}

// merges two sorted chains (linked by next only) into one
static Node* merge(Node* a, Node* b) {
    Node dummy;
    Node* end = &dummy;
    while (a && b) {
        if (comesBefore(b->data, a->data)) {
            end->next = b;
            b = b->next;
        } else {
            end->next = a;
            a = a->next;
        }
        end = end->next;
    }
    end->next = a ? a : b;
    return dummy.next;
}

// merge sorts a chain by splitting it in half with slow/fast pointers
static Node* mergeSort(Node* head) {
    if (!head || !head->next) {
        return head;
    }
    Node* slow = head;
    Node* fast = head->next;
    while (fast && fast->next) {
        slow = slow->next;
        fast = fast->next->next;
    }
    Node* second = slow->next;
    slow->next = nullptr;
    return merge(mergeSort(head), mergeSort(second));
}

// sorts the list with merge sort, then fixes prev pointers and tail
void sortList(MovieList& list) {
    list.head = mergeSort(list.head);
    Node* prev = nullptr;
    for (Node* cur = list.head; cur; cur = cur->next) {
        cur->prev = prev;
        prev = cur;
    }
    list.tail = prev;
}

// true if all three fields match
static bool sameMovie(const Movie& a, const Movie& b) {
    return a.year == b.year && a.title == b.title && a.actor == b.actor;
}

// deletes nodes equal to the node before them (list must be sorted)
void removeDuplicates(MovieList& list) {
    Node* cur = list.head;
    while (cur && cur->next) {
        Node* nxt = cur->next;
        if (sameMovie(cur->data, nxt->data)) {
            cur->next = nxt->next;
            if (nxt->next) {
                nxt->next->prev = cur;
            } else {
                list.tail = cur;
            }
            delete nxt;
            list.size--;
        } else {
            cur = nxt;
        }
    }
}

// prints one movie as "Year | Title | Actor"
static void printMovie(const Movie& m) {
    std::cout << m.year << " | " << m.title << " | " << m.actor << "\n";
}

// prints every entry from head to tail
void printList(const MovieList& list) {
    for (Node* cur = list.head; cur; cur = cur->next) {
        printMovie(cur->data);
    }
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
