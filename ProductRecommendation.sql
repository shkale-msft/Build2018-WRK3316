/*Contoso would like to provide recommended products to its online customers based on the shopping history of previous customers. 
Richard has been tasked to write a recommendation query with the following specifications:
•	If previous customers purchased a product (such as a bicycle) along with another product (such as a helmet) then the next customer buying the same bicycle should also be shown the helmet, particularly if multiple previous customers have purchased the same two items together.
•	The results should not include products already purchased by the customer.
To accomplish this task, Richard will populate the Graph tables from three existing tables in the ContosoDW database. The tables contain information on the Customer(DimCustomer), the Product(DimProduct), and the transaction of the Customer purchasing the Product(FactInternetSales).
The nodes and edge that will be created and used for the Match query are listed below:
Nodes
•	GraphCustomer
•	GraphProduct
Edge
•	purchased
After Richard creates and populates the nodes and edge, he will create a query to display the products other customers have purchased along with the product initially being purchased, and put the products in order based on the frequency of those purchases.
*/

---------------------------------------------------------------------------------------
-- CREATE GRAPH NODE AND EDGE TABLES
---------------------------------------------------------------------------------------

USE ContosoDW
CREATE TABLE GraphCustomer
(
     CustomerKey Integer
    ,CustomerName nvarchar(200)
    ,EmailAddress nvarchar(50)
    ,GeographyKey integer
    ,AddressLine1 nvarchar(120)
    ,AddressLine2 nvarchar(120)
)
AS NODE

CREATE TABLE GraphProduct
(
     ProductKey Integer
    ,ProductName nvarchar(500)
    ,ClassName nvarchar(20)
)
AS NODE

CREATE TABLE purchased AS EDGE;


---------------------------------------------------------------------------------------
-- INSERT DATA INTO NODE AND EDGE TABLES
---------------------------------------------------------------------------------------


USE ContosoDW
INSERT INTO [ContosoDW].[dbo].[GraphCustomer]
(    
     [CustomerKey]
    ,[CustomerName]
    ,[EmailAddress]
    ,[GeographyKey]
    ,[AddressLine1]
    ,[AddressLine2]
)
SELECT
     [CustomerKey]
    ,[FirstName] + ' ' + [LastName]
    ,[EmailAddress]
    ,[GeographyKey]
    ,[AddressLine1]
    ,[AddressLine2]
FROM [ContosoDW].[dbo].[DimCustomer]

USE ContosoDW
INSERT INTO [ContosoDW].[dbo].[GraphProduct]
(
     [ProductKey]
    ,[ProductName]
    ,[ClassName]
)
SELECT 
     [ProductKey]
    ,[EnglishProductName]             
    ,[Class]
FROM  [ContosoDW].[dbo].[DimProduct]

USE ContosoDW
INSERT purchased 
(
     $from_id
    ,$to_id
)
SELECT DISTINCT
     customer.$node_id
    ,product.$node_id
FROM [ContosoDW].[dbo].[FactInternetSales] sales
INNER JOIN [GraphProduct] product ON sales.ProductKey = product.ProductKey
INNER JOIN [GraphCustomer] customer ON customer.CustomerKey = sales.CustomerKey


---------------------------------------------------------------------------------------
-- PRODUCT RECOMMENDATION GRAPH QUERY
---------------------------------------------------------------------------------------


USE ContosoDW
SELECT
     ProductSimilar.ProductName as ProductAlsoBought
    ,COUNT(*) as CountPurchased
FROM 
[dbo].[GraphCustomer] as Customer,
[dbo].[GraphProduct] as Product, 
[dbo].[GraphProduct] as ProductSimilar, 
[dbo].[purchased] as Bought,
[dbo].[purchased] as BoughtAlso
WHERE Product.ProductName = 'Mountain-100 Black, 38' --Product being purchased
AND Customer.CustomerKey <> '26106' -- Customer purchasing product
AND ProductSimilar.ProductName <> Product.ProductName
AND MATCH(ProductSimilar<-(BoughtAlso)-Customer-(Bought)->Product)
GROUP BY ProductSimilar.ProductName, ProductSimilar.ProductKey
ORDER BY CountPurchased DESC


---------------------------------------------------------------------------------------
-- PRODUCT RECOMMENDATION QUERY - THE RELATIONAL WAY
---------------------------------------------------------------------------------------


USE ContosoDW;
WITH Current_Customer AS
(
  SELECT CustomerKey = '26106',
         ProductKey = '348' 
) ,

Other_Customer AS
(
  SELECT DC.CustomerKey, DP.ProductKey, Purchased_by_others = COUNT(*)
  FROM
    DimCustomer AS DC 
  JOIN
    FactInternetSales AS FIS ON FIS.CustomerKey = DC.CustomerKey
  JOIN
    DimProduct AS DP ON DP.ProductKey = FIS.ProductKey
  JOIN
    Current_Customer AS CC ON CC.ProductKey = FIS.ProductKey
  WHERE
    CC.CustomerKey <> FIS.CustomerKey
  GROUP BY
    DC.CustomerKey, DP.ProductKey
) , 
other_products AS
(
       SELECT DC.CustomerKey AS customer_key, 
                 s.ProductKey as product_key, 
                 other_products_purchased = COUNT(*)
       FROM
              DimCustomer as DC
       JOIN
              FactInternetSales as SA ON SA.CustomerKey = DC.CustomerKey
       JOIN
              DimProduct AS S ON S.ProductKey = SA.ProductKey
       JOIN 
              OTHER_CUSTOMER AS OU ON OU.CustomerKey = SA.CustomerKey
       WHERE 
              s.ProductKey <> 348
       GROUP BY
              DC.CustomerKey, s.ProductKey
)
SELECT S.EnglishProductName as ProductAlsoBought
                                , count(other_products_purchased) as CountPurchased
FROM 
       other_products OS
JOIN
       DimProduct S on S.ProductKey = OS.product_key
GROUP BY
       S.EnglishProductName
ORDER BY
       COUNT(other_products_purchased) DESC;
GO



