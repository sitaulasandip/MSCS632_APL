
```powershell
swipl -q -g demo -t halt family_tree.pl
```

Or load it interactively and ask your own questions:

```powershell
swipl family_tree.pl
```

```prolog
?- children_of(john, Children).
?- sibling(mary, X).
?- cousin(emma, olivia).
?- descendants_of(george, L).
?- demo.
```
