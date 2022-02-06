This mini-project demonstrates a simple filter plugin

Your custom filter

Must implement a "filters" function that returns a lookup table containing 
pointers to functions/methods for a "filter key"

```
a_filter: self.a_filter
```

The first variable in a method that implements the filter is the input from a |
e.g.

Given
```
{{ 'test' | a_filter }}

Then 'test' will be the argument for the method parameter, a_variable

def a_filter(self, a_variable)
...
```

Different types can be passed.
```
def c_filter(self,a_variable, servers):
  out = []

  for server in servers:
    out.append(server + "pdteam.apple.com")
  
  # returns a list as the output
  return out
```



