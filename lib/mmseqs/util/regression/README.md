# MMseqs2 Regression Test

The regression test runs most workflows (search, profile search, profile-profile, target-profile, clustering, linclust, etc.) after every commit.
It compares their results against known good values and fails if they don't match.

To run the regression test suite execute the following steps: 

```
./run_regression.sh path-to-mmseqs-binary intermediate-files-scratch-directory
```

The test suite will print a report telling if each test passed or failed.
