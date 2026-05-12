# INitiator
It generates jobs and start them.
```
INitiator (Cloud Run Job)
   ↓
generates files in GCS
   ↓
triggers downstream jobs:
   - details-wc-s1-job
   - tickers-wc-s1-job
```
## Input
It accepts the following ENV VARS:
- BUCKET
- ISIN_LIST=isin1|isin2|...
- TYPE_LIST=[quotes|details|tickers]+
- ISSUER=[bnp|leonteq|marex|vontobel]
- (optional) START_JOBS=[details|tickers]
- (optional) SILENT_MODE=false (if `true` then `setup.sh` does not wait for user confirm)

## Output
It produces:
- for TYPE as **'details'**
    - for ea. ISIN, a $ISIN.csv file that contains 1 line as 
`
https://....com/kid/$ISIN,$ISIN.md, startline, endline
`
    - the URL and other parameters depends on the ISSUER and TYPE var
    - the file is stored into  /data/$TYPE/jobs/1

- for TYPE as **'tickers'**
    - for ea. ISIN, a $ISIN.csv file that contains 1 line as 
`
https://....com/data/$ISIN,$ISIN.md, startline, endline
`
    - the URL and other parameters depends on the ISSUER and TYPE var
    - the file is stored into  /data/$TYPE/jobs/1

- for TYPE as **'quotes'**
    - for ea. ISIN, appends a line to /data/$TYPE/config/<ISSUER>.urls.$FORMAT:  
`
https://....com/$ISIN,$ISIN.$FORMAT
`
    - the URL and other parameters (FORMAT) depends on the ISSUER var

## Job starts
INitiator will start the following jobs, if `START_JOBS` was properly provided:
- `$TYPE-wc-s1-job` when TYPE is `details` or `tickers`

While `quotes-wc-batch-job` is a scheduled job.