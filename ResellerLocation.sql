/* Creating a Graph Query for the Reseller Location Scenario
Contoso needs to expand their product recall to include all Internet sales of the Sport-100 Helmet, Black product. Contoso also wants to recommend that customers who purchased the product go to a reseller to ensure the product is safe, or replace it if it is not safe.
Richard can develop a Graph query to match customers to resellers by creating a GraphGeography node from the DimGeography table. Since edges can be populated from different nodes, Richard will create a new edge called locatedIn and populate it with information from the Customers node and the Resellers node.
This query also needs to be fast as it may be used in the future to suggest retail locations to all online customers. Since Graph tables are integrated into the SQL Server ecosystem, the majority of functions that are used to increase performance from regular SQL queries can also be applied to Graph Databases.
Richard will create multiple clustered columnstore indexes on the new Geography node and locatedIn edge, as well as the nodes and edges created earlier in the lab.
The nodes and edges that will be created and used for the Match query are listed below:
Nodes
•	GraphCustomer
•	GraphProduct
•	GraphReseller
•	GraphGeography
Edges
•	purchased
•	resell
•	locatedIn
*/

---------------------------------------------------------------------------------------
-- CREATE GRAPH NODE AND EDGE TABLES
---------------------------------------------------------------------------------------

CREATE TABLE GraphGeography
(
                  GeographyKey Integer
                ,City nvarchar(30)
                ,StateProvinceCode nvarchar(3)
                ,StateProvinceName nvarchar(50)
                ,PostalCode nvarchar(15)
                ,CountryRegionCode nvarchar(3)
                ,EnglishCountryRegionName nvarchar(50)
)
AS NODE


CREATE TABLE locatedIn 
(
                AddressLine1 nvarchar(120)
                ,AddressLine2 nvarchar(120)

)
AS EDGE;


---------------------------------------------------------------------------------------
-- INSERT DATA INTO NODE AND EDGE TABLES
---------------------------------------------------------------------------------------

--Populate GraphGeography
INSERT INTO [ContosoDW].[dbo].[GraphGeography]
(
     [GeographyKey]
    ,[City]
    ,[StateProvinceCode]
    ,[StateProvinceName]
    ,[PostalCode]
    ,[CountryRegionCode]
    ,[EnglishCountryRegionName]
)
SELECT
     [GeographyKey]
    ,[City]
    ,[StateProvinceCode]
    ,[StateProvinceName]
    ,[PostalCode]
    ,[CountryRegionCode]
    ,[EnglishCountryRegionName]
FROM [ContosoDW].[dbo].[DimGeography]

--populate locatedIn Edge with Reseller location
INSERT locatedIn
($from_id, $to_id, AddressLine1, AddressLine2)
SELECT DISTINCT
     r.$node_id
    ,gg.$node_id
    ,r.AddressLine1
    ,r.AddressLine2
FROM [DimGeography] dg
INNER JOIN [GraphGeography] gg on dg.geographykey = gg.geographykey
INNER JOIN [GraphReseller] r on dg.GeographyKey = r.GeographyKey

--populate locatedIn Edge with Customer location
INSERT locatedIn
($from_id, $to_id, AddressLine1, AddressLine2)
SELECT DISTINCT
     c.$node_id
    ,gg.$node_id
    ,c.AddressLine1
    ,c.AddressLine2
FROM [DimGeography] dg
INNER JOIN [GraphGeography] gg on dg.geographykey = gg.geographykey
INNER JOIN [GraphCustomer] c on dg.GeographyKey = c.GeographyKey


---------------------------------------------------------------------------------------
-- CREATE CLUSTERED COLUMNSTORE INDEXES
---------------------------------------------------------------------------------------


USE ContosoDW
CREATE CLUSTERED COLUMNSTORE INDEX customer_cci 
ON GraphCustomer;

CREATE CLUSTERED COLUMNSTORE INDEX product_cci
ON GraphProduct;

CREATE CLUSTERED COLUMNSTORE INDEX reseller_cci
ON GraphReseller;

CREATE CLUSTERED COLUMNSTORE INDEX geography_cci
ON GraphGeography;

CREATE CLUSTERED COLUMNSTORE INDEX purchased_cci
ON purchased;

CREATE CLUSTERED COLUMNSTORE INDEX resell_cci
ON resell;

CREATE CLUSTERED COLUMNSTORE INDEX locatedIn_cci
ON locatedIn;


---------------------------------------------------------------------------------------
-- FIND THE RESELLER CLOSEST TO THE CUSTOMER OR COLOCATED RESELLER AND CUSTOMER
---------------------------------------------------------------------------------------

/* You should now see the customers that purchased the product and the resellers that are located in the same city as the customer.*/
SELECT 
     Customer.CustomerName
    ,Customer.EmailAddress
    ,Reseller.ResellerName
    ,resellerLocatedIn.AddressLine1
    ,resellerLocatedIn.AddressLine2
    ,Location.[City]
    ,Location.[StateProvinceCode]
    ,Location.[StateProvinceName]
    ,Location.[PostalCode]
    ,Location.[englishcountryregionname]
FROM 
[dbo].[GraphProduct] as Product,
[dbo].[GraphReseller] as Reseller,
[dbo].[GraphCustomer] as Customer,
[dbo].[GraphGeography] as Location,
[dbo].[purchased] as purchased,
[dbo].[locatedIn] as customerLocatedIn,
[dbo].[locatedIn] as resellerLocatedIn
WHERE Match(Product<-(purchased)-Customer-(customerLocatedIn)->Location<-(resellerLocatedIn)-Reseller)
AND Product.ProductName = 'Sport-100 Helmet, Black'

/* Richard was able to quickly create and use a Geography node to heterogeneously connect the Customer and the Reseller along the locatedIn Edge.
This will allow Contoso to inform the customers who purchased the recalled product, where a nearby retail location is located and could eventually be used to suggest retail locations to all online customers.
The clustered columnstore indexes Richard implemented will help to ensure performance future Graph query's.
*/

