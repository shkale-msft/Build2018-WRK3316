/* Contoso has found that a product (Sport-100 Helmet, Black) which has been sold in the United States by its resellers is being recalled by the manufacturer. Contoso needs to find the amount of the recalled items that each reseller has sold and get the address information for the reseller through the GeographyKey, which is a foreign key to the DimGeography table of ContosoDW.
Richard can develop a Graph query to accomplish these tasks by adding a node for Resellers and an edge for the product they sold. He will then join the new Graph tables to the DimGeography table that already exists in the Contoso data warehouse with a common table expression. This will allow Richard to filter on the Resellers that are located in the United States.
The nodes and edge that will be created and used for the Match query are listed below:
Nodes
•	GraphProduct
•	GraphReseller
Edge
•	resell

*/

---------------------------------------------------------------------------------------
-- CREATE GRAPH NODE AND EDGE TABLES
---------------------------------------------------------------------------------------

CREATE TABLE GraphReseller
(
                ResellerKey Integer
                ,ResellerName nvarchar(50)
                ,GeographyKey Integer
                ,BusinessType varchar(20)
                ,AddressLine1 nvarchar(120)
                ,AddressLine2 nvarchar(120)
)
AS NODE

CREATE TABLE resell 
(
                OrderDateKey Integer
)
AS EDGE;


---------------------------------------------------------------------------------------
-- INSERT DATA INTO NODE AND EDGE TABLES
---------------------------------------------------------------------------------------
INSERT INTO [ContosoDW].[dbo].[GraphReseller]
(
     [ResellerKey]
    ,[ResellerName]
    ,[GeographyKey]
    ,[BusinessType]
    ,[AddressLine1]
    ,[AddressLine2]
)
SELECT
     [ResellerKey]
    ,[ResellerName]
    ,[GeographyKey]
    ,[BusinessType]
    ,[AddressLine1]
    ,[AddressLine2]
From [ContosoDW].[dbo].[DimReseller]

INSERT resell
($from_id, $to_id, OrderDateKey)
SELECT DISTINCT
    r.$node_id,
    p.$node_id,
    resell.OrderDateKey
FROM [ContosoDW].[dbo].[FactResellerSales] resell
INNER JOIN [GraphReseller] r ON resell.ResellerKey = r.ResellerKey
INNER JOIN [GraphProduct] p ON resell.ProductKey = p.Productkey


---------------------------------------------------------------------------------------
-- RESELLER RECALL GRAPH QUERY
---------------------------------------------------------------------------------------


USE ContosoDW
SELECT 
     Reseller.ResellerKey as ResellerKey
    ,Reseller.ResellerName as ResellerName
    ,COUNT(*) as CountResold
FROM 
[dbo].[GraphProduct] as Product,
[dbo].[GraphReseller] as Reseller,
[dbo].[resell] as resold
WHERE MATCH(Reseller-(resold)->Product)
AND Product.ProductName = 'Sport-100 Helmet, Black'  --Product Being Recalled 
GROUP BY  Reseller.ResellerName, Reseller.ResellerKey
ORDER BY CountResold DESC


---------------------------------------------------------------------------------------
-- FOLLOWING QUERY JOINS THE GRAPH AND RELATIONAL DATA TOGETHER
---------------------------------------------------------------------------------------

/*Note: You should now see the resellers and the number of helmets being recalled. You will now join this query to the [DimGeography] SQL Server table using a common table expression.*/
/*Note: This query will return the resellers that have sold the helmet and are located within the United States.*/
USE ContosoDW;
WITH Resellers as
(
SELECT 
     Reseller.ResellerName as ResellerName
    ,Reseller.GeographyKey as GeographyKey
    ,Reseller.AddressLine1 as AddressLine1
    ,Reseller.AddressLine2 as AddressLine2
    ,COUNT(*) as CountResold
FROM 
[dbo].[GraphProduct] as Product,
[dbo].[GraphReseller] as Reseller,
[dbo].[resell] as resold
WHERE MATCH(Reseller-(resold)->Product)
AND Product.ProductName = 'Sport-100 Helmet, Black'  --Product Being Recalled
GROUP BY Reseller.ResellerName, Reseller.GeographyKey, Reseller.AddressLine1, Reseller.AddressLine2
)
SELECT 
     CountResold
    ,ResellerName
    ,r.AddressLine1
    ,r.AddressLine2
    ,g.City
    ,g.stateprovincename as State
    ,g.postalcode as PostalCode
    ,g.englishcountryregionname as Country
FROM Resellers as r
INNER JOIN dbo.DimGeography as g on r.GeographyKey = g.GeographyKey
WHERE g.englishcountryregionname = 'United States' -- only recall products sold through US resellers.
ORDER BY CountResold DESC


