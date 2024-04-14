import sys
import argparse
import csv

parser = argparse.ArgumentParser(description="Process and score data.")
subparsers = parser.add_subparsers(dest="command")

# Process subcommand
process_parser = subparsers.add_parser(
    "predict", help="Process input data for prediction."
)
process_parser.add_argument("input_path", help="Path to input data CSV file.")
process_parser.add_argument("--output", help="Path to prediction output CSV file.")

# Score subcommand
score_parser = subparsers.add_parser("score", help="Score (evaluate) predictions.")
score_parser.add_argument("prediction_path", help="Path to predicted outcome CSV file.")
score_parser.add_argument(
    "ground_truth_path", help="Path to ground truth outcome CSV file."
)
score_parser.add_argument("--output", help="Path to evaluation score output CSV file.")

args = parser.parse_args()


def predict(input_path, output):
    with open(output, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["prediction"])
        writer.writerow([1])


def score(prediction_path, ground_truth_path, output):
    with open(output, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["score"])
        writer.writerow([2])


if __name__ == "__main__":
    args = parser.parse_args()
    if args.command == "predict":
        predict(args.input_path, args.output)
    elif args.command == "score":
        score(args.prediction_path, args.ground_truth_path, args.output)
    else:
        parser.print_help()
        predict(args.input_path, args.output)
        sys.exit(1)
