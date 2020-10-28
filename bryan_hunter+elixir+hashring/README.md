# Globo

Simple example of using a HashRing to deterministically place processes on nodes by key rather than using a distributed registry.

This sample distributes actors across the cluster using the HashRing. As new nodes join the cluster there is basic migration for keys that no longer belong on the given node. 

This sample does not implement process pairs for hand-offs. If a node goes down the actors on that node are lost.

## Demo

Open three terminals

Terminal 1
```
$ iex --sname dracula@localhost -S mix
```

Terminal 2
```
$ iex --sname mummy@localhost -S mix
```

Terminal 3
```
$ iex --sname wolfman@localhost -S mix
```

Terminal 1: Create three actors (by key) and put a value in each 
```
iex> Node.connect(:mummy@localhost)
true
iex> Globo.put("fruit", "banana")
:ok 
iex> Globo.put("breakfast", "cheerios")
:ok
iex> Globo.put("sport", "curling")
:ok
```

Terminal 1: Ask the three actors (by key) to tell us about their location and state
```
iex> Globo.speak("fruit")     
Speaking: "Actor \"fruit\" on node mummy@localhost has value: \"banana\""
iex> Globo.speak("breakfast")
Speaking: "Actor \"breakfast\" on node dracula@localhost has value: \"cheerios\""
iex> Globo.speak("sport")
Speaking: "Actor \"sport\" on node mummy@localhost has value: \"curling\""
```

Terminal 1: Connect to the third node and see how migration happens
```
iex> Node.connect(:wolfman@localhost)
Moved misplaced actor: "breakfast"
iex> Globo.speak("breakfast")
Speaking: "Actor \"breakfast\" on node wolfman@localhost has value: \"cheerios\""
```

Terminal 2: Show that it doesn't matter where we do things.
```
iex> Globo.put("breakfast", "burned toast")
:ok
iex> Globo.speak("breakfast")
Speaking: "Actor \"breakfast\" on node wolfman@localhost has value: \"burned toast\""
```

Terminal 1: Ask dracula for breakfast
```
iex> Globo.speak("breakfast")
Speaking: "Actor \"breakfast\" on node wolfman@localhost has value: \"burned toast\""
```

Terminal 3: Ask wolfman for breakfast
```
iex> Globo.speak("breakfast")
Speaking: "Actor \"breakfast\" on node wolfman@localhost has value: \"burned toast\""
```