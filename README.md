# Build2018-WRK3316

SQL Server 2017: Graph Databases
SQL Server offers Graph database capabilities to model many-to-many relationships. The Graph relationships are integrated into Transact-SQL and share the benefits of using SQL Server as the foundational database management system.

Overview
Graph databases in SQL Server are composed of node and edge tables. A node represents an entity like a customer, product, or business, while an edge represents a relationship that exists between two nodes like purchased, employed by, and located in. Because nodes and edges are first-class entities in the database, each have properties associated with them and can be populated by existing tables in SQL Server.
Edges have two properties which express the relationship it connects, going From one node To another node. Edges are also heterogeneous in that they can connect multiple nodes together. For example, a Customer node can have the edge LocatedIn connecting to a Location node, and a Store node can use the same edge LocatedIn to connect to a Location node.

Use Cases for Graph Databases
Graph databases are great for producing powerful maintainable queries that would otherwise be cumbersome to do within a traditional SQL relational database. However, all query functionality within SQL Server 2017 Graph databases can be reproduced with traditional SQL tables and queries. Graph databases tend to work well in specific scenarios. If relationships have been defined as a primary application requirement, Graph databases can be used to solve the problem more intuitively and with highly maintainable code. They are also used for easily expressing pattern matching or multi-hop navigation queries.
Some of the common types of scenarios are listed below:
•	Recommendation systems
•	Content management
•	Fraud detection
•	Customer relationship management (CRM)
•	Hierarchical product/content models
For the Contoso data scenarios in this lab, you will need to create and populate the node and edge tables from existing SQL tables. Once the nodes and edges of the Graph database have been populated with data, you can query the Graph data using the new Match clause which supports pattern matching and multi-hop navigation through the Graph database. Match uses ASCII-art style syntax for pattern matching. The From and To direction on the edge is tied to the direction of the -> arrow.
    -- Find friends of John
    SELECT Person2.Name 
    FROM Person Person1, Friends, Person Person2
    WHERE MATCH(Person1-(Friends)->Person2)
    AND Person1.Name = 'John';

The Contoso Story
Richard the DBA for Contoso has been tasked with writing queries for the following scenarios:
1.	Contoso would like to provide recommended products to its online customers based on the shopping history of previous customers. If previous customers purchased a product (such as a bicycle) along with another product (such as a helmet) then the next customer buying the same bicycle should also be shown the helmet, particularly if multiple previous customers have purchased the same two items together.
2.	Contoso needs to issue a recall for a product that is causing safety issues for customers. Contoso needs to quickly compile a list of resellers that sold a specific product so that they can send replacement parts to the resellers.
3.	Contoso is expanding the recall to customers that purchased the product online. In order to ensure the product is safely installed, Contoso wants to recommend that customers take the recalled product to a nearby authorized reseller to have it installed.
Richard realizes that these queries could be done with the existing SQL tables in the Contoso data warehouse, however Richard also knows that SQL Server 2017 has Graph processing capabilities which will make these queries quicker and easier to write and maintain.

