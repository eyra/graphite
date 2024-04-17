Format voor de file die moet worden geupload is heel simpel, het is een csv met deze kolommen:
submission (de ID van de submission)
<metric 1>
<metric 2>
...
<metric n>

De csv heeft een header row (de namen hierboven), en dan voor iedere submissie 1 regel met de waardes voor die kolommen.

| p-value | length | submission|
|---------|--------|-----------|
|0.1|8.0|7|
|0.15|6.0|8|
|0.01|6.0|9|

```
p-value,length,submission
0.1,8.0,7
0.15,6.0,8
0.01,6.0,9

```
Een raar artefact van de parsing binnen Elixir is dat getallen die we als float willen hebben, ook daadwerkelijk een punt moeten hebben (dus 8.0 werkt, maar 8 niet).

Dit is een voorbeeld van de submissions file:


|id|url|ref|
|--|---|---|
|7|git@github.com:eyra/mono.git|d64a0b0e1ea78298c2d895bd190e77446ba929c2|
|8|git@github.com:eyra/mono.git|d64a0b0e1ea78298c2d895bd190e77446ba929c2|
|9|git@github.com:eyra/mono.git|d64a0b0e1ea78298c2d895bd190e77446ba929c2|

```
id,url,ref
7,git@github.com:eyra/mono.git,d64a0b0e1ea78298c2d895bd190e77446ba929c2
8,git@github.com:eyra/mono.git,d64a0b0e1ea78298c2d895bd190e77446ba929c2
9,git@github.com:eyra/mono.git,d64a0b0e1ea78298c2d895bd190e77446ba929c2

```
