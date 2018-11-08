DROP TABLE IF EXISTS #start;
CREATE TEMP TABLE #start AS
SELECT  ISNULL(MAX(day), '2014-07-24')::timestamp AS dt FROM adwords_spend;

DROP TABLE IF EXISTS #adwords_spend;
CREATE TEMP TABLE #adwords_spend AS 

SELECT  awdata.day,		
        awdata.campaignid,		
        awdata.adgroupid,   
        COALESCE(mp1.campaigngroup, mp2.campaigngroup)      AS campaigngroup,
        LOWER(COALESCE(mp1.campaign, mp2.campaign, 'no campaign')) AS campaign,
        LOWER(COALESCE(mp1.adgroup, mp2.adgroup, 'no adgroup')) AS adgroup,		
        awdata.keywordid,
        LOWER(lower(awdata.keyword)) AS keyword,
        CASE WHEN awdata.Device = 'Mobile devices with full browsers' THEN 1 ELSE 0 END AS IsMobile,
        lower(COALESCE(mp1.MappedSubject, mp2.mappedsubject, 'no subject')) AS mappedsubject,
        COALESCE(mp1.basecampaignid, mp2.basecampaignid) AS basecampaignid,
        COALESCE(mp1.baseadgroupid, mp2.baseadgroupid) AS baseadgroupid,
        SUM(clicks) AS Clicks,		
        SUM(cost) / 1000000.0 AS Cost,
		SUM(Impressions) AS Impressions,
		CASE
			WHEN sum(impressions) > 0 THEN SUM(avgposition * impressions::numeric (10,2))/SUM(impressions)::numeric (20,2)
		    ELSE 0.00 
		    END AS avgposition,
		CASE 
			WHEN sum(impressions) > 0 THEN SUM(qualityscore*impressions)::numeric (10,2)/ SUM(impressions)::numeric (10,2) 
			ELSE 0.00 
			END AS avgqualityscore

FROM 
(
	SELECT  
		day,
		device,
		campaign,
		campaignid,
		adgroup,
		adgroupid,
		keyword,
		keywordid,
		matchtype,
		avgposition,
		CASE WHEN clicktype = 'Headline' THEN impressions
		ELSE 0 
		END AS impressions,
		clicks,
		cost,
		qualityscore
		
	FROM    
		adwords_keywordreport
	WHERE   
	day >= (SELECT dt FROM #start)

	UNION ALL
	

	SELECT 
		ga.day,
		ga.device,
		ga.campaign,
		ga.campaignid,
		ga.adgroup,
		ga.adgroupid,
		'nokeyword' AS keyword,
		-1 AS keywordid,
		'nomatchtype' AS matchtype,
		ga.avgposition,
		ga.impressions,
		ga.clicks,
		ga.cost,
		-1.0 AS qualityscore

	FROM 	
		adwords_geoadgroupreport ga
-- Filters out campaigns / adgroups which we already got from the keyword report so we don't duplicate cost data:
    	LEFT JOIN (
    		SELECT 	
    			campaignid,
    			adgroupid
    		FROM 	
    			adwords_keywordreport
    		WHERE 	
    			day >= (SELECT dt FROM #start)
    		GROUP BY
    			1,2	
    	
    			) kw ON ga.campaignid = kw.campaignid AND ga.adgroupid = kw.adgroupid
	WHERE 	
		kw.campaignid IS NULL
) awdata


-- appends campaign, adgroup and subject information:
LEFT JOIN  adwords_account_mappings_07202016 mp1 
    ON  awdata.campaignid = mp1.campaignid 
    AND awdata.adgroupid = mp1.adgroupid 
    AND awdata.keywordid = mp1.keywordid
-- alternative:
    
LEFT JOIN (
    SELECT  campaignid, adgroupid,
    		MIN(CASE WHEN basecampaignid IS NOT NULL THEN basecampaignid END) AS basecampaignid,
    		MIN(CASE WHEN baseadgroupid IS NOT NULL THEN baseadgroupid END) AS baseadgroupid,
            MIN(lower(campaigngroup)) AS campaigngroup,
            MIN(lower(campaign)) AS campaign, 
            MIN(lower(adgroup)) AS adgroup, 
            MIN(lower(mappedsubject)) AS mappedsubject
    FROM    adwords_account_mappings_07202016 
    GROUP BY 1,2
 ) mp2 
	ON  awdata.campaignid = mp2.campaignid 
	AND awdata.adgroupid = mp2.adgroupid

/* MP1 & MP2 depend on campaigns to have keywords associated with them because they utilize the keyword report, this 3rd alternative join
 * will provide an option to attribute those campaigns that don't utilize keywords like Display and YouTube & RLSA camapaigns with
 * Campaign Groups, this is vital to our ability to control the data that is loaded into Chartio Dashboards	*/
--LEFT JOIN
	
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12
;

Select * From #adwords_spend