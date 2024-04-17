# CSV File Formats

## Input

### Columns
* submission-id
* url
* ref

### Table

| submission-id | url | ref |
|---------------|-----|-----|
|7|git@github.com:eyra/mono.git|d64a0b0e1ea78298c2d895bd190e77446ba929c2|
|8|git@github.com:eyra/mono.git|d64a0b0e1ea78298c2d895bd190e77446ba929c2|
|9|git@github.com:eyra/mono.git|d64a0b0e1ea78298c2d895bd190e77446ba929c2|

### Example

```
submission-id,url,ref
7,git@github.com:eyra/mono.git,d64a0b0e1ea78298c2d895bd190e77446ba929c2
8,git@github.com:eyra/mono.git,d64a0b0e1ea78298c2d895bd190e77446ba929c2
9,git@github.com:eyra/mono.git,d64a0b0e1ea78298c2d895bd190e77446ba929c2

```

## Output 

### Columns
* submission-id
* url
* ref
* \<metric 1\>
* \<metric 2\>
* ...
* \<metric n\>

### Table
De csv heeft een header row (de namen hierboven), en dan voor iedere submissie 1 regel met de waardes voor die kolommen.

| submission-id | url | ref | metric-1 | metric-2 |
|---------------|-----|-----|----------|----------|
|7|git@github.com:eyra/mono.git|d64a0b0e1ea78298c2d895bd190e77446ba929c2|0.1|8.0|
|8|git@github.com:eyra/mono.git|d64a0b0e1ea78298c2d895bd190e77446ba929c2|0.15|6.0|
|9|git@github.com:eyra/mono.git|d64a0b0e1ea78298c2d895bd190e77446ba929c2|0.01|6.0|

### Example

```
submission-id,url,ref,metric-1,metric-2
7,git@github.com:eyra/mono.git,d64a0b0e1ea78298c2d895bd190e77446ba929c2,0.1,8.0
8,git@github.com:eyra/mono.git,d64a0b0e1ea78298c2d895bd190e77446ba929c2,0.15,6.0
9,git@github.com:eyra/mono.git,d64a0b0e1ea78298c2d895bd190e77446ba929c2,0.01,6.0

```
Een raar artefact van de parsing binnen Elixir is dat getallen die we als float willen hebben, ook daadwerkelijk een punt moeten hebben (dus 8.0 werkt, maar 8 niet).

