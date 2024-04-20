# Graphite

## Script

This repo contains a script that:

- takes a settings has configuration for:
  - a CSV file with submissions as input
  - running the predictions & scoring
  - building the final score file
- runs all the submissions against the hold-out data
- returns a CSV file with scores as output.

## Build

```
$ mix escript.build
```

## Run

```
$ ./benchmarking  settings.json
```

## Settings

The `settings.json` file (can have a different name) should have the following
structure:

```json
{
  "template_repo": "<repo-url-of-the-base-repo>",
  "template_repo_ref": "master",
  "repositories_file": "<input CSV file with all repositories>",
  "prediction_volume_mounts": [
    // One or more volume mounts
    {
      "source": "<path to input data>",
      "target": "/data"
    },
    {
      "source": "<path to output folder, preferably empty>",
      "target": "/predictions"
    }
  ],
  "prediction_args": [
    "/data/input.csv",
    "/data/another_input.csv",
    "--output",
    "/predictions/predictions.csv"
  ],
  "score_volume_mounts": [
    {
      "source": "<path to output folder>",
      "target": "/predictions"
    },
    {
      "source": "<ground-truth-path>",
      "target": "/ground_truth"
    }
  ],
  "score_entrypoint": "conda",
  "score_args": [
    "run",
    "python",
    "/app/score.py",
    "/predictions/predictions.csv",
    "/ground_truth/outcome.csv",
    "--output",
    "/predictions/score.csv"
  ],
  "score_file": "out/score.csv",
  "results_file": "outcomes.csv",
  "results_headers": ["accuracy", "precision", "recall", "f1_score"]
}
```
