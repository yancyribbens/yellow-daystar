# yellow-daystar
Ruby gem which implements verifiable credential data model spec

## Docker

1. build the docker image:

```
  docker build -t yellow-daystar .
```

2. run the data model

```
  docker run -it yellow-daystar
  require 'yellow_daystar'
  vc = YellowDaystar::VerifiableCredential
  vc.produce(context: nil, id: nil, type: nil, credential_subject: nil, proof: nil)
```
