CREATE TEMP TABLE #start2 AS
SELECT  ISNULL(MAX(day), '2014-07-24')::timestamp AS dt FROM adwords_spend;

Select * From #start

