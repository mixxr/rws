EXPORT DATA OPTIONS (
    uri="gs://rws-data/bq_export/staging_certs_growth_*.csv",
    format="CSV",
    overwrite=true,
    header=true,
    field_delimiter=";"
  )
  AS
  select
      upper(d.isin) as isin,
      d.issuer as issuer,
      d.name as name,
      d.coupon as coupon,
      d.next_ex_date as next_ex_date,
      qc.ask as ask,
      qc.bid as bid,
      qc.Growth_1D as Growth_1D,
      qc.Growth_3Ds as Growth_3Ds,
      qc.Growth_1W as Growth_1W,
      qc.Growth_2W as Growth_2W,
      qc.Growth_4W as Growth_4W,
      qc.Growth_1D_Pct as Growth_1D_Pct,
      qc.Growth_3Ds_Pct as Growth_3Ds_Pct,
      qc.Growth_1W_Pct as Growth_1W_Pct,
      qc.Growth_2W_Pct as Growth_2W_Pct,
      qc.Growth_4W_Pct as Growth_4W_Pct,
      qc.Last_Update_DT as Last_Update_DT,
      qc.Par_Value as Par_Value
  from `ISINs.v_quotes_consolidated` qc
  inner join `ISINs.v_next_ex_date` d
      on upper(qc.isin) = upper(d.isin)