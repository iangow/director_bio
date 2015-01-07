# Code to create "cliques";
# Can be used to take pairs of identifiers with the relation "same person" and
# generate all identifiers associated with each person.
pairs = [[1,2], [2,5], [3,4], [4,6]]

from sets import Set

set_list = [Set(pairs[0])]

for pair in pairs[1:]:
    matched=False
    for set in set_list:
        if pair[0] in set or pair[1] in set:
            set.update(pair)
            matched=True
    if not matched:
        set_list.append(Set(pair))
            
print(set_list)            
