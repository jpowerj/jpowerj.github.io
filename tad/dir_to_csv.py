# Take a directory containing a bunch of .txt files (a corpora)
# and convert it into a single .csv file where each line represents
# one text.
import argparse
import sys

def create_csv(dir_name):
    

def main():
    # Parse the command-line argument
    parser = argparse.ArgumentParser()
    parser.add_argument('dir_name')
    args = parser.parse_args()
    dir_name = args.dir_name
    create_csv(dir_name)

if __name__ == "__main__":
    main()