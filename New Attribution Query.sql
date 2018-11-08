SELECT 
	AGGR.campaign,
	AGGR.campaignid,
	AGGR.adgroup,
	AGGR.adgroupid,
	CASE  
    	WHEN (campaign IN (
    		'Search_ROASExpansionTest_Beta',
    		'Search_ROASExpansionTest_Gamma'))
    		OR AGGR.campaign LIKE '%testing%'
    		OR AGGR.campaign LIKE '%lp test%'
    		OR AGGR.campaign LIKE '%lp_test%'             
        	THEN 'non_brand_experimental'  
        WHEN
        	AGGR.campaign LIKE '%GDN%'
        	OR AGGR.campaign LIKE '%display%'
        	OR campaign IN ('Android In-app Conversions','Android In-app Conversions')
        	THEN 'display'
        WHEN 
        	AGGR.campaign LIKE '%YT%'
        	OR AGGR.campaign LIKE '%Youtube%'
        	OR AGGR.campaign LIKE '%Video%'
        	THEN 'Video'
		WHEN
			AGGR.campaign LIKE '%brand%'
			OR AGGR.campaign LIKE '%recruiting%'
			 OR AGGR.campaign LIKE '%content%'
			 OR AGGR.campaign LIKE '%remarketing%'
			 OR AGGR.campaign LIKE '%dsk%'
			 OR AGGR.campaign LIKE '%yahoo%'
			 OR AGGR.campaign LIKE '%bing%'
			THEN 'brand'
        ELSE  'non_brand_core'
        END AS campaigngroup
FROM 
	public.adwords_geoadgroupreport AGGR

WHERE
	AGGR.day  > current_date - 100
	
GROUP BY
	1,2,3,4,5

ORDER BY
	1,3
	
-- So by inserting this into the COALESCE statement in position 3 it should apply campaign names as long as there is a record within date range specified
-- in the where clause. So i think if i want this to work with the existing chartio and Agg statement i need to evaluate the appropriate time period
-- for this. 	
	
-- Now this solves the problem of missing attribution in the adwords_spend table but i may want to add additional values to this 
-- Table to more accurately handle the graphical requirements of these.

-- Keyword & Mapped subject will remain blank but that should be okay for most of this.
	
	