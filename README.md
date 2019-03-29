# yellow-daystar
Ruby gem which implements verifiable credential data model spec

## Example

1. build the docker image:

```
  docker build -t yellow-daystar .
```

2. import gem

```
  docker run -it yellow-daystar
  require 'yellow_daystar'
  vc = YellowDaystar::VerifiableCredential
```

4. produce a credential:

```
vc.produce(context: nil, id: nil, type: nil, credential_subject: nil, proof: nil)
```

5. consume a credential:

```
require 'open-uri'
credential  = open('https://raw.githubusercontent.com/w3c/vc-test-suite/gh-pages/test/vc-data-model-1.0/input/example-1.jsonld') {|f| f.read }
vc.consume(JSON.parse(credential))
```
